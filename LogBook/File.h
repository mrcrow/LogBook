//
//  File.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-12.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Collection, Folder;

@interface File : NSManagedObject

@property (nonatomic, retain) NSString * fatherPath;
@property (nonatomic, retain) NSData * html;
@property (nonatomic, retain) NSNumber * isExistInServer;
@property (nonatomic, retain) NSNumber * isLastVersion;
@property (nonatomic, retain) NSDate * modifiedDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSSet *collections;
@property (nonatomic, retain) Folder *fromFolder;
@end

@interface File (CoreDataGeneratedAccessors)

- (void)addCollectionsObject:(Collection *)value;
- (void)removeCollectionsObject:(Collection *)value;
- (void)addCollections:(NSSet *)values;
- (void)removeCollections:(NSSet *)values;

@end
