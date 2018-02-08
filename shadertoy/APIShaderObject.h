//
//  ShaderObject.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface APIShaderPassInputSampler : NSObject

- (APIShaderPassInputSampler *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSString *filter;
@property (nonatomic, strong) NSString *wrap;
@property (nonatomic, strong) NSString *vflip;
@property (nonatomic, strong) NSString *srgb;

@end

@interface APIShaderPassInput : NSObject

- (APIShaderPassInput *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSNumber *inputId;
@property (nonatomic, strong) NSString *src;
@property (nonatomic, strong) NSString *ctype;
@property (nonatomic, strong) NSNumber *channel;
@property (nonatomic, strong) APIShaderPassInputSampler *sampler;

@end


@interface APIShaderPassOutput : NSObject

- (APIShaderPassOutput *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSNumber *outputId;
@property (nonatomic, strong) NSNumber *channel;

@end


@interface APIShaderPass : NSObject

- (APIShaderPass *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSMutableArray *inputs;
@property (nonatomic, strong) NSMutableArray *outputs;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *type;

@end


@interface APIShaderObject : NSObject

- (APIShaderObject *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSString *shaderId;
@property (nonatomic, strong) NSString *shaderName;
@property (nonatomic, strong) NSString *shaderDescription;
@property (nonatomic, strong) NSString *username;

@property (nonatomic, strong) NSNumber *viewed;
@property (nonatomic, strong) NSNumber *likes;
@property (nonatomic, strong) NSDate *date;

@property (nonatomic, strong) APIShaderPass *imagePass;
@property (nonatomic, strong) APIShaderPass *soundPass;
@property (nonatomic, strong) APIShaderPass *commonPass;
@property (nonatomic, strong) NSMutableArray *bufferPasses;

@property (nonatomic, weak)   NSURLSessionDataTask *requestOperation;

@property (nonatomic, strong) NSDate *dateLastUpdated;

- (NSURL *) getPreviewImageUrl;
- (NSURL *) getShaderUrl;
- (void) cancelShaderRequestOperation;
- (BOOL) needsUpdateFromAPI;
- (void) invalidateLastUpdatedDate;

- (BOOL) useMouse;
- (BOOL) vrImplemented;
- (BOOL) useMultiPass;
- (BOOL) useKeyboard;
- (NSString *) getHeaderComments;

@end
