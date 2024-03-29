//
//  CollectionViewController.m
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-12.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import "CollectionViewController.h"

@interface CollectionViewController ()
@property (strong, nonatomic) UIBarButtonItem *sendButton;
@property (strong, nonatomic) UIBarButtonItem *previewButton;
@property (strong, nonatomic) UIBarButtonItem *selectOrClearButton;

@property (strong, nonatomic) File *showFile;
@property (strong, nonatomic) NSMutableArray *collections;
@property (strong, nonatomic) NSMutableArray *sendCollections;
@end

@implementation CollectionViewController
@synthesize delegate;
@synthesize sendButton = _sendButton, previewButton = _previewButton, selectOrClearButton = _selectOrClearButton, showFile = _showFile, collections = _collections, sendCollections = _sendCollections;

@synthesize managedObjectContext = __managedObjectContext;

static NSString *previewTitle = @"Preview (%d)";
static NSString *previewTitleAll = @"Preview All";
static NSString *sendTitle = @"Send (%d)";
static NSString *sendTitleAll = @"Send All";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //test = [NSArray arrayWithObjects:@"collect 1", @"collect 2", @"collect 3", @"collect 4", nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resetButtonTitles];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table Content

- (void)showFileCollections:(File *)file
{
    _showFile = file;
    [self manageContent];
    [self.tableView reloadData];
    
}

- (void)emptyContainer
{
    if (!self.collections)
    {
        _collections = [NSMutableArray array];
    }
    else
    {
        [_collections removeAllObjects];
    }
}

- (void)manageContent
{
    [self emptyContainer];
    [_collections addObjectsFromArray:[_showFile.collections allObjects]];
    [self sortCollections];
}

- (void)sortCollections
{
    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES];
    NSArray *array = [_collections sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    [_collections removeAllObjects];
    [_collections addObjectsFromArray:array];
}

#pragma mark - Button Functions

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if ([_collections count] != 0)
    {
        if (editing)
        {
            [self addManageButtons];
        }
        else
        {
            [self removeManageButtons];
        }
        [self refreshButtonTitles];
    }
}

- (void)addManageButtons
{
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    if (!self.sendButton)
    {
        _sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send (0)" style:UIBarButtonItemStyleBordered target:self action:@selector(sendEmail:)];
        _sendButton.tintColor = [UIColor redColor];
        _sendButton.enabled = NO;
    }
    
    if (!self.previewButton)
    {
        _previewButton = [[UIBarButtonItem alloc] initWithTitle:@"Preview (0)" style:UIBarButtonItemStyleBordered target:self action:@selector(previewCollections:)];
        _previewButton.tintColor = [UIColor previewButtonColor];
        _previewButton.enabled = NO;
    }

    if (!self.selectOrClearButton)
    {
        _selectOrClearButton = [[UIBarButtonItem alloc] initWithTitle:@"Select All" style:UIBarButtonItemStyleDone target:self action:@selector(selectOrClearTable:)];
    }
    
    [self setToolbarItems:[NSArray arrayWithObjects:space, _previewButton, _sendButton, space, nil] animated:YES];
    [self.navigationItem setLeftBarButtonItem:_selectOrClearButton animated:YES];
}

- (void)removeManageButtons
{
    [self setToolbarItems:nil animated:YES];
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
}

- (void)sendEmail:(id)sender
{
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    
    if (mailClass != nil)
    {
        // We must always check whether the current device is configured for sending emails
        if ([mailClass canSendMail])
        {
            [self displayComposerSheet];
        }
    }
}

-(void)displayComposerSheet
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
    
    NSArray *selectArray = [self.tableView indexPathsForSelectedRows];
    NSString *collectNames = [NSString string];
    
    [self emptySendCollectionDraft];
    
    for (NSIndexPath *indexPath in selectArray)
    {
        Collection *collect = [_collections objectAtIndex:indexPath.row];
        [_sendCollections addObject:collect];
        collectNames = [collectNames stringByAppendingString:[NSString stringWithFormat:@"%@, ", collect.name]];
        [picker addAttachmentData:collect.attachment mimeType:@"text/csv" fileName:collect.name];
    }
    
	[picker setSubject:[NSString stringWithFormat:@"Some colected data of %@", _showFile.name]];
	
	// Set up recipients
	[picker setToRecipients:[NSArray arrayWithObject:TestEmail]];
	
	// Fill out the email body text
	NSString *emailBody = [NSString stringWithFormat: @"Email included the data of %@please check it.", collectNames];
	[picker setMessageBody:emailBody isHTML:YES];
	
	[self presentModalViewController:picker animated:YES];
    
    [self setEditing:NO animated:YES];
    [delegate collectionControllerDismissPopoverView];
}

