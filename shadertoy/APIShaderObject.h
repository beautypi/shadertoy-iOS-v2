//
//  ShaderObject.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface APIShaderPassInput : NSObject

- (APIShaderPassInput *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSString *inputId;
@property (nonatomic, strong) NSString *src;
@property (nonatomic, strong) NSString *ctype;
@property (nonatomic, strong) NSNumber *channel;

@end



@interface APIShaderPass : NSObject

- (APIShaderPass *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSMutableArray *inputs;
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

@property (nonatomic, weak)   AFHTTPRequestOperation *requestOperation;

@property (nonatomic, strong) NSDate *dateLastUpdated;

- (NSURL *) getPreviewImageUrl;
- (void) cancelShaderRequestOperation;
- (BOOL) needsUpdateFromAPI;
- (void) invalidateLastUpdatedDate;

@end
