//
//  QuickSVGInstance.m
//  QuickSVG
//
//  Created by Matthew Newberry on 9/28/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVGInstance.h"
#import "UIColor+Additions.h"

NSInteger const maxPathComplexity	= 1000;
NSInteger const maxParameters		= 64;
NSInteger const maxTokenLength		= 64;
NSString* const separatorCharString = @"-,CcMmLlHhVvZzqQaAsS";
NSString* const commandCharString	= @"CcMmLlHhVvZzqQaAsS";
unichar const invalidCommand		= '*';

@interface Token : NSObject {
@private
	unichar			command;
	NSMutableArray  *values;
}

- (id)initWithCommand:(unichar)commandChar;
- (void)addValue:(CGFloat)value;
- (CGFloat)parameter:(NSInteger)index;
- (NSInteger)valence;

@property(nonatomic, assign) unichar command;

@end

@implementation Token

- (id)initWithCommand:(unichar)commandChar {
	self = [self init];
    if (self) {
		command = commandChar;
		values = [[NSMutableArray alloc] initWithCapacity:maxParameters];
	}
	return self;
}

- (void)addValue:(CGFloat)value {
	[values addObject:[NSNumber numberWithDouble:value]];
}

- (CGFloat)parameter:(NSInteger)index {
	return [[values objectAtIndex:index] doubleValue];
}

- (NSInteger)valence
{
	return [values count];
}


@synthesize command;

@end


@interface QuickSVGInstance ()

@property (nonatomic, assign) CGFloat pathScale;
@property (nonatomic, strong) NSCharacterSet *separatorSet;
@property (nonatomic, strong) NSCharacterSet *commandSet;
@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) CGPoint lastControlPoint;
@property (nonatomic, assign) BOOL validLastControlPoint;
@property (nonatomic, strong) NSMutableArray *tokens;
@property (nonatomic, strong) UIBezierPath *bezierPathBeingDrawn;

@end

@implementation QuickSVGInstance

- (id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if(self)
	{
		self.backgroundColor = [UIColor clearColor];
		
		_pathScale = 0;
		[self reset];
		_separatorSet = [NSCharacterSet characterSetWithCharactersInString:separatorCharString];
		_commandSet = [NSCharacterSet characterSetWithCharactersInString:commandCharString];
	}
	
	return self;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.layer.borderColor = [UIColor redColor].CGColor;
	self.layer.borderWidth = self.layer.borderWidth == 0 ? 2 : 0;
}

- (void) drawRect:(CGRect)rect
{
	NSArray *elements = [NSArray arrayWithArray:_symbol.elements];
		
	for(NSDictionary *element in elements)
	{		
		if(![element isKindOfClass:[NSDictionary class]])
			continue;
		
		UIBezierPath *path;
		
		NSString *shapeKey = [[element allKeys] objectAtIndex:0];
		QuickSVGElementType type = [self elementTypeForElement:element];
		
		switch (type) {
			case QuickSVGElementTypeBasicShape:
			{
				path = [self addBasicShape:shapeKey withAttributes:element[shapeKey] inSymbol:_symbol];
				
			}
				break;
			case QuickSVGElementTypePath:
			{
				path = [self addPath:shapeKey withAttributes:element[shapeKey] inSymbol:_symbol];
			}
				break;
			case QuickSVGElementTypeUnknown:
			default:
				// NSLog(@"**** Invalid element type: %@", element);
				break;
		}
				
		if([[element[shapeKey] allKeys] containsObject:@"transform"] && [element[shapeKey][@"transform"] isKindOfClass:[NSValue class]])
		{
			CGAffineTransform transform = [element[shapeKey][@"transform"] CGAffineTransformValue];
			[path applyTransform:transform];
		}
		
		CGFloat transX = _symbol.frame.origin.x * -1;
		CGFloat transY = _symbol.frame.origin.y * -1;
		
		CGAffineTransform transform = CGAffineTransformMakeTranslation(transX, transY);
		[path applyTransform:transform];
		
		[self applyStyleAttributes:element[shapeKey] toBezierPath:path];
	}
}

- (QuickSVGElementType) elementTypeForElement:(NSDictionary *) element
{
	NSString *key = [[element allKeys] objectAtIndex:0];
	
	if([[self acceptableBasicShapeTypes] containsObject:key])
	{
		return QuickSVGElementTypeBasicShape;
	}
	else if([[self acceptablePathTypes] containsObject:key])
	{
		return QuickSVGElementTypePath;
	}
	else
	{
		return QuickSVGElementTypeUnknown;
	}
}


