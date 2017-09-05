//
//  APISoundCloud.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 07/12/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import "APISoundCloud.h"

@interface APISoundCloud () {
    AFHTTPSessionManager *_manager;
}
@end

@implementation APISoundCloud

- (id)init {
    self = [super init];
    if(self){
        _manager = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:@"https://api.soundcloud.com/"]];
        
        AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
        
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        [requestSerializer setValue:language forHTTPHeaderField:@"Accept-Language"];
        _manager.requestSerializer = requestSerializer;
        
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.securityPolicy = [AFSecurityPolicy defaultPolicy];
    }
    return self;
}

- (NSURLSessionDataTask *) resolve:(NSString *)url success:(void (^)(NSDictionary *resultDict))success {
    NSDictionary *params = @{
                             @"client_id": @"b1275b704badf79d972d51aa4b92ea15",
                             @"url": url
                             };
    
    return [_manager GET:@"resolve.json" parameters:params progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
        if(![responseObject isKindOfClass:[NSDictionary class]]){
            return;
        }
        success(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        
    }];
}

- (NSURLSessionDataTask *) track:(NSString *)location success:(void (^)(NSDictionary *resultDict))success {
    NSDictionary *params = @{};
    
    return [_manager GET:location parameters:params progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
        if(![responseObject isKindOfClass:[NSDictionary class]]){
            return;
        }
        NSDictionary *shaderDict = [responseObject objectForKey:@"Shader"];
        success(shaderDict);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        
    }];
}

@end
