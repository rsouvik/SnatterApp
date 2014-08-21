//
//  SnSyncEngine.m
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import "SnSyncEngine.h"
#import "SnCoreDataController.h"
#import "SnAPI.h"
#import "NSManagedObjectJSON.h"

NSString * const kSnSyncEngineInitialCompleteKey = @"SnSyncEngineInitialSyncCompleted";
NSString * const kSnSyncEngineSyncCompletedNotificationName = @"SnSyncEngineSyncCompleted";
NSDictionary *maprelation = nil;

@interface SnSyncEngine ()

@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation SnSyncEngine

@synthesize syncInProgress = _syncInProgress;

@synthesize registeredClassesToSync = _registeredClassesToSync;
@synthesize dateFormatter = _dateFormatter;

/*
 We want to sync: Client->Server: Qs asked by user; As answered by user, other related stuff (book-keeping) [also deleted stuff]
 Server->Client: As answered for client-asked Qs [deleted stuff], Qs routed to the user (client) [notification]
 */

+ (void)initialize {
    if(!maprelation)
        maprelation = [[NSDictionary alloc] initWithObjectsAndKeys:@"SnQuestion",@"utoq",@"SnAnswer",@"utoa", nil];
}

+ (SnSyncEngine *)sharedEngine {
    static SnSyncEngine *sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [[SnSyncEngine alloc] init];
    });
    
    return sharedEngine;
}

- (void)registerNSManagedObjectClassToSync:(Class)aClass {
    if (!self.registeredClassesToSync) {
        self.registeredClassesToSync = [NSMutableArray array];
    }
    
    if ([aClass isSubclassOfClass:[NSManagedObject class]]) {
        if (![self.registeredClassesToSync containsObject:NSStringFromClass(aClass)]) {
            [self.registeredClassesToSync addObject:NSStringFromClass(aClass)];
        } else {
            NSLog(@"Unable to register %@ as it is already registered", NSStringFromClass(aClass));
        }
    } else {
        NSLog(@"Unable to register %@ as it is not a subclass of NSManagedObject", NSStringFromClass(aClass));
    }
}

- (void)startSync {
    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self downloadDataForRegisteredObjects:YES toDeleteLocalRecords:NO];
        });
    }
}

- (void)executeSyncCompletedOperations {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setInitialSyncCompleted];
        NSError *error = nil;
        [[SnCoreDataController sharedInstance] saveBackgroundContext];
        if (error) {
            NSLog(@"Error saving background context after creating objects on server: %@", error);
        }
        
        [[SnCoreDataController sharedInstance] saveMasterContext];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kSnSyncEngineSyncCompletedNotificationName
         object:nil];
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = NO;
        [self didChangeValueForKey:@"syncInProgress"];
    });
}


- (BOOL)initialSyncComplete {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kSnSyncEngineInitialCompleteKey] boolValue];
}

