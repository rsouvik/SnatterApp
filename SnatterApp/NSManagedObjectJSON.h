//
//  NSManagedObjectJSON.h
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface NSManagedObject (JSON)

- (NSDictionary *)JSONToCreateObjectOnServer;

@end
