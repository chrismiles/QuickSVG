//
//  UIBezierPath+Additions.h
//  QuickSVG
//
//  Created by Matthew Newberry on 12/27/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (Additions)

- (UIBezierPath *) fitInRect: (CGRect) destRect;
+ (UIBezierPath *) pathWithPoints: (NSArray *) points;

@end
