//
//  HPFirstViewController.m
//  HonoursPrototype
//
//  Created by Andrew Bennett on 13/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HPFirstViewController.h"
#import "HPAppDelegate.h"
#import "MapViewController.h"
#import "RubberBand.h"

@implementation HPFirstViewController

@synthesize taskNames = _taskNames;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Task Selection", @"Task Selection");
		self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}
							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

-(void) runTaskWithName: (NSString*) name
{
	HPAppDelegate* appDelegate = (HPAppDelegate*)[[UIApplication sharedApplication] delegate];
	[[appDelegate tabBarController] setSelectedIndex: 1];
	[[appDelegate mapViewController] loadTaskNamed: name];
}

-(void) runNextTask
{
	self->_taskIndex = (self->_taskIndex+1) % [self->_taskNames count];
	[self runTaskWithName: [self->_taskNames objectAtIndex: self->_taskIndex]];
}

-(void) runTask: (id)sender
{
	[self updateBandOptions: nil];
	[self runTaskWithName: [self->_taskNames objectAtIndex: self->_taskIndex]];
}

-(IBAction) updateBandOptions: (id)sender
{
	RubberBandOptions options = 0;
	
	if ([self->option_thickness isOn])
		options |= kRubberBandOption_Thickness;
	if ([self->option_color isOn])
		options |= kRubberBandOption_Color;
	if ([self->option_tension isOn])
		options |= kRubberBandOption_Tension;
	
	HPAppDelegate* appDelegate = (HPAppDelegate*)[[UIApplication sharedApplication] delegate];
	[[appDelegate mapViewController] setBandOptions: options];
}


#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self->_taskNames count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
	NSString * taskName = nil;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
									   reuseIdentifier: CellIdentifier] autorelease];
    }
	
	// Configure the cell.
	taskName = [self->_taskNames objectAtIndex: [indexPath row]];
	cell.textLabel.text = NSLocalizedString(taskName, @"TaskName");
    return cell;
}


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString * taskName = nil;
    
	self->_taskIndex = [indexPath row];
	taskName = [self->_taskNames objectAtIndex: self->_taskIndex];

//	HPAppDelegate* appDelegate = (HPAppDelegate*)[[UIApplication sharedApplication] delegate];
//	[[appDelegate tabBarController] setSelectedIndex: 1];

//    if (!self.detailViewController)
//	{
//        self.detailViewController = [[[HPDetailViewController alloc] initWithNibName: @"HPDetailViewController"
//																			  bundle: nil] autorelease];
//    }
//	UISplitViewController * splitVC = self.splitViewController;
//	splitVC.modalPresentationStyle = UIModalPresentationFullScreen;
//	[splitVC presentModalViewController: [[splitVC viewControllers] objectAtIndex: 1]
//							   animated: NO];
	//    [self.navigationController pushViewController: self.detailViewController
	//										 animated: YES];
}

@end
