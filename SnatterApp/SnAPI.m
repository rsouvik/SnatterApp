//
//  SnAPI.m
//  SnatterApp
//
//  Created by Souvik Ray on 8/21/14.
//  Copyright (c) 2014 com.snattery. All rights reserved.
//

#import "SnAPI.h"

//the web location of the service (DB calls on local)
//#define kAPIHost @"http://192.168.1.6:8888"
#define kAPIHost @"http://192.168.1.102:8888"
//#define kAPIHost @"http://192.168.1.197:8888"

//db call on local
#define kAPIPath @"snatter/"
//POST call for GO
//#define kAPIPath @"q?uid=100006362773273&t=Q&pt=foo&at=e&qid=1"

#define goURL @"http://ads-app2.east.sharethis.com:8000"
//post call for GO server
//#define kAPIHost goURL

#define ensureInMainThread(); if (!NSThread.isMainThread) { [self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];    return; }

@implementation API

@synthesize user;
NSDictionary *mapsynccommand = nil;

#pragma mark - Singleton methods
/**
 * Singleton methods
 */
+(API*)sharedInstance {
    static API *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [[self alloc] initWithBaseURL:[NSURL URLWithString:kAPIHost]];
    });
    
    return sharedInstance;
}

+ (void)initialize {
    if (!mapsynccommand)
        mapsynccommand = [[NSDictionary alloc] initWithObjectsAndKeys:@"SnQuestion",@"syncuserques",@"SnAnswer",@"syncuseranswer", nil];
}

#pragma mark - init
//intialize the API class with the deistination host name

-(API*)init {
    //call super init
    self = [super init];
    if (self != nil) {
        //initialize the object
        user = nil;
        [self setParameterEncoding:AFJSONParameterEncoding];
        //[self setParameterEncoding:AFFormURLParameterEncoding];
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
        [self setDefaultHeader:@"Accept" value:@"application/json"];
        //[self setDefaultHeader:@"Accept" value:@"text/json"];
    }
    return self;
}


-(BOOL)isAuthorized {
    return [[user objectForKey:@"IdUser"] intValue]>0;
}

//GET
-(void)commandGet:(NSString*)params onCompletion:(JSONResponseBlock)completionBlock {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    NSString* appurl = [goURL stringByAppendingString:params];
    [request setURL:[NSURL URLWithString:appurl]];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
        
        NSLog(@"Success call to Go");
        if([response statusCode] != 200){
            NSLog(@"Error getting %@, HTTP status code %i", appurl, [response statusCode]);
        }
        else
            completionBlock(json);
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json) {
        
        // failed
        NSLog(@"Failed %@", error);
        completionBlock([NSDictionary dictionaryWithObject:[error localizedDescription] forKey:@"error"]);
        
    }];
    [self enqueueHTTPRequestOperation:operation];
}

