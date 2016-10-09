//
//  ViewController.h
//  TourMyTown
//
//  Created by Michael Katz on 8/3/13.
//  Copyright (c) 2013 mikekatz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapViewController : UIViewController <MKMapViewDelegate>
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) UIImageView *imageView;

- (IBAction)updateFilter:(id)sender;


@end
