//
//  MasterViewController.m
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-9.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import "MenuViewController.h"
#import "DisplayViewController.h"
#import "FolderManageController.h"

@interface MenuViewController ()

@property (nonatomic, strong) NSDictionary *JSON;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation MenuViewController
@synthesize displayViewController = _displayViewController;
@synthesize manageController = _manageController;
@synthesize managedObjectContext = __managedObjectContext;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Menu", @"Menu");
        self.clearsSelectionOnViewWillAppear = YES;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    // 
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
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 58.0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = [NSString stringWithFormat:@"File Manager"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.manageController)
    {
        self.manageController = [[FolderManageController alloc] initWithStyle:UITableViewStylePlain];
        _manageController.managedObjectContext = self.managedObjectContext;
        _manageController.delegate = self;
    }
    [_manageController fetchRootContents];
    [self.navigationController pushViewController:_manageController animated:YES];
}

#pragma mark - Open File Delegate Methods

- (void)folderManagerController:(FolderManageController *)controller openFile:(File *)file
{
    [_displayViewController openFile:file];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

@end
