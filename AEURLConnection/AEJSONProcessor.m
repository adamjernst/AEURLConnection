//
//  AEJSONProcessor.m
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEJSONProcessor.h"

@implementation AEJSONProcessor

static AEURLResponseProcessor JSONProcessor = nil;

+ (AEURLResponseProcessor)JSONResponseProcessor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JSONProcessor = [[self JSONResponseProcessorWithOptions:JKParseOptionNone] retain];
    });
    return JSONProcessor;
}

+ (AEURLResponseProcessor)JSONResponseProcessorWithOptions:(JKParseOptionFlags)options {
    return [[(id)^(NSURLResponse *response, NSData *data, NSError **error){
        return [data objectFromJSONDataWithParseOptions:options error:error];
    } copy] autorelease];
}

+ (AEURLParameterProcessor)JSONParameterProcessor {
    return [[^(NSDictionary *parameters, NSMutableURLRequest *targetRequest){
        [targetRequest setHTTPBody:[parameters JSONData]];
        [targetRequest setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    } copy] autorelease];
}

+ (NSSet *)defaultAcceptableJSONContentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
}

@end
