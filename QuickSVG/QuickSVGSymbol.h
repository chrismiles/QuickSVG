//
//  QuickSVGSymbol.h
//  QuickSVG
//
//  Created by Matthew Newberry on 9/28/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

typedef enum QuickSVGElementType
{
	QuickSVGElementTypeBasicShape,
	QuickSVGElementTypePath,
	QuickSVGElementTypeLink,
	QuickSVGElementTypeText,
	QuickSVGElementTypeUnknown
} QuickSVGElementType;

@interface QuickSVGSymbol : CAShapeLayer

@property (nonatomic, strong) NSMutableArray *elements;
@property (nonatomic, strong) NSMutableArray *instances;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) QuickSVGElementType type;
@property (nonatomic, strong) UIBezierPath *bezierPath;
@property (nonatomic, assign) BOOL adjusted;

+ (QuickSVGSymbol *) symbol;

@end