- (NSArray *) acceptableBasicShapeTypes
{
	NSArray *shapes = @[@"rect", @"circle", @"ellipse"];
	
	return shapes;
}

- (NSArray *) acceptablePathTypes
{
	NSArray *paths = @[@"path", @"polygon", @"line", @"polyline"];
	
	return paths;
}

- (UIBezierPath *) addPath:(NSString *) pathType withAttributes:(NSDictionary *) attributes inSymbol:(QuickSVGSymbol *) symbol
{
	if([pathType isEqualToString:@"path"])
	{
		return [self drawPathWithAttributes:attributes inSymbol:symbol];
	}
	else if([pathType isEqualToString:@"line"])
	{
		return [self drawLineWithAttributes:attributes inSymbol:symbol];
	}
	else if([pathType isEqualToString:@"polyline"])
	{
		return [self drawPolylineWithAttributes:attributes inSymbol:symbol];
	}
	else if([pathType isEqualToString:@"polygon"])
	{
		return [self drawPolygonWithAttributes:attributes inSymbol:symbol];
	}
	
	return nil;
}


- (UIBezierPath *) addBasicShape:(NSString *) shapeType withAttributes:(NSDictionary *) attributes inSymbol:(QuickSVGSymbol *) symbol
{
	if([shapeType isEqualToString:@"rect"])
	{
		return [self drawRectWithAttributes:attributes inSymbol:symbol];
	}
	else if([shapeType isEqualToString:@"circle"])
	{
		return [self drawCircleWithAttributes:attributes inSymbol:symbol];
	}
	else if([shapeType isEqualToString:@"ellipse"])
	{
		return [self drawEllipseWithAttributes:attributes inSymbol:symbol];
	}
	else
	{
		if (DEBUG) {
			NSLog(@"**** Invalid basic shape: %@", shapeType);
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Shape Drawing

- (UIBezierPath *) drawRectWithAttributes:(NSDictionary *) attributes inSymbol:(QuickSVGSymbol *) symbol
{
	CGRect frame = CGRectMake([attributes[@"x"] floatValue], [attributes[@"y"] floatValue], [attributes[@"width"] floatValue], [attributes[@"height"] floatValue]);
	
	UIBezierPath *rect = [UIBezierPath bezierPathWithRect:frame];
	
	return rect;
}

- (UIBezierPath *) drawCircleWithAttributes:(NSDictionary *) attributes inSymbol:(QuickSVGSymbol *) symbol
{
	CGPoint center = CGPointMake([attributes[@"cx"] floatValue], [attributes[@"cy"] floatValue]);
	CGSize radii = CGSizeMake([attributes[@"r"] floatValue], [attributes[@"r"] floatValue]);
	
	CGRect frame = CGRectMake(center.x - radii.width / 2, center.y - radii.height / 2, radii.width, radii.height);
	
	UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:frame];
	
	return circle;
}

- (UIBezierPath *) drawEllipseWithAttributes:(NSDictionary *) attributes inSymbol:(QuickSVGSymbol *) symbol
{
	CGPoint center = CGPointMake([attributes[@"cx"] floatValue], [attributes[@"cy"] floatValue]);
	CGSize radii = CGSizeMake([attributes[@"rx"] floatValue], [attributes[@"ry"] floatValue]);
	
	CGRect frame = CGRectMake(center.x - radii.width / 2, center.y - radii.height / 2, radii.width, radii.height);
	
	UIBezierPath *ellipse = [UIBezierPath bezierPathWithOvalInRect:frame];
	
	return ellipse;
}

- (UIBezierPath *) drawPathWithAttributes:(NSDictionary *) attributes inSymbol:(QuickSVGSymbol *) symbol
{
	self.bezierPathBeingDrawn = [UIBezierPath bezierPath];
	
	NSString *pathData = [attributes[@"d"] stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	[self parsePath:pathData];
	
	[self reset];
	
	for (Token *thisToken in _tokens) {
		unichar command = [thisToken command];
		switch (command) {
			case 'M':
			case 'm':
				[self appendSVGMCommand:thisToken];
				break;
			case 'L':
			case 'l':
			case 'H':
			case 'h':
			case 'V':
			case 'v':
				[self appendSVGLCommand:thisToken];
				break;
			case 'C':
			case 'c':
				[self appendSVGCCommand:thisToken];
				break;
			case 'S':
			case 's':
				[self appendSVGSCommand:thisToken];
				break;
			case 'Z':
			case 'z':
				[_bezierPathBeingDrawn closePath];
				break;
			default:
				NSLog(@"*** Error: Cannot process command : '%c'", command);
				break;
		}
	}
	
	return _bezierPathBeingDrawn;
}

- (UIBezierPath *) drawLineWithAttributes:(NSDictionary *) attributes inSymbol:(QuickSVGSymbol *) symbol
{
	UIBezierPath *line = [UIBezierPath bezierPath];
	CGPoint startingPoint = CGPointMake([attributes[@"x1"] floatValue], [attributes[@"y1"] floatValue]);
	CGPoint endingPoint = CGPointMake([attributes[@"x2"] floatValue], [attributes[@"y2"] floatValue]);
	
	[line moveToPoint:startingPoint];
	[line addLineToPoint:endingPoint];
	
	return line;
}

- (UIBezierPath *) drawPolylineWithAttributes:(NSDictionary *) attributes inSymbol:(QuickSVGSymbol *) symbol
{
	return [self drawPolyElementWithAttributes:attributes isPolygon:NO];
}

- (UIBezierPath *) drawPolygonWithAttributes:(NSDictionary *) attributes inSymbol:(QuickSVGSymbol *) symbol
{
	return [self drawPolyElementWithAttributes:attributes isPolygon:YES];
}

- (UIBezierPath *) drawPolyElementWithAttributes:(NSDictionary *) attributes isPolygon:(BOOL) isPolygon
{	
	NSArray *points = [self arrayFromPointsAttribute:attributes[@"points"]];
	UIBezierPath *polygon = [UIBezierPath bezierPath];
	
	CGPoint firstPoint = CGPointFromString(points[0]);
	[polygon moveToPoint:firstPoint];
	
	for(int x = 0; x < [points count]; x++)
	{		
		if(x + 1 < [points count])
		{
			CGPoint endPoint = CGPointFromString(points[x + 1]);
			[polygon addLineToPoint:endPoint];
		}
	}
	
	if(isPolygon)
	{
		[polygon addLineToPoint:firstPoint];
		[polygon closePath];
	}
	
	return polygon;
}

#pragma mark -
#pragma mark Path Drawing

- (NSMutableArray *)parsePath:(NSString *)attr
{
	NSMutableArray *stringTokens = [NSMutableArray arrayWithCapacity: maxPathComplexity];
	
	NSInteger index = 0;
	while (index < [attr length]) {
		
		NSMutableString *stringToken = [[NSMutableString alloc] initWithCapacity:maxTokenLength];
		[stringToken setString:@""];
		
		unichar	charAtIndex = [attr characterAtIndex:index];
		
		if (charAtIndex != ',') {
			[stringToken appendString:[NSString stringWithFormat:@"%c", charAtIndex]];
		}
		
		if (![_commandSet characterIsMember:charAtIndex] && charAtIndex != ',') {
			
			while ( (++index < [attr length]) && ![_separatorSet characterIsMember:(charAtIndex = [attr characterAtIndex:index])] ) {
				
				[stringToken appendString:[NSString stringWithFormat:@"%c", charAtIndex]];
			}
		}
		else {
			
			index++;
		}
		
		if ([stringToken length]) {
			
			[stringTokens addObject:stringToken];
		}
	}
	
	if ([stringTokens count] == 0) {
		
		NSLog(@"*** Error: Path string is empty of tokens");
		return nil;
	}
	
	// turn the stringTokens array into Tokens, checking validity of tokens as we go
	_tokens = [[NSMutableArray alloc] initWithCapacity:maxPathComplexity];
	index = 0;
	NSString *stringToken = [stringTokens objectAtIndex:index];
	unichar command = [stringToken characterAtIndex:0];
	while (index < [stringTokens count]) {
		if (![_commandSet characterIsMember:command]) {
			NSLog(@"*** Error: Path string parse error: found float where expecting command at token %d in path %s.",
				  index, [attr cStringUsingEncoding:NSUTF8StringEncoding]);
			return nil;
		}
		Token *token = [[Token alloc] initWithCommand:command];
		
		// There can be any number of floats after a command. Suck them in until the next command.
		while ((++index < [stringTokens count]) && ![_commandSet characterIsMember:
													 (command = [(stringToken = [stringTokens objectAtIndex:index]) characterAtIndex:0])]) {
			
			NSScanner *floatScanner = [NSScanner scannerWithString:stringToken];
			float value;
			if (![floatScanner scanFloat:&value]) {
				NSLog(@"*** Error: Path string parse error: expected float or command at token %d (but found %s) in path %s.",
					  index, [stringToken cStringUsingEncoding:NSUTF8StringEncoding], [attr cStringUsingEncoding:NSUTF8StringEncoding]);
				return nil;
			}
			// Maintain scale.
			_pathScale = (abs(value) > _pathScale) ? abs(value) : _pathScale;
			[token addValue:value];
		}
		
		// now we've reached a command or the end of the stringTokens array
		[_tokens	 addObject:token];
	}
	//[stringTokens release];
	return _tokens;
}

- (void)reset
{
	_lastPoint = CGPointMake(0, 0);
	_validLastControlPoint = NO;
}

- (void)appendSVGMCommand:(Token *)token
{
	_validLastControlPoint = NO;
	NSInteger index = 0;
	BOOL first = YES;
	while (index < [token valence]) {
		CGFloat x = [token parameter:index] + ([token command] == 'm' ? _lastPoint.x : 0);
		if (++index == [token valence]) {
			NSLog(@"*** Error: Invalid parameter count in M style token");
			return;
		}
		CGFloat y = [token parameter:index] + ([token command] == 'm' ? _lastPoint.y : 0);
		_lastPoint = CGPointMake(x, y);
		if (first) {
			[_bezierPathBeingDrawn moveToPoint:_lastPoint];
			first = NO;
		}
		else {
			[_bezierPathBeingDrawn addLineToPoint:_lastPoint];
		}
		index++;
	}
}

- (void)appendSVGLCommand:(Token *)token
{
	_validLastControlPoint = NO;
	NSInteger index = 0;
	while (index < [token valence]) {
		CGFloat x = 0;
		CGFloat y = 0;
		switch ( [token command] ) {
			case 'l':
				x = _lastPoint.x;
				y = _lastPoint.y;
			case 'L':
				x += [token parameter:index];
				if (++index == [token valence]) {
					NSLog(@"*** Error: Invalid parameter count in L style token");
					return;
				}
				y += [token parameter:index];
				break;
			case 'h' :
				x = _lastPoint.x;
			case 'H' :
				x += [token parameter:index];
				y = _lastPoint.y;
				break;
			case 'v' :
				y = _lastPoint.y;
			case 'V' :
				y += [token parameter:index];
				x = _lastPoint.x;
				break;
			default:
				NSLog(@"*** Error: Unrecognised L style command.");
				return;
		}
		_lastPoint = CGPointMake(x, y);
		
		[_bezierPathBeingDrawn addLineToPoint:_lastPoint];
		index++;
	}
}

- (void)appendSVGCCommand:(Token *)token
{
	NSInteger index = 0;
	while ((index + 5) < [token valence]) {  // we must have 6 floats here (x1, y1, x2, y2, x, y).
		CGFloat x1 = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.x : 0);
		CGFloat y1 = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.y : 0);
		CGFloat x2 = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.x : 0);
		CGFloat y2 = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.y : 0);
		CGFloat x  = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.x : 0);
		CGFloat y  = [token parameter:index++] + ([token command] == 'c' ? _lastPoint.y : 0);
		_lastPoint = CGPointMake(x, y);
		
		[_bezierPathBeingDrawn addCurveToPoint:_lastPoint
								 controlPoint1:CGPointMake(x1,y1)
								 controlPoint2:CGPointMake(x2, y2)];
		
		_lastControlPoint = CGPointMake(x2, y2);
		_validLastControlPoint = YES;
	}
	
	if (index == 0) {
		NSLog(@"*** Error: Insufficient parameters for C command");
	}
}

