//
//  ShaderCanvasInputController.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 06/12/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIShaderObject.h"

typedef NS_ENUM(NSUInteger, ShaderInputFilterMode) {
    NEAREST,
    MIPMAP,
    LINEAR
};

typedef NS_ENUM(NSUInteger, ShaderInputWrapMode) {
    CLAMP,
    REPEAT
};

typedef NS_ENUM(NSUInteger, ShaderInputType) {
    TEXTURE2D,
    TEXTURECUBE,
    KEYBOARD,
    VIDEO,
    WEBCAM,
    MUSIC,
    MICROPHONE,
    SOUNDCLOUD
};

@interface ShaderInput : NSObject

- (void) initWithShaderPassInput:(APIShaderPassInput *)input;
- (void) bindTexture;

- (void) pause;
- (void) play;
- (void) rewindTo:(double)time;
- (void) mute;

@end
