//
//  MapView.m
//  HonoursProject
//
//  Created by Andrew Bennett on 6/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MapView.h"

#import "HPAppDelegate.h"

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "RubberBand.h"
#import "PointOfInterest.h"
#import "PathUtility.h"

#import "HPLogging.h"

@interface MapView (MapViewInternal)

-(void) touchMovedAt: (CGPoint) point;

@end

@implementation MapView

@synthesize bandOptions = _bandOptions;

-(void) testStart
{
	self->_testLogString = [[NSMutableString alloc] init];	
	NSString * fstring = [NSString stringWithFormat:
						  @"test start (%@): %lf\n",
						  self->_taskName,
						  CFAbsoluteTimeGetCurrent()];
	NSLog(@"%@", fstring);
	[self->_testLogString appendString: fstring];
}
-(void) testIterate
{
//	NSString * fstring = [NSString stringWithFormat:
//						  @"screenshot: %@\n", [HPLogging saveView: self]];
//	[self->_testLogString appendString: fstring];
//	NSLog(@"%@", fstring);
}
-(void) testEnd
{
	[self testIterate];

	NSString * fstring = [NSString stringWithFormat:
						  @"test end (%@): %lf\n",
						  self->_taskName,
						  CFAbsoluteTimeGetCurrent()];
	NSLog(@"%@", fstring);
	[self->_testLogString appendString: fstring];
	[HPLogging logString: self->_testLogString];
}

const CGFloat kBackgroundColor[] = {1.0, 0.0, 0.0, 1.0};
const CGFloat kTouchColor[]      = {1.0, 1.0, 1.0, 1.0};
const CGFloat kBandTouchError    = 80.0 * 80.0;
const CGFloat kBandPathDistanceError = 0.01;
const CGFloat kBandStretchFactor     = 4.0;

const CGFloat  kMessageTextStrokeColor[]   = {0.0, 0.0, 0.0, 1.0};
const CGFloat  kMessageTextFillColor[]     = {1.0, 1.0, 1.0, 1.0};
const CGFloat  kMessageTextStrokeThickness = 2.0;
const char *   kMessageTextFont            = "Helvetica";
const CGFloat  kMessageTextSize			   = 48;

const NSString * const kMapView_MaxDistKey   = @"maxDist";
const NSString * const kMapView_POIsKey      = @"pois";
const NSString * const kMapView_BandsKey     = @"bands";

id CreateObjectFromCGPoint(CGPoint point);
CGPoint MakeCGPointFromObject(id object);
id CreateObjectFromCGPoint(CGPoint point)
{
	return [NSArray arrayWithObjects:
			[NSNumber numberWithDouble: point.x],
			[NSNumber numberWithDouble: point.y],
			nil];
}
CGPoint MakeCGPointFromObject(id object)
{
	return CGPointMake([[object objectAtIndex: 0] doubleValue],
					   [[object objectAtIndex: 1] doubleValue]);
}

void constructTopology(NSMutableSet* allTopology, NSArray* order, CGFloat sumLength, CGFloat maxLength);
CGFloat compareTopology(NSArray * topA, NSArray * topB);

-(void) constructPointOrderTopology
{
	NSMutableSet * allTopology = [[NSMutableSet alloc] init];
	NSArray * firstPoint = [NSArray arrayWithObject: [self->_pois objectAtIndex: 0]];
	constructTopology(allTopology, firstPoint, 0.0, self->_maxLength);
//	NSLog(@"%@", allTopology);
}

