//
//  NSAffineTransform+Additions.h
//  QuickSVG
//
//  Created by Chris Miles on 24/07/2014.
//  Copyright (c) 2014 Chris Miles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAffineTransform (Additions)

+ (NSAffineTransform *)quickSVG_transformWithCGAffineTransform:(CGAffineTransform)transform;

- (CGAffineTransform)quickSVG_CGAffineTransform;

@end
