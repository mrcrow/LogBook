//
//  FolderManageController.m
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-10.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import "FolderManageController.h"
#import "Folder.h"
#import "File.h"

@interface FolderManageController ()
@property (strong, nonatomic) NSArray *JSON;
@property (strong, nonatomic) NSMutableArray *files;
@property (strong, nonatomic) NSMutableArray *folders;
@property BOOL online;

@end

@implementation FolderManageController
@synthesize managedObjectContext = __managedObjectContext;

@synthesize folderController = _folderController;
@synthesize JSON = _JSON;
@synthesize files = _files, folders = _folders;
@synthesize online, delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"File Manager",  @"File Manager");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self setJSON:nil];
    [self setFiles:nil];
    [self setFolders:nil];
    [self setDelegate:nil];
    [self setManagedObjectContext:nil];
}

#pragma mark - Connection Check and JSON retrieving

- (void)checkServerConnection
{
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[ServerRequest stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    if (!data)
    {
        online = NO;
    }
    else
    {
        online = YES;
    }
}

- (void)fetchJSON
{
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[ServerRequest stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    NSError *error = nil;
    NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error];
    
    NSArray *rootContent = [results objectForKey:@"Child"];
    
    _JSON = [NSArray arrayWithArray:rootContent];
    
    NSLog(@"%@", _JSON);
}

#pragma mark - Load Data and Check Updates

- (void)fetchRootContents
{
    [self emptyContainers];
    
    NSArray *folderObjects = [self foldersInContent];
    NSArray *fileObjects = [self filesInContent];
    
    //check root folder is empty
    if ([folderObjects count] + [fileObjects count] != 0)
    {
        [self loadFiles:fileObjects andFolders:folderObjects];
    }
    else
    {
        [self downloadRootContentFromJSON];
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

- (NSArray *)foldersInContent
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *folderEntity = [NSEntityDescription
                                         entityForName:@"Folder" inManagedObjectContext:moc];
    NSFetchRequest *folderRequest = [[NSFetchRequest alloc] init];
    [folderRequest setEntity:folderEntity];
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fatherPath == %@", ServerRequest];
    [folderRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"name" ascending:YES];
    [folderRequest setSortDescriptors:@[sortDescriptor]];
    return [moc executeFetchRequest:folderRequest error:NULL];
}

- (NSArray *)filesInContent
{
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *folderEntity = [NSEntityDescription
                                         entityForName:@"File" inManagedObjectContext:moc];
    NSFetchRequest *folderRequest = [[NSFetchRequest alloc] init];
    [folderRequest setEntity:folderEntity];
    // Set example predicate and sort orderings...
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fatherPath == %@", ServerRequest];
    [folderRequest setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                        initWithKey:@"name" ascending:YES];
    [folderRequest setSortDescriptors:@[sortDescriptor]];

    return [moc executeFetchRequest:folderRequest error:NULL];
}

- (void)loadFiles:(NSArray *)fileObjects andFolders:(NSArray *)folderObjects
{
    [_files addObjectsFromArray:fileObjects];
    [_folders addObjectsFromArray:folderObjects];
    
    [self sortFiles];
    [self sortFolders];
    
    [self.tableView reloadData];
    
    [self checkServerConnection];
    
    if (online)
    {
        [self fetchJSON];
        [self resetExistenceAndVersion];
        [self updateExistenceAndVersion];
        [self checkForUpdates];
    }
    else
    {
        //alert view
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect to server" message:@"Please check your WiFi setting and the offline server is on" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)sortFolders
{
    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *array = [_folders sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortOrder]];
    [_folders removeAllObjects];
    [_folders addObjectsFromArray:array];
}

- (void)sortFiles
{
    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"modifiedDate" ascending:NO];
    NSArray *array = [_files sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortOrder]];
    [_files removeAllObjects];
    [_files addObjectsFromArray:array];
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
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
            NSDate *serverModifiedDate = [formatter dateFromString:modifiedDate];
            
            for (File *file in _files)
            {
                if ([file.name isEqualToString:name])
                {
                    file.isExistInServer = [NSNumber numberWithBool:YES];
                    if ([file.modifiedDate compare:serverModifiedDate] != NSOrderedAscending)
                    {
                        file.isLastVersion = [NSNumber numberWithBool:YES];
                    }
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
    if (![context save:&error]) {
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
                    NSString *urlString = [NSString stringWithFormat:@"%@/%@.html", ServerRequest, file.name];
                    NSURL *url = [NSURL URLWithString:urlString];
                    NSData *htmlData = [NSData dataWithContentsOfURL:url];
                    
                    NSString *modifiedDate = [object objectForKey:@"Date"];
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
                    NSDate *serverModifiedDate = [formatter dateFromString:modifiedDate];
                    
                    file.html = htmlData;
                    file.modifiedDate = serverModifiedDate;
                }
            }
        }
    }
    
    NSError *error = nil;
    if (![context save:&error]) {
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
    if (![context save:&error]) {
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
                [_files addObject:[self fileWithDictionary:object]];
            }
        }
        else
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
            NSArray *result = [_folders filteredArrayUsingPredicate:predicate];
            if ([result count] == 0)
            {
                [_folders addObject:[self folderWithDictionary:object]];
            }
        }
    }
}

