//
//  AEURLExampleTests.m
//  AEURLExampleTests
//
//  Created by Adam Ernst on 10/12/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEURLExampleTests.h"
#import "AEURLConnection.h"
#import "AEURLRequestFactory.h"

// This object simulates UIViewController, which can only be released on the 
// main thread. (This is the root of "The Deallocation Problem"; search the 
// web for more.)
@interface AEMainThreadReleaseOnlyObject : NSObject {
    BOOL *gotResponse;
    BOOL *dealloced;
    BOOL *deallocedOnMainThread;
}
- (id)initWithGotResponse:(BOOL *)g dealloced:(BOOL *)d onMainThread:(BOOL *)main;
- (void)handleResponse:(NSURLResponse *)response;
@end

@implementation AEURLExampleTests

- (void)testMainThreadReleaseOnlyObject {
    NSAssert([NSThread isMainThread], @"Expected unit test to run on main thread");
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com/"] 
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                         timeoutInterval:20.0];
    
    BOOL gotResponse = NO;
    BOOL dealloced = NO;
    BOOL deallocedOnMainThread = NO;
    AEMainThreadReleaseOnlyObject *obj;
    obj = [[AEMainThreadReleaseOnlyObject alloc] initWithGotResponse:&gotResponse 
                                                           dealloced:&dealloced 
                                                        onMainThread:&deallocedOnMainThread];
    
    [AEURLConnection sendAsynchronousRequest:request 
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [obj handleResponse:response];
                           }];
    [obj release];
    NSAssert(!dealloced, @"Object shouldn't be dealloced yet; should be dealloced during running of runloop");
    
    int runs = 0;
    while (dealloced == NO && runs < 20) {
        NSLog(@"Running main run loop since object isn't deallocated yet");
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
        runs++;
    }
    
    if (!gotResponse) {
        STFail(@"Completion handler never called, although timeout should have expired so we should have received response or error");
    } else if (!dealloced) {
        STFail(@"Object captured in completion handler was never released");
    } else if (!deallocedOnMainThread) {
        STFail(@"Main-thread-release-only object was dealloced, but not on main thread");
    }
}

- (void)testQueryStringEncode {
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"", @"empty_value",
                       @"blah", @"boring_value",
                       @"†éß†", @"aççén†é∂", nil];
    NSString *s = AEQueryStringFromParameters(d);
    NSDictionary *d2 = AEParametersFromQueryString(s);
    
    STAssertEqualObjects(d, d2, @"Query string encoding or decoding failed");
}

- (void)testBase64 {
    static const int kTestLength = 2043;
    NSMutableData *testData = [NSMutableData dataWithCapacity:kTestLength];
    srand(494020102);
    for (int i = 0; i < kTestLength / 4; i++) { 
        u_int32_t randomBits = rand();
        [testData appendBytes:(void*)&randomBits length:4];
    }
    
    NSString *base64Value = AEBase64EncodedStringFromData(testData);
    NSData *decodedValue = AEDataFromBase64EncodedString(base64Value);
    STAssertEqualObjects(testData, decodedValue, @"Base 64 encoding or decoding failed");
}

@end


@implementation AEMainThreadReleaseOnlyObject

- (id)initWithGotResponse:(BOOL *)g dealloced:(BOOL *)d onMainThread:(BOOL *)main {
    if (self = [super init]) {
        gotResponse = g;
        dealloced = d;
        deallocedOnMainThread = main;
    }
    return self;
}

- (void)dealloc {
    *deallocedOnMainThread = [NSThread isMainThread];
    *dealloced = YES;
    [super dealloc];
}

- (void)handleResponse:(NSURLResponse *)response {
    *gotResponse = YES;
}

@end
