//
//  QuickSVG.m
//  QuickSVG
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVG.h"
#import "QuickSVGSymbol.h"
#import "QuickSVGInstance.h"

#define DEBUG 1

@interface QuickSVG ()

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableArray *currentSymbolElements;
@property (nonatomic, assign) BOOL currentlyParsingASymbol;
@property (nonatomic, strong) NSMutableArray *parsedSymbolInstances;
@property (nonatomic, strong) NSMutableString *currentElementStringValue;

@end

@implementation QuickSVG

- (id) initWithDelegate:(id <QuickSVGDelegate>) delegate
{
	self = [super init];
	
	if(self)
	{
		self.delegate = delegate;
		self.symbols = [[NSMutableDictionary alloc] init];
		self.currentSymbolElements = [[NSMutableArray alloc] init];
		self.parsedSymbolInstances = [[NSMutableArray alloc] init];
		self.instances = [[NSMutableArray alloc] init];
		self.groups = [[NSMutableArray alloc] init];
		self.currentElementStringValue = [[NSMutableString alloc] initWithCapacity:50];
	}
	
	return self;
}

+ (QuickSVG *) svgFromURL:(NSURL *) url

{
	QuickSVG *svg = [[QuickSVG alloc] init];
	[svg parseSVGFileWithURL:url];
	
	return svg;
}

#pragma mark -
#pragma mark View

- (UIView *) view
{
	if(_view == nil)
	{
		_view = [[UIView alloc] initWithFrame:_canvasFrame];
	}
	else
	{
		[_view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	
	for(QuickSVGInstance *instance in self.instances)
	{
		[_view addSubview:instance];
	}
	
	return _view;
}

#pragma mark -
#pragma mark Parsing

- (BOOL) parseSVGFileWithURL:(NSURL *) url
{
	if (url == nil)
        return NO;
	
	[_instances removeAllObjects];
	[_groups removeAllObjects];
	[_symbols removeAllObjects];
    
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
	
	if(_delegate != nil && [_delegate respondsToSelector:@selector(quickSVG:didParseInstance:)])
	{
		[_delegate quickSVG:self didParseInstance:instance];
	}
}

- (QuickSVGInstance *) instanceWithAttributes:(NSDictionary *) attributes
{
	CGRect frame = CGRectMake([attributes[@"x"] floatValue], [attributes[@"y"] floatValue], [attributes[@"width"] floatValue], [attributes[@"height"] floatValue]);

	QuickSVGInstance *instance = [[QuickSVGInstance alloc] initWithFrame:frame];
	[instance.attributes addEntriesFromDictionary:attributes];
	instance.quickSVG = self;
	
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
		NSLog(@"%@", attributeDict);
		[_parsedSymbolInstances addObject:attributeDict];
		NSLog(@"%@", _parsedSymbolInstances);
	}
		
	if(_currentlyParsingASymbol)
	{
		[_currentSymbolElements addObject:@{[elementName lowercaseString] : attributeDict}];
	}
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if(_currentlyParsingASymbol && [elementName isEqualToString:@"text"])
	{
		NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:[_currentSymbolElements lastObject][elementName]];
		data[@"text"] = [NSString stringWithString:_currentElementStringValue];
		[_currentSymbolElements replaceObjectAtIndex:[_currentSymbolElements count] - 1 withObject:@{[elementName lowercaseString] : data}];
		[_currentElementStringValue setString:@""];
	}
	
	if(_currentlyParsingASymbol && [elementName isEqualToString:@"symbol"])
	{
		[self addCurrentElementsToCurrentSymbol];
		[_currentSymbolElements removeAllObjects];
		_currentlyParsingASymbol = NO;
	}
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[self.currentElementStringValue appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (void) parserDidEndDocument:(NSXMLParser *)parser
{	
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

@end
