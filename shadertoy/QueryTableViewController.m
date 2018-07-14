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

#import "LocalCache.h"
#import "UIBarButtonItem+BlocksKit.h"

#import "Utils.h"
#import "NSObject+BKBlockExecution.h"

@interface QueryTableViewController ()  {
    APIShadertoy* _client;
    APIShaderRepository* _repository;
    NSString* _sortBy;
    NSArray* _data;
    
    NSURLSessionDataTask*  _currentAFRequestOperation;
    
    UISearchBar*            _searchBar;
    NSString*               _searchQuery;
    id                      _searchBlockTimer;
    NSMutableDictionary*    _searchCache;
    
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
    _searchCache = [[NSMutableDictionary alloc] init];
    _queryTableMode = QUERY_NORMAL;
    
    [self switchQueryTableMode:QUERY_NORMAL];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
}

- (void) viewWillAppear:(BOOL)animated {
    trackScreen([@"QueryTable_" stringByAppendingString:_sortBy]);
    
    [self cancelRequests];
    
    if( [self getQueryTableMode] == QUERY_NORMAL ) {
        [self loadNormalData];
    }
    [[self navigationController] setNavigationBarHidden:NO animated:NO];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    _searchCache = [[NSMutableDictionary alloc] init];
    [super didReceiveMemoryWarning];
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
        [self.refreshControl endRefreshing];
        [self.refreshControl beginRefreshing];
        [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y-self.refreshControl.frame.size.height) animated:NO];
    }
    
    __weak QueryTableViewController *weakSelf = self;
    
    if( [self getQueryTableMode] == QUERY_NORMAL ) {
        _currentAFRequestOperation = [_client getShaderKeys:_sortBy success:^(NSArray *results) {
            [weakSelf setDataIsLoaded:results];
            [self storeDataToCache:results];
        }];
    }
    if( [self getQueryTableMode] == QUERY_SEARCH ) {
        NSString *searchQueryCopy = [_searchQuery copy];
        _currentAFRequestOperation = [_client getShaderKeys:_sortBy query:_searchQuery success:^(NSArray *results) {
            [weakSelf setDataIsLoaded:results];
            [self->_searchCache setValue:(results?results:[NSArray array]) forKey:searchQueryCopy];
            if( [results count] ) {
                [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }];
    }
}

- (void) setDataIsLoaded:(NSArray *)results {
    _data = results;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    [self setNoShadersFound:![_data count]];
}

- (void) setNoShadersFound:(BOOL)visible {
    if( visible ) {
        UILabel *noDataLabel          = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
        noDataLabel.text              = @"No shaders found";
        noDataLabel.textColor         = [UIColor darkGrayColor];
        noDataLabel.textAlignment     = NSTextAlignmentCenter;
        self.tableView.backgroundView = noDataLabel;
    } else {
        self.tableView.backgroundView = nil;
    }
}

#pragma mark - Query Table Modes

- (QueryTableMode) getQueryTableMode {
    return _queryTableMode;
}

- (void) switchQueryTableMode:(QueryTableMode) mode {
    [self hideLogo];
    [self hideSearchBar];
    [self cancelRequests];
    [self setNoShadersFound:NO];
    
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
    [self.refreshControl endRefreshing];
}

-(void) setupSearchBar {
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 24, 44)];
    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _searchBar.showsCancelButton = YES;
    UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:_searchBar];
    
    [self.navigationItem setRightBarButtonItem:nil animated:NO];
    [self.navigationItem setLeftBarButtonItem:searchBarItem animated:YES];
    
    [_searchBar becomeFirstResponder];
    [_searchBar setDelegate:self];
    
    _data = [[NSArray alloc] init];
    [self.tableView reloadData];
}

-(void) setupLogo {
    UIImage *logo = [[[UIImage imageNamed:@"shadertoy_title"] resizedImageWithMaximumSize:CGSizeMake(10000,24)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    __weak QueryTableViewController *weakSelf = self;
    UIBarButtonItem *item = [[UIBarButtonItem alloc] bk_initWithImage:logo style:UIBarButtonItemStylePlain handler:^(id sender) {
        if( [self->_data count] ) {
            [weakSelf.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }];
    self.navigationItem.leftBarButtonItem = item;
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonClick:)] animated:YES];
    [self loadNormalData];
}

-(void) navigateToShader:(NSString *)shaderId {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController* viewController = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderViewController"];
    
    [_repository getShader:shaderId success:^(APIShaderObject *shader) {
        if( shader.imagePass != NULL ) {
            [((ShaderViewController *)viewController) setShaderObject:shader];
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }];
}

#pragma mark - Search functions

- (IBAction) searchButtonClick:(id)sender {
    [self switchQueryTableMode:QUERY_SEARCH];
}

- (void) search:(NSString *)query {
    [self setNoShadersFound:NO];
    
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
    
    _searchQuery = [query lowercaseString];
    
    NSArray* cachedResults = [_searchCache valueForKey:_searchQuery];
    if( cachedResults ) {
        [self setDataIsLoaded:cachedResults];
    } else {
        _searchBlockTimer = [NSObject bk_performBlock:^{
            [self cancelRequests];
            [self reloadData];
        } afterDelay:.5];
    }
}

- (void)enableControlsInView:(UIView *)view {
    for (id subview in view.subviews) {
        if ([subview isKindOfClass:[UIControl class]]) {
            [subview setEnabled:YES];
        }
        [self enableControlsInView:subview];
    }
}

#pragma mark - Searchbar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_searchBar resignFirstResponder];
    [self enableControlsInView:_searchBar];
    [self search:searchBar.text];
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self search:searchText];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self switchQueryTableMode:QUERY_NORMAL];
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
        [self enableControlsInView:_searchBar];
        return;
    }
        
    NSString* shaderId = [_data objectAtIndex:indexPath.row];
    [self navigateToShader:shaderId];
}

@end
