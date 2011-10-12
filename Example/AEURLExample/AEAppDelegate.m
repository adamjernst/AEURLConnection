//
//  AEAppDelegate.m
//  AEURLExample
//
//  Created by Adam Ernst on 10/12/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import "AEAppDelegate.h"

#import "AEViewController.h"

@implementation AEAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize navigationController = _navigationController;

- (void)dealloc {
	[_window release];
	[_viewController release];
	[_navigationController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	self.viewController = [[[AEViewController alloc] initWithNibName:@"AEViewController" bundle:nil] autorelease];;
	self.navigationController = [[[UINavigationController alloc] initWithRootViewController:self.viewController] autorelease];
	self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
