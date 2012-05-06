//
//  MapView.h
//  HonoursProject
//
//  Created by Andrew Bennett on 6/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RubberBand;
@class PointOfInterest;

@interface MapView : UIView
{
	RubberBand * _lastBand;
	NSMutableArray * _path;

	NSArray * _pois;
	NSArray * _bands;

	CGPoint _youPoint;
	CGPoint _touchPoint;
	CGFloat _maxLength;

	RubberBand * _startDrag;

	CGFloat * _edgeCost;

	BOOL _changed;

	NSUInteger _touchIndex;

	NSUInteger _starSum;

	NSMutableString * _testLogString;

	NSString * _taskName;
	IBOutlet UIButton * nextTask;
	BOOL _runTesting;
	CGFloat _debugLength;

	unsigned int _bandOptions;
}

@property (readwrite) unsigned int  bandOptions;

-(void) loadFromFile: (NSString*) filename;
-(IBAction) toggleDebug: (id)sender;

-(IBAction) nextTest: (id)sender;

@end
