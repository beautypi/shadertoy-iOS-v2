//
//  LocalCache.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "LocalCache.h"

@interface LocalCache () {
    NSMutableDictionary *memoryCache;
}
@end

static LocalCache *__sharedInstance;

@implementation LocalCache

- (id)init {
    self = [super init];
    if(self){
        memoryCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (instancetype)sharedLocalCache {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[LocalCache alloc] init];
    });
    
    return __sharedInstance;
}

- (void) storeObject:(id)object forKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:object forKey:key];
    [userDefaults synchronize];
}

- (id) getObject:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:key];
}

- (void) storeShaderObject:(APIShaderObject *)object forKey:(NSString *)key {
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:encodedObject forKey:key];
    [userDefaults synchronize];
}

- (APIShaderObject *) getShaderObject:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData* object = [userDefaults objectForKey:key];
    if( !object ) return NULL;
    
    return  [NSKeyedUnarchiver unarchiveObjectWithData:object];
}

- (void) removeObject:(NSString *)key {
    [memoryCache removeObjectForKey:key];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:key];
}

- (void) clear {
    [memoryCache removeAllObjects];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
}

@end
