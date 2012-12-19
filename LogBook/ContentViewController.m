//
//  ContentViewController.m
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-16.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import "ContentViewController.h"

@interface ContentViewController ()
@property (strong, nonatomic) NSData *html;
@property (strong, nonatomic) NSString *path;
@end

@implementation ContentViewController
@synthesize html = _html, path = _path, collect = _collect;
@synthesize webView = _webView;

@synthesize managedObjectContext = __managedObjectContext;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.webView loadData:_html MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:nil];
    _webView.scalesPageToFit = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [self setHtml:nil];
    [self setCollect:nil];
    [super viewDidUnload];
}

#pragma mark - Fill Contents

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setFormJSON('%@')", _collect.json]];
}

#pragma mark - Manage Content

- (void)manageCollection:(Collection *)collection withHTMLData:(NSData *)html andPath:(NSString *)path
{
    [self loadColletion:collection withHTMLData:html andPath:path];
    [self manageButtons];
}

- (void)loadColletion:(Collection *)colletion withHTMLData:(NSData *)html andPath:(NSString *)path
{
    _collect = colletion;
    _html = [NSData dataWithData:html];
    _path = path;
}

#pragma mark - Button Management

- (void)manageButtons
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewController)];
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendCollection)];
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

- (void)sendCollection
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
	
	[picker setSubject:[NSString stringWithFormat:@"Collected Data of %@", _collect.name]];
	
	// Set up recipients
	NSArray *toRecipients = [NSArray arrayWithObject:@"first@example.com"];
	NSArray *ccRecipients = [NSArray arrayWithObjects:@"second@example.com", nil];

	[picker setToRecipients:toRecipients];
	[picker setCcRecipients:ccRecipients];
	
	// Attach an image to the email
	[picker addAttachmentData:_collect.attachment mimeType:@"text/csv" fileName:_collect.name];
	
	// Fill out the email body text
	NSString *emailBody = [NSString stringWithFormat: @"%@'s collection data is included in the attachment", _collect.name];
	[picker setMessageBody:emailBody isHTML:NO];
	
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
    
    _collect.sent = [NSNumber numberWithBool:YES];
    
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