- (void)setInitialSyncCompleted {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kSnSyncEngineInitialCompleteKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//User specific
- (NSDate *)mostRecentUpdatedAtDateForEntityWithName:(NSString *)entityName foruser:(NSString *)userName forrelationship:(NSString *)relation {
    
    __block NSDate *date = nil;
    NSMutableString *entity_ts = [NSMutableString stringWithString:entityName];
    [entity_ts appendString:@".timestamp"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"SnUser"];
    //predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username = %@", userName];
    [request setPredicate:predicate];
    
    [[[SnCoreDataController sharedInstance] backgroundManagedObjectContext] performBlockAndWait:^{
        NSError *error = nil;
        NSArray *fetcheduserobjects = [[[SnCoreDataController sharedInstance] backgroundManagedObjectContext] executeFetchRequest:request error:&error];
        if ([fetcheduserobjects lastObject])   {
            NSArray *fetchedquesobjects = [[fetcheduserobjects lastObject] valueForKey:relation];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:entity_ts ascending:NO];
            [fetchedquesobjects sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            if ([fetchedquesobjects lastObject]){
                date = [[fetchedquesobjects lastObject] valueForKey:@"timestamp"];
            }
        }
    }];
    
    return date;
}

//Non-user specific
- (NSDate *)mostRecentUpdatedAtDateForEntityWithName:(NSString *)entityName {
    
    __block NSDate *date = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [request setSortDescriptors:[NSArray arrayWithObject:
                                 [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    [request setFetchLimit:1];
    [[[SnCoreDataController sharedInstance] backgroundManagedObjectContext] performBlockAndWait:^{
        NSError *error = nil;
        NSArray *results = [[[SnCoreDataController sharedInstance] backgroundManagedObjectContext] executeFetchRequest:request error:&error];
        if ([results lastObject])   {
            date = [[results lastObject] valueForKey:@"timestamp"];
        }
    }];
    
    return date;
    
}

//download registeredclasses (not user specific)
- (void)downloadDataForRegisteredObjects:(BOOL)useUpdatedAtDate toDeleteLocalRecords:(BOOL)toDelete {
    NSMutableArray *operations = [NSMutableArray array];
    
    for (NSString *className in self.registeredClassesToSync) {
        NSDate *mostRecentUpdatedDate = nil;
        if (useUpdatedAtDate) {
            mostRecentUpdatedDate = [self mostRecentUpdatedAtDateForEntityWithName:className];
        }
        NSMutableURLRequest *request = [[API sharedInstance]
                                        GETRequestForAllRecordsOfClass:className
                                        updatedAfterDate:mostRecentUpdatedDate];
        //AFHTTPRequestOperation *operation = [[API sharedInstance] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
            if ([json isKindOfClass:[NSDictionary class]]) {
                [self writeJSONResponse:json toDiskForClassWithName:className];
            }
            //} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json) {
            NSLog(@"Request for class %@ failed with error: %@", className, error);
        }];
        
        [operations addObject:operation];
    }
    
    [[API sharedInstance] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
        
    } completionBlock:^(NSArray *operations) {
        
        if (!toDelete) {
            [self processJSONDataRecordsIntoCoreData];
        } else {
            [self processJSONDataRecordsForDeletion];
        }
    }];
}

//user-specific: inputs: user, relationship, class(e.g. Question)
/*- (void)downloadDataForRegisteredObjects:(BOOL)useUpdatedAtDate toDeleteLocalRecords:(BOOL)toDelete forclass:(NSString *)className foruser:(NSString *)user {
 
 NSMutableArray *operations = [NSMutableArray array];
 
 //for (NSString *className in self.registeredClassesToSync) {
 NSDate *mostRecentUpdatedDate = nil;
 if (useUpdatedAtDate) {
 mostRecentUpdatedDate = [self mostRecentUpdatedAtDateForEntityWithName:className foruser:user forrelationship:[maprelation valueForKey:className]]; //get class to relationship mapping from static map
 }
 NSMutableURLRequest *request = [[API sharedInstance]
 GETRequestForAllRecordsOfClass:className foruser:user
 updatedAfterDate:mostRecentUpdatedDate];
 //AFHTTPRequestOperation *operation = [[API sharedInstance] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
 AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
 if ([json isKindOfClass:[NSDictionary class]]) {
 [self writeJSONResponse:json toDiskForClassWithName:className];
 }
 //} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
 } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json) {
 NSLog(@"Request for class %@ failed with error: %@", className, error);
 }];
 
 [operations addObject:operation];
 //}
 
 [[API sharedInstance] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
 
 } completionBlock:^(NSArray *operations) {
 
 if (!toDelete) {
 [self processJSONDataRecordsIntoCoreData];
 } else {
 [self processJSONDataRecordsForDeletion];
 }
 }];
 }*/

//Store records from disk into coredata
- (void)processJSONDataRecordsIntoCoreData {
    NSManagedObjectContext *managedObjectContext = [[SnCoreDataController sharedInstance] backgroundManagedObjectContext];
    for (NSString *className in self.registeredClassesToSync) {
        if (![self initialSyncComplete]) { // import all downloaded data to Core Data for initial sync
            NSDictionary *JSONDictionary = [self JSONDictionaryForClassWithName:className];
            NSArray *records = [JSONDictionary objectForKey:@"results"]; //results or result?
            //NSArray *quesArray = [JSONBuilder postsFromJSON:json];
            for (NSDictionary *record in records) {
                [self newManagedObjectWithClassName:className forRecord:record];
            }
        } else {
            NSArray *downloadedRecords = [self JSONDataRecordsForClass:className sortedByKey:@"objectId"];
            if ([downloadedRecords lastObject]) {
                NSArray *storedRecords = [self managedObjectsForClass:className sortedByKey:@"objectId" usingArrayOfIds:[downloadedRecords valueForKey:@"objectId"] inArrayOfIds:YES];
                int currentIndex = 0;
                for (NSDictionary *record in downloadedRecords) {
                    NSManagedObject *storedManagedObject = nil;
                    if ([storedRecords count] > currentIndex) {
                        storedManagedObject = [storedRecords objectAtIndex:currentIndex];
                    }
                    
                    if ([[storedManagedObject valueForKey:@"objectId"] isEqualToString:[record valueForKey:@"objectId"]]) {
                        [self updateManagedObject:[storedRecords objectAtIndex:currentIndex] withRecord:record];
                    } else {
                        [self newManagedObjectWithClassName:className forRecord:record];
                    }
                    currentIndex++;
                }
            }
        }
        
        [managedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            if (![managedObjectContext save:&error]) {
                NSLog(@"Unable to save context for class %@", className);
            }
        }];
        
        [self deleteJSONDataRecordsForClassWithName:className];
    }
    
    [self downloadDataForRegisteredObjects:NO toDeleteLocalRecords:YES];
}

