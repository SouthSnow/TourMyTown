//
//  Locations.m
//  TourMyTown
//
//  Created by Michael Katz on 8/15/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import "Locations.h"
#import "Location.h"
#import "AFNetworking.h"
#import <MobileCoreServices/UTType.h>

//static NSString* const kBaseURL = @"http://127.0.0.1:3001/";

//static NSString* const kBaseURL = @"http://45.124.66.158:3001/";
//static NSString* const kLocations = @"locations/";
//static NSString* const kFiles = @"files/";


@interface Locations ()<NSURLSessionDataDelegate>
@property (nonatomic, strong) Location *currentLocation;
@property (nonatomic, strong) NSMutableArray* objects;

@end

@implementation Locations

- (id)init
{
    self = [super init];
    if (self) {
        _objects = [NSMutableArray array];
        _locations = [NSMutableArray arrayWithCapacity:1];
    }
    return self;
}

- (NSArray*) filteredLocations
{
    return [self objects];
}

- (void) addLocation:(Location*)location
{
    [self.objects addObject:location];
}

- (void)loadImage:(Location*)location
{
    NSURL* url = [NSURL URLWithString:[[kBaseURL stringByAppendingString:kFiles] stringByAppendingString:location.imageId]]; //1
    
    NSLog(@"ImageUrl: %@", url);
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDownloadTask* task = [session downloadTaskWithURL:url completionHandler:^(NSURL *fileLocation, NSURLResponse *response, NSError *error) { //2
        if (!error) {
            NSData* imageData = [NSData dataWithContentsOfURL:fileLocation]; //3
            UIImage* image = [UIImage imageWithData:imageData];
            if (!image) {
                NSLog(@"unable to build image");
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                location.image = image;
                if (self.delegate) {
                    [self.delegate modelUpdated];
                }
            });
            
        }
    }];
    
    [task resume]; //4
}

- (void)import
{
    NSURL* url = [NSURL URLWithString:[kBaseURL stringByAppendingString:kLocations]]; //1
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET"; //2
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"]; //3
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration]; //4
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
        if (error == nil) {
            NSArray* responseArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]; //6
            [self parseAndAddLocations:responseArray toArray:self.objects]; //7
        }
    }];
    
    [dataTask resume]; //8
}

- (void)parseAndAddLocations:(NSArray*)locations toArray:(NSMutableArray*)destinationArray
{
    [_locations removeAllObjects];
    
    for (NSDictionary* item in locations) {
        Location* location = [[Location alloc] initWithDictionary:item];
        [destinationArray addObject:location];
        if (location.imageId) { //1
            [self loadImage:location];
            [_locations addObject:location];

        }
    }
    
    if (self.delegate) {
        [self.delegate modelUpdated];
    }
}

- (void) runQuery:(NSString *)queryString
{
    NSString* urlStr = [[kBaseURL stringByAppendingString:kLocations] stringByAppendingString:queryString]; //1
    NSURL* url = [NSURL URLWithString:urlStr];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            [self.objects removeAllObjects]; //2
            NSArray* responseArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            NSLog(@"received %lu items", (unsigned long)responseArray.count);
            [self parseAndAddLocations:responseArray toArray:self.objects];
        }
    }];
    [dataTask resume];
}

- (void) queryRegion:(MKCoordinateRegion)region //1
{
    //not assumes the NE hemisphere. This logic should really check first.
    //also note that searches across hemisphere lines are not interpreted properly by Mongo
    CLLocationDegrees x0 = region.center.longitude - region.span.longitudeDelta; //2
    CLLocationDegrees x1 = region.center.longitude + region.span.longitudeDelta;
    CLLocationDegrees y0 = region.center.latitude - region.span.latitudeDelta;
    CLLocationDegrees y1 = region.center.latitude + region.span.latitudeDelta;
    
    NSString* boxQuery = [NSString stringWithFormat:@"{\"$geoWithin\":{\"$box\":[[%f,%f],[%f,%f]]}}",x0,y0,x1,y1]; //3
    NSString* locationInBox = [NSString stringWithFormat:@"{\"location\":%@}", boxQuery]; //4
    NSString* escBox = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                             (CFStringRef) locationInBox,
                                                                                             NULL,
                                                                                             (CFStringRef) @"!*();':@&=+$,/?%#[]{}",
                                                                                             kCFStringEncodingUTF8)); //5
    NSString* query = [NSString stringWithFormat:@"?query=%@", escBox]; //6
    [self runQuery:query]; //7
}