-(void) loadFromPList: (id) plist
{
	self->_maxLength    = [[plist objectForKey: kMapView_MaxDistKey] doubleValue];
	NSArray * in_pois  = [plist objectForKey: kMapView_POIsKey];
	NSArray * in_bands = [plist objectForKey: kMapView_BandsKey];

	NSMutableArray * tmpPOIS = [NSMutableArray arrayWithCapacity: [in_pois count]/2];
	for (NSUInteger i=0; i<[in_pois count]; i+=2)
	{
		[tmpPOIS addObject: [[[PointOfInterest alloc] initWithPoint: MakeCGPointFromObject([in_pois objectAtIndex:i+0])
															 value: [[in_pois objectAtIndex:i+1] integerValue]
							 ] autorelease]];
	}
	self->_pois = [[tmpPOIS copy] retain];
	NSMutableArray * tmpBands = [NSMutableArray arrayWithCapacity: [in_bands count]/3];
	for (NSUInteger i=0; i<[in_bands count]; i+=3)
	{
		NSUInteger a = [[in_bands objectAtIndex:i+0] integerValue];
		NSUInteger b = [[in_bands objectAtIndex:i+1] integerValue];
		CGPoint    t = MakeCGPointFromObject([in_bands objectAtIndex:i+2]);
		RubberBand * band = [[RubberBand alloc] initWithFromPoint: [self->_pois objectAtIndex: a]
														   toPoint: [self->_pois objectAtIndex: b]
													   tangentalTo: t];
		[band setOptions: self->_bandOptions];
		[[band from] addBand: band];
		[[band to] addBand: band];
		[tmpBands addObject: band];
		[band release];
	}
	self->_bands = [[tmpBands copy] retain];

	_path = [[NSMutableArray arrayWithObject: [_pois objectAtIndex: 0]] retain];
	[[_path lastObject] setVisited: YES];		

	for (RubberBand * band in self->_bands)
		[band setEnabled: NO];
	_lastBand = [self->_bands objectAtIndex: 0];
	[_lastBand setEnabled: YES];
	[_lastBand setStart: 0.0];
	[_lastBand setEnd: 0.25];
	_youPoint = [_lastBand pointAtPathDistance: 0.25
									   fromPOI: [_pois objectAtIndex: 0]];
	_touchPoint = _youPoint;

	if (self->_edgeCost != NULL)
		free(self->_edgeCost);

	NSUInteger i,j,c = [self->_pois count];
	self->_edgeCost = malloc(sizeof(CGFloat) * c * c);
	for (j=0; j<c; ++j)
	{
		for (i=0; i<c; ++i)
		{
			self->_edgeCost[i+j*c] = INFINITY;
		}
	}
	j = 0;
	for (PointOfInterest * poiA in self->_pois)
	{
		for (RubberBand * band in [poiA bands])
		{
			PointOfInterest * poiB = [band otherPOI: poiA];
			i = [self->_pois indexOfObject: poiB];
			self->_edgeCost[i+j*c] = [band length];
			self->_edgeCost[j+i*c] = [band length];
		}
		++j;
	}

	[self->nextTask setEnabled: NO];
	
	self->_changed = YES;
	[self constructPointOrderTopology];
	[self touchMovedAt: self->_youPoint];
}
-(id) saveToPList
{
	NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity: 3];
	NSMutableArray * out_pois  = [NSMutableArray array];
	NSMutableArray * out_bands = [NSMutableArray array];

	for (PointOfInterest * poi in self->_pois)
	{
		[out_pois addObject: CreateObjectFromCGPoint([poi point])];
		[out_pois addObject: [NSNumber numberWithInteger: [poi value]]];
	}
	for (RubberBand * band in self->_bands)
	{
		[out_bands addObject: [NSNumber numberWithInteger: [self->_pois indexOfObject: [band from]]]];
		[out_bands addObject: [NSNumber numberWithInteger: [self->_pois indexOfObject: [band to]]]];
		[out_bands addObject: CreateObjectFromCGPoint([band tangent])];
	}

	[dict setObject: [NSNumber numberWithDouble: self->_maxLength] forKey: kMapView_MaxDistKey];
	[dict setObject: out_pois  forKey: kMapView_POIsKey];
	[dict setObject: out_bands forKey: kMapView_BandsKey];

	return dict;
}

-(void) loadFromFile: (NSString*) filename
{
	NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
	NSString *error = nil;
	NSData * data = [NSData dataWithContentsOfURL: [[NSBundle mainBundle]
													URLForResource: filename withExtension: @"plist"]];
	if (data == nil)
	{
		NSLog(@"Unable to open file: %@", filename);
		abort();
	}
	id plist = [NSPropertyListSerialization propertyListFromData: data
												mutabilityOption: NSPropertyListImmutable
														  format: &format
												errorDescription: &error];
	if (plist == nil)
	{
		NSLog(@"Unable to open file: %@ (%@)", filename, error);
		[error release];
		abort();
	}
	[self loadFromPList: plist];
	NSLog(@"Loaded task: %@", filename);
	self->_taskName = [[filename copy] retain];
	[self testStart];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    if (self)
	{
//		[self loadFromFile: @"Task01"];
		self->_startDrag = nil;
		self->_edgeCost = NULL;
		
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(orientationDidChange:)
													 name: @"UIDeviceOrientationDidChangeNotification"
												   object: nil];

		NSTimer* timer = [NSTimer timerWithTimeInterval: 1.0
												 target: self
											   selector: @selector(loopTimer:)
											   userInfo: nil
												repeats: YES];
		self->_changed = YES;
		self->_runTesting = NO;
		self->_touchIndex = 0;
	
		self->_starSum = 0;

		[[NSRunLoop mainRunLoop] addTimer: timer
								  forMode: NSRunLoopCommonModes];
    }

    return self;
}

