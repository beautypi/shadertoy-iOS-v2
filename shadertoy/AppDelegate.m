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

@interface AppDelegate () {
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // ff8020
    self.window.tintColor = [UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f];
    [[UITabBar appearance] setBarTintColor:[UIColor darkGrayColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor darkGrayColor]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    if( [[LocalCache sharedLocalCache] getVersion] < [NSNumber numberWithInt:3]) {
        [[LocalCache sharedLocalCache] clear];
        [[LocalCache sharedLocalCache] setVersion:[NSNumber numberWithInt:3]];
    }
        
    if( ![GoogleAnalyticsKey isEqualToString:@""] ) {
        [GAI sharedInstance].trackUncaughtExceptions = YES;
        [[GAI sharedInstance] trackerWithTrackingId:GoogleAnalyticsKey];
        [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:NO];
    }
    
    [Fabric with:@[CrashlyticsKit]];
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
