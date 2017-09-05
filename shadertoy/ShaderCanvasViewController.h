//
//  ShaderCanvasViewController.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "APIShaderObject.h"
#import "VRSettings.h"
#import "ShaderSettings.h"

@interface ShaderCanvasViewController : GLKViewController

- (void) setVRSettings:(VRSettings *)vrSettings;
- (void) setShaderSettings:(ShaderSettings *)shaderSettings;
- (BOOL) compileShader:(APIShaderObject *)shader soundPass:(bool)soundPass theError:(NSString **)error;

- (void) start;
- (void) pause;
- (void) play;
- (void) rewind;
- (BOOL) isRunning;
- (void) setTimeLabel:(UILabel *)label;
- (void) forceDraw;
- (void) setFragCoordScale:(float)scale andXOffset:(float)xOffset andYOffset:(float)yOffset;

- (float) getIGlobalTime;

- (void) renderOneFrame:(float)globalTime success:(void (^)(UIImage *image))success;
- (void) setCanvasScaleFactor:(float)scaleFactor;
- (void) setDefaultCanvasScaleFactor;

- (void) pauseInputs;
- (void) resumeInputs;

- (void) updateKeyboardBufferDown:(int)v;
- (void) updateKeyboardBufferUp:(int)v;

@end
