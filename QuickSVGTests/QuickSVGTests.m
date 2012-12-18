//
//  QuickSVGTests.m
//  QuickSVGTests
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "QuickSVGTests.h"
#import "QuickSVG.h"

@interface QuickSVGTests ()

@property (nonatomic, strong) QuickSVG *quickSVG;

@end

@implementation QuickSVGTests

- (void)setUp
{
    [super setUp];
    
	self.quickSVG = [[QuickSVG alloc] init];
}

- (void)tearDown
{
    self.quickSVG = nil;
    
    [super tearDown];
}

- (void) testParsingSVGFiles
{
	NSArray *svgFiles = [[NSBundle bundleForClass:[self class]] pathsForResourcesOfType:@"svg" inDirectory:@"Sample SVGs"];
	
	for(NSString *filePath in svgFiles) {
		NSURL *fileURL = [NSURL fileURLWithPath:svgFiles[0]];
		STAssertTrue([_quickSVG parseSVGFileWithURL:fileURL], @"Failed To Parse SVG File: %@", @"");
	}
}

- (void) testAddingRects
{
	STAssertTrue(NO, @"Failed to added rects");
}

- (void) testAddingCircles
{
	STAssertTrue(NO, @"Failed to added circles");
}

- (void) testAddingEllipses
{
	STAssertTrue(NO, @"Failed to added ellipses");
}

- (void) testSymbolLinkageWithUse
{
	
}

@end
