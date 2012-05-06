//
//  HPAppDelegate.h
//  HonoursPrototype
//
//  Created by Andrew Bennett on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPLogging.h"

@class MapViewController;
@class HPFirstViewController;

@interface HPAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, HPLoggingDelegate>
{
	MapViewController * _mapViewController;
	HPFirstViewController * _taskSelectController;
}

@property (strong, nonatomic) MapViewController * mapViewController;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

-(void) runNextTest;

@end