#pragma mark - JSON to Folder and File

- (void)downloadRootContentFromJSON
{
    [self checkServerConnection];
    
    if (online)
    {
        [self fetchJSON];
        [self createContentsFromJSON];
    }
    else
    {
        //alert view
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect to server" message:@"Please check your WiFi setting and the offline server is on" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)createContentsFromJSON
{
    for (NSDictionary *object in _JSON)
    {
        NSString *type = [object objectForKey:@"Type"];
        
        if ([type isEqualToString:@"folder"])
        {
            Folder *folder = [self folderWithDictionary:object];
            [_folders addObject:folder];
        }
        else
        {
            File *file = [self fileWithDictionary:object];
            [_files addObject:file];
        }
    }
    
    [self.tableView reloadData];
}

- (File *)fileWithDictionary:(NSDictionary *)dict
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"File" inManagedObjectContext:context];
    File *file = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    //download file to direction
    NSString *urlString = [NSString stringWithFormat:@"%@%@", ServerRequest, [dict objectForKey:@"Url"]];
    NSLog(@"url :%@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *htmlData = [NSData dataWithContentsOfURL:url];
    
    //get last modified date
    NSString *modifiedDate = [dict objectForKey:@"Date"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    NSDate *serverModifiedDate = [formatter dateFromString:modifiedDate];
    
    file.fatherPath = ServerRequest;
    file.name = [dict objectForKey:@"Name"];
    file.path = [NSString stringWithFormat:@"%@/%@.html", file.fatherPath, file.name];
    file.isExistInServer = [NSNumber numberWithBool:YES];
    file.isLastVersion = [NSNumber numberWithBool:YES];
    file.html = htmlData;
    file.modifiedDate = serverModifiedDate;
    
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

- (Folder *)folderWithDictionary:(NSDictionary *)dict
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Folder" inManagedObjectContext:context];
    Folder *folder = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    folder.fatherPath = ServerRequest;
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
        cell.detailTextLabel.text = folder.path;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        cell.textLabel.text = @"Empty";
        cell.accessoryType = UITableViewCellAccessoryNone;
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
        cell.detailTextLabel.text = file.path;
    }
    else
    {
        cell.textLabel.text = @"Empty";
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
            
            if (!self.folderController)
            {
                self.folderController = [[FolderViewController alloc] initWithStyle:UITableViewStylePlain];
            }
            _folderController.managedObjectContext = self.managedObjectContext;
            [_folderController manageFolder:folder withJSON:data online:online];
            _folderController.delegate = self;
            
            [self.navigationController pushViewController:_folderController animated:YES];
        } break;
            
        default: {
            File *file = [_files objectAtIndex:indexPath.row];
            //Delegate method
            [delegate folderManagerController:self openFile:file];
        } break;
    }
}

#pragma mark - Open File Delegate Method

- (void)folderViewController:(FolderViewController *)controller openFile:(File *)file
{
    [delegate folderManagerController:self openFile:file];
}

@end
