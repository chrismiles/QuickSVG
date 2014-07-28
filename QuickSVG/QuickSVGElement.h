//
//  QuickSVGElement.h
//  QuickSVG
//
//  Created by Matthew Newberry on 9/28/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

@class QuickSVG;

typedef NSBezierPath QuickSVGBezierPath;

typedef enum QuickSVGElementType
{
	QuickSVGElementTypeBasicShape = 0,
	QuickSVGElementTypePath,
	QuickSVGElementTypeLink,
	QuickSVGElementTypeText,
	QuickSVGElementTypeUnknown
} QuickSVGElementType;

@interface QuickSVGElement : NSObject <NSCoding>

@property (nonatomic, weak) QuickSVG *quickSVG;
@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, strong) QuickSVGBezierPath *shapePath;
@property (nonatomic, strong) NSArray *elements;
@property (nonatomic, readonly) CGAffineTransform svgTransform;
//@property (nonatomic, strong) NSMutableArray *shapeLayers;

@end