- (void)appendSVGSCommand:(Token *)token
{
	if (!_validLastControlPoint) {
		NSLog(@"*** Error: Invalid last control point in S command");
	}
	
	NSInteger index = 0;
	while ((index + 3) < [token valence]) {  // we must have 4 floats here (x2, y2, x, y).
		CGFloat x1 = _lastPoint.x + (_lastPoint.x - _lastControlPoint.x); // + ([token command] == 's' ? lastPoint.x : 0);
		CGFloat y1 = _lastPoint.y + (_lastPoint.y - _lastControlPoint.y); // + ([token command] == 's' ? lastPoint.y : 0);
		CGFloat x2 = [token parameter:index++] + ([token command] == 's' ? _lastPoint.x : 0);
		CGFloat y2 = [token parameter:index++] + ([token command] == 's' ? _lastPoint.y : 0);
		CGFloat x  = [token parameter:index++] + ([token command] == 's' ? _lastPoint.x : 0);
		CGFloat y  = [token parameter:index++] + ([token command] == 's' ? _lastPoint.y : 0);
		_lastPoint = CGPointMake(x, y);
		
		[_bezierPathBeingDrawn addCurveToPoint:_lastPoint
								 controlPoint1:CGPointMake(x1,y1)
								 controlPoint2:CGPointMake(x2, y2)];
		
		_lastControlPoint = CGPointMake(x2, y2);
		_validLastControlPoint = YES;
	}
	
	if (index == 0) {
		NSLog(@"*** Error: Insufficient parameters for S command");
	}
}

