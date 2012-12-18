//
//  DetailViewController.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-9.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FolderManageController.h"
#import "FolderViewController.h"
#import "CollectionViewController.h"
#import "File.h"

@interface DisplayViewController : UIViewController <UISplitViewControllerDelegate, UIWebViewDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate, CollectionControllerDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) CollectionViewController *collectionController;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)openFile:(File *)file;

@end
