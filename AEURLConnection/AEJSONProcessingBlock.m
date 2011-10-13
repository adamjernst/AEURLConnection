//
//  AEJSONProcessingBlock.m
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEJSONProcessingBlock.h"

@implementation AEJSONProcessingBlock

static AEURLConnectionResponseProcessingBlock JSONProcessingBlock = nil;

+ (AEURLConnectionResponseProcessingBlock)JSONResponseProcessingBlock {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		JSONProcessingBlock = [[self JSONResponseProcessingBlockWithOptions:JKParseOptionNone] retain];
	});
	return JSONProcessingBlock;
}

+ (AEURLConnectionResponseProcessingBlock)JSONResponseProcessingBlockWithOptions:(JKParseOptionFlags)options {
	return [[(id)^(NSURLResponse *response, NSData *data, NSError **error){
		return [data objectFromJSONDataWithParseOptions:options error:error];
	} copy] autorelease];
}

+ (AEURLConnectionParameterProcessingBlock)JSONParameterProcessingBlock {
	return [[^(NSDictionary *parameters, NSMutableURLRequest *targetRequest){
		[targetRequest setHTTPBody:[parameters JSONData]];
		[targetRequest setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	} copy] autorelease];
}

@end
