//
//  SnQuestion.h
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SnQuestion : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * objectid;
@property (nonatomic, retain) NSString * questxt;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSNumber * timer;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * tokens;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSSet *qtoa;
@property (nonatomic, retain) NSManagedObject *qtou;
@end

@interface SnQuestion (CoreDataGeneratedAccessors)

- (void)addQtoaObject:(NSManagedObject *)value;
- (void)removeQtoaObject:(NSManagedObject *)value;
- (void)addQtoa:(NSSet *)values;
- (void)removeQtoa:(NSSet *)values;

@end
