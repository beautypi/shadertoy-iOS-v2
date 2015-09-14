//
//  APIShadertoy.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "APIShadertoy.h"
#import "NSString+URLEncode.h"

@interface APIShadertoy () {
    AFHTTPRequestOperationManager *_requestManager;
}
@end

@implementation APIShadertoy

- (id)init {
    self = [super init];
    if(self){
        _requestManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:APIShadertoyBaseUrl]];
        
        AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
        
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        [requestSerializer setValue:language forHTTPHeaderField:@"Accept-Language"];
        _requestManager.requestSerializer = requestSerializer;
        
        _requestManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _requestManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    }
    return self;
}

- (AFHTTPRequestOperation *) getShaderKeys:(NSString *)sortBy success:(void (^)(NSArray *results))success {
    NSDictionary *params = @{
                             @"key": APIShadertoyKey,
                             @"sort": sortBy
                             };
    
    return [self getShaderKeys:@"query" params:params success:success];
}

- (AFHTTPRequestOperation *) getShaderKeys:(NSString *)sortBy query:(NSString *)query success:(void (^)(NSArray *results))success {
    NSDictionary *params = @{
                             @"key": APIShadertoyKey,
                             @"sort": sortBy
                             };
    NSString *url = [@"query/" stringByAppendingString:[query URLEncode]];
    return [self getShaderKeys:url params:params success:success];
}

- (AFHTTPRequestOperation *) getShaderKeys:(NSString *)url params:(NSDictionary *)params success:(void (^)(NSArray *results))success {
    return [_requestManager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(![responseObject isKindOfClass:[NSDictionary class]]){
            return;
        }
        NSArray *results = [responseObject objectForKey:@"Results"];
        success(results);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (AFHTTPRequestOperation *) getShader:(NSString *)shaderId success:(void (^)(NSDictionary *shaderDict))success {
    NSDictionary *params = @{
                             @"key": APIShadertoyKey
                             };
    
    return [_requestManager GET:shaderId parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(![responseObject isKindOfClass:[NSDictionary class]]){
            return;
        }
        NSDictionary *shaderDict = [responseObject objectForKey:@"Shader"];
        success(shaderDict);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

@end