//POST
-(void)commandWithParams:(NSMutableDictionary*)params onCompletion:(JSONResponseBlock)completionBlock {
	NSData* uploadFile = nil;
	/*if ([params objectForKey:@"file"]) {
     uploadFile = (NSData*)[params objectForKey:@"file"];
     [params removeObjectForKey:@"file"];
     }*/
    
    NSMutableURLRequest *apiRequest = [self multipartFormRequestWithMethod:@"POST" path:kAPIPath parameters:params constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        //NSLog(@"Success in calling");
        
		if (uploadFile) {
			[formData appendPartWithFileData:uploadFile name:@"file" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
		}
	}];
    
    
    //AFJSONRequestOperation* operation = [[AFJSONRequestOperation alloc] initWithRequest: apiRequest];
    
    /*AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:apiRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
     NSLog(@"Success in calling");
     } failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
     NSLog(@"Failure in calling");
     }];
     
     //NSOperationQueue *queue = [[NSOperationQueue alloc] init];
     //[queue addOperation:operation];
     
     [operation start];*/
    
    /*[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
     //success!
     NSString* response = [operation responseString];
     NSLog(@"response: %@",response);
     NSLog(@"Success in calling");
     completionBlock(responseObject);
     NSLog(@"Success in calling");
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
     //failure :(
     completionBlock([NSDictionary dictionaryWithObject:[error localizedDescription] forKey:@"error"]);
     NSLog(@"Failure in calling");
     NSLog(@"%@ %d",[error localizedDescription],[error code]);
     
     }];
     [operation start];
     //[self enqueueHTTPRequestOperation:operation];
     NSLog(@"%@",[operation responseJSON]);
     NSLog(@"Operation started");
     NSString* response = [operation responseString];
     NSLog(@"response: %@",response);*/
    
    /*NSMutableURLRequest *apiRequest = [self multipartFormRequestWithMethod:@"POST" path:kAPIPath parameters:params constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
     NSLog(@"Success in calling");
     
     if (uploadFile) {
     [formData appendPartWithFileData:uploadFile name:@"file" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
     }
     }];*/
    
    /*__block int status = 0;
     NSMutableURLRequest *apiRequest = [self multipartFormRequestWithMethod:@"POST" path:kAPIPath parameters:params constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
     NSLog(@"Success in calling");
     
     if (uploadFile) {
     [formData appendPartWithFileData:uploadFile name:@"file" fileName:@"photo.jpg" mimeType:@"image/jpeg"];
     }
     }];
     
     
     //ensureInMainThread();
     NSURLRequest *scriptUrl = [NSURL URLWithString:@"http://www.google.com/m"];
     
     dispatch_queue_t requestQueue = dispatch_queue_create("requestQueue", NULL);
     
     AFJSONRequestOperation* operation = [[AFJSONRequestOperation alloc] initWithRequest: apiRequest];
     [operation setDownloadProgressBlock:^( NSUInteger bytesRead , long long totalBytesRead , long long totalBytesExpectedToRead )
     {
     NSLog(@"%lld of %lld", totalBytesRead, totalBytesExpectedToRead);
     }
     ];
     
     operation.successCallbackQueue = requestQueue;
     operation.failureCallbackQueue = requestQueue;
     NSLog(@"1");
     dispatch_async(dispatch_get_main_queue(), ^{
     [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
     //success!
     NSLog(@"Response: %@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
     NSLog(@"2");
     completionBlock(responseObject);
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
     //failure :(
     NSLog(@"3");
     completionBlock([NSDictionary dictionaryWithObject:[error localizedDescription] forKey:@"error"]);
     }];
     });
     NSLog(@"4");
     
     [operation setCompletionBlock:^{
     NSLog(@"33");
     }];
     [self enqueueHTTPRequestOperation:operation];
     */
    //[operation start];
    /*while (status == 0)
     {
     // run runloop so that async dispatch can be handled on main thread AFTER the operation has
     // been marked as finished (even though the call backs haven't finished yet).
     [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
     beforeDate:[NSDate date]];
     }*/
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:apiRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
        
        // success
        //dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Success");
        completionBlock(json);
        //});
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json) {
        
        // failed
        NSLog(@"Failed %@", error);
        completionBlock([NSDictionary dictionaryWithObject:[error localizedDescription] forKey:@"error"]);
        
    }];
    
    //[self enqueueHTTPRequestOperation:operation];
    
    /*[operation setDownloadProgressBlock:^( NSUInteger bytesRead , long long totalBytesRead , long long totalBytesExpectedToRead )
     {
     NSLog(@"%lld of %lld", totalBytesRead, totalBytesExpectedToRead);
     }
     ];*/
    [self enqueueHTTPRequestOperation:operation];
    
    //[operation start];
    NSLog(@"%@",[operation responseJSON]);
    
    /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
     
     NSString *response;
     NSError* error;
     __block int status = 0;
     NSURL *url = [[NSURL alloc] initWithString:@"http://www.google.com/m"];
     NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
     
     NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
     if (completionBlock) {
     //dispatch back to the UI thread again
     dispatch_async(dispatch_get_main_queue(), ^{
     if (responseData == nil) {
     //no response data, so pass nil to the stringOut so you know there was an error.
     completionBlock(nil);
     } else {
     //response received, get the content.
     NSString *content = [[NSString alloc] initWithBytes:[responseData bytes] length:responseData.length encoding:NSUTF8StringEncoding];
     
     NSLog(@"String received: %@", content);
     
     //call your completion handler with the result of your call.
     completionBlock(content);
     }
     });
     }
     });*/
    
    
    /* AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
     //dispatch_async(dispatch_get_main_queue(), ^{
     //NSLog(@"%@", JSON);
     NSLog(@"success");
     
     //});
     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
     NSLog(@"Request Failed with Error: %@, %@", error, error.userInfo);
     }];
     
     [self enqueueHTTPRequestOperation:operation];
     
     [operation setDownloadProgressBlock:^( NSUInteger bytesRead , long long totalBytesRead , long long totalBytesExpectedToRead )
     {
     NSLog(@"%lld of %lld", totalBytesRead, totalBytesExpectedToRead);
     }
     ];
     
     [operation setCompletionBlock:^{
     NSLog(@"operation complete");
     }];*/
    
    //NSLog(@"%@", [NSThread currentThread]);
    
    //[operation start];
    
    //NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    //[[queue addOperation:operation];
    //[self enqueueHTTPRequestOperation:operation];
    
    /*while (status == 0)
     {
     // run runloop so that async dispatch can be handled on main thread AFTER the operation has
     // been marked as finished (even though the call backs haven't finished yet).
     [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
     beforeDate:[NSDate date]];
     }*/
    
    //[operation start];
    
    //NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    //[queue addOperation:operation];
    
    //[operation start];
    /*NSLog(@"%@",[operation responseJSON]);
     
     NSURL *scriptUrl = [NSURL URLWithString:@"http://www.google.com/m"];
     NSData *data = [NSData dataWithContentsOfURL:scriptUrl];
     if (data){
     NSLog(@"Device is connected to the internet");
     NSLog(@"%@", data);
     }
     else
     NSLog(@"Device is not connected to the internet");*/
    
    
}

