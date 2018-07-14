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
#import "defines.h"

@interface APIShadertoy : NSObject

- (NSURLSessionDataTask *) getShaderKeys:(NSString *)sortBy success:(void (^)(NSArray *results))success;
- (NSURLSessionDataTask *) getShaderKeys:(NSString *)sortBy query:(NSString *)query success:(void (^)(NSArray *results))success;
- (NSURLSessionDataTask *) getShader:(NSString *)shaderId success:(void (^)(NSDictionary *shaderDict))success failure:(void (^)(void))failure;

@end
