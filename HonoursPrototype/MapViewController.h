//
//  MapViewController.h
//  HonoursProject
//
//  Created by Andrew Bennett on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MapView;

@interface MapViewController : UIViewController
{
}

-(void) loadTaskNamed: (NSString*) taskName;
-(void) setBandOptions: (unsigned int) options;

@end
