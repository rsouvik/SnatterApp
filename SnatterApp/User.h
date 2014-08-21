//
//  User.h
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SnAnswer, SnQuestion;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * objectid;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSString * socialID;
@property (nonatomic, retain) NSNumber * tokens;
@property (nonatomic, retain) NSString * uname;
@property (nonatomic, retain) NSSet *utoa;
@property (nonatomic, retain) NSSet *utoq;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addUtoaObject:(SnAnswer *)value;
- (void)removeUtoaObject:(SnAnswer *)value;
- (void)addUtoa:(NSSet *)values;
- (void)removeUtoa:(NSSet *)values;

- (void)addUtoqObject:(SnQuestion *)value;
- (void)removeUtoqObject:(SnQuestion *)value;
- (void)addUtoq:(NSSet *)values;
- (void)removeUtoq:(NSSet *)values;

@end
