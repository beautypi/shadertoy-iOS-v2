//
//  ShaderPassRenderer.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 23/01/16.
//  Copyright © 2016 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "APIShaderObject.h"
#import "VRSettings.h"
#import "ShaderSettings.h"

@interface ShaderPassRenderer : NSObject

- (BOOL) createShaderProgram:(APIShaderPass *)shaderPass commonPass:(APIShaderPass *)commonPass theError:(NSString **)error;

- (void) setVRSettings:(VRSettings *)vrSettings;
- (void) setShaderSettings:(ShaderSettings *)shaderSettings;
- (void) setFragCoordScale:(float)scale andXOffset:(float)xOffset andYOffset:(float)yOffset;
- (void) setResolution:(float)x y:(float)y;
- (void) setTime:(float)time;
- (void) setDate:(NSDate *)date;
- (void) setMouse:(GLKVector4) mouse;
- (void) setFrame:(int) frame;
- (void) setTimeDelta:(float)deltaTime;

- (void) render:(NSMutableArray *)shaderPasses;
- (void) nextFrame;
- (void) updateShaderInputs:(unsigned char*)keyboardBuffer;

- (void) start;
- (void) pauseInputs;
- (void) resumeInputs;
- (void) rewind;

- (NSNumber *) getOutputId;
- (GLuint) getCurrentTexId;

- (float) getWidth;
- (float) getHeight;
- (float) getDepth;
- (float) getTime;

@end
