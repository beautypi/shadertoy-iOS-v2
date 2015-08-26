//
//  ShaderCanvasViewController.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "APIShaderObject.h"

@interface ShaderCanvasViewController : GLKViewController

- (BOOL) compileShaderPass:(APIShaderPass *)shader theError:(NSString **)error;

- (void) start;
- (void) pause;
- (void) play;
- (void) rewind;
- (BOOL) isRunning;
- (void) setTimeLabel:(UILabel *)label;
- (void) forceDraw;

- (float) getIGlobalTime;

- (void) renderOneFrame:(float)globalTime success:(void (^)(UIImage *image))success;
- (void) setCanvasScaleFactor:(float)scaleFactor;
- (void) setDefaultCanvasScaleFactor;

@end
