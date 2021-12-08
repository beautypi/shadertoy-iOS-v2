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
#if BUILD_TARGET_STDEBUG
#import "Shadertoy_debug-Swift.h"
#elif BUILD_TARGET_ST
#import "Shadertoy-Swift.h"
#endif

@interface APIShaderRepository ()  {
    APIShadertoy* _client;
}

@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableArray<void(^)(NSString*, NSError*, BOOL)>* >* fileFetchingCallbacks;

@property (nonatomic, strong) TwoLevelCache* cache;

@end

static APIShaderRepository* __sharedInstance;

@implementation APIShaderRepository

+(_Nonnull instancetype) sharedRepo {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[APIShaderRepository alloc] init];
    });
    return __sharedInstance;
}

- (id) init {
    self = [super init];
    _client = [[APIShadertoy alloc] init];
    _fileFetchingCallbacks = [[NSMutableDictionary alloc] init];
    return self;
}

- (APIShaderObject *) getShader:(NSString *)shaderId success:(void (^)(APIShaderObject *shader))success {
    ///!!!For Debug: + Use local JSON file of shaderObject
    NSString* jsonPath = [[NSBundle mainBundle] pathForResource:shaderId ofType:@"json"];
    NSString* jsonString = [[NSString alloc] initWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil];
    if (jsonString && jsonString.length > 0)
    {
        NSArray* jsonObject = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        if (jsonObject && jsonObject.count > 0)
        {
            APIShaderObject* shader = [[APIShaderObject alloc] init];
            [shader updateWithDict:jsonObject[0]];
            shader.dateLastUpdated = [NSDate date];
            [self.cache setAndSave:shader to:shaderId with:10];
            success(shader);
            return shader;
        }
    }
    
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

-(NSString* _Nullable ) loadFileFromURL:(NSString*)url completion:(void(^)(NSString*, NSError*, BOOL))completion {
    NSString* docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    BOOL needFetchByMe = NO;
    @synchronized (_fileFetchingCallbacks)
    {
        NSString* fileName = (NSString*)[_cache getFrom:url ifMiss:nil];
        if (fileName)
        {
            NSString* filePath = [docPath stringByAppendingPathComponent:fileName];
            NSURL* fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
            NSString* urlPath = fileURL.path;
            // check if file exists
            NSError* err;
            [fileURL checkResourceIsReachableAndReturnError:&err];
            NSLog(@"#Cache# Hit cached fileURL %@ of key '%@'", fileURL, url);
            if (completion)
            {
                completion(urlPath, err, NO);
            }
            return urlPath;
        }
        
        NSMutableArray* callbacks = _fileFetchingCallbacks[url];
        if (!callbacks || 0 == callbacks.count)
        {
            NSLog(@"#Cache# Need fetch url '%@'", url);
            needFetchByMe = YES;
            if (!callbacks)
            {
                callbacks = [[NSMutableArray alloc] init];
                _fileFetchingCallbacks[url] = callbacks;
            }
        }
        if (completion)
        {
            [callbacks addObject:completion];
        }
    }
    
    if (needFetchByMe)
    {
        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSString* fileName = [[NSUUID new] UUIDString];
        NSString* filePath = [docPath stringByAppendingPathComponent:fileName];
        NSURL* fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
        NSLog(@"#Cache# Actually Will Download %@ to %@", url, fileURL);
        NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            NSLog(@"#Cache# Downloading '%@' callback with error %@", url, error);
            if (error)
            {
                NSArray* callbacks = nil;
                @synchronized (self.fileFetchingCallbacks)
                {
                    callbacks = self.fileFetchingCallbacks[url];
                    [self.fileFetchingCallbacks removeObjectForKey:url];
                }
                for (void(^callback)(NSString*, NSError*, BOOL) in callbacks)
                {
                    callback(nil, error, YES);
                }
            }
            else
            {
                [data writeToURL:fileURL options:NSDataWritingAtomic error:&error];
                
                NSArray* callbacks = nil;
                @synchronized (self.fileFetchingCallbacks)
                {
                    NSLog(@"#Cache# File is saved to %@", fileName);
                    [self.cache setAndSave:fileName to:url with:1];
                    
                    callbacks = self.fileFetchingCallbacks[url];
                    [self.fileFetchingCallbacks removeObjectForKey:url];
                }
                
                for (void(^callback)(NSString*, NSError*, BOOL) in callbacks)
                {
                    callback(filePath, error, YES);
                }
            }
        }] resume];
    }
    
    return nil;
}

@end
