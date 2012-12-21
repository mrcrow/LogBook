//
//  Collection.h
//  LogBook
//
//  Created by Wu Wenzhi on 12-12-20.
//  Copyright (c) 2012年 Wu Wenzhi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class File;

@interface Collection : NSManagedObject

@property (nonatomic, retain) NSString * json;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * sent;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSData * attachment;
@property (nonatomic, retain) File *fromFile;

@end
