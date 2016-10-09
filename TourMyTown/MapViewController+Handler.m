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



@end
