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
#import "QuickSVGUtils.h"

#define DEBUG 1

@interface QuickSVG ()

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableArray *currentSymbolElements;
@property (nonatomic, assign) BOOL currentlyParsingASymbol;
@property (nonatomic, strong) NSMutableArray *parsedSymbolInstances;
@property (nonatomic, strong) NSMutableString *currentElementStringValue;
@property (nonatomic, assign) BOOL aborted;
@property (nonatomic, strong) NSDictionary *currentElement;
@property (nonatomic, strong) NSMutableArray *anonymousElements;
@property (nonatomic, strong) NSDate *profileStartDate;
@property (nonatomic, strong) NSDictionary *currentMasterAttributes;
@property (nonatomic, assign) BOOL currentlyParsingAGroup;
@property (nonatomic, assign) BOOL skipCurrentElement;

@end

@implementation QuickSVG

- (id) initWithDelegate:(id <QuickSVGDelegate>) delegate
{
	self = [super init];
	
	if(self) {
		self.delegate = delegate;
		self.symbols = [NSMutableDictionary dictionary];
		self.currentSymbolElements = [NSMutableArray array];
		self.parsedSymbolInstances = [NSMutableArray array];
        self.anonymousElements = [NSMutableArray array];
		self.instances = [NSMutableArray array];
		self.groups = [NSMutableArray array];
		self.currentElementStringValue = [[NSMutableString alloc] init];
		self.aborted = NO;
	}
	
	return self;
}

+ (QuickSVG *) svgFromURL:(NSURL *) url

{
	QuickSVG *svg = [[QuickSVG alloc] initWithDelegate:nil];
	[svg parseSVGFileWithURL:url];
	
	return svg;
}

- (BOOL)isParsing
{
	return self.xmlParser != nil;
}

- (void) abort
{	
	self.aborted = YES;
	[self.xmlParser abortParsing];
}

#pragma mark -
#pragma mark View

