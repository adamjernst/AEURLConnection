//
//  AEJSONProcessor.h
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AEURLConnection.h"
#import "AEURLRequestFactory.h"

// AEJSONProcessor requires JSONKit.  You can use AEURLConnection
// without JSONKit; just remove the AEJSONProcessor.m/h files from your
// project, and parse JSON manually.
#import "JSONKit.h"


@interface AEJSONProcessor : NSObject

// These blocks are used to process a response from the server.
+ (AEURLResponseProcessor)JSONResponseProcessor;
+ (AEURLResponseProcessor)JSONResponseProcessorWithOptions:(JKParseOptionFlags)options;

// This block will put parameters into a NSMutableURLRequest's HTTP body, 
// encoded as JSON, and set the request's Content-Type header to 
// "application/json; charset=UTF-8".
+ (AEURLParameterProcessor)JSONParameterProcessor;

// A set with the most common Content-Types for JSON. Handy with the 
// [AEExpect contentType:] response processor, when used in a chain.
+ (NSSet *)defaultAcceptableJSONContentTypes;

@end