-(IBAction) toggleDebug: (id)sender
{
	self->_runTesting = !self->_runTesting;
}

-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: @"UIDeviceOrientationDidChangeNotification"
												  object: nil];
	[_pois release];
	[_bands release];
	[_path release];
	[super dealloc];
}

-(void) awakeFromNib
{
//	[self showMessage: @"Plan a route from the airport"
//		   afterDelay: 1.0];
//	[self showMessage: @"Get as many stars as possible"
//		   afterDelay: 4.0];
//	[self showMessage: @"Some stars are out of reach"
//		   afterDelay: 12.0];
}

-(void) orientationDidChange: (NSNotification*) notify
{
	[self setNeedsDisplay];
}

-(NSArray*) bandsWithPOI: (PointOfInterest*) a
{
	NSMutableSet * bandSet = [[NSMutableSet alloc] init];
	for (RubberBand * band in self->_bands)
	{
		if ([band from] == a || [band to] == a)
			[bandSet addObject: band];
	}
	return [bandSet allObjects];
}
-(RubberBand*) bandWithPOI: (PointOfInterest*) a
					   POI:  (PointOfInterest*) b
{
	for (RubberBand * band in self->_bands)
	{
		if (([band from] == a && [band to] == b) ||
			([band from] == b && [band to] == a))
		{
			return band;
		}
	}
	return nil;
}
-(NSArray*) pathBands
{
	NSMutableArray * bands = [NSMutableArray arrayWithCapacity: [self->_path count]-1];
	PointOfInterest * last = nil;
	RubberBand * band;
	for (PointOfInterest * poi in self->_path)
	{
		if (last != nil &&
			(band = [self bandWithPOI: last
								  POI: poi]) != nil)
		{
			[bands addObject: band];
		}
		last = poi;
	}
	return bands;
}

-(RubberBand*) touchedBandInBandArray: (NSArray*) array
{
	CGPoint pathPoint;
	CGFloat distance;
	RubberBand* nearestBand = nil;

	CGFloat minDistance = INFINITY;
	for (RubberBand * band in array)
	{
		pathPoint    = [band pointNearest: _touchPoint];
		distance     = CGPointDistance2(pathPoint, self->_touchPoint);
		if (distance < minDistance)
		{
			minDistance = distance;
			nearestBand = band;
		}
	}
	if (minDistance > kBandTouchError)
		return nil;
	return nearestBand;
}

-(RubberBand*) touchedBand
{
	return [self touchedBandInBandArray: self->_bands];
}

-(BOOL) respondToTouchNearBand: (RubberBand*) nearBand
{
	PointOfInterest * secondLastPOI = nil;
	PointOfInterest * lastPOI = nil;

	if (nearBand == nil)
		return NO;

	// get last two POIs
	lastPOI = [self->_path lastObject];
	if ([self->_path count] >= 2)
		secondLastPOI = [self->_path objectAtIndex: [self->_path count]-2];

	// if the touch has backtracked along the last band
	if ([nearBand hasPOI: secondLastPOI])
	{
		[lastPOI setVisited: NO];

		[self->_path removeLastObject];

		lastPOI = secondLastPOI;
		secondLastPOI = nil;
	}

	// Zero the last band
	if (_lastBand != nil)
	{
		[_lastBand setStart: 0.0];
		[_lastBand setEnd: 0.0];
		_lastBand = nil;
	}

	// get the length of all committed POIs
	NSArray * bands = [self pathBands];
	CGFloat sumLength = 0.0;
	for (RubberBand * band in bands)
	{
		sumLength += [band length];
		[band setStart: 0.0];
		[band setEnd: 1.0];
	}

	// if there's room for more
	if (sumLength < _maxLength)
	{
		CGFloat pathDistanceNear, pathDistanceMax, pathDistance;
		PointOfInterest * prevPOI = nil;
		
		prevPOI = [nearBand otherPOI: lastPOI];
		if (prevPOI != nil)
		{
			pathDistanceNear = [nearBand pathDistanceNearPoint: self->_touchPoint
													   fromPOI: lastPOI];
			pathDistanceMax  = [nearBand pathDistanceAtLength: _maxLength - sumLength
													  fromPOI: lastPOI];
			pathDistance     = MIN(pathDistanceNear, pathDistanceMax);

			self->_debugLength = sumLength + pathDistanceNear;

			// percent of maximum length that it can go
			CGFloat stretch = (sumLength + pathDistance*[nearBand length]) / _maxLength;
			if (stretch < 1.0)
				stretch = stretch*0.99;
			stretch = MIN(MAX(0.001, stretch), 0.999);

			CGFloat end;
			if ([nearBand options] & kRubberBandOption_Tension)
			{
				end = 1.0-pathDistanceNear * pow(0.5,2.0*(1.0-pathDistanceMax));
			}
			else
			{
				end = 1.0-MIN(pathDistanceNear, pathDistanceMax);
			}
			end = MIN(MAX(0.0, end), 1.0);
			[nearBand setPathDistance: end
							  fromPOI: prevPOI];
			[nearBand setPathDistance: 0.0
							  fromPOI: lastPOI];
			_youPoint = [nearBand pointAtPathDistance: end 
											  fromPOI: prevPOI];
			[nearBand setStretch: pow(stretch, kBandStretchFactor)];
			if (pathDistance > 1.0 - kBandPathDistanceError)
			{
				[prevPOI setVisited: YES];
				[self->_path addObject: prevPOI];
			}
		}
	}
	_lastBand = nearBand;

	return NO;
}

