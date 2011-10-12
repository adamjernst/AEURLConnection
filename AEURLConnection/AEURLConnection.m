//
//  AEURLConnection.m
//  AEURLExample
//
//  Created by Adam Ernst on 10/12/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEURLConnection.h"


@interface AEURLConnectionRequest : NSObject
- (id)initWithRequest:(NSURLRequest *)request 
				queue:(NSOperationQueue *)queue
	completionHandler:handler;
@property (nonatomic, retain, readonly) NSURLRequest *request;
@property (nonatomic, retain, readonly) NSOperationQueue *queue;

// handler is readwrite so that we can nil it out after calling it,
// to ensure it is released on |queue| and not on the network thread.
@property (nonatomic, copy, readwrite) void (^handler)(NSURLResponse*, NSData*, NSError*);

@property (nonatomic, retain, readwrite) NSURLConnection *connection;
@property (nonatomic, retain, readwrite) NSURLResponse *response;
@property (nonatomic, retain, readwrite) NSMutableData *data;
@end


@interface AEURLConnectionManager : NSObject {
	NSThread *_networkRequestThread;
	NSMutableArray *_executingRequests;
}
+ (AEURLConnectionManager *)sharedManager;
- (void)startRequest:(AEURLConnectionRequest *)req;
@end


@implementation AEURLConnection

+ (void)sendAsynchronousRequest:(NSURLRequest *)request
                          queue:(NSOperationQueue*)queue
              completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
	AEURLConnectionRequest *req = [[AEURLConnectionRequest alloc] initWithRequest:request queue:queue completionHandler:handler];
	[[AEURLConnectionManager sharedManager] startRequest:req];
	[req release];
}

@end


@implementation AEURLConnectionManager

static AEURLConnectionManager *sharedManager = nil;

+ (AEURLConnectionManager *)sharedManager {
	static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
		sharedManager = [[AEURLConnectionManager alloc] init];
    });
	return sharedManager;
}

- (void)networkRequestThreadEntryPoint:(id)__unused object {
    do {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [[NSRunLoop currentRunLoop] run];
        [pool drain];
    } while (YES);
}

- (id)init {
	self = [super init];
	if (self) {
		_executingRequests = [[NSMutableArray alloc] init];
		
		_networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
		[_networkRequestThread setThreadPriority:0.1];
        [_networkRequestThread start];

	}
    return self;
}

- (void)dealloc {
	[_networkRequestThread release];
	[_executingRequests release];
	[super dealloc];
}

- (void)startRequest:(AEURLConnectionRequest *)req {
	// Can be called from any thread.
	[self performSelector:@selector(networkThreadStartRequest:) 
				 onThread:_networkRequestThread
			   withObject:req 
			waitUntilDone:NO];
}

#define EXPECT_NETWORK_THREAD NSAssert([[NSThread currentThread] isEqual:_networkRequestThread], @"Expected network thread")

- (void)networkThreadStartRequest:(AEURLConnectionRequest *)req {
	EXPECT_NETWORK_THREAD;
	
	// When we get here, |req| should have been freshly created and so its
	// |connection|, |response|, and |data| properties should all be nil.
	NSAssert([req connection] == nil && [req response] == nil && [req data] == nil, 
			 @"Async request started with invalid state");
	
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:[req request] 
																  delegate:self
														  startImmediately:NO];
	[req setConnection:connection];
	[_executingRequests addObject:req];
	
	// Now that the request is safely initialized with |connection| and 
	// stored in |_executingRequests|, start it on the network thread.
	[connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[connection start];
}

