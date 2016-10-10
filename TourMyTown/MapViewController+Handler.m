//
//  MapViewController+Handler.m
//  TourMyTown
//
//  Created by fuli pang on 2016/10/9.
//  Copyright © 2016年 mikekatz. All rights reserved.
//

#import "MapViewController+Handler.h"

@implementation MapViewController (Handler)

- (void)loadImageWithImageID:(NSString *)imageId {
    
    if (!imageId) {
        return;
    }
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    NSURL *url = [[[NSURL URLWithString:kBaseURL] URLByAppendingPathComponent:kFiles] URLByAppendingPathComponent:imageId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (data) {
            self.imageView.image = [UIImage imageWithData:data];
        }
        
        
    } ];
    [task resume];
}

- (void)deleteLocationWithID:(NSString *)locationID {
    
    if (!locationID) {
        return;
    }
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    NSURL *url = [[[NSURL URLWithString:kBaseURL] URLByAppendingPathComponent:kLocations] URLByAppendingPathComponent:locationID];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"DELETE";
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {

        }
    } ];
    [task resume];
    
    
}

- (void)downLoadImageWithKey:(NSString *)key {
    if (!key) {
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSLog(@"currentThread: %@", [NSThread currentThread]);
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:5];
    for (int i = 1; i <= 5; i++) {
        [parameters setObject:@(i).stringValue forKey:[NSString stringWithFormat:@"parameter%@", @(i)]];
    }
    
    NSMutableString *params = [NSMutableString string];
    for (NSString *key in parameters.allKeys) {
        NSString *val = parameters[key];
        NSString *kv = [NSString stringWithFormat:@"%@=%@&", key, val];
        [params appendString:kv];
    }
    
    [params insertString:@"?" atIndex:0];
    [params deleteCharactersInRange:NSMakeRange(params.length-1, 1)];
    
    NSURL *url = [[[NSURL URLWithString:kBaseURL] URLByAppendingPathComponent:@"key"] URLByAppendingPathComponent:[key stringByAppendingString:params]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"get";
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"]; //3

    
//    request.HTTPMethod = @"post";
//    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"]; //4

    
    NSData *body = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:NULL];//[params dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setHTTPBody:body];
    
    
    
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }];
        
        NSLog(@"currentThread2: %@", [NSThread currentThread]);

        
        if (data) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            if (dic) {
                NSURL *url = [NSURL URLWithString:dic[@"imgUrl"]];
                NSData *data_ = [NSData dataWithContentsOfURL:url];
                if (!data_) {
                    return ;
                }
                UIImage *image = [UIImage imageWithData:data_];
                if (!image) {
                    return;
                }
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.imageView setImage:image];
                }];
            }
        }
    } ];
    [task resume];
    
    
    
    
}



@end








