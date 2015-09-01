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
#import "APIShaderRepository.h"
#import "ShaderViewController.h"
#import "UIImage+ResizeMagick.h"

#import "SVPullToRefresh.h"
#import "LocalCache.h"
#import "MBProgressHUD.h"
#import "UIBarButtonItem+BlocksKit.h"

#import "Utils.h"

@interface QueryTableViewController ()  {
    APIShadertoy* _client;
    APIShaderRepository* _repository;
    NSString* _sortBy;
    NSArray* _data;
}

@end

@implementation QueryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _client = [[APIShadertoy alloc] init];
    _repository = [[APIShaderRepository alloc] init];
    _data = [[NSArray alloc] init];
    
    UIImage *logo = [[[UIImage imageNamed:@"shadertoy_title"] resizedImageByMagick:@"10000x24"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    __weak QueryTableViewController *weakSelf = self;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] bk_initWithImage:logo style:UIBarButtonItemStylePlain handler:^(id sender) {
        [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }];
    
    self.navigationItem.leftBarButtonItem = item;
}

- (void) setSortBy:(NSString *)sortBy {
    _sortBy = sortBy;
    
    if( [_sortBy isEqualToString:@"popular"] )
        self.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMostViewed tag:1];
    
    if( [_sortBy isEqualToString:@"newest"] )
        self.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMostRecent tag:1];
    
    if( [_sortBy isEqualToString:@"love"] )
        self.navigationController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:1];
}

- (void) viewWillAppear:(BOOL)animated {
    // get data from cache
    _data = [self getDataFromCache];
    if( ![_data count] ) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self reloadData];
    }
    
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    [[self.tableView pullToRefreshView] stopAnimating];
    
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    __weak QueryTableViewController *weakSelf = self;
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf reloadData];
    }];
    
    [super viewDidAppear:animated];
    
    trackScreen([@"QueryTable_" stringByAppendingString:_sortBy]);
}

- (NSArray *) getDataFromCache {
    NSString* dataKey = [@"queryResults" stringByAppendingString:_sortBy];
    NSArray *data = [[LocalCache sharedLocalCache] getObject:dataKey];
    if( !data ) return [[NSArray alloc] init];
    
    dataKey = [@"queryResultsDateCached" stringByAppendingString:_sortBy];
    NSDate *date = [[LocalCache sharedLocalCache] getObject:dataKey];
    
    // reload every x days
    int refreshInterval = [_sortBy isEqualToString:@"newest"]?(1*30*60):(24*60*60);
    if( !date || [date timeIntervalSinceNow] < -refreshInterval ) {
        [self reloadData];
    }
    
    return data;
}

- (void) storeDataToCache:(NSArray *) data {
    NSString* dataKey = [@"queryResults" stringByAppendingString:_sortBy];
    [[LocalCache sharedLocalCache] storeObject:data forKey:dataKey];
    
    dataKey = [@"queryResultsDateCached" stringByAppendingString:_sortBy];
    [[LocalCache sharedLocalCache] storeObject:[NSDate date] forKey:dataKey];
}

- (void) reloadData {
    __weak QueryTableViewController *weakSelf = self;
    [_client getShaderKeys:_sortBy success:^(NSArray *results) {
        _data = results;
        [self storeDataToCache:_data];
        [weakSelf.tableView reloadData];
        [[weakSelf.tableView pullToRefreshView] stopAnimating];
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
    }];
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
    NSString *CellIdentifier = @"reuse"; //[[NSString alloc] initWithFormat:@"queryTableCell-%ld-%ld", (long)indexPath.row, (long)indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (nil == cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"QueryTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    NSString* shaderId = [_data objectAtIndex:indexPath.row];
    
    [((QueryTableViewCell *)cell) layoutForShader:[_repository getShader:shaderId success:^(APIShaderObject *shader) {
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
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController* viewController = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderViewController"];
    
    APIShaderObject* shader = [_repository getShader:shaderId success:^(APIShaderObject *shader) {}];
    [shader cancelShaderRequestOperation];
    
    if( shader.imagePass != NULL ) {
        [((ShaderViewController *)viewController) setShaderObject:shader];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
