//
//  DetailViewController.h
//  QuickSVGDemo
//
//  Created by Matthew Newberry on 8/16/13.
//  Copyright (c) 2013 quickcue. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
