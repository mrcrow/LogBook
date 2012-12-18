//
//  ContentViewController.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-16.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "Collection.h"

@interface ContentViewController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) Collection *collet;

//load in PageViewController
- (void)loadColletion:(Collection *)colletion withHTMLData:(NSData *)html andPath:(NSString *)path;

//load in CollectionViewController
- (void)manageCollection:(Collection *)collection withHTMLData:(NSData *)html andPath:(NSString *)path;

@end
