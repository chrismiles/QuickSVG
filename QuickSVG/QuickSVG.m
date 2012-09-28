//
//  QuickSVG.m
//  QuickSVG
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVG.h"

#define DEBUG 1
#define kTransformKey @"matrix"

@interface QuickSVG ()

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableArray *currentSymbolElements;
@property (nonatomic, assign) BOOL currentlyParsingASymbol;
@property (nonatomic, strong) NSMutableArray *parsedSymbolInstances;

@end

@implementation QuickSVG

+ (QuickSVG *) svgFromURL:(NSURL *) url

{
	QuickSVG *svg = [[QuickSVG alloc] init];
	[svg parseSVGFileWithURL:url];
	
	return svg;
}

- (id) init
{
	self = [super init];
	
	if(self){
		
		self.symbols = [[NSMutableDictionary alloc] init];
		self.currentSymbolElements = [[NSMutableArray alloc] init];
		self.parsedSymbolInstances = [[NSMutableArray alloc] init];
		self.instances = [[NSMutableArray alloc] init];
		self.groups = [[NSMutableArray alloc] init];		
	}
	
	return self;
}

#pragma mark -
#pragma mark View

- (UIView *) view
{
	if(_view == nil)
	{
		self.view = [[UIView alloc] init];
		_view.frame = _canvasFrame;
		
		for(QuickSVGInstance *instance in self.instances)
		{
			[_view addSubview:instance];
		}
	}
	
	return _view;
}

#pragma mark -
#pragma mark Parsing

- (BOOL) parseSVGFileWithURL:(NSURL *) url
{
	if (url == nil)
        return NO;
	
	self.view = nil;
    
	[_symbols removeAllObjects];
    self.xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    
    [_xmlParser setDelegate:self];
    [_xmlParser setShouldResolveExternalEntities:NO];
	
    BOOL success = [_xmlParser parse];
	
    if (success == NO)
        NSLog(@"*** XML Parsing Error");
    
    return success;
}

- (void) addCurrentElementsToCurrentSymbol
{
	if([_currentSymbolElements count] > 0)
	{
		NSDictionary *symbolDict = _currentSymbolElements[0];
		[_currentSymbolElements removeObjectAtIndex:0];
		
		NSDictionary *attributes = symbolDict[@"symbol"];
		QuickSVGSymbol *symbol = [self symbolWithAttributes:attributes andElements:_currentSymbolElements];

		_symbols[symbol.title] = symbol;
	}
}

- (QuickSVGSymbol *) symbolWithAttributes:(NSDictionary *) attributes andElements:(NSArray *) elements
{
	NSString *key = [[attributes allKeys] containsObject:@"id"] ? attributes[@"id"] : [NSString stringWithFormat:@"Symbol%i", [_symbols count] + 1];
	
	QuickSVGSymbol *symbol = [QuickSVGSymbol symbol];
	symbol.title = key;
	
	if([[attributes allKeys] containsObject:@"viewBox"])
	{
		symbol.frame = [self rectFromViewBoxString:attributes[@"viewBox"]];
	}
	
	[symbol.elements addObjectsFromArray:elements];
		
	return symbol;
}

- (void) resolveLinkedSymbolPaths
{
	[_symbols enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
	 {
		 QuickSVGSymbol *symbol = (QuickSVGSymbol *) obj;
		 __block NSMutableArray *resolvedElements = [NSMutableArray arrayWithArray:symbol.elements];
		 
		 int x = 0;
		 for(NSDictionary *element in symbol.elements)
		 {
			 if([[[element allKeys] objectAtIndex:0] isEqualToString:@"use"])
			 {
				 NSArray *newElements = [self instanceFromLinkedSymbolWithAttributes:element[@"use"]];
				 [resolvedElements removeObject:element];
				 [resolvedElements addObjectsFromArray:newElements];
			 }
			 
			 x++;
		 }
		 
		 [symbol.elements removeAllObjects];
		 [symbol.elements addObjectsFromArray:resolvedElements];
	 }];
}

