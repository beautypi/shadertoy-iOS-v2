//
//  shader.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#ifndef __shadertoy__shader__
#define __shadertoy__shader__

#include <stdio.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#if __cplusplus
extern "C" {
#endif
    
void initVertexBuffer();
void cleanupVertexBuffer();
GLuint createShaderProgram( const char* shaderCode );
void cleanupShaderProgram( GLuint programID );
void renderShader( GLuint programID );

#if __cplusplus
}
#endif

#endif /* defined(__shadertoy__shader__) */
