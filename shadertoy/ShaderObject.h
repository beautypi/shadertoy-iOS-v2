//
//  ShaderObject.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface ShaderPassInput : NSObject

- (ShaderPassInput *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSString *inputId;
@property (nonatomic, strong) NSString *src;
@property (nonatomic, strong) NSString *ctype;
@property (nonatomic, strong) NSNumber *channel;

@end



@interface ShaderPass : NSObject

- (ShaderPass *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSMutableArray *inputs;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *type;

@end


@interface ShaderObject : NSObject

- (ShaderObject *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSString *shaderId;
@property (nonatomic, strong) NSString *shaderName;
@property (nonatomic, strong) NSString *shaderDescription;
@property (nonatomic, strong) NSString *username;

@property (nonatomic, strong) NSNumber *viewed;
@property (nonatomic, strong) NSNumber *likes;
@property (nonatomic, strong) NSDate *date;

@property (nonatomic, strong) ShaderPass *imagePass;
@property (nonatomic, strong) ShaderPass *soundPass;

@property (nonatomic, weak)   AFHTTPRequestOperation *requestOperation;

- (NSURL *) getPreviewImageUrl;
- (void) cancelShaderRequestOperation;

@end
