//
//  Folder.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-12.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class File, Folder;

@interface Folder : NSManagedObject

@property (nonatomic, retain) NSString * fatherPath;
@property (nonatomic, retain) NSNumber * isExistInServer;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) Folder *fromFolder;
@property (nonatomic, retain) NSSet *subFiles;
@property (nonatomic, retain) NSSet *subFolders;
@end

@interface Folder (CoreDataGeneratedAccessors)

- (void)addSubFilesObject:(File *)value;
- (void)removeSubFilesObject:(File *)value;
- (void)addSubFiles:(NSSet *)values;
- (void)removeSubFiles:(NSSet *)values;

- (void)addSubFoldersObject:(Folder *)value;
- (void)removeSubFoldersObject:(Folder *)value;
- (void)addSubFolders:(NSSet *)values;
- (void)removeSubFolders:(NSSet *)values;

@end
