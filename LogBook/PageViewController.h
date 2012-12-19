//
//  PageViewController.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-16.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "ContentViewController.h"
#import "File.h"
#import "Collection.h"

@interface PageViewController : UIViewController <UIPageViewControllerDataSource, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)manageCollections:(NSArray *)collections withHTMLData:(NSData *)data andPath:(NSString *)path;

@end
