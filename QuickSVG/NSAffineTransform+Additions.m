//
//  NSAffineTransform+Additions.m
//  QuickSVG
//
//  Created by Chris Miles on 24/07/2014.
//  Copyright (c) 2014 Chris Miles. All rights reserved.
//

#import "NSAffineTransform+Additions.h"

@implementation NSAffineTransform (Additions)

+ (NSAffineTransform *)quickSVG_transformWithCGAffineTransform:(CGAffineTransform)transform
{
    NSAffineTransform *affineTransform = [NSAffineTransform transform];
    affineTransform.transformStruct = (NSAffineTransformStruct) {
        .m11 = transform.a,
        .m12 = transform.b,
        .m21 = transform.c,
        .m22 = transform.d,
        .tX = transform.tx,
        .tY = transform.ty
    };

    return affineTransform;
}

- (CGAffineTransform)quickSVG_CGAffineTransform
{
    NSAffineTransformStruct transform = self.transformStruct;

    return (CGAffineTransform) {
        .a = transform.m11,
        .b = transform.m12,
        .c = transform.m21,
        .d = transform.m22,
        .tx = transform.tX,
        .ty = transform.tY
    };
}

@end
