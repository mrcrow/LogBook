//
//  PageViewController.m
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-16.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import "PageViewController.h"

@interface PageViewController ()
@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) NSArray *pageContent;
@property (strong, nonatomic) NSData *html;
@property (strong, nonatomic) NSString *path;
@end

@implementation PageViewController
@synthesize pageContent = _pageContent, pageController = _pageController, html = _html, path = _path;

@synthesize managedObjectContext = __managedObjectContext;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSDictionary *options =
    [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:UIPageViewControllerSpineLocationMin]
                                forKey: UIPageViewControllerOptionSpineLocationKey];
    
    self.pageController = [[UIPageViewController alloc]
                           initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl
                           navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                           options: options];
    
    _pageController.dataSource = self;
    [[_pageController view] setFrame:[[self view] bounds]];
    
    ContentViewController *initialViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [_pageController setViewControllers:viewControllers
                             direction:UIPageViewControllerNavigationDirectionForward
                              animated:NO
                            completion:nil];
    
    [self addChildViewController:_pageController];
    [[self view] addSubview:[_pageController view]];
    [_pageController didMoveToParentViewController:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self setPageContent:nil];
    [self setPageController:nil];
    [self setHtml:nil];
    [self setPath:nil];
}

- (void)manageCollections:(NSArray *)collections withHTMLData:(NSData *)data andPath:(NSString *)path
{
    _pageContent = [NSArray arrayWithArray:collections];
    _html = [NSData dataWithData:data];
    _path = path;
    [self manageButtons];
}

#pragma mark - UIPageViewController Delegate

- (ContentViewController *)viewControllerAtIndex:(NSInteger)index
{
    // Return the data view controller for the given index.
    if (([self.pageContent count] == 0) || (index >= [self.pageContent count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    ContentViewController *dataViewController = [[ContentViewController alloc] initWithNibName:@"ContentViewController" bundle:nil];
    [dataViewController loadColletion:[self.pageContent objectAtIndex:index] withHTMLData:_html andPath:_path];
    return dataViewController;
}

- (NSUInteger)indexOfViewController:(ContentViewController *)viewController
{
    return [self.pageContent indexOfObject:viewController.collect];
}

- (UIViewController *)pageViewController:
(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(ContentViewController *)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageContent count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:
(UIPageViewController *)pageViewController viewControllerBeforeViewController:
(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(ContentViewController *)viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

#pragma mark - Buttons

- (void)manageButtons
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewController)];
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendAllCollections)];
    sendButton.tintColor = [UIColor redColor];
    
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    [self.navigationItem setRightBarButtonItem:cancelButton];
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self setToolbarItems:[NSArray arrayWithObjects:space, sendButton, space, nil]];
}


- (void)dismissModalViewController
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)sendAllCollections
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
    
    NSString *collectNames = [NSString string];
    NSString *fileName = [NSString string];
    NSInteger i = 0;
    
    for (Collection *collect in _pageContent)
    {
        i ++;
        if (i == 1)
        {
            fileName = collect.fromFile.name;
        }
        collectNames = [collectNames stringByAppendingString:[NSString stringWithFormat:@"%@, ", collect.name]];
        [picker addAttachmentData:collect.attachment mimeType:@"text/csv" fileName:collect.name];
    }
    
	[picker setSubject:[NSString stringWithFormat:@"Some colected data of %@", fileName]];
	
	// Set up recipients
	[picker setToRecipients:[NSArray arrayWithObject:TestEmail]];
	
	// Fill out the email body text
	NSString *emailBody = [NSString stringWithFormat: @"Email included the data of %@please check it.", collectNames];
	[picker setMessageBody:emailBody isHTML:YES];
	
	[self presentModalViewController:picker animated:YES];
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

#pragma mark - Mail Delegate Method

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
    
    for (Collection *collect in _pageContent)
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
