//
//  AEURLRequestFactory.m
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEURLRequestFactory.h"

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
    return [NSString stringWithFormat:@"Basic %@", AEBase64EncodedStringFromData([[NSString stringWithFormat:@"%@:%@", username, password] dataUsingEncoding:NSUTF8StringEncoding])];
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

@end

#pragma mark - URLEncoding

// These functions are based on AFNetworking's equivalents (substituting AE for
// AF in the function prefix to prevent linker conflicts). Thanks AFNetworking!
// (Used with permission.)

NSString *AEURLEncodedStringFromString(NSString *string) {
    static NSString * const kAELegalCharactersToBeEscaped = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\|~ ";
    
    return [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, (CFStringRef)kAELegalCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease];
}

NSString *AEQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutableParameterComponents = [NSMutableArray array];
    for (id key in [parameters allKeys]) {
        NSString *component = [NSString stringWithFormat:@"%@=%@", AEURLEncodedStringFromString([key description]), AEURLEncodedStringFromString([[parameters valueForKey:key] description])];
        [mutableParameterComponents addObject:component];
    }
    
    return [mutableParameterComponents componentsJoinedByString:@"&"];
}

// AEStringFromURLEncodedString and AEParametersFromQueryString
// are loosely based on Google Web Toolkit.

NSString *AEStringFromURLEncodedString(NSString *formEncodedString) {
    NSMutableString *resultString = [NSMutableString stringWithString:formEncodedString];
    [resultString replaceOccurrencesOfString:@"+"
                                  withString:@" "
                                     options:NSLiteralSearch
                                       range:NSMakeRange(0, [resultString length])];
    return [resultString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

NSDictionary *AEParametersFromQueryString(NSString *queryString) {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    // Use reverse order so that the first occurrence of a key replaces later ones.
    [components enumerateObjectsWithOptions:NSEnumerationReverse
                                 usingBlock:^(id component, NSUInteger idx, BOOL *stop) {
                                     if ([component length] == 0) return;
                                     
                                     NSRange pos = [component rangeOfString:@"="];
                                     NSString *key;
                                     NSString *val;
                                     if (pos.location == NSNotFound) {
                                         key = AEStringFromURLEncodedString(component);
                                         val = @"";
                                     } else {
                                         key = AEStringFromURLEncodedString([component substringToIndex:pos.location]);
                                         val = AEStringFromURLEncodedString([component substringFromIndex:pos.location + pos.length]);
                                     }
                                     // stringByUnescapingQueryString returns nil on invalid UTF8
                                     // and NSMutableDictionary raises an exception when passed nil values.
                                     if (!key) key = @"";
                                     if (!val) val = @"";
                                     [ret setObject:val forKey:key];
                                 }];
    return ret;
}

NSString * AEBase64EncodedStringFromData(NSData *data) {
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
        
        static uint8_t const kAEBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAEBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAEBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAEBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAEBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding] autorelease];
}

NSData *AEDataFromBase64EncodedString(NSString *base64) {
	// Adapted from NSData+Base64; Thanks, Matt Gallagher!
    // http://cocoawithlove.com/2009/06/base64-encoding-options-on-mac-and.html
	const char *input = [base64 cStringUsingEncoding:NSUTF8StringEncoding];
	unsigned long length = strlen(input);
	NSMutableData *output = [NSMutableData dataWithCapacity:((length + 3) / 4) * 3];
	
	//
	// Definition for "masked-out" areas of the base64DecodeLookup mapping
	//
	static const unsigned char xx = 65;
	
	//
	// Mapping from ASCII character to 6 bit pattern.
	//
	static unsigned char base64DecodeLookup[256] =
	{
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 62, xx, xx, xx, 63, 
		52, 53, 54, 55, 56, 57, 58, 59, 60, 61, xx, xx, xx, xx, xx, xx, 
		xx,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 
		15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, xx, xx, xx, xx, xx, 
		xx, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 
		41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
		xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
	};
	
	size_t i = 0;
	size_t j = 0;
	while (i < length)
	{
		//
		// Accumulate 4 valid characters (ignore everything else)
		//
		unsigned char accumulated[4];
		size_t accumulateIndex = 0;
		while (i < length)
		{
			unsigned char decode = base64DecodeLookup[input[i++]];
			if (decode != xx)
			{
				accumulated[accumulateIndex] = decode;
				accumulateIndex++;
				
				if (accumulateIndex == 4) break;
			}
		}
		
        for (int k = 0; k < accumulateIndex - 1; k++) {
            uint8_t byte = (accumulated[k] << (k + 1) * 2) | (accumulated[k + 1] >> (2 - k) * 2);
			[output appendBytes:&byte length:1];
        }
		j += accumulateIndex - 1;
	}
	
	return output;
}
