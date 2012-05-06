//
//  MapViewController.m
//  HonoursProject
//
//  Created by Andrew Bennett on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"

#import "MapView.h"

@implementation MapViewController

- (id)initWithNibName: (NSString *)nibNameOrNil
			   bundle: (NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName: nibNameOrNil
						   bundle: nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Task", @"Task");
		self.tabBarItem.image = [UIImage imageNamed:@"second"];
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return interfaceOrientation==UIDeviceOrientationPortrait;
}

-(void) loadTaskNamed: (NSString*) taskName
{
	MapView * mapView = (MapView *)[self view];
	
	[mapView loadFromFile: taskName];
}

-(void) setBandOptions: (unsigned int) options
{
	MapView * mapView = (MapView *)[self view];
	[mapView setBandOptions: options];
}

@end
