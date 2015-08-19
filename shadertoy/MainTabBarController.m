//
//  MainTabBarController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "MainTabBarController.h"
#import "QueryTableViewController.h"

@interface MainTabBarController ()

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController* viewController1 = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"NavigationController"];
    UIViewController* viewController2 = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"NavigationController"];
    UIViewController* viewController3 = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"NavigationController"];
    
    [((QueryTableViewController *)[[viewController1 childViewControllers] objectAtIndex:0]) setSortBy:@"popular"];
    [((QueryTableViewController *)[[viewController2 childViewControllers] objectAtIndex:0]) setSortBy:@"newest"];
    [((QueryTableViewController *)[[viewController3 childViewControllers] objectAtIndex:0]) setSortBy:@"love"];
    
    
    [self setViewControllers:[[NSArray alloc] initWithObjects:viewController1, viewController2, viewController3, nil]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