- (NSArray *) instanceFromLinkedSymbolWithAttributes:(NSDictionary *) attributes
{
	__block NSMutableArray *resolvedSymbolElements = [NSMutableArray array];
	__block NSString *symbolRef = [attributes[@"xlink:href"] substringFromIndex:1];
	
	[_symbols enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
	 {
		 NSComparisonResult result = [symbolRef caseInsensitiveCompare:key];
		 
		 if(result == NSOrderedSame)
		 {
			 QuickSVGSymbol *symbol = (QuickSVGSymbol *) obj;
			 
			 for(NSDictionary *pathData in symbol.elements)
			 {
				 NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:attributes];
				 [data addEntriesFromDictionary:[[pathData allValues] objectAtIndex:0]];
				 
				 CGAffineTransform transform = [self transformForSVGMatrix:data];
				 [data setObject:[NSValue valueWithCGAffineTransform:transform] forKey:@"transform"];
				 
				 [resolvedSymbolElements addObject:@{[[pathData allKeys] objectAtIndex:0] : data}];
			 }
		 }
	 }];
	
	return resolvedSymbolElements;
}

- (void) addInstanceOfSymbol:(NSDictionary *) attributes
{
	__block NSString *symbolRef = [attributes[@"xlink:href"] substringFromIndex:1];
	QuickSVGInstance *instance = [self instanceWithAttributes:attributes];
	
	[_symbols enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
	{
		NSComparisonResult result = [symbolRef caseInsensitiveCompare:key];
		
		if(result == NSOrderedSame)
		{
			QuickSVGSymbol *symbol = (QuickSVGSymbol *) obj;
			[symbol.instances addObject:instance];
			instance.symbol = symbol;
			
			[_instances addObject:instance];
		}
	}];
}

- (QuickSVGInstance *) instanceWithAttributes:(NSDictionary *) attributes
{
	CGRect frame = CGRectMake([attributes[@"x"] floatValue], [attributes[@"y"] floatValue], [attributes[@"width"] floatValue], [attributes[@"height"] floatValue]);
	
	QuickSVGInstance *instance = [[QuickSVGInstance alloc] initWithFrame:frame];
	instance.transform = [self transformForSVGMatrix:attributes];
	
	return instance;
}

#pragma mark -
#pragma mark NSXMLParser Delegate

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{	
	if([elementName isEqualToString:@"symbol"])
	{
		_currentlyParsingASymbol = YES;
	}
	else if([elementName isEqualToString:@"svg"])
	{
		self.canvasFrame = [self rectFromViewBoxString:attributeDict[@"viewBox"]];
	}
	else if([elementName isEqualToString:@"use"] && !_currentlyParsingASymbol)
	{
		[_parsedSymbolInstances addObject:attributeDict];
	}
	
	if(_currentlyParsingASymbol)
	{
		[_currentSymbolElements addObject:@{[elementName lowercaseString] : attributeDict}];
	}
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if(_currentlyParsingASymbol && ([elementName isEqualToString:@"symbol"]))
	{
		[self addCurrentElementsToCurrentSymbol];
		[_currentSymbolElements removeAllObjects];
		_currentlyParsingASymbol = NO;
	}
}

- (void) parserDidEndDocument:(NSXMLParser *)parser
{
	[self resolveLinkedSymbolPaths];
	
	for(NSDictionary *data in _parsedSymbolInstances)
	{
		[self addInstanceOfSymbol:data];
	}
}

- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	if(DEBUG){
		
		NSLog(@"XMLParser ParseError: %@", [parseError localizedDescription]);
	}
}

- (void) parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
	
	if(DEBUG){
		
		NSLog(@"XMLParser Validation Error: %@", [validationError localizedDescription]);
	}
}


#pragma mark -
#pragma mark Utilities

- (CGRect) rectFromViewBoxString:(NSString *) viewBox
{
	NSArray *pieces = [viewBox componentsSeparatedByString:@" "];
	return CGRectMake([pieces[0] floatValue], [pieces[1] floatValue], [pieces[2] floatValue], [pieces[3] floatValue]);
}

- (CGAffineTransform ) transformForSVGMatrix:(NSDictionary *) attributes
{
	NSString *transformString = [attributes[@"transform"] substringWithRange:NSMakeRange([kTransformKey length] + 1, [attributes[@"transform"] length] - [kTransformKey length] - 2)];
	NSArray *c = [transformString componentsSeparatedByString:@" "];
	
	CGAffineTransform transform = CGAffineTransformMake([c[0] floatValue], [c[1] floatValue], [c[2] floatValue], [c[3] floatValue], [c[4] floatValue], [c[5] floatValue]);
	
	return transform;
}

@end
