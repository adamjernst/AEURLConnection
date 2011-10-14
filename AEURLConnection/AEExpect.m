//
//  AEExpect.m
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEExpect.h"

NSString *AEExpectErrorDomain = @"AEExpectErrorDomain";

@implementation AEExpect

+ (NSError *)error:(AEExpectErrorCode)code message:(NSString *)message {
    return [NSError errorWithDomain:AEExpectErrorDomain 
                               code:code
                           userInfo:[NSDictionary dictionaryWithObject:message 
                                                                forKey:NSLocalizedDescriptionKey]];
}

+ (AEURLResponseProcessor)statusCode:(NSIndexSet *)acceptableCodes {
    return [[^(NSURLResponse *response, id data, NSError **error){
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            *error = [AEExpect error:AEExpectResponseNotHTTPError
                             message:@"Response is not HTTP"];
            return nil;
        }
        
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (![acceptableCodes containsIndex:statusCode]) {
            *error = [AEExpect error:AEExpectInvalidStatusCodeError
                             message:[NSString stringWithFormat:@"%@ (HTTP status %d)", 
                                      [NSHTTPURLResponse localizedStringForStatusCode:statusCode], 
                                      statusCode]];
            return nil;
        }
        
        return data;
    } copy] autorelease];
}

+ (NSIndexSet *)defaultAcceptableStatusCodes {
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
}

// Sets an error if the Content-Type header does not match one of the included
// acceptable content types, after removing any "charset" or other parameters.
+ (AEURLResponseProcessor)contentType:(NSSet *)acceptableTypes {
    return [[^(NSURLResponse *response, id data, NSError **error) {
        if (![acceptableTypes containsObject:[response MIMEType]]) {
            *error = [AEExpect error:AEExpectInvalidContentTypeError
                             message:[NSString stringWithFormat:@"Invalid Content-Type %@", [response MIMEType]]];
            return nil;
        }
        
        return data;
    } copy] autorelease];
}

// Sets an error if the passed data is not an instance of a certain class.
// Handy for use after an AEJSONProcessor, if you want to ensure that
// you're getting a dictionary vs. an array.
+ (AEURLResponseProcessor)responseClass:(Class)class {
    return [[^(NSURLResponse *response, id data, NSError **error) {
        if (![data isKindOfClass:class]) {
            *error = [AEExpect error:AEExpectInvalidResponseClassError
                             message:[NSString stringWithFormat:@"Invalid response class %@", NSStringFromClass([data class])]];
            return nil;
        }
        
        return data;
    } copy] autorelease];
}

@end
