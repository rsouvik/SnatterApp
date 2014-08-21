//
//  SnAnswer.m
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import "SnAnswer.h"
#import "SnQuestion.h"
#import "SnSyncEngine.h"
#import "NSManagedObjectJSON.h"

@implementation SnAnswer

@dynamic createdAt;
@dynamic objectid;
@dynamic anstxt;
@dynamic rating;
@dynamic timestamp;
@dynamic tokens;
@dynamic updatedAt;
@dynamic atoq;
@dynamic atou;

- (NSDictionary *)JSONToCreateObjectOnServer {
    NSString *jsonString = nil;
    NSDictionary *date = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Date", @"__type",
                          [[SnSyncEngine sharedEngine] dateStringForAPIUsingDate:self.timestamp], @"iso" , nil];
    
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    self.anstxt, @"anstxt", self.tokens, @"tokens",
                                    self.rating, @"rating",
                                    date, @"date", nil];
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
