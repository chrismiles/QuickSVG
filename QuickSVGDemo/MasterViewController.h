//
//  MasterViewController.h
//  QuickSVGDemo
//
//  Created by Matthew Newberry on 8/16/13.
//  Copyright (c) 2013 quickcue. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