- (void) saveNewLocationImageFirst1:(Location*)location {
    
    NSURL* url = [NSURL URLWithString:[kBaseURL stringByAppendingString:kFiles]]; //1
    CGSize newSize = CGSizeMake(300, 400);
    UIGraphicsBeginImageContext(CGSizeMake(300, 400));
    [location.image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    //NSLog(@" 转换图片1：%@",newImage);
    UIGraphicsEndImageContext();
    
    NSData* bytes = UIImagePNGRepresentation(newImage); //4
    
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager POST:[kBaseURL stringByAppendingString:kFiles] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:bytes
                                    name:@"files"
                                fileName:@"logo.png" mimeType:@"image/jpeg"];
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"responseObject: %@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.localizedDescription);
    }];
}

- (void) saveNewLocationImageFirst:(Location*)location
{
    
    self.currentLocation = location;
    
    NSURL* url = [[NSURL URLWithString:kBaseURL]URLByAppendingPathComponent:kFiles]; //1
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"0xKhTmLbOuNdArY";
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@",charset, boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *tempPostData = [NSMutableData data];
    [tempPostData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    
    // Sample file to send as data
    [tempPostData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"files\"; filename=\"%@\"\r\n", @"company-logo.png"] dataUsingEncoding:NSUTF8StringEncoding]];
    [tempPostData appendData:[[[@"Content-Type: " stringByAppendingString:AFContentTypeForPathExtension([@"company-logo.png" pathExtension])]stringByAppendingString:@"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    CGSize newSize = CGSizeMake(300, 400);
    UIGraphicsBeginImageContext(CGSizeMake(300, 400));
    [location.image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    //NSLog(@" 转换图片1：%@",newImage);
    UIGraphicsEndImageContext();
    
    NSData* bytes = UIImagePNGRepresentation(newImage); //4
    
    [tempPostData appendData:bytes];
    
    [tempPostData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:tempPostData];
    [request setValue:[NSString stringWithFormat:@"%lu",(unsigned long)tempPostData.length] forHTTPHeaderField:@"Content-Length"];
    
    
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionUploadTask *streamTask = [session uploadTaskWithStreamedRequest:request];
    [streamTask resume];
}


- (void) persist:(Location*)location
{
    if (!location || location.name == nil || location.name.length == 0) {
        return; //input safety check
    }
    
    //if there is an image, save it first
    if (location.image != nil && location.imageId == nil) { //1
        [self saveNewLocationImageFirst:location]; //2
        return;
    }
    
    
    NSString* locations = [kBaseURL stringByAppendingString:kLocations];
    
    BOOL isExistingLocation = location._id != nil;
    NSURL* url = isExistingLocation ? [NSURL URLWithString:[locations stringByAppendingString:location._id]] :
    [NSURL URLWithString:locations]; //1
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = isExistingLocation ? @"PUT" : @"POST"; //2
    
    NSData* data = [NSJSONSerialization dataWithJSONObject:[location toDictionary] options:0 error:NULL]; //3
    request.HTTPBody = data;
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"]; //4
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
        if (!error) {
            NSArray* responseArray = @[[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]];
            [self parseAndAddLocations:responseArray toArray:self.objects];
        }
    }];
    [dataTask resume];
}

static inline NSString * AFContentTypeForPathExtension(NSString *extension) {
#ifdef __UTTYPE__
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
#else
#pragma unused (extension)
    return @"application/octet-stream";
#endif
}


#pragma makr NSURLSessionTaskDelegate


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream * _Nullable))completionHandler {
    NSLog(@"completionHandler");
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSLog(@"totalBytesSent: %llu", totalBytesSent);
    NSLog(@"totalBytesExpectedToSend: %llu", totalBytesExpectedToSend);
    
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"error: %@", error.localizedDescription);
    
    if (!error) {
        
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    NSLog(@"response: %@", response);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    NSLog(@"dataTask");
    
    if (!data) {
        return;
    }
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (dic) {
        NSLog(@"dic: %@", dic);
        NSLog(@"_id: %@", dic[@"_id"]);
        
        if (dic[@"_id"]) {
            self.currentLocation.imageId = dic[@"_id"];
            [self persist:self.currentLocation];
        }
    }
}




@end












