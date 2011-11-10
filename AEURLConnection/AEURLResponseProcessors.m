//
//  AEURLResponseProcessors.m
//  Turntable
//
//  Created by Adam Ernst on 11/10/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEURLResponseProcessors.h"

NSString *AEURLResponseProcessorsErrorDomain = @"AEURLResponseProcessorsErrorDomain";

@implementation AEURLResponseProcessors

+ (AEURLResponseProcessor)imageResponseProcessor {
    return [[^(NSURLResponse *response, id data, NSError **error) {
        UIImage *image = [[[UIImage alloc] initWithData:data] autorelease];
        if (!image) {
            if (error) {
                *error = [NSError errorWithDomain:AEURLResponseProcessorsErrorDomain
                                             code:AEURLResponseProcessorsErrorImageDecodingFailed
                                         userInfo:nil];
            }
            return nil;
        }
        return image;
    } copy] autorelease];
}

+ (AEURLResponseProcessor)chainedResponseProcessor:(AEURLResponseProcessor)firstProcessor, ... {
    NSMutableArray *processors = [NSMutableArray array];
    va_list args;
    va_start(args, firstProcessor);
    for (AEURLResponseProcessor processor = firstProcessor; processor != nil; processor = va_arg(args, AEURLResponseProcessor)) {
        [processors addObject:[[processor copy] autorelease]];
    }
    
    return [[^(NSURLResponse *response, id data, NSError **error) {
        id newData = data;
        for (AEURLResponseProcessor processor in processors) {
            newData = processor(response, newData, error);
            if (*error) {
                NSAssert(newData == nil, @"Expected data or error but not both");
                return nil;
            }
        }
        return newData;
    } copy] autorelease];
}

@end
