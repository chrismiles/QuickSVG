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

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_elements forKey:@"elements"];
	[aCoder encodeObject:_title forKey:@"title"];
	[aCoder encodeObject:_bezierPath forKey:@"bezierPath"];
	[aCoder encodeObject:@(_type) forKey:@"type"];
	[aCoder encodeCGRect:self.frame forKey:@"frame"];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [QuickSVGSymbol symbol];
	
	if(self) {
		self.elements = [aDecoder decodeObjectForKey:@"elements"];
		self.title = [aDecoder decodeObjectForKey:@"title"];
		self.bezierPath = [aDecoder decodeObjectForKey:@"bezierPath"];
		self.type = [[aDecoder decodeObjectForKey:@"type"] intValue];
		self.frame = [aDecoder decodeCGRectForKey:@"frame"];
	}
	
	return self;
}

@end
