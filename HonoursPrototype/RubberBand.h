//
//  RubberBand.h
//  HonoursProject
//
//  Created by Andrew Bennett on 27/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PointOfInterest;

typedef unsigned int RubberBandOptions;
const unsigned int kRubberBandOption_Tension;
const unsigned int kRubberBandOption_Thickness;
const unsigned int kRubberBandOption_Color;

@interface RubberBand : NSObject
{
	PointOfInterest * _from;
	PointOfInterest * _to;

	CGPoint _tangent;
	CGFloat _start;
	CGFloat _end;
	CGFloat _stretch;

	CGFloat _length;

	BOOL _enabled;

	RubberBandOptions _options;
}

@property (readwrite,retain) PointOfInterest * from;
@property (readwrite,retain) PointOfInterest * to;

@property (readwrite) CGPoint tangent;

@property (readwrite) CGFloat start;
@property (readwrite) CGFloat end;
@property (readwrite) CGFloat stretch;

@property (readwrite) BOOL enabled;

@property (readwrite) RubberBandOptions options;

-initWithFromPoint: (PointOfInterest*) from
		   toPoint: (PointOfInterest*) to
	   tangentalTo: (CGPoint) tangent;

-(void) draw;
-(void) drawInContext: (CGContextRef) context
		withTransform: (CGAffineTransform*) transform;

-(BOOL) isConnected;

-(BOOL) hasPOI: (PointOfInterest*) poi;

-(CGFloat) length;

-(PointOfInterest*) otherPOI: (PointOfInterest*) poi;

-(CGFloat) pathDistanceFromPOI: (PointOfInterest*) poi;
-(void) setPathDistance: (CGFloat) pathDistance
				fromPOI: (PointOfInterest*) poi;

-(CGPoint) pointAtPathDistance: (CGFloat) pathDistance
					   fromPOI: (PointOfInterest*) poi;
-(CGFloat) pathDistanceAtLength: (CGFloat) length
						fromPOI: (PointOfInterest*) poi;
-(CGFloat) pathDistanceNearPoint: (CGPoint) point
						 fromPOI: (PointOfInterest*) poi;

-(CGPoint) pointNearest: (CGPoint) point;

@end
