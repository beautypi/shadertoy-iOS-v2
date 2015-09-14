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
    UISearchBar* _searchBar;
    NSString* _searchQuery;
    AFHTTPRequestOperation* _currentAFRequestOperation;
    BOOL _searchMode;
}
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchBarButtonItem;

@end

@implementation QueryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _client = [[APIShadertoy alloc] init];
    _repository = [[APIShaderRepository alloc] init];
    _data = [[NSArray alloc] init];
    _searchMode = NO;
    
    [self showLogo];
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
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    if( ![self isInSearchMode] ) {
        [self loadData];
    }
    
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    [[self.tableView pullToRefreshView] stopAnimating];
    
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
    __weak QueryTableViewController *weakSelf = self;
    
    [self.tableView addPullToRefreshWithActionHandler:^{
        if( [weakSelf isInSearchMode] ) {
            [weakSelf reloadSearchData];
        } else {
            [weakSelf reloadData];
        }
    }];
    
    [super viewDidAppear:animated];
    
    trackScreen([@"QueryTable_" stringByAppendingString:_sortBy]);
}

- (void) loadData {
    // get data from cache
    _data = [self getDataFromCache];
    if( ![_data count] ) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self reloadData];
    }
    [self.tableView reloadData];
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
    [_currentAFRequestOperation cancel];
    __weak QueryTableViewController *weakSelf = self;
    _currentAFRequestOperation = [_client getShaderKeys:_sortBy success:^(NSArray *results) {
        _data = results;
        [self storeDataToCache:_data];
        [weakSelf.tableView reloadData];
        [[weakSelf.tableView pullToRefreshView] stopAnimating];
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
    }];
}

- (void) reloadSearchData {
    [_currentAFRequestOperation cancel];
    __weak QueryTableViewController *weakSelf = self;
    _currentAFRequestOperation = [_client getShaderKeys:_sortBy query:_searchQuery success:^(NSArray *results) {
        _data = results;
        [weakSelf.tableView reloadData];
        [[weakSelf.tableView pullToRefreshView] stopAnimating];
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
        if( [_data count] ) {
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }];
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Search functions

- (void) showLogo {
    UIImage *logo = [[[UIImage imageNamed:@"shadertoy_title"] resizedImageWithMaximumSize:CGSizeMake(10000,24)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    __weak QueryTableViewController *weakSelf = self;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] bk_initWithImage:logo style:UIBarButtonItemStylePlain handler:^(id sender) {
        if( [_data count] ) {
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }];
    self.navigationItem.leftBarButtonItem = item;
}

- (UISearchBar *) showSearchBar {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 88, 44)];
    UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:searchBar];
    [self.navigationItem setLeftBarButtonItem:searchBarItem animated:YES];
    return searchBar;
}

- (IBAction) searchButtonClick:(id)sender {
    _searchMode = YES;
    
    _searchBar = [self showSearchBar];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSearchButtonClick:)] animated:YES];
    
    [_searchBar becomeFirstResponder];
    [_searchBar setDelegate:self];
    
    [_currentAFRequestOperation cancel];
    [[self.tableView pullToRefreshView] stopAnimating];
    
    
    _data = [[NSArray alloc] init];
    [self.tableView reloadData];
}

- (IBAction) cancelSearchButtonClick:(id)sender {
    _searchMode = NO;
    
    _searchBar = nil;
    [self showLogo];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonClick:)] animated:YES];
    [self loadData];
    if( [_data count] ) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void) search:(NSString *)query {
    _searchQuery = query;
}

- (BOOL) isInSearchMode {
    return _searchMode;
}

#pragma mark - Searchbar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_searchBar resignFirstResponder];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self reloadSearchData];
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self search:searchText];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
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
    if( _searchBar && [_searchBar isFirstResponder] ) {
        [_searchBar resignFirstResponder];
        return;
    }
    
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
