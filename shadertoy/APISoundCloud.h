//
//  APISoundCloud.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 07/12/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "defines.h"

@interface APISoundCloud : NSObject

- (AFHTTPRequestOperation *) resolve:(NSString *)url success:(void (^)(NSDictionary *resultDict))success;
- (AFHTTPRequestOperation *) track:(NSString *)location success:(void (^)(NSDictionary *resultDict))success;

@end