- (void)processJSONDataRecordsForDeletion {
    NSManagedObjectContext *managedObjectContext = [[SnCoreDataController sharedInstance] backgroundManagedObjectContext];
    for (NSString *className in self.registeredClassesToSync) {
        NSArray *JSONRecords = [self JSONDataRecordsForClass:className sortedByKey:@"objectId"];
        if ([JSONRecords count] > 0) {
            NSArray *storedRecords = [self
                                      managedObjectsForClass:className
                                      sortedByKey:@"objectId"
                                      usingArrayOfIds:[JSONRecords valueForKey:@"objectId"]
                                      inArrayOfIds:NO];
            
            [managedObjectContext performBlockAndWait:^{
                for (NSManagedObject *managedObject in storedRecords) {
                    [managedObjectContext deleteObject:managedObject];
                }
                NSError *error = nil;
                BOOL saved = [managedObjectContext save:&error];
                if (!saved) {
                    NSLog(@"Unable to save context after deleting records for class %@ because %@", className, error);
                }
            }];
        }
        
        [self deleteJSONDataRecordsForClassWithName:className];
    }
    //Push local objects to server (sync client->server)
    [self postLocalObjectsToServer];
}

- (void)newManagedObjectWithClassName:(NSString *)className forRecord:(NSDictionary *)record {
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:[[SnCoreDataController sharedInstance] backgroundManagedObjectContext]];
    [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key forManagedObject:newManagedObject];
    }];
    [record setValue:[NSNumber numberWithInt:SDObjectSynced] forKey:@"syncStatus"];
}

- (void)updateManagedObject:(NSManagedObject *)managedObject withRecord:(NSDictionary *)record {
    [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key forManagedObject:managedObject];
    }];
}

