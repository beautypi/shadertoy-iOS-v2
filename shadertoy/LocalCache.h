//
//  LocalCache.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIShaderObject.h"

@interface LocalCache : NSObject

+ (instancetype)sharedLocalCache;

- (void) storeObject:(id)object forKey:(NSString *)key;
- (id) getObject:(NSString *)key;

- (void) storeShaderObject:(APIShaderObject *)object forKey:(NSString *)key;
- (APIShaderObject *) getShaderObject:(NSString *)key;

- (void) removeObject:(NSString *)key;
- (void) clear;

- (NSNumber *) getVersion;
- (void) setVersion:(NSNumber *)version;

@end
