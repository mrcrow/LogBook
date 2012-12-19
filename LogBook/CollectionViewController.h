//
//  CollectionViewController.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-12.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "File.h"
#import "Collection.h"
#import "ContentViewController.h"
#import "PageViewController.h"

@protocol CollectionControllerDelegate;

@interface CollectionViewController : UITableViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) id <CollectionControllerDelegate> delegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)showFileCollections:(File *)file;

@end

@protocol CollectionControllerDelegate

- (void)collectionControllerDismissPopoverView;

@end
