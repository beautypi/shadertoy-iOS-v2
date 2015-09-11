//
//  APIShadertoy.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "APIShaderObject.h"

#define APIShadertoyBaseUrl @"https://www.shadertoy.com/api/v1/shaders/"
#define APIShadertoyKey @"NtHKWH"

@interface APIShadertoy : NSObject

- (AFHTTPRequestOperation *) getShaderKeys:(NSString *)sortBy success:(void (^)(NSArray *results))success;
- (AFHTTPRequestOperation *) getShader:(NSString *)shaderId success:(void (^)(NSDictionary *shaderDict))success;

@end
