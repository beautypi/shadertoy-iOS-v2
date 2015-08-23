//
//  ShaderCanvasViewController.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "ShaderObject.h"

@interface ShaderCanvasViewController : GLKViewController

- (BOOL)compileShaderObject:(ShaderObject *)shader theError:(NSString **)error;
- (void)pause;
- (void)resume;

@end
