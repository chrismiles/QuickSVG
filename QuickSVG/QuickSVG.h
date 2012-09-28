//
//  QuickSVG.h
//  QuickSVG
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVGSymbol.h"
#import "QuickSVGInstance.h"

@interface QuickSVG : NSObject <NSXMLParserDelegate>

@property (nonatomic, strong) NSURL *documentURL;
@property (nonatomic, strong) NSMutableDictionary *symbols;
@property (nonatomic, strong) NSMutableArray *instances;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) CGRect canvasFrame;

- (BOOL) parseSVGFileWithURL:(NSURL *) url;

@end
