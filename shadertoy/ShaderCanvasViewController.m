//
//  ShaderCanvasViewController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "ShaderCanvasViewController.h"
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

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

@interface ShaderCanvasViewController () {
    GLuint _programId;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexArray;
}
@property (strong, nonatomic) EAGLContext *context;

@end

@implementation ShaderCanvasViewController

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void) createShaderProgram {
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    
    NSString *VertexShaderCode = @"attribute vec3 vertexPosition_modelspace; \
    void main() { \
    gl_Position.xyz = vertexPosition_modelspace; \
    gl_Position.w = 1.0; \
    }";
    
    char const * VertexSourcePointer = [VertexShaderCode UTF8String];
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
    glCompileShader(VertexShaderID);
    
    NSString *FragmentShaderCode = @"\
    void main() { \
    gl_FragColor = vec4(1.,1.,0.,1.); \
    }";
    
    char const * FragmentSourcePointer = [FragmentShaderCode UTF8String];
    glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , NULL);
    glCompileShader(FragmentShaderID);
   
    // Link the program
    _programId = glCreateProgram();
    glAttachShader(_programId, VertexShaderID);
    glAttachShader(_programId, FragmentShaderID);
    glLinkProgram(_programId);
    
    glDeleteShader(VertexShaderID);
    glDeleteShader(FragmentShaderID);
}

- (void)genBuffers {
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    //glDeleteVertexArraysOES(1, &_vertexArray);
    glDeleteProgram(_programId);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    
    [EAGLContext setCurrentContext:self.context];
    
    [self createShaderProgram];
    [self genBuffers];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}


#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(1., 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(_programId);
    
    glBindVertexArrayOES(_vertexArray);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
}

#pragma mark - GLKViewControllerDelegate

- (void)update {
}

@end
