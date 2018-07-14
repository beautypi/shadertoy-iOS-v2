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
    AFHTTPSessionManager *_manager;
}
@end

@implementation APIShadertoy

- (id)init {
    self = [super init];
    if(self){
        _manager = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:APIShadertoyBaseUrl]];
        
        AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
        
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        [requestSerializer setValue:language forHTTPHeaderField:@"Accept-Language"];
        _manager.requestSerializer = requestSerializer;
        
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    }
    return self;
}

- (NSURLSessionDataTask *) getShaderKeys:(NSString *)sortBy success:(void (^)(NSArray *results))success {
    NSDictionary *params = @{
                             @"key": APIShadertoyKey,
                             @"sort": sortBy
                             };
    
    return [self getShaderKeys:@"query" params:params success:success];
}

- (NSURLSessionDataTask *) getShaderKeys:(NSString *)sortBy query:(NSString *)query success:(void (^)(NSArray *results))success {
    NSDictionary *params = @{
                             @"key": APIShadertoyKey,
                             @"sort": sortBy
                             };
    NSString *url = [@"query/" stringByAppendingString:[query URLEncode]];
    return [self getShaderKeys:url params:params success:success];
}

- (NSURLSessionDataTask *) getShaderKeys:(NSString *)url params:(NSDictionary *)params success:(void (^)(NSArray *results))success {
    return [_manager GET:url parameters:params progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
        if(![responseObject isKindOfClass:[NSDictionary class]]){
            return;
        }
        NSArray *results = [responseObject objectForKey:@"Results"];
        success(results);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        
    }];
}

- (NSURLSessionDataTask *) getShader:(NSString *)shaderId success:(void (^)(NSDictionary *shaderDict))success failure:(void (^)(void))failure {
    NSDictionary *params = @{
                             @"key": APIShadertoyKey
                             };
    
    return [_manager GET:shaderId parameters:params progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
        if(![responseObject isKindOfClass:[NSDictionary class]]){
            return;
        }
        NSDictionary *shaderDict = [responseObject objectForKey:@"Shader"];
        if( shaderDict != nil) {
            success(shaderDict);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        failure();
    }];
}

@end
