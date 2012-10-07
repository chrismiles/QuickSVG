//
//  DetailViewController.h
//  QuickSVGRenderingTests
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickSVG/QuickSVG.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate, UIScrollViewDelegate, QuickSVGDelegate>

@property (strong, nonatomic) NSURL *detailItem;

@end
