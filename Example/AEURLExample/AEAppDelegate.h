//
//  AEAppDelegate.h
//  AEURLExample
//
//  Created by Adam Ernst on 10/12/11.
//  Copyright (c) 2011 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AEViewController;

@interface AEAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AEViewController *viewController;
@property (strong, nonatomic) UINavigationController *navigationController;

@end
