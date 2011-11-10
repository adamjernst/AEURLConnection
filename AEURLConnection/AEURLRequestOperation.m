//
//  AEURLRequestOperation.m
//  Turntable
//
//  Created by Adam Ernst on 11/10/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEURLRequestOperation.h"

typedef enum {
    AEURLRequestOperationStateInitial,
    AEURLRequestOperationStateExecuting,
    AEURLRequestOperationStateFinished,
} AEURLRequestOperationState;

@interface AEURLRequestOperation ()
@property (nonatomic, retain, readwrite) NSURLResponse *response;
@property (nonatomic, retain, readwrite) id data;
@property (nonatomic, retain, readwrite) NSError *error;

@property (nonatomic) AEURLRequestOperationState state;
@end

@implementation AEURLRequestOperation

@synthesize request=_request;
@synthesize processor=_processor;
@synthesize response=_response;
@synthesize data=_data;
@synthesize error=_error;
@synthesize state=_state;

+ (AEURLRequestOperation *)URLRequestOperationWithRequest:(NSURLRequest *)request {
    return [[[AEURLRequestOperation alloc] initWithRequest:request] autorelease];
}

+ (AEURLRequestOperation *)URLRequestOperationWithRequest:(NSURLRequest *)request processor:(AEURLResponseProcessor)processor {
    return [[[AEURLRequestOperation alloc] initWithRequest:request processor:processor] autorelease];
}

- (id)initWithRequest:(NSURLRequest *)request {
    return [self initWithRequest:request processor:nil];
}

- (id)initWithRequest:(NSURLRequest *)request processor:(AEURLResponseProcessor)processor {
    self = [super init];
    if (self) {
        _request = [request retain];
        _processor = [processor copy];
    }
    return self;
}

- (void)dealloc {
    [_request release];
    [_processor release];
    [_response release];
    [_data release];
    [_error release];
    [super dealloc];
}

#pragma mark - State

- (void)setState:(AEURLRequestOperationState)newState {
    AEURLRequestOperationState oldState = _state;
    
    if ( (newState == AEURLRequestOperationStateExecuting) || (oldState == AEURLRequestOperationStateExecuting) ) {
        [self willChangeValueForKey:@"isExecuting"];
    }
    if (newState == AEURLRequestOperationStateFinished) {
        [self willChangeValueForKey:@"isFinished"];
    }
    _state = newState;
    if (newState == AEURLRequestOperationStateFinished) {
        [self didChangeValueForKey:@"isFinished"];
    }
    if ( (newState == AEURLRequestOperationStateExecuting) || (oldState == AEURLRequestOperationStateExecuting) ) {
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (BOOL)isFinished {
    return [self state] == AEURLRequestOperationStateFinished;
}

- (BOOL)isExecuting {
    return [self state] == AEURLRequestOperationStateExecuting;
}

#pragma mark - NSOperation

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    if ([self isCancelled]) {
        [self setState:AEURLRequestOperationStateFinished];
        return;
    }
    
    static NSOperationQueue *responseQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        responseQueue = [[NSOperationQueue alloc] init];
    });
    
    [self setState:AEURLRequestOperationStateExecuting];
    
    [AEURLConnection sendAsynchronousRequest:[self request] 
                                       queue:responseQueue
                                   processor:[self processor]
                           completionHandler:^(NSURLResponse *response, id data, NSError *error) {
                               [self setResponse:response];
                               [self setData:data];
                               [self setError:error];
                               
                               [self setState:AEURLRequestOperationStateFinished];
                           }];
}

@end