- (AEURLConnectionRequest *)executingRequestForConnection:(NSURLConnection *)connection {
	for (AEURLConnectionRequest *req in _executingRequests) {
		if ([req connection] == connection) {
			return req;
		}
	}
	NSAssert(false, @"Couldn't find executing request for a given connection");
	return nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	EXPECT_NETWORK_THREAD;
	
	AEURLConnectionRequest *req = [self executingRequestForConnection:connection];

	// Reset the request's data. From the docs for 
	// connection:didReceiveResponse:, we read:
	
	// In rare cases, for example in the case of an HTTP load where the
	// content type of the load data is multipart/x-mixed-replace, 
	// the delegate will receive more than one 
	// connection:didReceiveResponse: message. In the event this 
	// occurs, delegates should discard all data previously delivered 
	// by connection:didReceiveData:, and should be prepared to handle 
	// the, potentially different, MIME type reported by the newly 
	// reported URL response.
	
	[req setData:[NSMutableData data]];
	[req setResponse:response];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	EXPECT_NETWORK_THREAD;
	
	AEURLConnectionRequest *req = [self executingRequestForConnection:connection];
	// We strongly expect that [req data] is not nil. However I stop 
	// short of asserting it, because according to the docs:

	// Zero or more connection:didReceiveResponse: messages will be 
	// sent to the delegate before receiving a connection:didReceiveData: 
	// message. The only case where connection:didReceiveResponse: is 
	// not sent to a delegate is when the protocol implementation 
	// encounters an error before a response could be created.

	// I am not entirely clear on when you might receive data without
	// first receiving a response. If that happens, though, just drop
	// the data on the floor; since [req data] is nil, that happens
	// automatically.
	[[req data] appendData:data];
}

- (void)executeHandlerForConnection:(NSURLConnection *)connection error:(NSError *)error {
	AEURLConnectionRequest *req = [self executingRequestForConnection:connection];
	
	// It is very important that |handler| is deallocated in the context of
	// |queue|, since doing so has the very nice property of solving the thorny
	// Deallocation Problem:
	// http://developer.apple.com/library/ios/#technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11
	// Note that:
	// - You might create a block that captures |handler|, separately from 
	//   adding it to the queue, and call setHandler:nil between creating that
	//   block and adding it to the queue, in an attempt to ensure |handler|
	//   is deallocated on |queue|. However this won't work since the block you
	//   create will be stack-allocated, and thus won't retain |handler|
	//   until you copy the block. When you call setHandler:nil the handler
	//   will be deallocated, with the stack-allocated block left holding
	//   a  bad reference.
	//   If you copy the block, though, you'll be right back at square 
	//   one: you have to release it after adding it to the queue, but then
	//   you race with the block's completion on |queue| for releasing the
	//   last reference to the block.
	// - If you just naively reference [req handler] in the block, |req| itself
	//   will be captured. Again, however, you need to release |req| after
	//   either copying the block or adding it to the queue, introducing
	//   the same race condition.
	
	// So, create a __block variable with a copy of the handler. This prevents
	// any kind of variable capture for |handler| itself.
	__block void (^handler)(NSURLResponse *, NSData *, NSError *) = [[req handler] copy];
	// Now call setHandler:nil on |req|. This should release our last retaining
	// reference to |handler| EXCEPT for the __block variable.
	[req setHandler:nil];
	// Now |handler| is at +1 retain count. Have it release on |queue| after
	// executing. That guarantees our last reference is released on |queue|.
	
	// Note that the block below captures |req|. That is OK since |req| no 
	// longer has a reference to |handler| (since we called setHandler:nil).
	
	[[req queue] addOperationWithBlock:^{
		handler([req response], error ? nil : [req data], error);
		[handler release];
	}];
	
	// Don't remove |req| from |_executingRequests| until this point. Since
	// the array is the last retaining reference to |req|, removing it sooner 
	// will deallocate |req| (and cause us to crash when we try to access its 
	// properties).
	[_executingRequests removeObject:req];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	EXPECT_NETWORK_THREAD;
	[self executeHandlerForConnection:connection error:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	EXPECT_NETWORK_THREAD;
	[self executeHandlerForConnection:connection error:nil];
}

@end


@implementation AEURLConnectionRequest

@synthesize request=_request;
@synthesize queue=_queue;
@synthesize handler=_handler;

@synthesize connection=_connection;
@synthesize response=_response;
@synthesize data=_data;

- (id)initWithRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(id)handler {
	self = [super init];
	if (self) {
		_request = [request retain];
		_queue = [queue retain];
		_handler = [handler copy];
	}
	return self;
}

- (void)dealloc {
	[_request release];
	[_queue release];
	[_handler release];
	[_response release];
	[_data release];
	[super dealloc];
}

@end