// dragging through a path that doesn't have a band causes the band to change routes through that path \
	if the far poi has a band
//  if the far poi doesn't have a band then the path is travelled bidirectionally and is removed (animated?) if undragged
-(void)touchesMovedNew:(NSSet *)touches
			 withEvent:(UIEvent *)event
{
	RubberBand * band;

	BOOL startConnected, endConnected;

	self->_touchPoint  = [[touches anyObject] locationInView: self];

	band = [self touchedBand];
	if (self->_startDrag == nil)
	{
		self->_startDrag = band;
		startConnected   = [band isConnected];
		endConnected     = startConnected;
	}
	else
	{
		startConnected   = [self->_startDrag isConnected];
		endConnected     = [band isConnected];
	}
}
-(void) touchesEnded:(NSSet *)touches
		   withEvent:(UIEvent *)event
{
	self->_startDrag = nil;
}

-(void) touchesBegan:(NSSet *)touches
		   withEvent:(UIEvent *)event
{
	if (!self->_runTesting)
		return;
	
	NSUInteger pois  = [self->_pois count];
	NSUInteger bands = [self->_bands count];
	NSUInteger i;
	CGPoint point  = [[touches anyObject] locationInView: self];
	RubberBand * band;
	PointOfInterest * poi;

	if (self->_touchIndex < pois)
	{
		i = self->_touchIndex;
		poi = [self->_pois objectAtIndex: i];
		[poi setPoint: point];
	}
	else
	{
		if (self->_touchIndex-pois < bands)
		{
			i = self->_touchIndex-pois;
			band = [self->_bands objectAtIndex: i];
			[band setTangent: point];
		}
		else
		{
			self->_maxLength = 1000.0;
		}
	}
	[self setNeedsDisplayInRect: self.bounds];
	self->_touchIndex = (self->_touchIndex+1) % (pois + bands + 1);
	if (self->_touchIndex == 0)
	{
		id plist = [self saveToPList];
		NSError *error = nil;
		NSData * data;
		NSString * string;
		data = [NSPropertyListSerialization dataWithPropertyList: plist
														  format: kCFPropertyListXMLFormat_v1_0
														 options: 0
														   error: &error];
		string = [[NSString alloc] initWithData: data
									   encoding: NSUTF8StringEncoding];
		NSLog(@"plist: %@", string);
		[string release];
	}
}

-(void) touchMovedAt: (CGPoint) point
{
	NSArray * bands  = nil;
	RubberBand * nearBand = nil;
	
	_touchPoint  = point;
	
	bands = [self bandsWithPOI: [self->_path lastObject]];
	for (RubberBand * band in self->_bands)
		[band setEnabled: NO];
	for (RubberBand * band in bands)
		[band setEnabled: YES];
	
	// ordered point visits
	
	//	if (bands != nil && _lastBand != nil)
	//	{
	//		PointOfInterest * nextPOI = [_lastBand otherPOI: [self->_path lastObject]];
	//		if (nextPOI != nil)
	//		{
	//			NSMutableSet * bandSet = [NSMutableSet set];
	//			[bandSet addObjectsFromArray: bands];
	//			[bandSet addObjectsFromArray: [self bandsWithPOI: nextPOI]];
	//			bands = [bandSet allObjects];
	//		}
	//	}
	if (bands != nil)
	{
		nearBand = [self touchedBandInBandArray: bands];
	}
	if (nearBand != nil)
	{
		[self respondToTouchNearBand: nearBand];
	}
	
	self->_changed = YES;
	[self setNeedsDisplayInRect: [self bounds]];
}

