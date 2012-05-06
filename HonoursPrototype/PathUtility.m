//
//  PathUtility.cpp
//  HonoursProject
//
//  Created by Andrew Bennett on 6/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "PathUtility.h"

CGFloat CGPointDistance2(CGPoint a, CGPoint b)
{
	CGFloat dx = a.x-b.x, dy = a.y-b.y;
	return dx*dx + dy*dy;
}
CGFloat CGPointDistance(CGPoint a, CGPoint b)
{
	CGFloat dx = a.x-b.x, dy = a.y-b.y;
	return sqrt(dx*dx + dy*dy);
}

CGPoint CGPointAdd(CGPoint a, CGPoint b) {return CGPointMake(a.x+b.x, a.y+b.y);}
CGPoint CGPointSub(CGPoint a, CGPoint b) {return CGPointMake(a.x-b.x, a.y-b.y);}
CGPoint CGPointMul(CGPoint a, CGFloat b) {return CGPointMake(a.x*b, a.y*b);}
CGPoint CGPointDiv(CGPoint a, CGFloat b) {return CGPointMake(a.x/b, a.y/b);}

//CGPoint operator + (const CGPoint& a, const CGPoint& b) {return CGPointMake(a.x+b.x, a.y+b.y);}
//CGPoint operator - (const CGPoint& a, const CGPoint& b) {return CGPointMake(a.x-b.x, a.y-b.y);}
//CGPoint operator * (const CGPoint& a, CGFloat m) {return CGPointMake(a.x*m, a.y*m);}
//CGPoint operator / (const CGPoint& a, CGFloat d) {CGFloat m=1.0/d; return CGPointMake(a.x*m, a.y*m);}

//CGPoint operator - (const CGPoint& a) {return CGPointMake(-a.x, -a.y);}

CGFloat CGPointDot(CGPoint a, CGPoint b) {return a.x*b.x + a.y*b.y;}
CGPoint CGPointPerp(CGPoint a) {return CGPointMake(-a.y, a.x);}

CGPoint RayIntersect(CGPoint a0, CGPoint a1, CGPoint b0, CGPoint b1)
{
	CGPoint da = CGPointSub(a1,a0), db = CGPointSub(b1,b0);
	CGPoint prp = CGPointPerp(db);
	CGPoint dif = CGPointSub(a0,b0);
	CGFloat nb = CGPointDot(prp, da);
	if (nb==0.0) return CGPointMake(NAN, NAN);
	double na = -CGPointDot(prp, dif);
	return CGPointAdd(a0, CGPointMul(da, (na / nb)));
}

void CGPathMoveToCGPoint(CGMutablePathRef path, CGAffineTransform* transform, CGPoint point)
{
	CGPathMoveToPoint(path, transform, point.x, point.y);
}
void CGPathAddQuadCurveToCGPoint(CGMutablePathRef path, CGAffineTransform* transform, CGPoint p0, CGPoint p1)
{
	CGPathAddQuadCurveToPoint(path, transform, p0.x, p0.y, p1.x, p1.y);
}
void CGPathAddArcToCGPoint(CGMutablePathRef path, CGAffineTransform* transform, CGPoint p0, CGPoint p1, CGFloat r)
{
	CGPathAddArcToPoint(path, transform, p0.x, p0.y, p1.x, p1.y, r);
}
void CGPathAddLineToCGPoint(CGMutablePathRef path, CGAffineTransform* transform, CGPoint p)
{
	CGPathAddLineToPoint(path, transform, p.x, p.y);
}

CGFloat CGFloatOfPathAtTime(CGFloat p0, CGFloat p1, CGFloat p2, CGFloat t)
{
	return p0 * ((1.0-t)*(1.0-t)) + p1 * (2.0*(1.0-t)*t) + p2 * (t * t);
}
CGPoint CGPointOfPathAtTime(CGPoint p0, CGPoint p1, CGPoint p2, CGFloat t)
{
	return CGPointAdd(CGPointMul(p0, (1.0-t)*(1.0-t)),
					  CGPointAdd(CGPointMul(p1, 2.0*(1.0-t)*t),
								 CGPointMul(p2, (t * t))));
}

CGFloat PathNearestPoint(CGPoint p0, CGPoint p1, CGPoint p2, CGPoint point)
{
	CGFloat dist, bestT, bestDist = INFINITY;
	CGFloat a = 0.0, b = 1.0;
	for (int i=0; i<8; ++i)
	{
		for (int j=1; j<8; ++j)
		{
			CGFloat t = a + (b-a) * j / 8.0;
			dist = CGPointDistance2(CGPointOfPathAtTime(p0,p1,p2, t), point);
			if (dist < bestDist)
			{
				bestDist = dist;
				bestT = t;
			}
		}
		CGFloat diff = (b-a)/8.0;
		a = bestT-diff;
		b = bestT+diff;
	}
	if (bestT < 0.125 && CGPointDistance2(CGPointOfPathAtTime(p0,p1,p2, 0.0), point) < bestDist)
		return 0.0;
	if (bestT > 0.875 && CGPointDistance2(CGPointOfPathAtTime(p0,p1,p2, 1.0), point) < bestDist)
		return 1.0;

	return bestT;
}

