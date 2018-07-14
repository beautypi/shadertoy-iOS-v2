//
//  ShaderRepository.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "APIShaderRepository.h"
#import "APIShadertoy.h"
#import "LocalCache.h"

@interface APIShaderRepository ()  {
    APIShadertoy* _client;
}

@end

@implementation APIShaderRepository

- (id) init {
    self = [super init];
    _client = [[APIShadertoy alloc] init];
    
    return self;
}

- (APIShaderObject *) getShader:(NSString *)shaderId success:(void (^)(APIShaderObject *shader))success {
    APIShaderObject* shader;
    BOOL needsUpdate = NO;
    
    APIShaderObject* cachedShader = [[LocalCache sharedLocalCache] getShaderObject:shaderId];
    if( cachedShader ) {
        shader = cachedShader;
        
        if( [shader needsUpdateFromAPI] ) {
            needsUpdate = YES;
        } else {
            success(shader);            
        }
    } else {
        shader = [[APIShaderObject alloc] init];
        shader.shaderId = shaderId;
        needsUpdate = YES;
    }
    
    if( needsUpdate ) {
        shader.requestOperation = [_client getShader:shaderId success:^(NSDictionary *shaderDict) {
            [shader updateWithDict:shaderDict];
            [[LocalCache sharedLocalCache] storeShaderObject:shader forKey:shaderId];
            success(shader);
        } failure:^{
            if (cachedShader) {
                success(shader);
            }
        }];
    }
    
    return shader;
}

- (void) invalidateShader:(NSString *)shaderId {
    APIShaderObject* cachedShader = [[LocalCache sharedLocalCache] getShaderObject:shaderId];
    if( cachedShader ) {
        [cachedShader invalidateLastUpdatedDate];
        [[LocalCache sharedLocalCache] storeShaderObject:cachedShader forKey:shaderId];
    }
}

@end
