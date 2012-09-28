//
//  QuickSVGInstance.h
//  QuickSVG
//
//  Created by Matthew Newberry on 9/28/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVGSymbol.h"

@interface QuickSVGInstance : UIView

@property (nonatomic, strong) QuickSVGSymbol *symbol;
@property (nonatomic, strong) id object;

@end
