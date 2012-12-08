//
//  DetailViewController.m
//  QuickSVGRenderingTests
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "DetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <QuickSVG/QuickSVG.h>
#import <QuickSVG/QuickSVGInstance.h>

@interface DetailViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) QuickSVG *quickSVG;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *holderView;

- (void)configureView;

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(NSURL *)newDetailItem
{
	_detailItem = newDetailItem;
	
    [self configureView];
	
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    [_quickSVG parseSVGFileWithURL:_detailItem];
}

- (void) quickSVGDidParse:(QuickSVG *)quickSVG
{
    [_holderView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for(QuickSVGInstance *instance in _quickSVG.instances)
    {
        [_holderView addSubview:instance];
    }

    _holderView.frame = _quickSVG.canvasFrame;
    _scrollView.contentSize = _holderView.frame.size;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.view.backgroundColor = [UIColor whiteColor];
	self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    _scrollView.backgroundColor = [UIColor whiteColor];

    self.holderView = [[UIView alloc] initWithFrame:self.scrollView.frame];
    [_scrollView addSubview:_holderView];
	
	_scrollView.minimumZoomScale = 1.0;
	_scrollView.maximumZoomScale = 3.0;
	_scrollView.bouncesZoom = YES;
	_scrollView.delegate = self;
	
	UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
	doubleTapGesture.numberOfTapsRequired = 2;
	[_scrollView addGestureRecognizer:doubleTapGesture];
	
	[self.view addSubview:_scrollView];
}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _holderView;
}

- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale{
	
	for (QuickSVGInstance *view in _quickSVG.instances){
		
		view.contentScaleFactor = scale;
	}
}

- (void) doubleTapGesture:(UITapGestureRecognizer *) gesture{
	
	CGPoint location = [gesture locationInView:self.view];
	
	if(_scrollView.zoomScale == _scrollView.maximumZoomScale){
		
		[_scrollView setZoomScale:1 animated:YES];
	}
	else{
		
		[_scrollView zoomToRect:CGRectMake(location.x, location.y, 0, 0) animated:YES];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Detail", @"Detail");
		self.quickSVG = [[QuickSVG alloc] initWithDelegate:self];
    }
    return self;
}

- (void) quickSVG:(QuickSVG *)quickSVG didSelectInstance:(QuickSVGInstance *)instance
{
	//instance.attributes[@"fill"] = @"#4F99D3";
	//[instance setNeedsDisplay];
}
							
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
