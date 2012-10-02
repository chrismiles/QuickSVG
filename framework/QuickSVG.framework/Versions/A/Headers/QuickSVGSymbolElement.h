//
//  QuickSVGSymbolElement.h
//  QuickSVG
//
//  Created by Matthew Newberry on 9/28/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QuickSVGSymbolElement : NSObject

@property (nonatomic, strong) NSDictionary *styleAttributes;
@property (nonatomic, strong) UIBezierPath *bezierPath;

+ (QuickSVGSymbolElement *) elementWithStyle:(NSDictionary *) style forBezierPath:(UIBezierPath *) bezierPath;

@end
