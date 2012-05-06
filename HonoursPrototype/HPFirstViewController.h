//
//  HPFirstViewController.h
//  HonoursPrototype
//
//  Created by Andrew Bennett on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPFirstViewController : UIViewController//TableViewController
{
	NSArray *_taskNames;
	NSUInteger _taskIndex;

	IBOutlet UISwitch * option_thickness;
	IBOutlet UISwitch * option_tension;
	IBOutlet UISwitch * option_color;
}

@property (strong, nonatomic) NSArray * taskNames;

-(IBAction) runTask: (id)sender;
-(IBAction) updateBandOptions: (id)sender;

-(void) runNextTask;

@end
