//
//  AEExpect.h
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AEURLConnection.h"

extern NSString *AEExpectErrorDomain;

typedef enum {
    AEExpectInvalidStatusCodeError = -101,
    AEExpectResponseNotHTTPError = -102,
    AEExpectInvalidContentTypeError = -103,
    AEExpectInvalidResponseClassError = -104,
} AEExpectErrorCode;

@interface AEExpect : NSObject

// Sets an error if the HTTP status code is not in the provided set.
+ (AEURLResponseProcessor)statusCode:(NSIndexSet *)acceptableCodes;

// All 200 status codes
+ (NSIndexSet *)defaultAcceptableStatusCodes; 

// Sets an error if the Content-Type header does not match one of the included
// acceptable content types, after removing any "charset" or other parameters.
// See [AEJSONProcessor defaultAcceptableJSONContentTypes] for an example set.
+ (AEURLResponseProcessor)contentType:(NSSet *)acceptableTypes;

// Sets an error if the passed data is not an instance of a certain class.
// Handy for use after an AEJSONProcessor, if you want to ensure that
// you're getting a dictionary vs. an array.
+ (AEURLResponseProcessor)responseClass:(Class)class;

@end
