//
//  GLUtils.h
//  Shadertoy
//
//  Created by Reinder Nijhoff on 30/09/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface GLUtils : NSObject

+(GLuint) createRenderBuffer;
+(GLuint) compileShader:(NSString *)VertexShaderCode fragmentShaderCode:(NSString *)FragmentShaderCode theError:(NSString **)error;
+(void) createVAO:(GLuint*)vertexArray buffer:(GLuint*)buffer index:(GLuint*)index;
    
@end
