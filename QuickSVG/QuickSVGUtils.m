//
//  QuickSVGUtils.m
//  QuickSVG
//
//  Created by Matthew Newberry on 12/18/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVGUtils.h"

CGAffineTransform makeTransform(CGFloat xScale, CGFloat yScale, CGFloat theta, CGFloat tx, CGFloat ty) {
    CGAffineTransform t = CGAffineTransformIdentity;
    t.a = xScale * cos(theta);
    t.b = yScale * sin(theta);
    t.c = xScale * -sin(theta);
    t.d = yScale * cos(theta);
    t.tx = tx;
    t.ty = ty;
    
    return t;
}

CGAffineTransform makeTransformFromSVGMatrix(NSString *matrix) {
    matrix = [matrix stringByReplacingOccurrencesOfString:@"matrix(" withString:@"{"];
    matrix = [matrix stringByReplacingOccurrencesOfString:@")" withString:@"}"];
    matrix = [matrix stringByReplacingOccurrencesOfString:@" " withString:@","];
	
	CGAffineTransform t = CGAffineTransformFromString(matrix);
    
    CGFloat xScale = getXScale(t);
    CGFloat yScale = getYScale(t);
    CGFloat rotation = getRotation(t);
    
    return makeTransform(xScale, yScale, rotation, t.tx, t.ty);
}

CGFloat getXScale(CGAffineTransform t) {
    return sqrtf(t.a * t.a + t.c * t.c);
}

CGFloat getYScale(CGAffineTransform t) {
    return sqrtf(t.b * t.b + t.d * t.d);
}

CGFloat getRotation(CGAffineTransform t) {
    return atan2f(t.b, t.a);
}

CGFloat aspectScale(CGSize sourceSize, CGSize destSize) {
	CGFloat scaleW = destSize.width / sourceSize.width;
	CGFloat scaleH = destSize.height / sourceSize.height;
	return MIN(scaleW, scaleH);
}