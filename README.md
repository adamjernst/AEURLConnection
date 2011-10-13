# AEURLConnection #
## Effortless, safe block-based URL requests ##

iOS 5 introduces [sendAsynchronousRequest:queue:completionHandler:](http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURLConnection_Class/Reference/Reference.html#//apple_ref/occ/clm/NSURLConnection/sendAsynchronousRequest:queue:completionHandler:),
a great new API that makes it easy to dispatch a `NSURLRequest` and safely 
receive a callback when it finishes.

`AEURLConnection` is a simple reimplementation of the API for use on iOS 4.
Used properly, it is also guaranteed to be safe against [The Deallocation Problem](http://developer.apple.com/library/ios/technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11),
a thorny threading issue that affects most other networking libraries.

## How do I use it? ##

1. Construct an `NSURLRequest`.
2. Send it like this:
        [AEURLConnection sendAsynchronousRequest:request 
                                           queue:[NSOperationQueue mainQueue] 
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            // Handle the response, or error.
        }];
3. That's all there is!

## What's this "Deallocation Problem"? ##

explanation to come.

## Don't I want to use an `NSOperation`? ##
Almost certainly not.

Most other Cocoa networking libraries (like [ASIHTTPRequest](http://allseeing-i.com/ASIHTTPRequest/) and [AFNetworking](https://github.com/gowalla/AFNetworking))
have seized on the idea of using `NSOperation` to encapsulate a network 
operation. This is appealing; fetching something from a network is operation-like,
so why not use `NSOperation`?

