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
#import <QuickSVG/QuickSVGElement.h>
#import <QuickSVG/QuickSVGUtils.h>
#import <QuickSVG/QuickSVGParser.h>

@interface DetailViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) QuickSVG *quickSVG;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *holderView;
@property (nonatomic, strong) NSMutableArray *instanceFrames;
@property (nonatomic, strong) UIBezierPath *path;

- (void)configureView;

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(NSURL *)newDetailItem
{
	_detailItem = newDetailItem;
    self.path = [UIBezierPath bezierPath];
	
    [self configureView];
	
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    _holderView.layer.sublayers = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
         [_quickSVG parseSVGFileWithURL:_detailItem];
    });
    [_instanceFrames removeAllObjects];
}

- (void) quickSVG:(QuickSVG *)quickSVG didParseElement:(QuickSVGElement *)element
{
    assert([element.layer isKindOfClass:[CALayer class]]);
    dispatch_async(dispatch_get_main_queue(), ^{
        element.frame = CGRectMake(element.frame.origin.x - CGRectGetMinX(_quickSVG.canvasFrame), element.frame.origin.y - CGRectGetMinY(_quickSVG.canvasFrame), element.frame.size.width, element.frame.size.height);
        
        /*
         Uncomment the line below to asyncronously add all parsed views
         */
        //[_holderView addSubview:element];
    });
}

- (void) quickSVGDidParse:(QuickSVG *)quickSVG
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _holderView.frame = CGRectMake(0, 0, CGRectGetWidth(_quickSVG.canvasFrame), CGRectGetHeight(_quickSVG.canvasFrame));
        _scrollView.contentSize = _holderView.frame.size;
        _scrollView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        
        /*
         Comment the line below to add all parsed views at once
         */
        [_holderView addSubview:quickSVG.view];
    });
}

- (void)quickSVGDidAbort:(QuickSVG *)quickSVG
{
    _holderView.layer.sublayers = nil;
}

- (void) resize
{
    for(QuickSVGElement *instance in _quickSVG.parser.instances) {
        
        instance.frame = CGRectMake(instance.frame.origin.x, instance.frame.origin.y, instance.frame.size.width + 20, instance.frame.size.height + 20);
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.instanceFrames = [NSMutableArray array];
	self.view.backgroundColor = [UIColor whiteColor];
	self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    _scrollView.backgroundColor = [UIColor whiteColor];

    self.holderView = [[UIView alloc] initWithFrame:self.scrollView.frame];
    [_scrollView addSubview:_holderView];
    	
	_scrollView.minimumZoomScale = 0.5;
	_scrollView.maximumZoomScale = 3.0;
	_scrollView.bouncesZoom = YES;
	_scrollView.delegate = self;
    _holderView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    _holderView.layer.delegate = self;
	
	UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGesture:)];
	doubleTapGesture.numberOfTapsRequired = 2;
	[_scrollView addGestureRecognizer:doubleTapGesture];
	
	[self.view addSubview:_scrollView];
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 0, 200, 25)];
    slider.value = 1;
    [slider addTarget:self action:@selector(scaleSliderChanged:) forControlEvents:UIControlEventValueChanged];
    //[self.view addSubview:slider];
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"Save Image" style:UIBarButtonItemStyleBordered target:self action:@selector(saveImage)];
    self.navigationItem.rightBarButtonItem = save;
}

- (void)saveImage
{
    // Begin image context
    UIGraphicsBeginImageContextWithOptions(_holderView.bounds.size, YES, [UIScreen mainScreen].scale);
    [[UIColor whiteColor] set];
    CGContextFillRect(UIGraphicsGetCurrentContext(), _holderView.bounds);
    [_holderView.layer renderInContext:UIGraphicsGetCurrentContext()];
    CGImageRef screenshotRef = CGBitmapContextCreateImage(UIGraphicsGetCurrentContext());
    UIImage *screenshot = [[UIImage alloc] initWithCGImage:screenshotRef];
    
    // End image context
    UIGraphicsEndImageContext();
    // Release CGImage
    CGImageRelease(screenshotRef);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [[_detailItem lastPathComponent] stringByDeletingPathExtension]]];
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:UIImagePNGRepresentation(screenshot) attributes:nil];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return NULL;
}


- (void) scaleSliderChanged:(UISlider *) slider
{    
    float scale = slider.value;
    NSArray *array = [NSArray arrayWithArray:[_quickSVG.parser.instances allValues]];
    for(QuickSVGElement *instance in array) {
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        if(instance.attributes[@"transform"]) {
            transform = instance.svgTransform;
        }
        transform = CGAffineTransformScale(transform, scale, scale);
        instance.transform = transform;
    }
}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _holderView;
}

- (void) doubleTapGesture:(UITapGestureRecognizer *) gesture{
	
	CGPoint location = [gesture locationInView:_scrollView];
	
	if(_scrollView.zoomScale == _scrollView.maximumZoomScale){
		
		[_scrollView setZoomScale:1 animated:YES];
	}
	else{
		[_scrollView zoomToRect:CGRectMake(location.x, location.y, 0, 0) animated:YES];
	}
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
 //   _holderView.layer.shouldRasterize = NO;
}

- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    _holderView.layer.rasterizationScale = [UIScreen mainScreen].scale * scale;
   // _holderView.layer.shouldRasterize = YES;
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
        self.quickSVG.parserDelegate = self;
    }
    return self;
}

- (void) quickSVG:(QuickSVG *)quickSVG didSelectInstance:(QuickSVGElement *)instance
{
//    NSString *stroke = @"#4F99D3";
//	instance.attributes[@"stroke"] = [instance.attributes[@"stroke"] isEqualToString:stroke] ? @"" : stroke;
//	[instance setNeedsDisplay];
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