// perhaps do shortest path from point to point (on graph)
// then determine the difference required to accomplish this
-(void)touchesMoved:(NSSet *)touches
		  withEvent:(UIEvent *)event
{
	[self touchMovedAt: [[touches anyObject] locationInView: self]];
}

-(void) loopTimer: (NSTimer*) timer
{
	if (self->_changed)
	{
		self->_starSum = 0;
		for (PointOfInterest * poi in self->_path)
			self->_starSum += [poi value];
		if (self->_starSum >= 5)
		{
			[self->nextTask setEnabled: YES];
		}
		else
		{
			[self->nextTask setEnabled: NO];
		}
		[self testIterate];
		self->_changed = NO;
	}
}

-(void) drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();

//	CGContextSetFillColor(context, kBackgroundColor);
//	CGContextFillRect(context, rect);
	UIImage* kBackroundTile = [UIImage imageNamed: @"Tiles"];
	
	CGContextDrawTiledImage(context, (CGRect){CGPointZero,[kBackroundTile size]}, [kBackroundTile CGImage]);

	CGContextSetStrokeColor(context, kTouchColor);
	CGContextStrokeEllipseInRect(context, CGRectMake(_touchPoint.x-64,
													 _touchPoint.y-64,
													 128, 128));

	for (RubberBand * band in self->_bands)
	{
		[band drawInContext: context
			  withTransform: NULL];
	}
	for (PointOfInterest * poi in self->_pois)
	{
		if (poi == [self->_pois objectAtIndex: 0])
		{
			[poi drawWithIcon: @"Airport"
					  context: context];
		}
		else
		{
			[poi drawWithContext: context];
		}
	}
	
	UIImage * you = [UIImage imageNamed: @"You"];
	[you drawInRect: CGRectMake(_youPoint.x-floor(you.size.width*0.5),
								_youPoint.y-floor(you.size.height*0.5),
								you.size.width, you.size.height)];
}

-(IBAction) nextTest: (id)sender
{
	[self testEnd];

	HPAppDelegate * delegate;
	delegate = (HPAppDelegate *) [[UIApplication sharedApplication] delegate];
	[delegate runNextTest];
}

@end

void constructTopology(NSMutableSet* allTopology, NSArray* order, CGFloat sumLength, CGFloat maxLength)
{
	PointOfInterest * poi = (PointOfInterest *)[order lastObject];
	NSArray * next_order;
	CGFloat next_length;
	
	for (RubberBand * band in [poi bands])
	{
		next_length = sumLength + [band length];
		if (next_length >= maxLength)
			continue;
		
		next_order = [order arrayByAddingObject: [band otherPOI: poi]];
		[allTopology addObject: next_order];
		
		constructTopology(allTopology, next_order, next_length, maxLength);
	}
}

CGFloat compareTopology(NSArray * topA, NSArray * topB)
{
	NSEnumerator * e;
	CGFloat diffLen = 0.0;
	NSMutableSet * sA = [NSMutableSet set];
	NSMutableSet * sB = [NSMutableSet set];
	NSMutableSet * inter, * diff;
	PointOfInterest * npoi, * poi;

	e = [topA objectEnumerator];
	poi = [e nextObject];
	while ((npoi = [e nextObject]) != nil)
	{
		[sA addObject: [poi bandToPOI: npoi]];
		poi = npoi;
	}

	e = [topB objectEnumerator];
	poi = [e nextObject];
	while ((npoi = [e nextObject]) != nil)
	{
		[sB addObject: [poi bandToPOI: npoi]];
		poi = npoi;
	}

	// all object
	diff = [NSMutableSet setWithSet: sA];
	[diff unionSet: sB];

	// common objects
	inter = [NSMutableSet setWithSet: sA];
	[inter intersectSet: sB];

	[diff minusSet: inter];

	for (RubberBand * band in diff)
		diffLen += [band length];

	return diffLen;
}

