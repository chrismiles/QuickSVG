//
//  QuickSVGSymbol.m
//  QuickSVG
//
//  Created by Matthew Newberry on 9/28/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVGSymbol.h"

@implementation QuickSVGSymbol

+ (QuickSVGSymbol *) symbol
{
	QuickSVGSymbol *symbol = (QuickSVGSymbol *) [QuickSVGSymbol layer];
	symbol.instances = [[NSMutableArray alloc] init];
	symbol.bezierPath = [UIBezierPath bezierPath];
	symbol.elements = [[NSMutableArray alloc] init];
	
	return symbol;
}

@end
