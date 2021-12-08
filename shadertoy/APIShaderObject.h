//
//  ShaderObject.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

typedef NS_ENUM(NSInteger, STInputType) {
    STInputTypeTexture = 0, //"texture"
    STInputTypeCubemap = 1, //"cubemap"
    STInputTypeVolume = 2, //"volume"
    STInputTypeBuffer = 3, //"buffer"
    STInputTypeKeyboard = 4, //"keyboard"
    STInputTypeVideo = 5, //"video"
    STInputTypeMusic = 6, //"music"
    STInputTypeMusicStream = 7, //"musicstream"
    STInputTypeWebCam = 8, //"webcam"
    STInputTypeMic = 9, //"mic"
    STInputTypeInvalid = 100
};

typedef NS_ENUM(NSInteger, STSamplerFilter) {
    STSamplerFilterNearest = 0, //"nearest"
    STSamplerFilterLinear = 1, //"linear"
    STSamplerFilterMipmap = 2, //"mipmap"
    STSamplerFilterInvalid = 100
};

typedef NS_ENUM(NSInteger, STSamplerWrap) {
    STSamplerWrapRepeat = 0, //"repeat"
    STSamplerWrapClamp = 1, //"clamp"
    STSamplerWrapInvalid = 100
};

typedef NS_ENUM(NSInteger, STPassType) {
    STPassTypeImage = 0, //"image"
    STPassTypeBuffer = 1, //"buffer"
    STPassTypeSound = 2, //"sound"
    STPassTypeCommon = 3, //"common"
    STPassTypeInvalid = 100
};

@interface APIShaderPassInputSampler : NSObject

- (APIShaderPassInputSampler *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, copy) NSNumber* filter;
@property (nonatomic, copy) NSNumber* wrap;
@property (nonatomic, strong) NSString* vflip;
@property (nonatomic, strong) NSString* srgb;

@end

@interface APIShaderPassInput : NSObject

- (APIShaderPassInput *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, copy) NSString* inputId;
@property (nonatomic, copy) NSString* filepath;
@property (nonatomic, copy) NSNumber* type;
@property (nonatomic, strong) NSNumber* channel;
@property (nonatomic, strong) APIShaderPassInputSampler *sampler;

@end


@interface APIShaderPassOutput : NSObject

- (APIShaderPassOutput *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, copy) NSString* outputId;
@property (nonatomic, strong) NSNumber* channel;

@end


@interface APIShaderPass : NSObject

- (APIShaderPass *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, strong) NSMutableArray<APIShaderPassInput*>* inputs;
@property (nonatomic, strong) NSMutableArray<APIShaderPassOutput*>* outputs;
@property (nonatomic, copy) NSString* code;
@property (nonatomic, copy) NSNumber* type;
@property (nonatomic, copy) NSString* name;

@end


extern const int LicenseNotSpecified;
extern const int LicenseCC0;
extern const int LicenseMIT;
extern const int LicenseForbidModify;
extern const int LicenseForbidCommercial;
extern const int LicenseEducationalOnly;

@interface APIShaderObject : NSObject<NSCoding>

- (APIShaderObject *) updateWithDict:(NSDictionary *) dict;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;

@property (nonatomic, copy) NSString* summaryDescription;

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

@property (nonatomic, strong) NSDate *dateLastUpdated;

@property (nonatomic, weak)   NSURLSessionDataTask *requestOperation;

@property (nonatomic, assign) int license;

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
