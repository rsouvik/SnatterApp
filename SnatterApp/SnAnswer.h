//
//  SnAnswer.h
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SnQuestion;

@interface SnAnswer : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * objectid;
@property (nonatomic, retain) NSString * anstxt;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * tokens;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) SnQuestion *atoq;
@property (nonatomic, retain) NSManagedObject *atou;

@end
