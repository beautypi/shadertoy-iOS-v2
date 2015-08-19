//
//  ShaderRepository.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "ShaderRepository.h"
#import "APIShadertoy.h"
#import "LocalCache.h"

@interface ShaderRepository ()  {
    APIShadertoy* _client;
}

@end

@implementation ShaderRepository

- (id) init {
    self = [super init];
    _client = [[APIShadertoy alloc] init];

    return self;
}

- (ShaderObject *) getShader:(NSString *)shaderId success:(void (^)(ShaderObject *shader))success {
    ShaderObject* cachedShader = [[LocalCache sharedLocalCache] getShaderObject:shaderId];
    if( cachedShader ) {
        return cachedShader;
    }
    
    ShaderObject* shader = [[ShaderObject alloc] init];
    shader.shaderId = shaderId;
    
    shader.requestOperation = [_client getShader:shaderId success:^(NSDictionary *shaderDict) {
        [shader updateWithDict:shaderDict];
        [[LocalCache sharedLocalCache] storeShaderObject:shader forKey:shaderId];
        success(shader);
    }];
    
    return shader;
}

@end