- (void)emptySendCollectionDraft
{
    if (!self.sendCollections)
    {
        _sendCollections = [NSMutableArray array];
    }
    else
    {
        [_sendCollections removeAllObjects];
    }
}

/*
-(void)launchMailAppOnDevice
{
	NSString *recipients = @"mailto:first@example.com?cc=second@example.com&subject=Hello from California!";
	NSString *body = @"&body=It is raining in sunny California!";
	
	NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
	email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}*/

- (void)previewCollections:(id)sender
{
    NSArray *selectArray = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *selectCollections = [NSMutableArray array];
    
    for (NSIndexPath *indexPath in selectArray)
    {
        Collection *collect = [_collections objectAtIndex:indexPath.row];
        [selectCollections addObject:collect];
    }
    
    PageViewController *pageController = [[PageViewController alloc] initWithNibName:@"PageViewController" bundle:nil];
    pageController.managedObjectContext = self.managedObjectContext;
    [pageController manageCollections:selectCollections withHTMLData:_showFile.html andPath:_showFile.path];
    UINavigationController *pageNavController = [[UINavigationController alloc] initWithRootViewController:pageController];
    pageNavController.modalPresentationStyle = UIModalPresentationPageSheet;
    
    [self setEditing:NO animated:YES];
    [self.navigationController presentModalViewController:pageNavController animated:YES];
}

- (void)selectOrClearTable:(id)sender
{
    NSArray *selectArray = [self.tableView indexPathsForSelectedRows];
    if ([selectArray count] != [_collections count])
    {
        [self selectAllCells];
        [self refreshButtonTitles];
    }
    else
    {
        [self clearSelectedCells];
        [self refreshButtonTitles];
    }
}

- (void)selectAllCells
{
    for (int i = 0; i < [self.tableView numberOfSections]; i++)
    {
        for (int j = 0; j < [self.tableView numberOfRowsInSection:i]; j++)
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:j inSection:i];
            [self.tableView selectRowAtIndexPath:path animated:YES scrollPosition:UITableViewScrollPositionBottom];
        }
    }
}

- (void)clearSelectedCells
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    for (NSIndexPath *path in selectedRows)
    {
        [self.tableView deselectRowAtIndexPath:path animated:YES];
    }
}

- (void)resetButtonTitles
{
    _previewButton.enabled = NO;
    _previewButton.title = @"Preview (0)";
    
    _sendButton.enabled = NO;
    _sendButton.title = @"Send (0)";
    
    _selectOrClearButton.title = @"Select All";
}

- (void)refreshButtonTitles
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    //enablle or unable buttons
    if ([selectedRows count] != 0)
    {
        _previewButton.enabled = YES;
        _sendButton.enabled = YES;
    }
    else
    {
        _previewButton.enabled = NO;
        _sendButton.enabled = NO;
    }
    
    //manage button title
    if ([selectedRows count] != [self.collections count])
    {
        _previewButton.title = [NSString stringWithFormat:previewTitle, [selectedRows count]];
        _sendButton.title = [NSString stringWithFormat:sendTitle, [selectedRows count]];
        _selectOrClearButton.title = @"Select All";
    }
    else
    {
        _previewButton.title = previewTitleAll;
        _sendButton.title = sendTitleAll;
        _selectOrClearButton.title = @"Clear All";
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_collections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Collection *collect = [_collections objectAtIndex:indexPath.row];
    cell.textLabel.text = collect.name;
 
    if ([collect.sent boolValue])
    {
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    else
    {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    cell.detailTextLabel.text = [formatter stringFromDate:collect.time];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing)
    {
        [self refreshButtonTitles];
    }
    else
    {
        [delegate collectionControllerDismissPopoverView];
        
        ContentViewController *previewController = [[ContentViewController alloc] initWithNibName:@"ContentViewController" bundle:nil];
        previewController.managedObjectContext = self.managedObjectContext;
        
        Collection *collection = [_collections objectAtIndex:indexPath.row];
        [previewController manageCollection:collection withHTMLData:_showFile.html andPath:_showFile.path];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:previewController];
        
        navController.modalPresentationStyle = UIModalPresentationPageSheet;
        [self.navigationController presentModalViewController:navController animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing)
    {
        [self refreshButtonTitles];
    }
}

- (void)viewDidUnload {
    [self setDelegate:nil];
    [self setSendButton:nil];
    [self setPreviewButton:nil];
    [self setSelectOrClearButton:nil];
    [self setShowFile:nil];
    [super viewDidUnload];
}

#pragma mark - MFMailComposeDelegate Method

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (result == MFMailComposeResultSent)
    {
        [self checkSentCollections];
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)checkSentCollections
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    for (Collection *collect in _sendCollections)
    {
        collect.sent = [NSNumber numberWithBool:YES];
    }
    
    NSError *error = nil;
    if (![context save:&error])
    {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

@end
