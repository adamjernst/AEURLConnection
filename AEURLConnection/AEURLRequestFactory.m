//
//  AEURLRequestFactory.m
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEURLRequestFactory.h"

// Forward declarations:
static NSString * AEURLEncodedStringFromString(NSString *string);
static NSString * AEQueryStringFromParameters(NSDictionary *parameters);
static NSString * AEBase64EncodedStringFromString(NSString *string);

@implementation AEURLRequestFactory

+ (AEURLRequestFactory *)defaultFactory {
    static AEURLRequestFactory *defaultFactory;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultFactory = [[AEURLRequestFactory alloc] init];
    });
    return defaultFactory;
}

- (id)init {
    self = [super init];
    if (self) {
        _defaultHeaderValues = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_defaultHeaderValues release];
    [super dealloc];
}

- (NSURLRequest *)requestWithURL:(NSURL *)url
                          method:(NSString *)method 
                      parameters:(NSDictionary *)parameters {
    AEURLParameterProcessor processor = nil;
    if ([method isEqualToString:@"GET"]) {
        processor = [AEURLRequestFactory queryStringProcessor];
    } else {
        processor = [AEURLRequestFactory formURLEncodedProcessor];
    }
    return [self requestWithURL:url method:method parameters:parameters parameterProcessor:processor];
}

- (NSURLRequest *)requestWithURL:(NSURL *)url
                          method:(NSString *)method 
                      parameters:(NSDictionary *)parameters
        parameterProcessor:(AEURLParameterProcessor)parameterProcessor {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:_defaultHeaderValues];
    parameterProcessor(parameters, request);
    return request;
}

#pragma mark - Default Header Values

- (NSString *)defaultValueForHeader:(NSString *)header {
    return [_defaultHeaderValues objectForKey:header];
}

- (void)setDefaultValue:(NSString *)value forHeader:(NSString *)header {
    [_defaultHeaderValues setObject:value forKey:header];
}

#pragma mark - Authorization Header Generation

+ (NSString *)authorizationHeaderForUsername:(NSString *)username password:(NSString *)password {
    return [NSString stringWithFormat:@"Basic %@", AEBase64EncodedStringFromString([NSString stringWithFormat:@"%@:%@", username, password])];
}

#pragma mark - Parameter Encoding Blocks

+ (AEURLParameterProcessor)queryStringProcessor {
    static AEURLParameterProcessor queryStringProcessor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queryStringProcessor = [^(NSDictionary *parameters, NSMutableURLRequest *targetRequest){
            NSString *oldURL = [[targetRequest URL] absoluteString];
            NSURL *newURL = [NSURL URLWithString:[oldURL stringByAppendingFormat:[oldURL rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", AEQueryStringFromParameters(parameters)]];
            [targetRequest setURL:newURL];
        } copy];
    });
    return queryStringProcessor;
}

+ (AEURLParameterProcessor)formURLEncodedProcessor {
    static AEURLParameterProcessor formURLEncodedProcessor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formURLEncodedProcessor = [^(NSDictionary *parameters, NSMutableURLRequest *targetRequest){
            [targetRequest setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
            [targetRequest setHTTPBody:[AEQueryStringFromParameters(parameters) dataUsingEncoding:NSUTF8StringEncoding]];
        } copy];
    });
    return formURLEncodedProcessor;
}

#pragma mark - URLEncoding

// These functions are based on AFNetworking's equivalents (substituting AE for
// AF in the function prefix to prevent linker conflicts). Thanks AFNetworking!
// (Used with permission.)

static NSString * AEURLEncodedStringFromString(NSString *string) {
    static NSString * const kAFLegalCharactersToBeEscaped = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\|~ ";
    
    return [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, (CFStringRef)kAFLegalCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease];
}

static NSString * AEQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutableParameterComponents = [NSMutableArray array];
    for (id key in [parameters allKeys]) {
        NSString *component = [NSString stringWithFormat:@"%@=%@", AEURLEncodedStringFromString([key description]), AEURLEncodedStringFromString([[parameters valueForKey:key] description])];
        [mutableParameterComponents addObject:component];
    }
    
    return [mutableParameterComponents componentsJoinedByString:@"&"];
}

static NSString * AEBase64EncodedStringFromString(NSString *string) {
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string length]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]); 
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding] autorelease];
}

@end
