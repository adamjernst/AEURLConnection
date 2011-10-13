//
//  AEJSONProcessingBlock.h
//  AEURLExample
//
//  Created by Adam Ernst on 10/13/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AEURLConnection.h"

// AEJSONProcessingBlock requires JSONKit.  You can use AEURLConnection
// without JSONKit; just remove the AEJSONProcessingBlock.m/h files from your
// project, and parse JSON manually.
#import "JSONKit.h"


@interface AEJSONProcessingBlock : NSObject

+ (AEURLConnectionProcessingBlock)JSONProcessingBlock;
+ (AEURLConnectionProcessingBlock)JSONProcessingBlockWithOptions:(JKParseOptionFlags)options;

@end
