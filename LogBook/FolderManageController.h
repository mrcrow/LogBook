//
//  FolderManageController.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-10.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FolderViewController.h"

@protocol FolderManagerControllerDelegate;

@interface FolderManageController : UITableViewController <FolderViewControllerDelegate>

@property (strong, nonatomic) FolderViewController *folderController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, weak) id <FolderManagerControllerDelegate> delegate;

- (void)fetchRootContents;

@end

@protocol FolderManagerControllerDelegate

- (void)folderManagerController:(FolderManageController *)controller openFile:(File *)file;

@end