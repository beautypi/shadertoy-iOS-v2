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

- (BOOL)compileShaderObject:(APIShaderObject *)shader theError:(NSString **)error;

- (void)start;
- (void)pause;
- (void)resume;

- (float)getIGlobalTime;

- (UIImage *)renderOneFrame:(float)globalTime withScaleFactor:(float)scaleFactor;
- (void)setCanvasScaleFactor:(float)scaleFactor;
- (float)getDefaultCanvasScaleFactor;

@end