- (UIView *) view
{
	if(_view == nil) {
		_view = [[UIView alloc] initWithFrame:_canvasFrame];
	}
	else {
		[_view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	
	for(QuickSVGInstance *instance in self.instances) {
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
    [_currentSymbolElements removeAllObjects];
	[_parsedSymbolInstances removeAllObjects];
    [_anonymousElements removeAllObjects];
	_currentElementStringValue.string = @"";
	
    self.xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    
    [_xmlParser setDelegate:self];
    [_xmlParser setShouldResolveExternalEntities:NO];
	
    BOOL success = [_xmlParser parse];
	success = success && !self.aborted;
	
	[_xmlParser setDelegate:nil];
	self.xmlParser = nil;
	self.aborted = NO;
	
    if (success == NO)
        NSLog(@"*** XML Parsing Error");
    
    return success;
}

- (void) addCurrentElementsToCurrentSymbol
{
	if([_currentSymbolElements count] > 0) {
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
	
	if([[attributes allKeys] containsObject:@"viewBox"]) {
		symbol.frame = [self rectFromViewBoxString:attributes[@"viewBox"]];
	}
	
	[symbol.elements addObjectsFromArray:elements];
		
	return symbol;
}

- (void) findAndAddInstanceOfSymbol:(NSDictionary *) attributes
{
	__block NSString *symbolRef = [attributes[@"xlink:href"] substringFromIndex:1];
	
	[_symbols enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSComparisonResult result = [symbolRef caseInsensitiveCompare:key];
		
		if(result == NSOrderedSame) {
            [self addInstanceOfSymbol:obj attributes:attributes];
            *stop = YES;
		}
	}];
}

- (void) addInstanceOfSymbol:(QuickSVGSymbol *)symbol attributes:(NSDictionary *) attributes
{
    QuickSVGInstance *instance = [self instanceWithAttributes:attributes];
    [symbol.instances addObject:instance];
    instance.frame = symbol.frame;
    instance.elements = symbol.elements;
        
    if(attributes[@"transform"]) {
        instance.transform = makeTransformFromSVGMatrix(attributes[@"transform"]);
    }
    
    [_instances addObject:instance];
    
    if(_delegate != nil && [_delegate respondsToSelector:@selector(quickSVG:didParseInstance:)]) {
        [_delegate quickSVG:self didParseInstance:instance];
    }
}

- (QuickSVGInstance *) instanceWithAttributes:(NSDictionary *) attributes
{    
    NSMutableDictionary *allAttributes = [NSMutableDictionary dictionary];
    [allAttributes addEntriesFromDictionary:attributes];
    
    if(_currentlyParsingAGroup) {
        [allAttributes addEntriesFromDictionary:_currentMasterAttributes];
    }
    
    CGRect frame = CGRectMake([attributes[@"x"] floatValue], [attributes[@"y"] floatValue], [attributes[@"width"] floatValue], [attributes[@"height"] floatValue]);

	QuickSVGInstance *instance = [[QuickSVGInstance alloc] initWithFrame:frame];
	[instance.attributes addEntriesFromDictionary:allAttributes];
	instance.quickSVG = self;
   	
	return instance;
}

- (void) addCurrentAnonymousElement
{
    NSDictionary *attributes = _currentElement[[_currentElement allKeys][0]];
    
    QuickSVGSymbol *symbol = [self symbolWithAttributes:attributes andElements:@[_currentElement]];
    [self addInstanceOfSymbol:symbol attributes:attributes];
}

#pragma mark -
#pragma mark NSXMLParser Delegate

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    NSDictionary *elementData = @{[elementName lowercaseString] : attributeDict};
    
    self.skipCurrentElement = [attributeDict[@"display"] isEqualToString:@"none"];
    
	if([elementName isEqualToString:@"symbol"]) {
		_currentlyParsingASymbol = YES;
        self.currentMasterAttributes = attributeDict;
	}
	else if([elementName isEqualToString:@"svg"]) {
		self.canvasFrame = [self rectFromViewBoxString:attributeDict[@"viewBox"]];
        return;
	}
	else if([elementName isEqualToString:@"use"]) {
        [self findAndAddInstanceOfSymbol:attributeDict];
		[_parsedSymbolInstances addObject:attributeDict];
	}
    else if([elementName isEqualToString:@"g"]) {
        _currentlyParsingAGroup = YES;
        self.currentMasterAttributes = attributeDict;
    }
	
    if(_currentlyParsingASymbol) {
		[_currentSymbolElements addObject:elementData];
	} else {
       _currentElement = elementData;
    }
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if(_skipCurrentElement)
        return;
    
	if([elementName isEqualToString:@"text"]) {
		NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:_currentElement];
		data[elementName][@"text"] = [NSString stringWithString:_currentElementStringValue];
		_currentElement = data;
		[_currentElementStringValue setString:@""];
	}
    else if(_currentlyParsingAGroup && [elementName isEqualToString:@"g"]) {
        _currentlyParsingAGroup = NO;
    }
    
    if(_currentlyParsingASymbol && [elementName isEqualToString:@"symbol"]) {
		[self addCurrentElementsToCurrentSymbol];
		[_currentSymbolElements removeAllObjects];
		_currentlyParsingASymbol = NO;
	}
    else if(_currentElement != nil && ![elementName isEqualToString:@"use"]) {
        [self addCurrentAnonymousElement];
    }
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[self.currentElementStringValue appendString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (void) parserDidStartDocument:(NSXMLParser *)parser
{
	if(DEBUG)
		self.profileStartDate = [NSDate date];
	
	if(_delegate != nil && [_delegate respondsToSelector:@selector(quickSVGWillParse:)]) {
		[_delegate quickSVGWillParse:self];
	}
}

- (void) parserDidEndDocument:(NSXMLParser *)parser
{    
    self.canvasFrame = CGRectMake(fabs(_canvasFrame.origin.x), fabs(_canvasFrame.origin.y), _canvasFrame.size.width, _canvasFrame.size.height);
	
	if(!self.aborted && _delegate != nil && [_delegate respondsToSelector:@selector(quickSVGDidParse:)]) {
		[_delegate quickSVGDidParse:self];
	}
	
	if(DEBUG) {
		NSTimeInterval interval = [self.profileStartDate timeIntervalSinceNow];
		
		NSLog(@"----- QuickSVG parsed %i symbols, %i instances, %i objects in %f seconds", [_symbols count], [_instances count], [_anonymousElements count], fabs(interval));
	}
}

- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	// Note: this method is called when `abortParsing` is called.
	
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
