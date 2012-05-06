//
//  PointOfInterest.m
//  HonoursProject
//
//  Created by Andrew Bennett on 28/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PointOfInterest.h"
#import "RubberBand.h"

#import "PathUtility.h"

@implementation PointOfInterest

const CGFloat  kLargeNumber = 1024.0 * 1024.0;

const CGFloat  kPOIFillColor[]         = {1.0, 1.0, 1.0, 1.0};
const CGFloat  kPOIStrokeColor[]       = {0.0, 0.0, 0.0, 1.0};
const CGFloat  kPOIThickness		   = 4.0;
const CGFloat  kPOISize				   = 16.0;
const CGPoint  kPOIDefaltStarOffset    = (CGPoint){36.0, -24.0};

const CGFloat  kPOITextStrokeColor[]   = {0.0, 0.0, 0.0, 1.0};
const CGFloat  kPOITextFillColor[]     = {1.0, 1.0, 1.0, 1.0};
const CGFloat  kPOITextStrokeThickness = 2.0;
const char *   kPOITextFont            = "Helvetica";
const CGFloat  kPOITextSize			   = 48;

@synthesize point   = _point;
@synthesize value   = _value;
@synthesize visited = _visited;
@synthesize tempVisited = _tempVisited;

@synthesize starOffset = _starOffset;

-initWithPoint: (CGPoint) p
		 value: (NSUInteger) v
{
	if (self = [super init])
	{
		self->_point   = p;
		self->_value   = v;
		self->_visited = NO;
		self->_starOffset = kPOIDefaltStarOffset;
		self->_bands = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void) addBand: (RubberBand*) band
{
	[self->_bands addObject: band];
	// sort bands by length
	[self->_bands sortedArrayUsingComparator:^(id obj1, id obj2)
	{
		if ([obj1 length] < [obj2 length])
			return NSOrderedAscending;
		if ([obj1 length] > [obj2 length])
			return NSOrderedDescending;
		return NSOrderedSame;
	}];
}

-(void) draw
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawWithIcon: nil
			   context: context];
}
-(void) drawWithContext: (CGContextRef) context
{
	[self drawWithIcon: nil
			   context: context];	
}
-(void) drawWithIcon: (NSString*) icon
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawWithIcon: icon
			   context: context];
}
-(void) drawWithIcon: (NSString*) icon
			 context: (CGContextRef) context
{
	UIImage* kStarImage = [UIImage imageNamed: @"Star"];
	UIImage* kUnStarImage = [UIImage imageNamed: @"StarUnselected"];
	UIImage* kIconImage = [UIImage imageNamed: icon ? icon : @"DefaultPOI"];

	UIImage* image = self->_visited ? kStarImage : kUnStarImage;
	CGSize size = [image size];
	
	CGContextSaveGState(context);

	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, _point.x, _point.y);
	switch (orientation)
	{
		case UIDeviceOrientationUnknown:
		case UIDeviceOrientationFaceDown:
		case UIDeviceOrientationFaceUp:
			break;
		case UIDeviceOrientationPortrait:
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			CGContextRotateCTM(context, M_PI);
			break;
		case UIDeviceOrientationLandscapeLeft:
			CGContextRotateCTM(context, 1.0*M_PI/2.0);
			break;
		case UIDeviceOrientationLandscapeRight:
			CGContextRotateCTM(context, 3.0*M_PI/2.0);
			break;
	}
	CGContextTranslateCTM(context, -_point.x, -_point.y);	

	
	if (self->_value > 0)
	{
		NSString * poiMessage = [NSString stringWithFormat: @"%ld", self->_value];
		CGPoint offset = CGPointMake(_point.x+_starOffset.x + round([image size].width * 0.5),
									 _point.y+_starOffset.y + round(kPOITextSize * 0.3));

		CGContextSaveGState(context);
		CGContextSetTextMatrix(context, CGAffineTransformMake(1, 0, 0, -1, 0, 0));

		CGContextSetCharacterSpacing(context, 3);
		
		CGContextSelectFont(context, kPOITextFont, kPOITextSize, kCGEncodingMacRoman);
		CGContextSetTextDrawingMode(context, kCGTextStroke);
		CGContextSetLineWidth(context, 2.0);
		CGContextSetStrokeColor(context, kPOITextStrokeColor);
		CGContextShowTextAtPoint(context, offset.x, offset.y,
								 [poiMessage UTF8String], [poiMessage length]);
		
//		CGContextSetAllowsAntialiasing(context, YES);
//		CGContextSetAllowsFontSmoothing(context, YES);
//		CGContextSetAllowsFontSubpixelPositioning(context, YES);
		
		CGContextSetTextDrawingMode(context, kCGTextFill);
		CGContextSetFillColor(context, kPOITextFillColor);
		CGContextShowTextAtPoint(context, offset.x, offset.y,
								 [poiMessage UTF8String], [poiMessage length]);

		CGContextRestoreGState(context);

		CGContextDrawImage(context, (CGRect){
			(CGFloat)(_point.x+_starOffset.x-floor(size.width  * 0.5)),
			(CGFloat)(_point.y+_starOffset.y- ceil(size.height * 0.5)), 
			size}, [image CGImage]);
	}

	size = [kIconImage size];
	CGContextDrawImage(context, (CGRect){
		(CGFloat)(_point.x-floor(size.width  * 0.5)),
		(CGFloat)(_point.y- ceil(size.height * 0.5)), 
		size}, [kIconImage CGImage]);

//	CGRect poiRect = CGRectMake(_point.x-kPOISize, _point.y-kPOISize, 2.0*kPOISize, 2.0*kPOISize);
//	CGContextSetFillColor(context, kPOIFillColor);
//	CGContextFillEllipseInRect(context, poiRect);
//	CGContextSetLineWidth(context, kPOIThickness);
//	CGContextSetStrokeColor(context, kPOIStrokeColor);
//	CGContextStrokeEllipseInRect(context, poiRect);

	CGContextRestoreGState(context);
}

-(NSMutableArray *) bands
{
	return [[self->_bands retain] autorelease];
}

-(RubberBand*) bandToPOI: (PointOfInterest*) poi
{
	for (RubberBand* band in self->_bands)
	{
		if ([band otherPOI: self] == poi)
			return band;
	}
	return nil;
}

@end

