//
//  SnQuestion.m
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import "SnQuestion.h"
#import "SnSyncEngine.h"
#import "NSManagedObjectJSON.h"

@implementation SnQuestion

@dynamic createdAt;
@dynamic objectid;
@dynamic questxt;
@dynamic syncStatus;
@dynamic timer;
@dynamic timestamp;
@dynamic tokens;
@dynamic updatedAt;
@dynamic qtoa;
@dynamic qtou;

- (NSDictionary *)JSONToCreateObjectOnServer {
    NSString *jsonString = nil;
    NSDictionary *date = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Date", @"__type",
                          [[SnSyncEngine sharedEngine] dateStringForAPIUsingDate:self.timestamp], @"iso" , nil];
    
    
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self.questxt, @"questxt",
                                    date, @"date", self.tokens, @"tokens",
                                    self.timer, @"timer", nil];
    
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
