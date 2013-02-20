//
//  QuickSVGParser.h
//  QuickSVG
//
//  Created by Matthew Newberry on 2/20/13.
//  Copyright (c) 2013 Matthew Newberry. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QuickSVG, QuickSVGElement;
@protocol QuickSVGParserDelegate <NSObject>

@optional
- (void)quickSVGWillParse:(QuickSVG *)quickSVG;
- (void)quickSVGDidParse:(QuickSVG *)quickSVG;
- (void)quickSVG:(QuickSVG *)quickSVG didParseElement:(QuickSVGElement *)element;
@end

@interface QuickSVGParser : NSObject

@property (nonatomic, strong) id <QuickSVGParserDelegate> delegate;
@property (nonatomic, strong) NSMutableDictionary *symbols;
@property (nonatomic, strong) NSMutableDictionary *instances;
@property (nonatomic, strong) NSMutableDictionary *groups;
@property (nonatomic, weak) QuickSVG *quickSVG;
@property (nonatomic) BOOL isParsing;

- (id)initWithQuickSVG:(QuickSVG *)quickSVG;
- (BOOL)parseSVGFileWithURL:(NSURL *) url;

- (void)abort;

@end
