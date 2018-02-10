//
//  ShaderObject.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "APIShaderObject.h"


@implementation APIShaderPassInputSampler : NSObject
- (APIShaderPassInputSampler *) updateWithDict:(NSDictionary *) dict {
    self.filter = [dict objectForKey:@"filter"];
    self.wrap = [dict objectForKey:@"wrap"];
    self.vflip = [dict objectForKey:@"vflip"];
    self.srgb = [dict objectForKey:@"srgb"];
    
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.filter forKey:@"filter"];
    [coder encodeObject:self.wrap forKey:@"wrap"];
    [coder encodeObject:self.vflip forKey:@"vflip"];
    [coder encodeObject:self.srgb forKey:@"srgb"];
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.filter = [coder decodeObjectForKey:@"filter"];
        self.wrap = [coder decodeObjectForKey:@"wrap"];
        self.vflip = [coder decodeObjectForKey:@"vflip"];
        self.srgb = [coder decodeObjectForKey:@"srgb"];
    }
    return self;
}
@end


@implementation APIShaderPassInput : NSObject
- (APIShaderPassInput *) updateWithDict:(NSDictionary *) dict {
    self.inputId = [dict objectForKey:@"id"];
    self.src = [dict objectForKey:@"src"];
    self.ctype = [dict objectForKey:@"ctype"];
    self.channel = [dict objectForKey:@"channel"];
    NSDictionary* d = [dict objectForKey:@"sampler"];
    self.sampler = [[[APIShaderPassInputSampler alloc] init] updateWithDict:d];
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.inputId forKey:@"inputId"];
    [coder encodeObject:self.src forKey:@"src"];
    [coder encodeObject:self.ctype forKey:@"ctype"];
    [coder encodeObject:self.channel forKey:@"channel"];
    [coder encodeObject:self.sampler forKey:@"sampler"];
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.inputId = [coder decodeObjectForKey:@"inputId"];
        self.src = [coder decodeObjectForKey:@"src"];
        self.ctype = [coder decodeObjectForKey:@"ctype"];
        self.channel = [coder decodeObjectForKey:@"channel"];
        self.sampler = [coder decodeObjectForKey:@"sampler"];
    }
    return self;
}
@end


@implementation APIShaderPassOutput : NSObject
- (APIShaderPassOutput *) updateWithDict:(NSDictionary *) dict {
    self.outputId = [dict objectForKey:@"id"];
    self.channel = [dict objectForKey:@"channel"];
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.outputId forKey:@"outputId"];
    [coder encodeObject:self.channel forKey:@"channel"];
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.outputId = [coder decodeObjectForKey:@"outputId"];
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
    self.outputs = [[NSMutableArray alloc] init];
    NSArray* inputs = [dict objectForKey:@"inputs"];
    for( NSDictionary* d in inputs) {
        [self.inputs addObject:[[[APIShaderPassInput alloc] init] updateWithDict:d]];
    }
    NSArray* outputs = [dict objectForKey:@"outputs"];
    for( NSDictionary* d in outputs) {
        [self.outputs addObject:[[[APIShaderPassOutput alloc] init] updateWithDict:d]];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.code forKey:@"code"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.inputs forKey:@"inputs"];
    [coder encodeObject:self.outputs forKey:@"outputs"];
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.code = [coder decodeObjectForKey:@"code"];
        self.type = [coder decodeObjectForKey:@"type"];
        self.inputs = [coder decodeObjectForKey:@"inputs"];
        self.outputs = [coder decodeObjectForKey:@"outputs"];
    }
    return self;
}
- (NSString *) getHeaderComments {
    BOOL inCommentBlock = NO;
    NSString* header = @"";
    NSArray* lines = [self.code componentsSeparatedByString:@"\n"];
    
    for( NSString* line in lines ) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if( inCommentBlock ) {
            header = [[header stringByAppendingString:trimmedLine] stringByAppendingString:@"\n"];
            if(  [line rangeOfString:@"*/"].location != NSNotFound ) {
                return [header stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        } else if( [line rangeOfString:@"/*"].location != NSNotFound ) {
            inCommentBlock = YES;
            header = [[header stringByAppendingString:trimmedLine] stringByAppendingString:@"\n"];
        } else if( [line isEqualToString:@""] || ([line rangeOfString:@"//"].location == 0 && [line rangeOfString:@"#define"].location == NSNotFound) ) {
            header = [[header stringByAppendingString:trimmedLine] stringByAppendingString:@"\n"];
        } else {
            return [header stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    return @"";
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

    self.imagePass = nil;
    self.soundPass = nil;
    self.bufferPasses = [[NSMutableArray alloc] init];

    NSArray* renderpasses = [dict objectForKey:@"renderpass"];
    
    for( NSDictionary* d in renderpasses ) {
        if( [[d objectForKey:@"type"] isEqualToString:@"image"] ) {
            self.imagePass = [[[APIShaderPass alloc] init] updateWithDict:d];
        } else if( [[d objectForKey:@"type"] isEqualToString:@"sound"] ) {
            self.soundPass = [[[APIShaderPass alloc] init] updateWithDict:d];
        } else if( [[d objectForKey:@"type"] isEqualToString:@"common"] ) {
            self.commonPass = [[[APIShaderPass alloc] init] updateWithDict:d];
        } else {
            [self.bufferPasses addObject:[[[APIShaderPass alloc] init] updateWithDict:d]];
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
    [coder encodeObject:self.commonPass forKey:@"commonPass"];
    [coder encodeObject:self.bufferPasses forKey:@"bufferPasses"];
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
        self.commonPass = [coder decodeObjectForKey:@"commonPass"];
        self.bufferPasses = [coder decodeObjectForKey:@"bufferPasses"];
        self.dateLastUpdated = [coder decodeObjectForKey:@"dateLastUpdated"];
    }
    return self;
}

- (NSURL *) getPreviewImageUrl {
    //    NSString* url = [[@"https://www.shadertoy.com/media/shaders/" stringByAppendingString:_shaderId] stringByAppendingString:@".jpg"];
    NSString* url = [[@"http://reindernijhoff.net/shadertoythumbs/" stringByAppendingString:_shaderId] stringByAppendingString:@".jpg"];
    
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

- (BOOL) useMouse {
    return [self.imagePass.code containsString:@"iMouse"];
}

- (BOOL) vrImplemented {
    return  ([self.imagePass.code containsString:@"mainVR("] ||
             [self.imagePass.code containsString:@"mainVR ("] ||
             [self.imagePass.code containsString:@"mainVR  ("]);
}

- (NSString *) getHeaderComments {
    return [self.imagePass getHeaderComments];
}

- (BOOL) useMultiPass {
    return [self.bufferPasses count] > 0;
}

- (BOOL) useKeyboard {
    for( APIShaderPass *pass in self.bufferPasses ) {
        for( APIShaderPassInput *input in pass.inputs ) {
            if( [input.ctype isEqualToString:@"keyboard"] ) return true;
        }
    }
    for( APIShaderPassInput *input in self.imagePass.inputs ) {
        if( [input.ctype isEqualToString:@"keyboard"] ) return true;
    }
    return false;
}

@end
