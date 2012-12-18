//
//  FolderViewController.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-10.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Folder.h"
#import "File.h"

@protocol FolderViewControllerDelegate;

@interface FolderViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) FolderViewController *subFolderController;

@property (nonatomic, weak) id <FolderViewControllerDelegate> delegate;

- (void)manageFolder:(Folder *)folder withJSON:(NSDictionary *)json online:(BOOL)online;

@end

@protocol FolderViewControllerDelegate

- (void)folderViewController:(FolderViewController *)controller openFile:(File *)file;

@end