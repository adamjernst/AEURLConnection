//
//  AEURLRequestFactory.h
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^AEURLParameterProcessor)(NSDictionary *parameters, NSMutableURLRequest *targetRequest);

@interface AEURLRequestFactory : NSObject {
    NSMutableDictionary *_defaultHeaderValues;
}

// A singleton request factory. If you set any default header values on this 
// factory, they persist to future uses.
+ (AEURLRequestFactory *)defaultFactory;

// This method puts parameters in the query string if method is GET; otherwise,
// it puts them in the HTTP body as x-www-form-urlencoded (just like a browser-
// submitted POST form).
// Need to modify the returned request further? Just use -mutableCopy.
- (NSURLRequest *)requestWithURL:(NSURL *)url 
                          method:(NSString *)method 
                      parameters:(NSDictionary *)parameters;

// You can pass any block to put the parameters into the generated request: e.g.
// [AEJSONProcessor JSONParameterProcessor], or you could write your own for 
// XML, plist, or other encodings.
- (NSURLRequest *)requestWithURL:(NSURL *)url
                          method:(NSString *)method 
                      parameters:(NSDictionary *)parameters
              parameterProcessor:(AEURLParameterProcessor)parameterProcessor;

- (NSString *)defaultValueForHeader:(NSString *)header;
- (void)setDefaultValue:(NSString *)value forHeader:(NSString *)header;

// Use this utility functions with setDefaultValue:forHeader:, passing
// "Authorization" for the header.
+ (NSString *)authorizationHeaderForUsername:(NSString *)username password:(NSString *)password;

// A parameter processing block that puts the parameters into the query string
// (usually for GET requests).
+ (AEURLParameterProcessor)queryStringProcessor;

// A parameter processing block that puts the parameters into the HTTP body in
// x-www-form-urlencoded format, like a browser's POST form encoding.
+ (AEURLParameterProcessor)formURLEncodedProcessor;

// See AEJSONProcessor for a parameter processing block that creates JSON.

@end
