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

@interface ShaderPassRenderer : NSObject

- (BOOL) createShaderProgram:(APIShaderPass *)shaderPass theError:(NSString **)error;

- (void) setVRSettings:(VRSettings *)vrSettings;
- (void) setFragCoordScale:(float)scale andXOffset:(float)xOffset andYOffset:(float)yOffset;
- (void) setResolution:(float)x y:(float)y;
- (void) setIGlobalTime:(float)iGlobalTime;
- (void) setDate:(NSDate *)date;
- (void) setMouse:(GLKVector4) mouse;

- (void) render;

- (void) start;
- (void) pauseInputs;
- (void) resumeInputs;
- (void) rewind;

@end
