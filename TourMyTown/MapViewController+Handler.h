//
//  MapViewController+Handler.h
//  TourMyTown
//
//  Created by fuli pang on 2016/10/9.
//  Copyright © 2016年 mikekatz. All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController (Handler)

- (void)loadImageWithImageID:(NSString*)imageId;

- (void)deleteLocationWithID:(NSString*)locationID;

@end
