//
//  ShaderObject.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "APIShaderObject.h"

@implementation APIShaderPassInput : NSObject
- (APIShaderPassInput *) updateWithDict:(NSDictionary *) dict {
    self.inputId = [dict objectForKey:@"id"];
    self.src = [dict objectForKey:@"src"];
    self.ctype = [dict objectForKey:@"ctype"];
    self.channel = [dict objectForKey:@"channel"];
    
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.inputId forKey:@"inputId"];
    [coder encodeObject:self.src forKey:@"src"];
    [coder encodeObject:self.ctype forKey:@"ctype"];
    [coder encodeObject:self.channel forKey:@"channel"];
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.inputId = [coder decodeObjectForKey:@"inputId"];
        self.src = [coder decodeObjectForKey:@"src"];
        self.ctype = [coder decodeObjectForKey:@"ctype"];
        self.channel = [coder decodeObjectForKey:@"channel"];
    }
    return self;
}
@end

@implementation APIShaderPass : NSObject
- (APIShaderPass *) updateWithDict:(NSDictionary *) dict {
    self.code = [dict objectForKey:@"code"];
    self.type = [dict objectForKey:@"type"];
    self.inputs = [[NSMutableArray alloc] init];
    NSArray* inputs = [dict objectForKey:@"inputs"];
    for( NSDictionary* d in inputs) {
        [self.inputs addObject:[[[APIShaderPassInput alloc] init] updateWithDict:d]];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.code forKey:@"code"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.inputs forKey:@"inputs"];
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.code = [coder decodeObjectForKey:@"code"];
        self.type = [coder decodeObjectForKey:@"type"];
        self.inputs = [coder decodeObjectForKey:@"inputs"];
    }
    return self;
}
@end

@implementation APIShaderObject : NSObject
- (APIShaderObject *) updateWithDict:(NSDictionary *) dict {
    NSDictionary* info = [dict objectForKey:@"info"];
                          
    self.shaderId = [info objectForKey:@"id"];
    self.shaderName = [info objectForKey:@"name"];
    self.shaderDescription = [info objectForKey:@"description"];
    self.username = [info objectForKey:@"username"];
    
    self.viewed = [info objectForKey:@"viewed"];
    self.likes = [info objectForKey:@"likes"];
    self.date = [[NSDate alloc] initWithTimeIntervalSince1970:[[info objectForKey:@"date"] floatValue]];
    
    self.dateLastUpdated = [[NSDate alloc] init];
    
    NSArray* renderpasses = [dict objectForKey:@"renderpass"];
    
    for( NSDictionary* d in renderpasses ) {
        if( [[d objectForKey:@"type"] isEqualToString:@"image"] ) {
            self.imagePass = [[[APIShaderPass alloc] init] updateWithDict:d];
        } else {
            self.soundPass = [[[APIShaderPass alloc] init]  updateWithDict:d];
        }
    }
    
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.shaderId forKey:@"shaderId"];
    [coder encodeObject:self.shaderName forKey:@"shaderName"];
    [coder encodeObject:self.shaderDescription forKey:@"shaderDescription"];
    [coder encodeObject:self.username forKey:@"username"];
    [coder encodeObject:self.viewed forKey:@"viewed"];
    [coder encodeObject:self.likes forKey:@"likes"];
    [coder encodeObject:self.date forKey:@"date"];
    [coder encodeObject:self.imagePass forKey:@"imagePass"];
    [coder encodeObject:self.soundPass forKey:@"soundPass"];
    [coder encodeObject:self.dateLastUpdated forKey:@"dateLastUpdated"];
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.shaderId = [coder decodeObjectForKey:@"shaderId"];
        self.shaderName = [coder decodeObjectForKey:@"shaderName"];
        self.shaderDescription = [coder decodeObjectForKey:@"shaderDescription"];
        self.username = [coder decodeObjectForKey:@"username"];
        self.viewed = [coder decodeObjectForKey:@"viewed"];
        self.likes = [coder decodeObjectForKey:@"likes"];
        self.date = [coder decodeObjectForKey:@"date"];
        self.imagePass = [coder decodeObjectForKey:@"imagePass"];
        self.soundPass = [coder decodeObjectForKey:@"soundPass"];
        self.dateLastUpdated = [coder decodeObjectForKey:@"dateLastUpdated"];
    }
    return self;
}

- (NSURL *) getPreviewImageUrl {
    NSString* url = [[@"https://www.shadertoy.com/media/shaders/" stringByAppendingString:_shaderId] stringByAppendingString:@".jpg"];
    return [NSURL URLWithString:url];
}

- (NSURL *) getShaderUrl {
    NSString* url = [@"https://www.shadertoy.com/view/" stringByAppendingString:_shaderId];
    return [NSURL URLWithString:url];
}

- (void) cancelShaderRequestOperation {
    [self.requestOperation cancel];
}

- (BOOL) needsUpdateFromAPI {
    if( !self.dateLastUpdated ) {
        return YES;
    }
    
    NSDate* now = [NSDate date];
    if( [now timeIntervalSinceDate:self.date] > [self.dateLastUpdated timeIntervalSinceDate:self.date] * 2.f ) {
        return YES;
    }
    
    return NO;
}

- (void) invalidateLastUpdatedDate {
    self.dateLastUpdated = self.date;
}


@end