void GetPathThroughPointsInRange(CGPoint p0,  CGFloat radius0,
								 CGPoint p1,
								 CGPoint p2,  CGFloat radius2,
								 CGFloat from, CGFloat to,
								 CGPoint * out_points,
								 CGFloat * out_radius)
{
	out_points[0] = CGPointOfPathAtTime(p0, p1, p2, from);
	out_points[1] = RayIntersect(CGPointAdd(p0, CGPointMul(CGPointSub(p1,p0),from)),
								 CGPointAdd(p1, CGPointMul(CGPointSub(p2,p1), from)),
								 CGPointAdd(p0, CGPointMul(CGPointSub(p1,p0),to  )),
								 CGPointAdd(p1, CGPointMul(CGPointSub(p2,p1), to)));
	out_points[2] = CGPointOfPathAtTime(p0, p1, p2, to);

	out_radius[0] = radius0+(radius2-radius0)*from;
	out_radius[1] = radius0+(radius2-radius0)*to;
}

CGFloat PathLengthInRange(CGPoint p0, CGPoint p1, CGPoint p2,
						  CGFloat from, CGFloat to)
{
	CGFloat step = (to-from)/64.0;
	CGFloat length = 0.0;
	CGPoint next, last = CGPointOfPathAtTime(p0,p1,p2,from);
	if (step <= 0.0)
		return 0.0;
	for (CGFloat t=from+step; t<=to; t += step)
	{
		next = CGPointOfPathAtTime(p0,p1,p2,t);
		length += CGPointDistance(last, next);
		last = next;
	}
	return length;
}
CGFloat PathAtLength(CGPoint p0, CGPoint p1, CGPoint p2, CGFloat length)
{
	CGFloat step = 1.0/128.0;
	CGFloat sumlength = 0.0;
	CGPoint next, last = CGPointOfPathAtTime(p0,p1,p2,0.0);
	CGFloat t, diff;
	for (t=0.0; t<=1.0; t += step)
	{
		next       = CGPointOfPathAtTime(p0,p1,p2,t);
		diff       = CGPointDistance(last, next);
		if (sumlength + diff > length)
		{
			if (diff == 0.0)
				return 0.0;
			return t - ((length-sumlength) / diff) * step;
			return t;
		}
		sumlength += diff;
		last = next;
	}
	return 1.0;
}

CGPathRef CreatePathThroughPoints(CGPoint p0, CGFloat radius0,
								  CGPoint p1,
								  CGPoint p2, CGFloat radius2)
{
	CGPoint d0 = CGPointMul(CGPointSub(p1,p0),(radius0/CGPointDistance(p0,p1)));
	CGPoint d2 = CGPointMul(CGPointSub(p1,p2),(radius2/CGPointDistance(p2,p1)));
	CGPoint n0 = CGPointPerp(d0), n2 = CGPointPerp(d2);

	CGPoint p[12];
	p[0] = CGPointSub(p0,n0);
	p[1] = CGPointSub(CGPointSub(p0,d0),n0);
	p[2] = CGPointSub(p0,d0);
	p[3] = CGPointAdd(CGPointSub(p0,d0),n0);
	p[4] = CGPointAdd(p0,n0);
	p[6] = CGPointSub(p2,n2);
	p[7] = CGPointSub(CGPointSub(p2,d2),n2);
	p[8] = CGPointSub(p2,d2);
	p[9] = CGPointAdd(CGPointSub(p2,d2),n2);
	p[10] = CGPointAdd(p2,n2);

	if (-CGPointDot(d0, d2) > radius0 * radius2 * 0.99)
	{
		p[ 5] = CGPointMul(CGPointAdd(p[ 4], p[ 6]),0.5);
		p[11] = CGPointMul(CGPointAdd(p[10], p[ 0]),0.5);
	}
	else
	{
		p[ 5] = RayIntersect(p[ 3],p[ 4], p[ 6],p[ 7]);
		p[11] = RayIntersect(p[ 9],p[10], p[ 0],p[ 1]);
	}

	CGMutablePathRef path;
	path = CGPathCreateMutable();

	const BOOL capEnds = YES;
	if (capEnds)
	{
		CGPathMoveToCGPoint(path, NULL, p[0]);
			CGPathAddArcToCGPoint(path, NULL, p[ 1], p[ 2], radius0);
			CGPathAddArcToCGPoint(path, NULL, p[ 3], p[ 4], radius0);
		CGPathAddQuadCurveToCGPoint(path, NULL, p[ 5], p[ 6]);
			CGPathAddArcToCGPoint(path, NULL, p[ 7], p[ 8], radius2);
			CGPathAddArcToCGPoint(path, NULL, p[ 9], p[10], radius2);
		CGPathAddQuadCurveToCGPoint(path, NULL, p[11], p[ 0]);
	}
	else
	{
		CGPathMoveToCGPoint(path, NULL, p[0]);
			CGPathAddLineToCGPoint(path, NULL, p[4]);
		CGPathAddQuadCurveToCGPoint(path, NULL, p[ 5], p[ 6]);
			CGPathAddLineToCGPoint(path, NULL, p[10]);
		CGPathAddQuadCurveToCGPoint(path, NULL, p[11], p[ 0]);
	}

	return path;
}
