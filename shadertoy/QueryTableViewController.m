//
//  QueryTableViewController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "QueryTableViewController.h"
#import "APIShadertoy.h"
#import "QueryTableViewCell.h"
#import "ShaderRepository.h"
#import "ShaderViewController.h"

@interface QueryTableViewController ()  {
    APIShadertoy* _client;
    ShaderRepository* _repository;
    NSArray* _data;
}

@end

@implementation QueryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _client = [[APIShadertoy alloc] init];
    _repository = [[ShaderRepository alloc] init];
    _data = [[NSArray alloc] init];
}

- (void) viewWillAppear:(BOOL)animated {
    [_client getShaderKeys:@"newest" success:^(NSArray *results) {
        _data = results;
        [self.tableView reloadData];
    }];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [_data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = [[NSString alloc] initWithFormat:@"queryTableCell-%ld-%ld", (long)indexPath.row, (long)indexPath.section];
 //   CellIdentifier = @"reuse";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"QueryTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    NSString* shaderId = [_data objectAtIndex:indexPath.row];
    
    [((QueryTableViewCell *)cell) layoutForShader:[_repository getShader:shaderId success:^(ShaderObject *shader) {
        [((QueryTableViewCell *)cell) layoutForShader:shader];
    }]];

    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:YES];
    
    NSString* shaderId = [_data objectAtIndex:indexPath.row];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    UIViewController* viewController = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderViewController"];

    [((ShaderViewController *)viewController) setShaderObject:[_repository getShader:shaderId success:^(ShaderObject *shader) {}]];
    
    [self.navigationController pushViewController:viewController animated:YES];
    
}



@end
