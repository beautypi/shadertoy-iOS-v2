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
    TEXTURE3D,
    TEXTURECUBE,
    KEYBOARD,
    VIDEO,
    WEBCAM,
    MUSIC,
    MICROPHONE,
    SOUNDCLOUD,
    BUFFER
};

@interface ShaderInput : NSObject

- (void) initWithShaderPassInput:(APIShaderPassInput *)input;
- (void) update:(unsigned char*)keyboardBuffer;
- (void) bindTexture:(NSMutableArray *)shaderPasses;

- (void) pause;
- (void) play;
- (void) rewindTo:(double)time;
- (void) mute;

- (float) getWidth;
- (float) getHeight;
- (float) getDepth;
- (float) getTime;

- (int) getChannel;

- (void) updateSpectrum:(unsigned char *)data;

@end
