# AEURLConnection #
## Effortless, safe block-based URL requests ##

iOS 5 introduces [sendAsynchronousRequest:queue:completionHandler:](http://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURLConnection_Class/Reference/Reference.html#//apple_ref/occ/clm/NSURLConnection/sendAsynchronousRequest:queue:completionHandler:),
a great new API that makes it easy to dispatch a `NSURLRequest` and safely 
receive a callback when it finishes.

`AEURLConnection` is a simple reimplementation of the API for use on iOS 4.
Used properly, it is also guaranteed to be safe against [The Deallocation Problem](http://developer.apple.com/library/ios/technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11),
a thorny threading issue that affects most other networking libraries.

## How do I use it? ##

    [AEURLConnection sendAsynchronousRequest:request 
                                       queue:[NSOperationQueue mainQueue] 
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        // Handle the response, or error.
    }];

## What's this "Deallocation Problem"? ##

[Read up on it here.](http://developer.apple.com/library/ios/technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11)
If you are making asynchronous network requests from a `UIViewController`, 
your app almost certainly **will crash** under certain circumstances. (Of
course, you shouldn't be calling the network from `UIViewController` if
you're implementing MVC properly, but that's another story!) Here's a
short summary:

1. UIViewController **must** be deallocated on the main thread.
2. Depending on how you are issuing asynchronous network requests, it is 
   likely that your `UIViewController` is being retained by a background
   thread.
     * If you're using `-performSelectorInBackground:withObject:` and then 
       calling `+sendSynchronousRequest:returningResponse:error:`, you are 
       spawning a background thread that retains `UIViewController` since it
       is the target of the invocation.
     * If you're using `NSOperation` in any way—e.g. 
       [ASIHTTPRequest](http://allseeing-i.com/ASIHTTPRequest/) or 
       `AFHTTPRequestOperation` from 
       [AFNetworking](https://github.com/gowalla/AFNetworking)—you're almost 
       certainly retaining your `UIViewController`, unless you have total 
       separation between the controller and a model layer that never lets
       the controller see a secondary thread. If you set a `completionBlock` 
       on an operation that references the view controller, or reference the 
       view controller from an AFNetworking success/failure block, you're 
       retaining the controller on a background thread.
3. If the background thread is the last object to release your 
   `UIViewController`, your app will crash.
     * This can happen if the user pops a view controller (by tapping the 
       back button) before a running operation completes. 
     * To see it in action, open your app on a slow network connection. Open
       a view that loads data from the network, then immediately press back.
       If you're vulnerable, your app will crash.

It's a nasty problem that's extremely difficult to work around. If you're 
using an `NSOperation`, the only way to prevent it is to:

* Never reference `self` or any ivars in the completion block
* Create a `__block id blockSelf` variable to refer to `self`, like so:

        block id blockSelf = [self retain];
        [myOperation setCompletionBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [blockSelf operationFinishedWithData:[myOperation data]];
                [blockSelf release];
            }
            // Prevent retain cycle since completionBlock references
            // myOperation
            [myOperation setCompletionBlock:nil];
        }];

Or, the simpler option: **don't use `NSOperation` at all**. Instead use 
`AEURLConnection`.

## How does AEURLConnection solve the problem? ##

First, it allows you to specify a queue that you want to receive the response 
on, instead of giving it to you on a random background thread. Most of the
time you'll want to specify `[NSOperationQueue mainQueue]`, which will execute 
the completion handler on the main thread.

Second, the `completionHandler` block is guaranteed to be *released* on that 
same queue. This means you can capture `UIViewControllers` willy-nilly without
worrying; the `completionHandler`, and thus all the view controllers it 
captures, will safely be released on the main thread.

## When should I use an `NSOperation`? ##

You might need to use an `NSOperation` if:

1. You need to limit the number of requests being issued simultaneously.
2. You need the ability to cancel a request, or get the request progress.
3. You need to download large files. `NSURLConnectionDownloadDelegate` provides
   a better solution for this, but it's iOS 5 only.

I'm working on a solution for number 2 that allows you to pass an
`options` dictionary with blocks for progress updates, and returning an object
to the caller that can be canceled.
