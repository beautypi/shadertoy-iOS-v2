//
//  ShaderObject.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "APIShaderObject.h"

static STInputType STInputTypeFromStr(NSString* str) {
    if ([str isEqualToString:@"texture"]) return STInputTypeTexture;
    if ([str isEqualToString:@"cubemap"]) return STInputTypeCubemap;
    if ([str isEqualToString:@"volume"]) return STInputTypeVolume;
    if ([str isEqualToString:@"buffer"]) return STInputTypeBuffer;
    if ([str isEqualToString:@"keyboard"]) return STInputTypeKeyboard;
    if ([str isEqualToString:@"video"]) return STInputTypeVideo;
    if ([str isEqualToString:@"music"]) return STInputTypeMusic;
    if ([str isEqualToString:@"musicstream"]) return STInputTypeMusicStream;
    if ([str isEqualToString:@"webcam"]) return STInputTypeWebCam;
    if ([str isEqualToString:@"mic"]) return STInputTypeMic;
    return STInputTypeInvalid;
}

static STSamplerFilter STSamplerFilterFromStr(NSString* str) {
    if ([str isEqualToString:@"nearest"]) return STSamplerFilterNearest;
    if ([str isEqualToString:@"linear"]) return STSamplerFilterLinear;
    if ([str isEqualToString:@"mipmap"]) return STSamplerFilterMipmap;
    return STSamplerFilterInvalid;
}

static STSamplerWrap STSamplerWrapFromStr(NSString* str) {
    if ([str isEqualToString:@"repeat"]) return STSamplerWrapRepeat;
    if ([str isEqualToString:@"clamp"]) return STSamplerWrapClamp;
    return STSamplerWrapInvalid;
}

static STPassType STPassTypeFromStr(NSString* str) {
    if ([str isEqualToString:@"image"]) return STPassTypeImage;
    if ([str isEqualToString:@"buffer"]) return STPassTypeBuffer;
    if ([str isEqualToString:@"sound"]) return STPassTypeSound;
    if ([str isEqualToString:@"common"]) return STPassTypeCommon;
    return STPassTypeInvalid;
}

static NSString* STInputTypeToStr(STInputType value) {
    if (value == STInputTypeTexture) return @"texture";
    if (value == STInputTypeCubemap) return @"cubemap";
    if (value == STInputTypeVolume) return @"volume";
    if (value == STInputTypeBuffer) return @"buffer";
    if (value == STInputTypeKeyboard) return @"keyboard";
    if (value == STInputTypeVideo) return @"video";
    if (value == STInputTypeMusic) return @"music";
    if (value == STInputTypeMusicStream) return @"musicstream";
    if (value == STInputTypeWebCam) return @"webcam";
    if (value == STInputTypeMic) return @"mic";
    return @"STInputTypeInvalid";
}

static NSString* STSamplerFilterToStr(STSamplerFilter value) {
    if (value == STSamplerFilterNearest) return @"nearest";
    if (value == STSamplerFilterLinear) return @"linear";
    if (value == STSamplerFilterMipmap) return @"mipmap";
    return @"STSamplerFilterInvalid";
}

static NSString* STSamplerWrapToStr(STSamplerWrap value) {
    if (value == STSamplerWrapRepeat) return @"repeat";
    if (value == STSamplerWrapClamp) return @"clamp";
    return @"STSamplerWrapInvalid";
}

static NSString* STPassTypeToStr(STPassType value) {
    if (value == STPassTypeImage) return @"image";
    if (value == STPassTypeBuffer) return @"buffer";
    if (value == STPassTypeSound) return @"sound";
    if (value == STPassTypeCommon) return @"common";
    return @"STPassTypeInvalid";
}

