//
//  APIShadertoy.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "APIShaderObject.h"
#import "Keys.h"

#define APIShadertoyBaseUrl @"https://www.shadertoy.com/api/v1/shaders/"

@interface APIShadertoy : NSObject

- (AFHTTPRequestOperation *) getShaderKeys:(NSString *)sortBy success:(void (^)(NSArray *results))success;
- (AFHTTPRequestOperation *) getShaderKeys:(NSString *)sortBy query:(NSString *)query success:(void (^)(NSArray *results))success;
- (AFHTTPRequestOperation *) getShader:(NSString *)shaderId success:(void (^)(NSDictionary *shaderDict))success;

@end
