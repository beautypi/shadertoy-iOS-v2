//
//  QueryTableViewController.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, QueryTableMode) {
    QUERY_NORMAL,
    QUERY_SEARCH
};

@interface QueryTableViewController : UITableViewController <UISearchBarDelegate>

- (void) setSortBy:(NSString *)sortBy;
- (void) reloadData;
- (void) navigateToShader:(NSString *)shaderId;

@end