- (void)setValue:(id)value forKey:(NSString *)key forManagedObject:(NSManagedObject *)managedObject {
    if ([key isEqualToString:@"createdAt"] || [key isEqualToString:@"updatedAt"]) {
        NSDate *date = [self dateUsingStringFromAPI:value];
        [managedObject setValue:date forKey:key];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        if ([value objectForKey:@"__type"]) {
            NSString *dataType = [value objectForKey:@"__type"];
            if ([dataType isEqualToString:@"Date"]) {
                NSString *dateString = [value objectForKey:@"iso"];
                NSDate *date = [self dateUsingStringFromAPI:dateString];
                [managedObject setValue:date forKey:key];
            } else if ([dataType isEqualToString:@"File"]) {
                NSString *urlString = [value objectForKey:@"url"];
                NSURL *url = [NSURL URLWithString:urlString];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                NSURLResponse *response = nil;
                NSError *error = nil;
                NSData *dataResponse = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                [managedObject setValue:dataResponse forKey:key];
            } else {
                NSLog(@"Unknown Data Type Received");
                [managedObject setValue:nil forKey:key];
            }
        }
    } else {
        [managedObject setValue:value forKey:key];
    }
}

- (void)postLocalObjectsToServer {
    NSMutableArray *operations = [NSMutableArray array];
    for (NSString *className in self.registeredClassesToSync) {
        NSArray *objectsToCreate = [self managedObjectsForClass:className withSyncStatus:SDObjectCreated];
        for (NSManagedObject *objectToCreate in objectsToCreate) {
            NSDictionary *jsonString = [objectToCreate JSONToCreateObjectOnServer];
            NSMutableURLRequest *request = [[API sharedInstance] POSTRequestForClass:className parameters:jsonString];
            
            AFHTTPRequestOperation *operation = [[API sharedInstance] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success creation: %@", responseObject);
                NSDictionary *responseDictionary = responseObject;
                NSDate *createdDate = [self dateUsingStringFromAPI:[responseDictionary valueForKey:@"createdAt"]];
                [objectToCreate setValue:createdDate forKey:@"createdAt"];
                [objectToCreate setValue:[responseDictionary valueForKey:@"objectId"] forKey:@"objectId"];
                [objectToCreate setValue:[NSNumber numberWithInt:SDObjectSynced] forKey:@"syncStatus"];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed creation: %@", error);
            }];
            [operations addObject:operation];
        }
    }
    
    [[API sharedInstance] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
        NSLog(@"Completed %d of %d create operations", numberOfCompletedOperations, totalNumberOfOperations);
    } completionBlock:^(NSArray *operations) {
        if ([operations count] > 0) {
            NSLog(@"Creation of objects on server compelete, updated objects in context: %@", [[[SnCoreDataController sharedInstance] backgroundManagedObjectContext] updatedObjects]);
            [[SnCoreDataController sharedInstance] saveBackgroundContext];
            NSLog(@"SBC After call creation");
        }
        
        [self deleteObjectsOnServer];
        
    }];
}

- (void)deleteObjectsOnServer {
    NSMutableArray *operations = [NSMutableArray array];
    for (NSString *className in self.registeredClassesToSync) {
        NSArray *objectsToDelete = [self managedObjectsForClass:className withSyncStatus:SDObjectDeleted];
        for (NSManagedObject *objectToDelete in objectsToDelete) {
            NSMutableURLRequest *request = [[API sharedInstance]
                                            DELETERequestForClass:className
                                            forObjectWithId:[objectToDelete valueForKey:@"objectId"]];
            
            AFHTTPRequestOperation *operation = [[API sharedInstance] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success deletion: %@", responseObject);
                [[[SnCoreDataController sharedInstance] backgroundManagedObjectContext] deleteObject:objectToDelete];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to delete: %@", error);
            }];
            
            [operations addObject:operation];
        }
    }
    
    [[API sharedInstance] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
        
    } completionBlock:^(NSArray *operations) {
        if ([operations count] > 0) {
            NSLog(@"Deletion of objects on server compelete, updated objects in context: %@", [[[SnCoreDataController sharedInstance] backgroundManagedObjectContext] updatedObjects]);
        }
        
        [self executeSyncCompletedOperations];
    }];
}

