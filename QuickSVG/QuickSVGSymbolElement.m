//
//  QuickSVGSymbolElement.m
//  QuickSVG
//
//  Created by Matthew Newberry on 9/28/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVGSymbolElement.h"

@implementation QuickSVGSymbolElement

+ (QuickSVGSymbolElement *) elementWithStyle:(NSDictionary *) style forBezierPath:(UIBezierPath *) bezierPath
{
	QuickSVGSymbolElement *element = [[QuickSVGSymbolElement alloc] init];
	element.styleAttributes = style;
	element.bezierPath = bezierPath;
	
	return element;
}

@end