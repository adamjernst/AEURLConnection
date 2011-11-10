//
//  AEURLResponseProcessors.h
//  Turntable
//
//  Created by Adam Ernst on 11/10/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

// This block can be used as a parameter to |processor:| in AEURLConnection.
// It is REQUIRED that the block either returns an object and leaves the error
// parameter untouched, or sets an error and returns nil. This is enforced with
// an assertion.
typedef id (^AEURLResponseProcessor)(NSURLResponse *, id, NSError **);

extern NSString *AEURLResponseProcessorsErrorDomain;

enum {
    AEURLResponseProcessorsErrorImageDecodingFailed = -100,
};

@interface AEURLResponseProcessors : NSObject

// A basic response processor that decodes an image, or returns an error.
+ (AEURLResponseProcessor)imageResponseProcessor;

// The real power comes when you chain processors together. This allows
// you to verify that the status code is acceptable, then that the content-type
// is what you expect, then parse JSON, and finally require that the response 
// is a dictionary (not an array)--and to do it all in a declarative way.
// This means you can store the chained processor in your app and reuse it in 
// different contexts, instead of duplicating the logic everywhere.

// Note that because completionHandler returns *either* an NSError *or* data,
// never both, you cannot get the document data if a response processor fails.
// If you need to access the HTTP body, you'll need to do your response
// processing the old fashioned way.

// The returned processor will run each processor in sequence. If one fails by
// returning an NSError*, processing stops immediately and the subsequent
// processors are not run.
// Just like NSArray, *the last argument must be nil.*
+ (AEURLResponseProcessor)chainedResponseProcessor:(AEURLResponseProcessor)firstProcessor, ... NS_REQUIRES_NIL_TERMINATION;

@end
