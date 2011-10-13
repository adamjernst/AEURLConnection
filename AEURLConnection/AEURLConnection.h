//
//  AEURLConnection.h
//  AEURLExample
//
//  Created by Adam Ernst on 10/12/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^AEURLConnectionResponseProcessingBlock)(NSURLResponse *, NSData *, NSError **);

@interface AEURLConnection : NSObject

// Mirrors the sendAsynchronousRequest:queue:completionHandler: API from iOS 5,
// but is safe for use with iOS 4. |completionHandler| is guaranteed to be 
// called *and* released from the context of |queue|.
+ (void)sendAsynchronousRequest:(NSURLRequest *)request
                          queue:(NSOperationQueue*)queue
              completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

// You may want to process the response on a background thread, but still safely
// receive the response on |queue|. This method runs |processingBlock| on a 
// low-priority serial queue (one operation at a time, to prevent thrashing the 
// CPU). completionHandler returns the result of the processing block, instead
// of an NSData* object.
// Check out AEJSONProcessingBlock for an example usage.
+ (void)sendAsynchronousRequest:(NSURLRequest *)request 
                          queue:(NSOperationQueue *)queue
                processingBlock:(AEURLConnectionResponseProcessingBlock)processingBlock
              completionHandler:(void (^)(NSURLResponse *, id, NSError *))handler;

@end
