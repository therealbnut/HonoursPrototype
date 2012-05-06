//
//  RubberBand.m
//  HonoursProject
//
//  Created by Andrew Bennett on 27/08/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RubberBand.h"
#import "PathUtility.h"
#import "PointOfInterest.h"

const unsigned int kRubberBandOption_Tension   = 1;
const unsigned int kRubberBandOption_Thickness = 2;
const unsigned int kRubberBandOption_Color     = 4;

const CGFloat kPathColor[]       = {0.2, 0.2, 0.2, 1.0};
const CGFloat kPathThickColor[]  = {1.0, 1.0, 1.0, 1.0};
const CGFloat kPathThinColor[]   = {1.0, 0.0, 0.0, 1.0};
const CGFloat kPointColor[]      = {0.0, 0.0, 1.0, 1.0};

const CGFloat kBandThinRadius  = 2.0;
const CGFloat kBandThickRadius = 4.0;
const CGFloat kPathRadius = 8.0;
const CGFloat kPathDisabledOpacity = 0.50;


#pragma mark -
#pragma mark Predefine
#pragma mark -

typedef struct _Edge {size_t a, b, d, poi;} Edge;
inline Edge Edge_make(size_t a, size_t b, size_t d, size_t poi);
inline int  Edge_compare(const void * a, const void * b);

Edge Edge_make(size_t a, size_t b, size_t d, size_t poi)
{
	if (a < b)
		return (Edge){a, b, d, poi};
	return (Edge){b, a, d, poi};
}
int Edge_compare(const void * a, const void * b)
{
	const Edge * ea = (const Edge *)a, * eb = (const Edge *)b;
	//	if (ea->a == eb->a)
	//		return (ea->b - eb->b);
	//	return ea->a - eb->a;
	return ea->d - eb->d;
}

void calcMST(const Edge * edges, size_t edgeCount, size_t vertCount,
			 Edge ** mst_out, size_t * mst_count_out);
void addCurve(Edge ** edges, size_t * edgeCount,
			  CGPoint ** verts, size_t * vertCount,
			  size_t from, size_t to, CGPoint via);
void DrawBandThrough(CGContextRef context, CGAffineTransform* transform,
					 CGPoint p0, CGPoint p1, CGPoint p2, CGFloat thickness,
					 RubberBandOptions options);
void DrawPathThrough(CGContextRef context, CGAffineTransform* transform,
					 CGPoint p0, CGPoint p1, CGPoint p2,
					 CGFloat opacity);

#pragma mark -
#pragma mark Implementation
#pragma mark -

@implementation RubberBand

@synthesize tangent = _tangent;
@synthesize start = _start, end = _end, stretch = _stretch;
@synthesize from = _from, to = _to;
@synthesize enabled = _enabled;
@synthesize options = _options;

-initWithFromPoint: (PointOfInterest*) poi_from
		   toPoint: (PointOfInterest*) poi_to
	   tangentalTo: (CGPoint) tangent;
{
	if (self = [super init])
	{
		_tangent = tangent;
		_from    = poi_from;
		_to      = poi_to;
		_start   = 0.0;
		_end     = 0.0;
		_stretch = 0.0;
		_enabled = YES;
		_options =	kRubberBandOption_Tension |
					kRubberBandOption_Thickness |
					kRubberBandOption_Color;
		_length = PathLengthInRange([_from point], _tangent, [_to point], 0.0, 1.0);
	}
	return self;
}

-(void) draw
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawInContext: context
		  withTransform: NULL];
}
-(void) drawInContext: (CGContextRef) context
		withTransform: (CGAffineTransform*) transform
{
	DrawPathThrough(context, transform, [_from point], _tangent, [_to point], _enabled ? 1.0 : kPathDisabledOpacity);
	CGPoint subpath[3];
	CGFloat subradius[2];

	CGFloat cstretch = MIN(MAX(FLT_EPSILON, _stretch),1.0-FLT_EPSILON);// * 0.999;
	CGFloat cstart   = MIN(MAX(0.0, _start),1.0);
	CGFloat cend     = MIN(MAX(0.0, _end),1.0);

	GetPathThroughPointsInRange([_from point], 4.0, _tangent, [_to point], 4.0,
								cstart, cend, subpath, subradius);
	DrawBandThrough(context, NULL, subpath[0], subpath[1], subpath[2], 1.0-cstretch,
					self->_options);
}

-(BOOL) hasPOI: (PointOfInterest*) poi
{
	return poi==_from || poi==_to;
}
-(PointOfInterest*) otherPOI: (PointOfInterest*) poi
{
	if (poi==_from) return _to;
	if (poi==  _to) return _from;
	return nil;
}

