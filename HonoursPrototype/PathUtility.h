//
//  PathUtility.h
//  HonoursProject
//
//  Created by Andrew Bennett on 6/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef HonoursProject_PathUtility_h
#define HonoursProject_PathUtility_h

//#ifdef __cplusplus
//
//CGPoint operator + (const CGPoint& a, const CGPoint& b);
//CGPoint operator - (const CGPoint& a, const CGPoint& b);
//CGPoint operator * (const CGPoint& a, CGFloat m);
//CGPoint operator / (const CGPoint& a, CGFloat d);
//
//CGPoint operator - (const CGPoint& a);
//
//extern "C"
//{
//#endif

CGPoint CGPointAdd(CGPoint a, CGPoint b);
CGPoint CGPointSub(CGPoint a, CGPoint b);
CGPoint CGPointMul(CGPoint a, CGFloat b);
CGPoint CGPointDiv(CGPoint a, CGFloat b);


#import <UIKit/UIKit.h>

	CGFloat CGPointDistance(CGPoint a, CGPoint b);
	CGFloat CGPointDistance2(CGPoint a, CGPoint b);

	CGFloat CGPointDot(CGPoint a, CGPoint b);
	CGPoint CGPointPerp(CGPoint a);
	CGPoint RayIntersect(CGPoint a0, CGPoint a1, CGPoint b0, CGPoint b1);

	void CGPathMoveToCGPoint(CGMutablePathRef path, CGAffineTransform* transform, CGPoint point);
	void CGPathAddQuadCurveToCGPoint(CGMutablePathRef path, CGAffineTransform* transform, CGPoint p0, CGPoint p1);
	void CGPathAddArcToCGPoint(CGMutablePathRef path, CGAffineTransform* transform,
							   CGPoint p0, CGPoint p1, CGFloat r);
	void CGPathAddLineToCGPoint(CGMutablePathRef path, CGAffineTransform* transform, CGPoint p);

	CGPoint CGPointOfPathAtTime(CGPoint p0, CGPoint p1, CGPoint p2, CGFloat t);
	CGFloat CGFloatOfPathAtTime(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat t);

	CGFloat PathLengthInRange(CGPoint p0, CGPoint p1, CGPoint p2,
							  CGFloat from, CGFloat to);
	CGFloat PathAtLength(CGPoint p0, CGPoint p1, CGPoint p2, CGFloat length);
	CGFloat PathNearestPoint(CGPoint p0, CGPoint p1, CGPoint p2, CGPoint point);
	CGPathRef CreatePathThroughPoints(CGPoint p0, CGFloat radius0,
									  CGPoint p1,
									  CGPoint p2, CGFloat radius2);
	void GetPathThroughPointsInRange(CGPoint p0,  CGFloat radius0,
									 CGPoint p1,
									 CGPoint p2,  CGFloat radius2,
									 CGFloat from, CGFloat to,
									 CGPoint * out_points,
									 CGFloat * out_radius);

//#ifdef __cplusplus
//}
//#endif

#endif
