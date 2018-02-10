//
//  AppDelegate.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "AppDelegate.h"

#import <GoogleAnalytics/GAI.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "defines.h"
#import "LocalCache.h"

#import "MainTabBarController.h"
#import "QueryTableViewController.h"
#import "APIShaderRepository.h"

@interface AppDelegate () {
}
@end

@implementation AppDelegate

- (void)initApp {
    // ff8020
    self.window.tintColor = [UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f];
    [[UITabBar appearance] setBarTintColor:[UIColor darkGrayColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor darkGrayColor]];
    
    if( [[LocalCache sharedLocalCache] getVersion] < [NSNumber numberWithInt:5]) {
        [[LocalCache sharedLocalCache] clear];
        [[LocalCache sharedLocalCache] setVersion:[NSNumber numberWithInt:5]];
    }
    
    if( ![GoogleAnalyticsKey isEqualToString:@""] ) {
        [GAI sharedInstance].trackUncaughtExceptions = YES;
        [[GAI sharedInstance] trackerWithTrackingId:GoogleAnalyticsKey];
        [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:NO];
    }
    
    [Fabric with:@[CrashlyticsKit]];
}

- (void)handleURL:(NSURL *)url {
    if( url ) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSArray<NSString *> *pathComponents = [url pathComponents];
            if( [pathComponents count] >= 3 ) {
                NSString* shaderId = [pathComponents objectAtIndex:2];

                MainTabBarController* mainTabBarController = (MainTabBarController *)self.window.rootViewController;
                [mainTabBarController setSelectedIndex:0];
                
                UINavigationController* navigationController = [mainTabBarController.viewControllers objectAtIndex:0];
                [navigationController popToRootViewControllerAnimated:NO];
                
                QueryTableViewController* queryTableViewController = [navigationController.childViewControllers objectAtIndex:0];
                
                [[[APIShaderRepository alloc] init] getShader:shaderId success:^(APIShaderObject *shader) {
                    [queryTableViewController navigateToShader:shaderId];
                }];
            }
        });
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initApp];
    [self handleURL:[launchOptions objectForKey:@"url"]];
    
    return YES;
}


-(BOOL) application:(UIApplication * )application openURL:(NSURL * )url sourceApplication:(NSString * )sourceApplication annotation:(id)annotation {
    [self handleURL:url];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
