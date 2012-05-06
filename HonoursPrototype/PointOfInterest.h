//
//  PointOfInterest.h
//  HonoursProject
//
//  Created by Andrew Bennett on 28/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RubberBand;

@interface PointOfInterest : NSObject
{
	NSMutableArray * _bands;

	CGPoint _starOffset;
	CGPoint _point;
	NSUInteger _value;
	BOOL _visited;

	BOOL _tempVisited;
}
@property (readwrite) CGPoint point;
@property (readwrite) NSUInteger value;
@property (readwrite) BOOL visited;

@property (readwrite) BOOL tempVisited;

@property (readwrite) CGPoint starOffset;

-initWithPoint: (CGPoint) point
		 value: (NSUInteger) value;

-(RubberBand*) bandToPOI: (PointOfInterest*) poi;
-(void) addBand: (RubberBand*) band;

-(void) draw;
-(void) drawWithContext: (CGContextRef) context;

-(void) drawWithIcon: (NSString*) icon;
-(void) drawWithIcon: (NSString*) icon
			 context: (CGContextRef) context;

-(NSMutableArray *) bands;

@end