@implementation APIShaderPassInputSampler : NSObject
- (APIShaderPassInputSampler *) updateWithDict:(NSDictionary *) dict {
    self.filter = @(STSamplerFilterFromStr([dict objectForKey:@"filter"]));
    self.wrap = @(STSamplerWrapFromStr([dict objectForKey:@"wrap"]));
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
-(NSString*) description {
    return [NSString stringWithFormat:@"{filter:'%@', wrap:'%@', vflip:'%@', srgb:'%@'}", STSamplerFilterToStr(self.filter.integerValue), STSamplerWrapToStr(self.wrap.integerValue), self.vflip, self.srgb];
}
@end


@implementation APIShaderPassInput : NSObject
- (APIShaderPassInput *) updateWithDict:(NSDictionary *) dict {
    self.inputId = [dict objectForKey:@"id"];
    self.filepath = [dict objectForKey:@"filepath"];
    self.type = @(STInputTypeFromStr([dict objectForKey:@"type"]));
    self.channel = [dict objectForKey:@"channel"];
    NSDictionary* d = [dict objectForKey:@"sampler"];
    self.sampler = [[[APIShaderPassInputSampler alloc] init] updateWithDict:d];
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.inputId forKey:@"inputId"];
    [coder encodeObject:self.filepath forKey:@"filepath"];
    [coder encodeObject:self.type forKey:@"type"];
    [coder encodeObject:self.channel forKey:@"channel"];
    [coder encodeObject:self.sampler forKey:@"sampler"];
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.inputId = [coder decodeObjectForKey:@"inputId"];
        self.filepath = [coder decodeObjectForKey:@"filepath"];
        self.type = [coder decodeObjectForKey:@"type"];
        self.channel = [coder decodeObjectForKey:@"channel"];
        self.sampler = [coder decodeObjectForKey:@"sampler"];
    }
    return self;
}
-(NSString*) description {
    return [NSString stringWithFormat:@"{type:'%@', inputID:%@, channel:%d, \n  sampler:%@,\n  src:'...'}", STInputTypeToStr(_type.integerValue), _inputId, _channel.intValue, _sampler];
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
-(NSString*) description {
    return [NSString stringWithFormat:@"{outputID:%@, channel:%d}", _outputId, _channel.intValue];
}
@end


@implementation APIShaderPass : NSObject
-(NSString*) description {
    return [NSString stringWithFormat:@"{type:'%@', name:'%@',\n  inputs:\n%@,\n  outputs:\n%@,\n  code:'%@'}", STPassTypeToStr(_type.integerValue), _name, _inputs, _outputs, _code];
}
- (APIShaderPass *) updateWithDict:(NSDictionary *) dict {
    self.code = [dict objectForKey:@"code"];
    self.type = @(STPassTypeFromStr([dict objectForKey:@"type"]));
    self.name = [dict objectForKey:@"name"];
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
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.inputs forKey:@"inputs"];
    [coder encodeObject:self.outputs forKey:@"outputs"];
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self != nil) {
        self.code = [coder decodeObjectForKey:@"code"];
        self.type = [coder decodeObjectForKey:@"type"];
        self.name = [coder decodeObjectForKey:@"name"];
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

@interface APIShaderObject ()
{
    NSString* _summaryDescription;
}

@end

@implementation APIShaderObject : NSObject

-(NSString*) description {
    return [NSString stringWithFormat:@"{name:'%@', ID:'%@', username:'%@',\n  imagePass:\n%@,\n  bufferPasses:\n%@,\n  commonPass:\n%@,\n  soundPass:\n%@\nlicense=%d\n}", _shaderName, _shaderId, _username, _imagePass, _bufferPasses, _commonPass, _soundPass, _license];
}

-(NSString*) summaryDescription {
    if (!_summaryDescription)
    {
        NSMutableString* ret = [[NSMutableString alloc] init];
        for (APIShaderPass* pass in _bufferPasses)
        {
            NSString* outputID = @"";
            if (pass.outputs && pass.outputs.count > 0)
            {
                outputID = ((APIShaderPassOutput*)pass.outputs[0]).outputId;
            }
            for (APIShaderPassInput* input in pass.inputs)
            {
                [ret appendFormat:@"%@ ->[%d] %@\n", input.inputId, input.channel.intValue, outputID];
            }
        }
        if (_imagePass)
        {
            NSString* outputID = @"";
            if (_imagePass.outputs && _imagePass.outputs.count > 0)
            {
                outputID = ((APIShaderPassOutput*)_imagePass.outputs[0]).outputId;
            }
            for (APIShaderPassInput* input in _imagePass.inputs)
            {
                [ret appendFormat:@"%@ ->[%d] %@\n", input.inputId, input.channel.intValue, outputID];
            }
        }
        for (APIShaderPass* pass in _bufferPasses)
        {
            NSString* outputID = @"";
            if (pass.outputs && pass.outputs.count > 0)
            {
                outputID = ((APIShaderPassOutput*)pass.outputs[0]).outputId;
            }
            [ret appendFormat:@"%@:\n", outputID];
            if (pass.code && pass.code.length > 0)
            {
                [ret appendString:pass.code];
                [ret appendString:@"\n"];
            }
            [ret appendString:@"\n"];
        }
        if (_commonPass)
        {
            [ret appendString:@"Common:\n"];
            [ret appendString:_commonPass.code];
            [ret appendString:@"\n"];
        }
        if (_soundPass)
        {
            [ret appendString:@"Sound:\n"];
            [ret appendString:_soundPass.code];
            [ret appendString:@"\n"];
        }
        if (_imagePass)
        {
            [ret appendString:@"Image:\n"];
            [ret appendString:_imagePass.code];
            [ret appendString:@"\n"];
        }
        
        _summaryDescription = [NSString stringWithString:ret];
    }
    return _summaryDescription;
}

const int LicenseNotSpecified = 0;
const int LicenseCC0 = 0x01;
const int LicenseMIT = 0x02;
const int LicenseForbidModify = 0x04;
const int LicenseForbidCommercial = 0x08;
const int LicenseEducationalOnly = 0x10;

+(int) checkForLicense:(NSString*)text {
    static dispatch_once_t once;
    static NSMutableArray<NSMutableArray<NSRegularExpression* >* >* LicensePatternRegs;
    dispatch_once(&once, ^{
        NSArray<NSArray<NSString* >* >* LicensePatterns = @[
            @[@"cc0 license", @"license cc0", @"license: cc0"],
            @[@"mit license"],
            @[@"not modify", @" gpl ", @"general public license"],
            @[@"noncommercial", @"non-commercial", @"non commercial"],
            @[@" or commer", @" or non-commer", @"or noncommer", @" or noncommer"],
        ];
        LicensePatternRegs = [[NSMutableArray alloc] init];
        for (NSArray* patterns in LicensePatterns)
        {
            NSMutableArray<NSRegularExpression* >* regs = [[NSMutableArray alloc] init];
            [LicensePatternRegs addObject:regs];
            for (NSString* pattern in patterns)
            {
                NSRegularExpression* reg = [[NSRegularExpression alloc] initWithPattern:pattern options:(NSRegularExpressionCaseInsensitive) error:nil];
                if (reg)
                {
                    [regs addObject:reg];
                }
            }
        }
    });
    
    if (!text || text.length == 0)
    {
        return 0;
    }
    
    int license = 0;
    int curCode = 0x01;
    for (NSInteger i = 0; i < LicensePatternRegs.count; ++i)
    {
        NSArray<NSRegularExpression* >* regs = LicensePatternRegs[i];
        for (NSRegularExpression* reg in regs)
        {
            NSArray* matches = [reg matchesInString:text options:0 range:NSMakeRange(0, text.length)];
            if (matches.count > 0)
            {
                license |= curCode;
            }
        }
        curCode <<= 1;
    }
    return license;
}

-(void) checkLicense {
    int licenseLevel = 0;
    {
        licenseLevel |= [self.class checkForLicense:_commonPass.code];
    }
    {
        licenseLevel |= [self.class checkForLicense:_imagePass.code];
    }
    for (APIShaderPass* pass in _bufferPasses)
    {
        licenseLevel |= [self.class checkForLicense:pass.code];
    }
    
    _license = licenseLevel;
}

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
    
    [self checkLicense];

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
    [coder encodeInt:self.license forKey:@"license"];
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
        self.license = [coder decodeIntForKey:@"license"];
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
            if (input.type.integerValue == STInputTypeKeyboard) return true;
        }
    }
    for( APIShaderPassInput *input in self.imagePass.inputs ) {
        if (input.type.integerValue == STInputTypeKeyboard) return true;
    }
    return false;
}

@end