- (NSArray *)managedObjectsForClass:(NSString *)className withSyncStatus:(SDObjectSyncStatus)syncStatus {
    __block NSArray *results = nil;
    NSManagedObjectContext *managedObjectContext = [[SnCoreDataController sharedInstance] backgroundManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"syncStatus = %d", syncStatus];
    [fetchRequest setPredicate:predicate];
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key usingArrayOfIds:(NSArray *)idArray inArrayOfIds:(BOOL)inIds {
    __block NSArray *results = nil;
    NSManagedObjectContext *managedObjectContext = [[SnCoreDataController sharedInstance] backgroundManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    NSPredicate *predicate;
    if (inIds) {
        predicate = [NSPredicate predicateWithFormat:@"objectId IN %@", idArray];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"NOT (objectId IN %@)", idArray];
    }
    
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:
                                      [NSSortDescriptor sortDescriptorWithKey:@"objectId" ascending:YES]]];
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;
}

- (void)initializeDateFormatter {
    if (!self.dateFormatter) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [self.dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    }
}

- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString {
    [self initializeDateFormatter];
    // NSDateFormatter does not like ISO 8601 so strip the milliseconds and timezone
    dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-5)];
    
    return [self.dateFormatter dateFromString:dateString];
}

- (NSString *)dateStringForAPIUsingDate:(NSDate *)date {
    [self initializeDateFormatter];
    NSString *dateString = [self.dateFormatter stringFromDate:date];
    // remove Z
    dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-1)];
    // add milliseconds and put Z back on
    dateString = [dateString stringByAppendingFormat:@".000Z"];
    
    return dateString;
}

#pragma mark - File Management

- (NSURL *)applicationCacheDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)JSONDataRecordsDirectory{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL URLWithString:@"JSONRecords/" relativeToURL:[self applicationCacheDirectory]];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:[url path]]) {
        [fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return url;
}

//write json response to disk
- (void)writeJSONResponse:(id)response toDiskForClassWithName:(NSString *)className {
    NSURL *fileURL = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]];
    if (![(NSDictionary *)response writeToFile:[fileURL path] atomically:YES]) {
        NSLog(@"Error saving response to disk, will attempt to remove NSNull values and try again.");
        // remove NSNulls and try again...
        //NSArray *records = [response objectForKey:@"results"];
        NSArray *records = [response objectForKey:@"result"];
        NSMutableArray *nullFreeRecords = [NSMutableArray array];
        for (NSDictionary *record in records) {
            NSMutableDictionary *nullFreeRecord = [NSMutableDictionary dictionaryWithDictionary:record];
            [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([obj isKindOfClass:[NSNull class]]) {
                    [nullFreeRecord setValue:nil forKey:key];
                }
            }];
            [nullFreeRecords addObject:nullFreeRecord];
        }
        
        NSDictionary *nullFreeDictionary = [NSDictionary dictionaryWithObject:nullFreeRecords forKey:@"results"];
        
        if (![nullFreeDictionary writeToFile:[fileURL path] atomically:YES]) {
            NSLog(@"Failed all attempts to save reponse to disk: %@", response);
        }
    }
}

- (void)deleteJSONDataRecordsForClassWithName:(NSString *)className {
    NSURL *url = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]];
    NSError *error = nil;
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    if (!deleted) {
        NSLog(@"Unable to delete JSON Records at %@, reason: %@", url, error);
    }
}

- (NSDictionary *)JSONDictionaryForClassWithName:(NSString *)className {
    NSURL *fileURL = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]];
    return [NSDictionary dictionaryWithContentsOfURL:fileURL];
}

- (NSArray *)JSONDataRecordsForClass:(NSString *)className sortedByKey:(NSString *)key {
    NSDictionary *JSONDictionary = [self JSONDictionaryForClassWithName:className];
    NSArray *records = [JSONDictionary objectForKey:@"results"];
    return [records sortedArrayUsingDescriptors:[NSArray arrayWithObject:
                                                 [NSSortDescriptor sortDescriptorWithKey:key ascending:YES]]];
}


@end

