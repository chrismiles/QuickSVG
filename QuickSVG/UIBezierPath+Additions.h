//
//  UIBezierPath+Additions.h
//  QuickSVG
//
//  Created by Matthew Newberry on 12/27/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import <UIKit/UIKit.h>

#define POINT(_INDEX_) \
[(NSValue *)[points objectAtIndex:_INDEX_] CGPointValue]
#define VALUE(_INDEX_) \
[NSValue valueWithCGPoint:points[_INDEX_]]

@interface UIBezierPath (Additions)

- (UIBezierPath *) fitInRect: (CGRect) destRect;
- (NSArray *) points;
+ (UIBezierPath *) pathWithPoints: (NSArray *) points;

@end
