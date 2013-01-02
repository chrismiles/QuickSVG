//
//  QuickSVGInstance.h
//  QuickSVG
//
//  Created by Matthew Newberry on 9/28/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVGSymbol.h"

@class QuickSVG;

@interface QuickSVGInstance : UIView

@property (nonatomic, weak) QuickSVG *quickSVG;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, strong) UIBezierPath *shapePath;
@property (nonatomic, strong) CAShapeLayer *drawingLayer;
@property (nonatomic, strong) NSArray *elements;

@end