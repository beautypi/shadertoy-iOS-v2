//
//  MainTabBarController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "MainTabBarController.h"
#import "QueryTableViewController.h"
#import "AboutViewController.h"

@interface MainTabBarController ()

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController* viewController1 = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"NavigationController"];
    UIViewController* viewController2 = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"NavigationController"];
    UIViewController* viewController3 = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"NavigationController"];
    UIViewController* viewController4 = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"AboutNavigationController"];
    
    [((QueryTableViewController *)[[viewController1 childViewControllers] objectAtIndex:0]) setSortBy:@"popular"];
    [((QueryTableViewController *)[[viewController2 childViewControllers] objectAtIndex:0]) setSortBy:@"newest"];
    [((QueryTableViewController *)[[viewController3 childViewControllers] objectAtIndex:0]) setSortBy:@"love"];
    [((AboutViewController *)[[viewController4 childViewControllers] objectAtIndex:0]) initTabBarItem];
    
    [self setViewControllers:[[NSArray alloc] initWithObjects:viewController1, viewController2, viewController3, viewController4, nil]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
