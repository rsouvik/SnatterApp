//
//  SnSyncEngine.h
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SDObjectSynced = 0,
    SDObjectCreated,
    SDObjectDeleted,
} SDObjectSyncStatus;

@interface SnSyncEngine : NSObject

@property (atomic, readonly) BOOL syncInProgress;

+ (SnSyncEngine *)sharedEngine;

- (void)registerNSManagedObjectClassToSync:(Class)aClass;
- (void)startSync;
- (NSString *)dateStringForAPIUsingDate:(NSDate *)date;


@end
