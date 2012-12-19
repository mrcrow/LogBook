//
//  DetailViewController.m
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-9.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import "DisplayViewController.h"
#import "File.h"

@interface DisplayViewController ()
@property (strong, nonatomic) File *openFile;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) UIPopoverController *collectionPopController;
- (void)configureView;
@end

@implementation DisplayViewController
@synthesize openFile = _openFile;
@synthesize webView = _webView;
@synthesize masterPopoverController = _masterPopoverController;
@synthesize collectionPopController = _collectionPopController;

@synthesize collectionController = _collectionController;
@synthesize managedObjectContext = __managedObjectContext;

#pragma mark - Managing WebView

- (void)openFile:(File *)file
{
    _openFile = file;
    [self configureView];
    if (self.collectionPopController)
    {
        [self dismissCollectionPopoverView];
    }
}

- (void)dismissCollectionPopoverView
{
    [_collectionPopController dismissPopoverAnimated:YES];
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)configureView
{
    if (self.masterPopoverController)
    {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
    
    if (_openFile)
    {
        self.title = _openFile.name;
        NSLog(@"%@", _openFile.html);
        [_webView loadData:_openFile.html MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:[NSURL URLWithString:_openFile.path]];
        [self addComfirmAndCollectionButton];
    }
}

- (void)addComfirmAndCollectionButton
{
    if (!self.navigationItem.rightBarButtonItem)
    {
        UIBarButtonItem *collectionButton = [[UIBarButtonItem alloc] initWithTitle:@"Collections" style:UIBarButtonItemStylePlain target:self action:@selector(showCollections:)];
        [self.navigationItem setRightBarButtonItem:collectionButton animated:YES];
    }
    
    if (!self.toolbarItems)
    {
        UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithTitle:@"Confirm" style:UIBarButtonItemStyleDone target:self action:@selector(getFormData)];
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        
        [self setToolbarItems:[NSArray arrayWithObjects:space, confirmButton, space, nil]];
    }

    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)removeConfirmAndViewButton
{
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

#pragma mark - Check Input and Add Collection
#warning here
- (void)getFormData
{    
    NSString *value = [_webView stringByEvaluatingJavaScriptFromString:@"getFormJSON()"];
    
    //[_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"alert('%@')", value]];
    //[_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"resetdata('regform')"]];
    
    //[_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setFormJSON('%@')", value]];
    
    //NSLog(@"%@", value);
    
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];

    NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:NULL];
    
    NSLog(@"data :%@", results);
    
    BOOL isStandard = [self checkUserInput:results];
    
    if (isStandard)
    {
        [_openFile addCollectionsObject:[self collectionWithDictionary:value]];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:[results objectForKey:@"msg"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (BOOL)checkUserInput:(NSDictionary *)info
{
    if ([[info objectForKey:@"result"] integerValue] == 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (Collection *)collectionWithDictionary:(NSString *)json
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Collection" inManagedObjectContext:context];
    Collection *collect = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    collect.time = [NSDate date];
    collect.name = [NSString stringWithFormat:@"Collection %d", [[_openFile.collections allObjects] count] + 1];
    collect.data = json;
    collect.fromFile = _openFile;
    
    NSError *error = nil;
    if (![context save:&error])
    {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return collect;
}

#pragma mark - Show Collections

#define ContentWidth 320.0
#define ContentHeight 515.0

- (void)showCollections:(id)sender
{
    if (!self.collectionController)
    {
        self.collectionController = [[CollectionViewController alloc] initWithNibName:@"CollectionViewController" bundle:nil];
        _collectionController.delegate = self;
    }
    
    [_collectionController showFileCollections:_openFile];
    UINavigationController *controllerNavigator = [[UINavigationController alloc] initWithRootViewController:_collectionController];
    [controllerNavigator setToolbarHidden:NO];
    UIPopoverController *pop = [[UIPopoverController alloc] initWithContentViewController:controllerNavigator];
    pop.popoverContentSize = CGSizeMake(ContentWidth, ContentHeight);
    self.collectionPopController = pop;
    self.collectionPopController.delegate = self;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.collectionPopController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - UIPopoverViewController Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == self.collectionPopController)
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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
        self.title = NSLocalizedString(@"Form", @"Form");
    }
    return self;
}
							
#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Menu", @"Menu");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [self setOpenFile:nil];
    [self setManagedObjectContext:nil];
    [self setCollectionController:nil];
    [self setCollectionPopController:nil];
    [self setMasterPopoverController:nil];
    [super viewDidUnload];
}

#pragma mark - Delegate

- (void)collectionControllerDismissPopoverView
{
    [self dismissCollectionPopoverView];
}

@end