//POST
-(void)commandPost:(NSMutableDictionary*)params onCompletion:(JSONResponseBlock)completionBlock {
	
    NSMutableURLRequest *apiRequest = [self multipartFormRequestWithMethod:@"POST" path:kAPIPath parameters:params constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        //NSLog(@"Success in calling");
        
	}];
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:apiRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
        
        // success
        //dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Success call to Go");
        if([response statusCode] != 200){
            NSLog(@"Error HTTP status code %i", [response statusCode]);
        }
        else
            completionBlock(json);
        //});
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id json) {
        
        // failed
        NSLog(@"Failed %@", error);
        completionBlock([NSDictionary dictionaryWithObject:[error localizedDescription] forKey:@"error"]);
        
    }];
    
    [self enqueueHTTPRequestOperation:operation];
    
    //[operation start];
    NSLog(@"%@",[operation responseJSON]);
    
}

-(NSURL*)urlForImageWithId:(NSNumber*)IdPhoto isThumb:(BOOL)isThumb {
    NSString* urlString = [NSString stringWithFormat:@"%@/%@upload/%@%@.jpg", kAPIHost, kAPIPath, IdPhoto, (isThumb)?@"-thumb":@""];
    return [NSURL URLWithString:urlString];
}

- (NSMutableURLRequest *)GETRequestForClass:(NSString *)className parameters:(NSDictionary *)parameters {
    NSMutableURLRequest *request = nil;
    //request = [self requestWithMethod:@"GET" path:[NSString stringWithFormat:@"classes/%@", className] parameters:parameters];
    request = [self requestWithMethod:@"GET" path:kAPIPath parameters:parameters];
    return request;
}

//Create the request for REST call
//non-user specific
- (NSMutableURLRequest *)GETRequestForAllRecordsOfClass:(NSString *)className updatedAfterDate:(NSDate *)updatedDate {
    
    NSMutableURLRequest *request = nil;
    NSDictionary *parameters = nil;
    if (updatedDate) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.'999Z'"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        
        /*NSString *jsonString = [NSString
         stringWithFormat:@"{\"updatedAt\":{\"$gte\":{\"__type\":\"Date\",\"iso\":\"%@\"}}}",
         [dateFormatter stringFromDate:updatedDate]];
         
         paramters = [NSDictionary dictionaryWithObject:jsonString forKey:@"where"];
         */
        //NSString* command = @"updateques";
        NSString* command = [mapsynccommand valueForKey:className];
        
        NSString* fid = [user objectForKey:@"id"];
        //NSString* funame = [user objectForKey:user.name];
        NSString* lastupdate = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:updatedDate]];
        NSMutableDictionary* parameters =[NSMutableDictionary dictionaryWithObjectsAndKeys: command, @"command", fid, @"fid", lastupdate, @"timestamp", nil];
    }
    
    request = [self GETRequestForClass:className parameters:parameters];
    return request;
}

//Create the request for REST call
- (NSMutableURLRequest *)GETRequestForAllRecordsOfClass:(NSString *)className foruser:(NSString *) userid updatedAfterDate:(NSDate *)updatedDate {
    
    NSMutableURLRequest *request = nil;
    NSMutableDictionary *parameters = nil;
    if (updatedDate) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        //[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.'999Z'"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        
        /*NSString *jsonString = [NSString
         stringWithFormat:@"{\"updatedAt\":{\"$gte\":{\"__type\":\"Date\",\"iso\":\"%@\"}}}",
         [dateFormatter stringFromDate:updatedDate]];
         
         paramters = [NSDictionary dictionaryWithObject:jsonString forKey:@"where"];
         */
        NSString* command = [mapsynccommand valueForKey:className];
        NSString* fid = userid;
        //NSString* fid = [user objectForKey:@"id"];
        //NSString* funame = [user objectForKey:user.name];
        NSString* lastupdate = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:updatedDate]];
        parameters =[NSMutableDictionary dictionaryWithObjectsAndKeys: command, @"command", fid, @"fid", lastupdate, @"timestamp", nil];
    }
    
    request = [self GETRequestForClass:className parameters:parameters];
    return request;
}

- (NSMutableURLRequest *)POSTRequestForClass:(NSString *)className parameters:(NSDictionary *)parameters {
    NSMutableURLRequest *request = nil;
    request = [self requestWithMethod:@"POST" path:[NSString stringWithFormat:@"classes/%@", className] parameters:parameters];
    return request;
}

- (NSMutableURLRequest *)DELETERequestForClass:(NSString *)className forObjectWithId:(NSString *)objectId {
    NSMutableURLRequest *request = nil;
    request = [self requestWithMethod:@"DELETE" path:[NSString stringWithFormat:@"classes/%@/%@", className, objectId] parameters:nil];
    return request;
}


@end

