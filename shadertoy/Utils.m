//
//  Utils.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 31/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "Utils.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

void trackEvent( NSString *category, NSString *action, NSString *label ) {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category    // Event category (required)
                                                      action:action
                                                       label:label           // Event label
                                                       value:nil] build]];   // Event value
}

void trackScreen( NSString *screen ) {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screen];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}