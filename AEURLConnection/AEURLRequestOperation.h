//
//  AEURLRequestOperation.h
//  Turntable
//
//  Created by Adam Ernst on 11/10/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AEURLConnection.h"

@interface AEURLRequestOperation : NSOperation

+ (AEURLRequestOperation *)URLRequestOperationWithRequest:(NSURLRequest *)request;
+ (AEURLRequestOperation *)URLRequestOperationWithRequest:(NSURLRequest *)request processor:(AEURLResponseProcessor)processor;

- (id)initWithRequest:(NSURLRequest *)request;
- (id)initWithRequest:(NSURLRequest *)request processor:(AEURLResponseProcessor)processor;

@property (nonatomic, retain, readonly) NSURLRequest *request;
@property (nonatomic, retain, readonly) AEURLResponseProcessor processor;

@property (nonatomic, retain, readonly) NSURLResponse *response;
@property (nonatomic, retain, readonly) id data;
@property (nonatomic, retain, readonly) NSError *error;

@end
