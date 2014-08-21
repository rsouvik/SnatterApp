//
//  User.m
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import "User.h"
#import "SnAnswer.h"
#import "SnQuestion.h"
#import "NSManagedObjectJSON.h"


@implementation User

@dynamic objectid;
@dynamic rating;
@dynamic socialID;
@dynamic tokens;
@dynamic uname;
@dynamic utoa;
@dynamic utoq;

- (NSDictionary *)JSONToCreateObjectOnServer {
    NSString *jsonString = nil;
    //NSDictionary *date = [NSDictionary dictionaryWithObjectsAndKeys:
    //                    @"Date", @"__type",
    //                  [[SDSyncEngine sharedEngine] dateStringForAPIUsingDate:self.date], @"iso" , nil];
    
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self.uname, @"uname",
                                    self.socialID, @"socialID",
                                    self.rating, @"rating",
                                    self.tokens, @"tokens",
                                    nil];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:jsonDictionary
                        options:NSJSONWritingPrettyPrinted
                        error:&error];
    if (!jsonData) {
        NSLog(@"Error creaing jsonData: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonDictionary;
}

@end
