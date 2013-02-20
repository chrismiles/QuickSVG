//
//  DetailViewController.h
//  QuickSVGRenderingTests
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickSVG/QuickSVG.h>
#import "QuickSVGParser.h"

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, UIScrollViewDelegate, QuickSVGDelegate, QuickSVGParserDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSURL *detailItem;

@end
