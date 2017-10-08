//
//  GLUtils.m
//  Shadertoy
//
//  Created by Reinder Nijhoff on 30/09/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import "GLUtils.h"

const float Vertices[] = {
    1, -1, 0,    1,0,
    1,  1, 0,    1,1,
    -1,  1, 0,   0,1,
    -1, -1, 0,   0,0
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

@implementation GLUtils
    
+(GLuint) createRenderBuffer {
    GLint drawFboId;
    GLuint frameBuffer;
    
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &drawFboId);
    
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, drawFboId);
    
    return frameBuffer;
}
    
+(GLuint) compileShader:(NSString *)VertexShaderCode fragmentShaderCode:(NSString *)FragmentShaderCode theError:(NSString **)error {
    GLint logLength;
    
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    
    char const * VertexSourcePointer = [VertexShaderCode UTF8String];
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
    glCompileShader(VertexShaderID);
    
    glGetShaderiv(VertexShaderID, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(VertexShaderID, logLength, &logLength, log);
        *error = [NSString stringWithFormat:@"%s", log];
        free(log);
        
        glDeleteShader(VertexShaderID);
        glDeleteShader(FragmentShaderID);
        
        return -1;
    }
    
    char const * FragmentSourcePointer = [FragmentShaderCode UTF8String];
    glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , NULL);
    glCompileShader(FragmentShaderID);
    
    glGetShaderiv(FragmentShaderID, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(FragmentShaderID, logLength, &logLength, log);
        *error = [NSString stringWithFormat:@"%s", log];
        free(log);
        
        glDeleteShader(VertexShaderID);
        glDeleteShader(FragmentShaderID);
        
        return -1;
    }
    
    GLuint programId = glCreateProgram();
    glAttachShader(programId, VertexShaderID);
    glAttachShader(programId, FragmentShaderID);
    glLinkProgram(programId);
    
    glDeleteShader(VertexShaderID);
    glDeleteShader(FragmentShaderID);
    
    glGetProgramiv(programId, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(programId, logLength, &logLength, log);
        *error = [NSString stringWithFormat:@"%s", log];
        free(log);
        
        return -1;
    }
    
    return programId;
}
    
+(void) createVAO:(GLuint*)vertexArray buffer:(GLuint*)buffer index:(GLuint*)index {
    glGenVertexArrays(1, vertexArray);
    glBindVertexArray(*vertexArray);
    
    glGenBuffers(1, buffer);
    glBindBuffer(GL_ARRAY_BUFFER, *buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (const GLvoid *) 0);
    
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (const GLvoid *) 3);
    
    glGenBuffers(1, index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    glBindVertexArray(0);
}
    
@end
