//
//  AEJSONProcessingBlock.m
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEJSONProcessingBlock.h"

@implementation AEJSONProcessingBlock

static AEURLConnectionProcessingBlock JSONProcessingBlock = nil;

+ (AEURLConnectionProcessingBlock)JSONProcessingBlock {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		JSONProcessingBlock = [[self JSONProcessingBlockWithOptions:JKParseOptionNone] retain];
	});
	return JSONProcessingBlock;
}

+ (AEURLConnectionProcessingBlock)JSONProcessingBlockWithOptions:(JKParseOptionFlags)options {
	return [[(id)^(NSURLResponse *response, NSData *data, NSError **error){
		return [data objectFromJSONDataWithParseOptions:options error:error];
	} copy] autorelease];
}

@end
