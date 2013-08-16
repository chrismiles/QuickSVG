//
//  QuickSVGTests.m
//  QuickSVGTests
//
//  Created by Matthew Newberry on 8/16/13.
//  Copyright (c) 2013 quickcue. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface QuickSVGW3Tests : XCTestCase

@property (nonatomic, strong) NSArray *svgFiles;
@property (nonatomic, strong) NSArray *pngFiles;

@end

@implementation QuickSVGW3Tests

- (id)initWithInvocation:(NSInvocation *)anInvocation
{
    self = [super initWithInvocation:anInvocation];
    if (self) {
        
        [self loadResources];
    }
    
    return self;
}

- (void)loadResources
{
    self.svgFiles = [[NSBundle bundleForClass:[self class]] pathsForResourcesOfType:@"" inDirectory:@"Resources/w3/svg"];
    self.pngFiles = [[NSBundle bundleForClass:[self class]] pathsForResourcesOfType:@"" inDirectory:@"Resources/w3/png"];
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSArray *)svgResourcesOfPrefix:(NSString *)prefix
{
    return [self resourcesOfType:@"svg" withPrefix:prefix];
}

- (NSArray *)pngResourcesOfPrefix:(NSString *)prefix
{
    return [self resourcesOfType:@"png" withPrefix:prefix];
}

- (NSArray *)resourcesOfType:(NSString *)type withPrefix:(NSString *)prefix
{
    NSArray *files = [type isEqualToString:@"svg"] ? self.svgFiles : self.pngFiles;
    
    NSIndexSet *indexes = [files indexesOfObjectsPassingTest:^BOOL(NSString *path, NSUInteger idx, BOOL *stop) {
        return [path rangeOfString:[NSString stringWithFormat:@"%@-", prefix]].location != NSNotFound;
    }];
    return [files objectsAtIndexes:indexes];
}



- (void)testLoadingResources
{
    XCTAssertTrue([self.svgFiles count] > 0, @"Failed to load W3 SVG files");
    XCTAssertTrue([self.pngFiles count] > 0, @"Failed to load W3 PNG files");

}

- (void)testPaths
{
    NSArray *svgs = [self svgResourcesOfPrefix:@"paths"];
    NSArray *pngs = [self pngResourcesOfPrefix:@"paths"];
    
    XCTAssertEqual([svgs count], [pngs count], @"Unequal svgs and pngs files");
}

@end
