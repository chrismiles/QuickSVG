//
//  MasterViewController.m
//  QuickSVGRenderingTests
//
//  Created by Matthew Newberry on 9/26/12.
//  Copyright (c) 2012 Matthew Newberry. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

@interface MasterViewController () {
    NSMutableArray *_objects;
    NSString *_directory;
}
@end

@implementation MasterViewController

- (id)initWithDirectory:(NSString *)directory
{
    self = [super initWithStyle:UITableViewStylePlain];
    if(self) {
        _directory = directory;
        
        self.title = NSLocalizedString(@"Master", @"Master");
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		    self.clearsSelectionOnViewWillAppear = NO;
		    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
		}
    }
    
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.tableView.delegate = self;
	
	_objects = [[NSMutableArray alloc] init];
	
	for(NSString *path in [[NSBundle mainBundle] pathsForResourcesOfType:@"" inDirectory:_directory]) {
		NSURL *url = [NSURL fileURLWithPath:path];
		[_objects addObject:url];
	}
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
    if(_objects.count > 0) {
        NSURL *firstObject = _objects[0];
        
        if(![self isDirectory:firstObject])
            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _objects.count == 0 ? 0 : _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }


	NSURL *url = _objects[indexPath.row];
    cell.accessoryType = [self isDirectory:url] ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
	cell.textLabel.text = [url lastPathComponent];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (BOOL)isDirectory:(NSURL *)url
{
    NSError *error;
    NSDictionary *attribs = [[NSFileManager defaultManager] attributesOfItemAtPath:url.filePathURL.path error:&error];
    
    BOOL isDir = NO;
    
    if(!error) {
        isDir = [attribs[NSFileType] isEqualToString:NSFileTypeDirectory];
    }   
    
    return isDir;
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *object = _objects[indexPath.row];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    if (!self.detailViewController) {
	        self.detailViewController = [[DetailViewController alloc] initWithNibName:nil bundle:nil];
	    }
	    self.detailViewController.detailItem = object;
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    } else {
        
        if([self isDirectory:object]) {
            MasterViewController *vc = [[MasterViewController alloc] initWithDirectory:[NSString stringWithFormat:@"%@/%@", _directory, [object lastPathComponent]]];
            vc.detailViewController = self.detailViewController;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            self.detailViewController.detailItem = object;
        }
    }
    
    if([self isDirectory:object])
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
