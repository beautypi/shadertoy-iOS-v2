//
//  shader.cpp
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#include "shader.h"

#include <string>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

using namespace std;

GLuint _vertexBuffer;
GLuint _indexBuffer;

typedef struct {
    float Position[3];
} Vertex;

const Vertex Vertices[] = {
    {{1, -.5, 0}},
    {{1, 1, 0}},
    {{-1, 1, 0}},
    {{-1, -1, 0}}
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

void initVertexBuffer() {
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

void cleanupVertexBuffer() {
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
}

GLuint createShaderProgram( const char* shaderCode ) {
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    
    string VertexShaderCode = "attribute vec3 vertexPosition_modelspace; \
    void main() { \
        gl_Position.xyz = vertexPosition_modelspace; \
        gl_Position.w = 1.0; \
    }";

    char const * VertexSourcePointer = VertexShaderCode.c_str();
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
    glCompileShader(VertexShaderID);

    string FragmentShaderCode = " \
    void main() { \
        gl_FragColor = vec4(1.,1.,0.,1.); \
    }";
    
    char const * FragmentSourcePointer = FragmentShaderCode.c_str();
    glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , NULL);
    glCompileShader(FragmentShaderID);
    
    // Link the program
    GLuint ProgramID = glCreateProgram();
    glAttachShader(ProgramID, VertexShaderID);
    glAttachShader(ProgramID, FragmentShaderID);
    glLinkProgram(ProgramID);
    
    glDeleteShader(VertexShaderID);
    glDeleteShader(FragmentShaderID);
    
    return ProgramID;
}

void cleanupShaderProgram( GLuint programID ) {
    glDeleteProgram(programID);
}

void renderShader( GLuint programID ) {
    glClearColor(1., 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(programID);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    glDisableVertexAttribArray(0);
}




