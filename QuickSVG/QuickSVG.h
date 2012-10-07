//
//  QuickSVG.h
//  QuickSVG
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

@class QuickSVGInstance, QuickSVG;

@protocol QuickSVGDelegate <NSObject>

@optional
- (BOOL) quickSVG:(QuickSVG *) quickSVG shouldSelectInstance:(QuickSVGInstance *) instance;
- (void) quickSVG:(QuickSVG *) quickSVG didParseInstance:(QuickSVGInstance *)instance;

@required
- (void) quickSVG:(QuickSVG *) quickSVG didSelectInstance:(QuickSVGInstance *) instance;

@end

@interface QuickSVG : NSObject <NSXMLParserDelegate>

@property (nonatomic, strong) id <QuickSVGDelegate> delegate;
@property (nonatomic, strong) NSMutableDictionary *symbols;
@property (nonatomic, strong) NSMutableArray *instances;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) CGRect canvasFrame;

- (id) initWithDelegate:(id <QuickSVGDelegate>) delegate;
+ (QuickSVG *) svgFromURL:(NSURL *) url;
- (BOOL) parseSVGFileWithURL:(NSURL *) url;

@end
