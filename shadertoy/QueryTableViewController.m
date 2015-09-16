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
#import "NSObject+BKBlockExecution.h"

@interface QueryTableViewController ()  {
    APIShadertoy* _client;
    APIShaderRepository* _repository;
    NSString* _sortBy;
    NSArray* _data;
    
    AFHTTPRequestOperation* _currentAFRequestOperation;
    
    UISearchBar*    _searchBar;
    NSString*       _searchQuery;
    id              _searchBlockTimer;
    
    QueryTableMode _queryTableMode;
}
@property (strong, nonatomic) IBOutlet UIBarButtonItem *searchBarButtonItem;

@end

@implementation QueryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _client = [[APIShadertoy alloc] init];
    _repository = [[APIShaderRepository alloc] init];
    _data = [[NSArray alloc] init];
    _queryTableMode = QUERY_NORMAL;
    
    [self switchQueryTableMode:QUERY_NORMAL];
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
    [self cancelRequests];
    
    if( [self getQueryTableMode] == QUERY_NORMAL ) {
        [self loadNormalData];
    }
    
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    [[self.tableView pullToRefreshView] stopAnimating];
    
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
    __weak QueryTableViewController *weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf reloadData];
    }];
    
    [super viewDidAppear:animated];
    
    trackScreen([@"QueryTable_" stringByAppendingString:_sortBy]);
}

- (void) loadNormalData {
    // get data from cache
    _data = [self getDataFromCache];
    if( ![_data count] ) {
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
    if( ![_data count] ) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    __weak QueryTableViewController *weakSelf = self;
    
    if( [self getQueryTableMode] == QUERY_NORMAL ) {
        _currentAFRequestOperation = [_client getShaderKeys:_sortBy success:^(NSArray *results) {
            [weakSelf setDataIsLoaded:results];
            [self storeDataToCache:results];
        }];
    }
    if( [self getQueryTableMode] == QUERY_SEARCH ) {
        _currentAFRequestOperation = [_client getShaderKeys:_sortBy query:_searchQuery success:^(NSArray *results) {
            [weakSelf setDataIsLoaded:results];
            if( [results count] ) {
                [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }];
    }
}

- (void) setDataIsLoaded:(NSArray *)results {
    _data = results;
    [self.tableView reloadData];
    [[self.tableView pullToRefreshView] stopAnimating];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

#pragma mark - Query Table Modes

- (QueryTableMode) getQueryTableMode {
    return _queryTableMode;
}

- (void) switchQueryTableMode:(QueryTableMode) mode {
    [self hideLogo];
    [self hideSearchBar];
    [self cancelRequests];
    
    switch( mode ) {
        case QUERY_SEARCH:
            [self setupSearchBar];
            break;
        default:
        case QUERY_NORMAL:
            [self setupLogo];
            break;
    }
    _queryTableMode = mode;
    
    if( [_data count] ) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

-(void) hideLogo {
    [self.navigationItem setLeftBarButtonItem:nil animated:NO];
}

-(void) hideSearchBar {
    [self.navigationItem setLeftBarButtonItem:nil animated:NO];
    _searchBar = nil;
}

-(void) cancelRequests {
    [_currentAFRequestOperation cancel];
    [[self.tableView pullToRefreshView] stopAnimating];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

-(void) setupSearchBar {
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 88, 44)];
    UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:_searchBar];
    
    [self.navigationItem setLeftBarButtonItem:searchBarItem animated:YES];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelSearchButtonClick:)] animated:YES];
    
    [_searchBar becomeFirstResponder];
    [_searchBar setDelegate:self];
    
    _data = [[NSArray alloc] init];
    [self.tableView reloadData];
}

-(void) setupLogo {
    UIImage *logo = [[[UIImage imageNamed:@"shadertoy_title"] resizedImageWithMaximumSize:CGSizeMake(10000,24)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    __weak QueryTableViewController *weakSelf = self;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] bk_initWithImage:logo style:UIBarButtonItemStylePlain handler:^(id sender) {
        if( [_data count] ) {
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }];
    self.navigationItem.leftBarButtonItem = item;
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonClick:)] animated:YES];
    [self loadNormalData];
}

#pragma mark - Search functions

- (IBAction) searchButtonClick:(id)sender {
    [self switchQueryTableMode:QUERY_SEARCH];
}

- (IBAction) cancelSearchButtonClick:(id)sender {
    [self switchQueryTableMode:QUERY_NORMAL];
}

- (void) search:(NSString *)query {
    if(_searchBlockTimer) {
        [NSObject bk_cancelBlock:_searchBlockTimer];
        _searchBlockTimer = nil;
    }
    
    if( [query isEqualToString:@""] ) {
        [self cancelRequests];
        _data = [[NSArray alloc] init];
        [self.tableView reloadData];
        return;
    }
    
    _searchQuery = query;
    
    _searchBlockTimer = [NSObject bk_performBlock:^{
        [self cancelRequests];
        [self reloadData];
    } afterDelay:.5];
}

#pragma mark - Searchbar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_searchBar resignFirstResponder];
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