- (NSArray *) arrayFromPointsAttribute:(NSString *) points
{
    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
	NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
	
	NSArray *parts = [points componentsSeparatedByCharactersInSet:whitespaces];
	NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
	NSString *parsed = [filteredArray componentsJoinedByString:@","];
	
	NSArray *commaPieces = [parsed componentsSeparatedByString:@","];
	
	NSMutableArray *pointsArray = [NSMutableArray arrayWithCapacity:[commaPieces count] / 2];
	
	for(int x = 0; x < [commaPieces count]; x++)
	{
		if(x % 2 == 0)
		{
			CGPoint point = CGPointMake([commaPieces[x] floatValue], [commaPieces[x + 1] floatValue]);
			[pointsArray addObject:NSStringFromCGPoint(point)];
		}
	}
	NSLog(@"%@", pointsArray);
	
	return pointsArray;
}

#pragma mark -
#pragma mark Shape Styling

- (void) applyStyleAttributes:(NSDictionary *) attributes toBezierPath:(UIBezierPath *) bezierPath
{
	// Defaults
	__block BOOL stroke = NO;
	__block BOOL fill = NO;
	__block CGFloat lineWidth = 1;
	bezierPath.lineCapStyle = kCGLineCapSquare;
	bezierPath.lineJoinStyle = kCGLineJoinMiter;
	
	[attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		
		if([key isEqualToString:@"stroke-width"])
		{
			lineWidth = [obj floatValue];
		}
		else if([key isEqualToString:@"stroke-linecap"])
		{
			if([obj isEqualToString:@"butt"])
			{
				bezierPath.lineCapStyle = kCGLineCapButt;
			}
			else if([obj isEqualToString:@"round"])
			{
				bezierPath.lineCapStyle = kCGLineCapRound;
			}
			else if([obj isEqualToString:@"square"])
			{
				bezierPath.lineCapStyle = kCGLineCapSquare;
			}
		}
		else if([key isEqualToString:@"stroke-dasharray"])
		{
			NSArray *pieces = [attributes[@"stroke-dasharray"] componentsSeparatedByString:@","];
			int a = [pieces[0] intValue];
			int b = [pieces[1] intValue];
			
			const float p[2] = {a,b};
			
			[bezierPath setLineDash:p count:2 phase:0.3];
		}
		else if([key isEqualToString:@"stroke-linejoin"])
		{
			if([obj isEqualToString:@"bevel"])
			{
				bezierPath.lineJoinStyle = kCGLineJoinBevel;
			}
			else if([obj isEqualToString:@"round"])
			{
				bezierPath.lineJoinStyle = kCGLineJoinRound;
			}
			else if([obj isEqualToString:@"miter"])
			{
				bezierPath.lineJoinStyle = kCGLineJoinMiter;
			}
		}
		else if([key isEqualToString:@"stroke"])
		{
			CGFloat alpha = 1.0f;
			
			if([key isEqualToString:@"stroke-opacity"])
			{
				alpha = [obj floatValue];
			}
			
			NSString *hexString = [obj substringFromIndex:1];
			UIColor *color = [UIColor colorWithHexString:hexString withAlpha:alpha];
			[color setStroke];
			
			stroke = YES;
		}
		else if([key isEqualToString:@"fill"])
		{
			CGFloat alpha = 1.0f;
			
			if([key isEqualToString:@"fill-opacity"])
			{
				alpha = [obj floatValue];
			}
			
			if([attributes[@"fill"] isEqualToString:@"none"])
			{
				[[UIColor clearColor] set];
			}
			else
			{
				NSString *hexString = [obj substringFromIndex:1];
				UIColor *color = [UIColor colorWithHexString:hexString withAlpha:alpha];

				[color setFill];
			}
			
			fill = YES;
		}
	}];
	
	if(fill)
	{
		[bezierPath fill];
	}
	
	if(stroke)
	{
		bezierPath.lineWidth = lineWidth;
		[bezierPath stroke];
	}	
}

@end
