//
//  APISoundCloud.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 07/12/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import "APISoundCloud.h"




@interface APISoundCloud () {
    AFHTTPRequestOperationManager *_requestManager;
}
@end

@implementation APISoundCloud

- (id)init {
    self = [super init];
    if(self){
        _requestManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.soundcloud.com/"]];
        
        AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
        
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        [requestSerializer setValue:language forHTTPHeaderField:@"Accept-Language"];
        _requestManager.requestSerializer = requestSerializer;
        
        _requestManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _requestManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    }
    return self;
}


- (AFHTTPRequestOperation *) resolve:(NSString *)url success:(void (^)(NSDictionary *resultDict))success {
    NSDictionary *params = @{
                             @"client_id": @"64a52bb31abd2ec73f8adda86358cfbf",
                             @"url": url
                             };
    
    return [_requestManager GET:@"resolve.json" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(![responseObject isKindOfClass:[NSDictionary class]]){
            return;
        }
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (AFHTTPRequestOperation *) track:(NSString *)location success:(void (^)(NSDictionary *resultDict))success {
    NSDictionary *params = @{
                             
                             };
    
    return [_requestManager GET:location parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(![responseObject isKindOfClass:[NSDictionary class]]){
            return;
        }
        NSDictionary *shaderDict = [responseObject objectForKey:@"Shader"];
        success(shaderDict);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

@end
