//
//  MasterViewController.h
//  QuickSVGRenderingTests
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

- (id)initWithDirectory:(NSString *)directory;

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
