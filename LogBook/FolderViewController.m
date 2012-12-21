//
//  FolderViewController.m
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-10.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import "FolderViewController.h"

@interface FolderViewController ()
@property (strong, nonatomic) NSArray *JSON;
@property (strong, nonatomic) Folder *container;
@property (strong, nonatomic) NSMutableArray *folders;
@property (strong, nonatomic) NSMutableArray *files;
@property BOOL isOnline;
@end

@implementation FolderViewController
@synthesize managedObjectContext = __managedObjectContext;
@synthesize subFolderController = _subFolderController;

@synthesize JSON = _JSON, container = _container, files = _files, folders = _folders, isOnline = _isOnline, delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self setContainer:nil];
    [self setFolders:nil];
    [self setFiles:nil];
    [self setJSON:nil];
    [self setSubFolderController:nil];
    [self setManagedObjectContext:nil];
    [self setDelegate:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Folder Content

- (void)manageFolder:(Folder *)folder withJSON:(NSDictionary *)json online:(BOOL)online
{
    _container = folder;
    _JSON = [NSArray arrayWithArray:[json objectForKey:@"Child"]];
    [self manageContent];
    _isOnline = online;
    self.title = _container.name;
}

#pragma mark - Content Management

- (void)manageContent
{
    [self emptyContainers];
    
    NSInteger sum = [[_container.subFolders allObjects] count] + [[_container.subFiles allObjects] count];

    //check root folder is empty
    if (sum != 0)
    {
        [self loadFilesAndFolders];
    }
    else
    {
        [self createContentsFromJSON];
    }
}

- (void)emptyContainers
{
    if (!self.files)
    {
        _files = [NSMutableArray array];
    }
    else
    {
        [_files removeAllObjects];
    }
    
    if (!self.folders)
    {
        _folders = [NSMutableArray array];
    }
    else
    {
        [_folders removeAllObjects];
    }
}

- (void)loadFilesAndFolders
{
    [_files addObjectsFromArray:[_container.subFiles allObjects]];
    [_folders addObjectsFromArray:[_container.subFolders allObjects]];
    
    [self sortFiles];
    [self sortFolders];
    
    [self.tableView reloadData];
    
    if ([self checkServerConnection])
    {
        [self resetExistenceAndVersion];
        [self updateExistenceAndVersion];
        [self checkForUpdates];
    }
}

- (void)sortFolders
{
    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *array = [_folders sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    [_folders removeAllObjects];
    [_folders addObjectsFromArray:array];
}

- (void)sortFiles
{
    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"modifiedDate" ascending:NO];
    NSArray *array = [_files sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    
    //NSLog(@"%@", array);
    
    [_files removeAllObjects];
    [_files addObjectsFromArray:array];
}

- (BOOL)checkServerConnection
{
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[ServerRequest stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    if (!data)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

#pragma mark - Check For Updates

- (void)resetExistenceAndVersion
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    for (File *file in _files)
    {
        file.isExistInServer = [NSNumber numberWithBool:NO];
        file.isLastVersion = [NSNumber numberWithBool:NO];
    }
    
    for (Folder *folder in _folders)
    {
        folder.isExistInServer = [NSNumber numberWithBool:NO];
    }
    
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)updateExistenceAndVersion
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    for (NSDictionary *object in _JSON)
    {
        NSString *type = [object objectForKey:@"Type"];
        NSString *name = [object objectForKey:@"Name"];
        
        if ([type isEqualToString:@"form"])
        {
            NSString *modifiedDate = [object objectForKey:@"Date"];
            NSLog(@"string date :%@", modifiedDate);
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
            NSDate *serverModifiedDate = [formatter dateFromString:modifiedDate];
            
            NSLog(@"nsdate :%@", serverModifiedDate);
            
            for (File *file in _files)
            {
                if ([file.name isEqualToString:name])
                {
                    file.isExistInServer = [NSNumber numberWithBool:YES];
                    
                    NSLog(@"%@, %@", file.modifiedDate, serverModifiedDate);
                    
                    #warning for testing
                    //if ([file.modifiedDate compare:serverModifiedDate] != NSOrderedAscending)
                    //{
                    //    file.isLastVersion = [NSNumber numberWithBool:YES];
                    //}
                }
            }
        }
        else
        {
            for (Folder *folder in _folders)
            {
                if ([folder.name isEqualToString:name])
                {
                    folder.isExistInServer = [NSNumber numberWithBool:YES];
                }
            }
        }
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

- (void)checkForUpdates
{
    BOOL fileHasUpdate = NO;
    for (File *file in _files)
    {
        if ([file.isExistInServer boolValue] == NO || [file.isLastVersion boolValue] == NO)
        {
            NSLog(@"%d, %d", [file.isExistInServer boolValue], [file.isLastVersion boolValue]);
            fileHasUpdate = YES;
            break;
        }
    }
    
    BOOL folderHasUpdate = NO;
    for (Folder *folder in _folders)
    {
        if ([folder.isExistInServer boolValue] == NO)
        {
            NSLog(@"%d", [folder.isExistInServer boolValue]);
            folderHasUpdate = YES;
            break;
        }
    }
    
    BOOL numberHasUpdate = NO;
    if ([_JSON count] != [_files count] + [_folders count])
    {
        numberHasUpdate = YES;
    }
    
    if (fileHasUpdate || folderHasUpdate || numberHasUpdate)
    {
        [self enableUpdateButton];
    }
}

#pragma mark - Update Button

- (void)enableUpdateButton
{
    UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(updateContent)];
    [self.navigationItem setRightBarButtonItem:updateButton animated:YES];
}

- (void)updateContent
{
    [self deleteUnexistFilesOrFolders];
    [self updateFiles];
    [self addUpdatedFilesOrFolders];
    
    [self sortFolders];
    [self sortFiles];
    
    [self.tableView reloadData];
    
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
}

- (void)updateFiles
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    for (File *file in _files)
    {
        if (![file.isLastVersion boolValue])
        {
            for (NSDictionary *object in _JSON)
            {
                NSString *type = [object objectForKey:@"Type"];
                NSString *name = [object objectForKey:@"Name"];
                
                if ([type isEqualToString:@"form"] && [file.name isEqualToString:name])
                {
                    NSString *urlString = [NSString stringWithFormat:@"%@/%@.html", _container.path, file.name];
                    NSURL *url = [NSURL URLWithString:urlString];
                    //NSLog(@"%@", urlString);
                    
                    NSData *htmlData = [NSData dataWithContentsOfURL:url];
                    
                    if (htmlData)
                    {
                        
                        NSString *modifiedDate = [object objectForKey:@"Date"];
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
                        NSDate *serverModifiedDate = [formatter dateFromString:modifiedDate];
                        
                        file.html = htmlData;
                        file.modifiedDate = serverModifiedDate;
                    }
                    else
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to update the file from server" message:@"Please check the status of WiFi connection and make sure you have connect to the internet" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                        
                        break;
                    }
                }
            }
        }
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

- (void)deleteUnexistFilesOrFolders
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    for (File *file in _files)
    {
        if (![file.isExistInServer boolValue])
        {
            [context deleteObject:file];
            [_files removeObject:file];
        }
    }
    
    for (Folder *folder in _folders)
    {
        if (![folder.isExistInServer boolValue])
        {
            [context deleteObject:folder];
            [_folders removeObject:folder];
        }
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

- (void)addUpdatedFilesOrFolders
{
    for (NSDictionary *object in _JSON)
    {
        NSString *type = [object objectForKey:@"Type"];
        NSString *name = [object objectForKey:@"Name"];
        
        if ([type isEqualToString:@"form"])
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
            NSArray *result = [_files filteredArrayUsingPredicate:predicate];
            if ([result count] == 0)
            {
                File *file = [self fileWithDictionary:object];
                if (file)
                {
                    [_files addObject:file];
                    [_container addSubFilesObject:file];
                }
                else
                {
                    break;
                }
            }
        }
        else
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
            NSArray *result = [_folders filteredArrayUsingPredicate:predicate];
            if ([result count] == 0)
            {
                Folder *folder = [self folderWithDictionary:object];
                [_folders addObject:folder];
                [_container addSubFoldersObject:folder];
            }
            
        }
    }
}

#pragma mark - JSON to Folder and File

- (void)createContentsFromJSON
{
    for (NSDictionary *object in _JSON)
    {
        NSString *type = [object objectForKey:@"Type"];
        
        if ([type isEqualToString:@"folder"])
        {
            Folder *folder = [self folderWithDictionary:object];
            [_folders addObject:folder];
            [_container addSubFoldersObject:folder];
        }
        else
        {
            File *file = [self fileWithDictionary:object];
            if (file)
            {
                [_files addObject:file];
                [_container addSubFilesObject:file];
            }
            else
            {
                break;
            }
        }
    }
    
    [self.tableView reloadData];
}

- (File *)fileWithDictionary:(NSDictionary *)dict
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    //download file to direction
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.html", _container.path, [dict objectForKey:@"Name"]]];
    NSData *htmlData = [NSData dataWithContentsOfURL:url];
    
    if (htmlData)
    {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"File" inManagedObjectContext:context];
        File *file = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
        
        //get last modified date
        NSString *modifiedDate = [dict objectForKey:@"Date"];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        NSDate *serverModifiedDate = [formatter dateFromString:modifiedDate];
        
        file.fromFolder = _container;
        file.fatherPath = _container.path;
        file.name = [dict objectForKey:@"Name"];
        file.path = [NSString stringWithFormat:@"%@/%@.html", file.fatherPath, file.name];
        //NSLog(@"file path:%@", file.path);
        
        file.isExistInServer = [NSNumber numberWithBool:YES];
        file.isLastVersion = [NSNumber numberWithBool:YES];
        
        file.html = htmlData;
        file.modifiedDate = serverModifiedDate;
        file.collectionNo = [NSNumber numberWithInt:0];
        
        NSError *error = nil;
        if (![context save:&error])
        {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        return file;
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to download the file from server" message:@"Please check the status of WiFi connection and make sure you have connect to the internet" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        return nil;
    }
}

- (Folder *)folderWithDictionary:(NSDictionary *)dict
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Folder" inManagedObjectContext:context];
    Folder *folder = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    folder.fromFolder = _container;
    folder.fatherPath = _container.path;
    folder.name = [dict objectForKey:@"Name"];
    folder.path = [NSString stringWithFormat:@"%@/%@", folder.fatherPath, folder.name];
    folder.isExistInServer = [NSNumber numberWithBool:YES];
    
    NSError *error = nil;
    if (![context save:&error])
    {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return folder;
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0: return [_folders count];
        default: return [_files count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0: return [self cellForFolderAtIndex:indexPath.row];
        default: return [self cellForFileAtIndex:indexPath.row];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 58.0;
}

- (UITableViewCell *)cellForFolderAtIndex:(NSInteger)index
{
    static NSString *cellIdentifier = @"FolderCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    if ([_folders count] != 0)
    {
        Folder *folder = [_folders objectAtIndex:index];
        
        cell.textLabel.text = folder.name;
        //cell.detailTextLabel.text = folder.path;
        cell.imageView.image = [UIImage imageNamed:@"folder"];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (UITableViewCell *)cellForFileAtIndex:(NSInteger)index
{
    static NSString *cellIdentifier = @"FileCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if ([_files count] != 0)
    {
        File *file = [_files objectAtIndex:index];
        
        cell.textLabel.text = file.name;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        cell.detailTextLabel.numberOfLines = 2;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"last modified on:\n%@", [formatter stringFromDate:file.modifiedDate]];
        
        cell.imageView.image = [UIImage imageNamed:@"file"];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            Folder *folder = [_folders objectAtIndex:indexPath.row];
            NSDictionary *data = nil;
            for (NSDictionary *object in _JSON)
            {
                NSString *name = [object objectForKey:@"Name"];
                NSString *type = [object objectForKey:@"Type"];
                
                if ([type isEqualToString:@"folder"] && [name isEqualToString:folder.name])
                {
                    data = object;
                    break;
                }
            }
            
            if (!self.subFolderController)
            {
                self.subFolderController = [[FolderViewController alloc] initWithStyle:UITableViewStylePlain];
            }
            _subFolderController.managedObjectContext = self.managedObjectContext;
            [_subFolderController manageFolder:folder withJSON:data online:_isOnline];
            _subFolderController.delegate = self.delegate;
            
            [self.navigationController pushViewController:_subFolderController animated:YES];
        } break;
            
        default: {
            File *file = [_files objectAtIndex:indexPath.row];
            [delegate folderViewController:self openFile:file];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        } break;
    }
}

@end