-(CGFloat) length
{
	return self->_length;
}
-(CGFloat) pathDistanceFromPOI: (PointOfInterest*) poi
{
	if (_from == poi) return _start;
	if (_to == poi) return 1.0 - _end;
	return -1.0;
}
-(void) setPathDistance: (CGFloat) pathDistance
				fromPOI: (PointOfInterest*) poi
{
	if (_from == poi)    _start = pathDistance;
	else if (_to == poi) _end   = 1.0 - pathDistance;
	else abort();
}
-(CGFloat) pathDistanceAtLength: (CGFloat) length
						fromPOI: (PointOfInterest*) poi
{
	if (poi == _from)
	{
		return PathAtLength([_from point], _tangent, [_to point], length);
	}
	else if (poi == _to)
	{
		return 1.0-PathAtLength([_to point], _tangent, [_from point], length);
	}
	return -1.0;	
}
-(CGFloat) pathDistanceNearPoint: (CGPoint) point
						 fromPOI: (PointOfInterest*) poi
{
	if (poi == _from)
	{
		return PathNearestPoint([_from point], _tangent, [_to point], point);
	}
	else if (poi == _to)
	{
		return 1.0-PathNearestPoint([_to point], _tangent, [_from point], point);
	}
	return -1.0;
}
-(CGPoint) pointNearest: (CGPoint) point
{
	CGFloat pathDistance;
	CGPoint nearPoint;
	pathDistance = PathNearestPoint([_from point], _tangent, [_to point], point);
	nearPoint    = CGPointOfPathAtTime([_from point], _tangent, [_to point], pathDistance);
	return nearPoint;
}
-(CGPoint) pointAtPathDistance: (CGFloat) pathDistance
					   fromPOI: (PointOfInterest*) poi
{
	if (poi == _from)
	{
		return CGPointOfPathAtTime([_from point], _tangent, [_to point], pathDistance);
	}
	else if (poi == _to)
	{
		return CGPointOfPathAtTime([_to point], _tangent, [_from point], pathDistance);
	}
	return CGPointMake(NAN, NAN);
}

-(BOOL) isConnected
{
	return fabs(self->_start - self->_end) > 0.001;
}

@end

#pragma mark -
#pragma mark Utility
#pragma mark -

void calcMST(const Edge * edges, size_t edgeCount, size_t vertCount,
			 Edge ** mst_out, size_t * mst_count_out)
{
	size_t* parents = calloc(vertCount, sizeof(size_t));
	size_t u, v, mst_count = 0;
	
	Edge * mst = calloc(edgeCount, sizeof(Edge));
	
	memcpy(mst, edges, edgeCount * sizeof(Edge));
	qsort(mst, edgeCount, sizeof(Edge), Edge_compare);
	
	for (size_t i=0; i<vertCount; ++i)
		parents[i] = i;
	for (size_t i=0; i<edgeCount; ++i)
	{
		for (u = mst[i].a; u != parents[u]; u = parents[u]);
		for (v = mst[i].b; v != parents[v]; v = parents[v]);
		if (u != v)
		{
			parents[v] = u;
			mst[mst_count] = mst[i];
			++mst_count;
		}
	}
	mst = realloc(mst, mst_count * sizeof(Edge));
	free(parents);
	
	*mst_out       = mst;
	*mst_count_out = mst_count;
}

void DrawBandThrough(CGContextRef context, CGAffineTransform* transform,
					 CGPoint p0, CGPoint p1, CGPoint p2, CGFloat thickness,
					 RubberBandOptions options)
{
	CGPathRef path;
	CGPoint subpath[3];
	CGFloat subradius[2];

//	CGFloat t  = sqrt(thickness);
//	CGFloat t2 = t * t * (3.0 - 2.0 * t);
	CGFloat color[4];
	if (options & kRubberBandOption_Color)
	{
		for (int i=0; i<4; ++i)
			color[i] = kPathThinColor[i]*(1.0-thickness) + kPathThickColor[i]*thickness;
	}
	else
	{
		for (int i=0; i<4; ++i)
			color[i] = kPathThickColor[i];		
	}
	CGFloat radius = kBandThickRadius;//kBandThinRadius*(1.0-thickness) + kBandThickRadius*thickness;

	CGContextSetFillColor(context, color);

	if (!(options & kRubberBandOption_Thickness))
		thickness = 1.0;

	GetPathThroughPointsInRange(p0, radius, p1, p2, radius,
								0.0, 0.5, subpath, subradius);
	path = CreatePathThroughPoints(subpath[0],subradius[0],
								   subpath[1],
								   subpath[2],subradius[1]*thickness);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	CGPathRelease(path);
	
	GetPathThroughPointsInRange(p0, radius, p1, p2, radius,
								0.5, 1.0, subpath, subradius);
	path = CreatePathThroughPoints(subpath[0],subradius[0]*thickness,
								   subpath[1],
								   subpath[2],subradius[1]);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	CGPathRelease(path);
}

void DrawPathThrough(CGContextRef context, CGAffineTransform* transform,
					 CGPoint p0, CGPoint p1, CGPoint p2,
					 CGFloat opacity)
{
	CGPathRef path;
	CGFloat color[4];
	for (int i=0; i<4; ++i) color[i] = kPathColor[i];
	color[3] *= opacity;
	
	path = CreatePathThroughPoints(p0, kPathRadius, p1, p2, kPathRadius);
	CGContextSetFillColor(context, color);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	CGPathRelease(path);
}
