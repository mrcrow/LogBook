//
//  MasterViewController.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-9.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FolderManageController.h"

@class DisplayViewController;

#import <CoreData/CoreData.h>

@interface MenuViewController : UITableViewController <NSFetchedResultsControllerDelegate, FolderManagerControllerDelegate>

@property (strong, nonatomic) DisplayViewController *displayViewController;
@property (strong, nonatomic) FolderManageController *manageController;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
