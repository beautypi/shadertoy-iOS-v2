//
//  LocalCache.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShaderObject.h"

@interface LocalCache : NSObject

+ (instancetype)sharedLocalCache;

- (void) storeShaderObject:(ShaderObject *)object forKey:(NSString *)key;
- (ShaderObject *) getShaderObject:(NSString *)key;
- (void) removeObject:(NSString *)key;

- (void) clear;

@end
