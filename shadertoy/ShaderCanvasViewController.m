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
    {{1, -1., 0}},
    {{1, 1, 0}},
    {{-1, 1, 0}},
    {{-1, -1, 0}}
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

@interface ShaderCanvasViewController () {
    ShaderObject* _shader;
    
    GLuint _programId;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexArray;
    
    GLuint _positionSlot;
    GLuint _resolutionUniform;
    GLuint _globalTimeUniform;
    GLuint _mouseUniform;
    GLuint _dateUniform;
    GLuint _sampleRateUniform;
    GLuint _channelResolutionUniform;
    GLuint _channelTimeUniform;
    GLuint _channelUniform[4];
    
    GLKVector4 _mouse;
    BOOL _mouseDown;
    NSDate *_startTime;
    float *_channelTime;
    float *_channelResolution;
    GLuint _channelTarget[4];
}

@property (strong, nonatomic) EAGLContext *context;

@end

@implementation ShaderCanvasViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void) createShaderProgram:(ShaderPass *)shaderPass {
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    
    NSString *VertexShaderCode = @"\n \
    precision highp float;\n \
    precision highp int;\n \
    attribute vec3 position; \
    void main() { \
    gl_Position.xyz = position; \
    gl_Position.w = 1.0; \
    }";
    
    char const * VertexSourcePointer = [VertexShaderCode UTF8String];
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
    glCompileShader(VertexShaderID);
    
    NSString *FragmentShaderCode = @"\n \
    precision highp float;\n \
    precision highp int;\n \
    precision mediump sampler2D;\n \
    uniform vec3      iResolution;           // viewport resolution (in pixels) \n \
    uniform highp float     iGlobalTime;           // shader playback time (in seconds) \n \
    uniform vec4      iMouse;                // mouse pixel coords \n \
    uniform vec4      iDate;                 // (year, month, day, time in seconds) \n \
    uniform float     iSampleRate;           // sound sample rate (i.e., 44100) \n \
    uniform vec3      iChannelResolution[4]; // channel resolution (in pixels) \n \
    uniform float     iChannelTime[4];       // channel playback time (in sec) \n   \n \
    ";
    
    for( ShaderPassInput* input in shaderPass.inputs )  {
        if( [input.ctype isEqualToString:@"cubemap"] ) {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform mediump samplerCube iChannel%@;\n", input.channel];
        } else {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform mediump sampler2D iChannel%@;\n", input.channel];
        }
    }
    
    FragmentShaderCode = [FragmentShaderCode stringByAppendingString:shaderPass.code];
    FragmentShaderCode = [FragmentShaderCode stringByAppendingString:
    @"void main()  { \n \
        mainImage(gl_FragColor, gl_FragCoord.xy); \n \
    } \n \
    " ];
    
    char const * FragmentSourcePointer = [FragmentShaderCode UTF8String];
    glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , NULL);
    glCompileShader(FragmentShaderID);
    
    GLint logLength;
    glGetShaderiv(FragmentShaderID, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(FragmentShaderID, logLength, &logLength, log);
        NSLog(@"Shader (%@) info log:\n%s", _shader.shaderId, log);
        free(log);
    }
    
    // Link the program
    _programId = glCreateProgram();
    glAttachShader(_programId, VertexShaderID);
    glAttachShader(_programId, FragmentShaderID);
    glLinkProgram(_programId);
    
    glGetProgramiv(_programId, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(_programId, logLength, &logLength, log);
        NSLog(@"Shader (%@) info log:\n%s", _shader.shaderId, log);
        free(log);
    }
    
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
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    glDeleteProgram(_programId);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setAlpha:0.f];
}

- (id)updateWithShaderObject:(ShaderObject *)shader {
    _shader = shader;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.contentScaleFactor = .75f;
    
    [EAGLContext setCurrentContext:self.context];
    
    [self genBuffers];
    [self createShaderProgram:_shader.imagePass];
    [self findUniforms];
    
    self.preferredFramesPerSecond = 20.;
    _startTime = [[NSDate alloc] init];
    
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    __weak typeof (self) weakSelf = self;
    [UIView transitionWithView:weakSelf.view duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [weakSelf.view setAlpha:1.f];
    } completion:nil];
    
    return self;
}

- (void)allocChannels {
    _channelTime = malloc(sizeof(float) * 4);
    _channelResolution = malloc(sizeof(float) * 12);
    memset (_channelTime,0,sizeof(float) * 4);
    memset (_channelResolution,0,sizeof(float) * 12);
}

- (void)findUniforms {
    // Position uniform
    _positionSlot = glGetAttribLocation(_programId, "position");
    
    // Frag Shader uniforms
    _resolutionUniform = glGetUniformLocation(_programId, "iResolution");
    _globalTimeUniform = glGetUniformLocation(_programId, "iGlobalTime");
    _mouseUniform = glGetUniformLocation(_programId, "iMouse");
    _dateUniform = glGetUniformLocation(_programId, "iDate");
    _sampleRateUniform = glGetUniformLocation(_programId, "iSampleRate");
    _channelTimeUniform = glGetUniformLocation(_programId, "iChannelTime");
    _channelResolutionUniform = glGetUniformLocation(_programId, "iChannelResolution");
    
    for (ShaderPassInput* input in _shader.imagePass.inputs)  {
        NSString* channel = [NSString stringWithFormat:@"iChannel%@", input.channel];
        NSLog(@"%@ %@ %@\n", channel, input.ctype, input.src );
        if( [input.ctype isEqualToString:@"texture"] ) {
            // load texture to channel
            NSError *theError;
            NSString* url = [@"https://www.shadertoy.com" stringByAppendingString:input.src];
            //GLKTextureInfo *spriteTexture = [GLKTextureLoader textureWithContentsOfURL:[NSURL URLWithString:url] options:nil error:&theError];
            
            NSString* file = [[@"." stringByAppendingString:input.src] stringByReplacingOccurrencesOfString:@".jpg" withString:@".png"];
            NSLog(@"load %@\n", file);
            
            NSLog(@"GL Error = %u", glGetError());
            
            GLKTextureInfo *spriteTexture = [GLKTextureLoader textureWithCGImage:[[UIImage imageNamed:file] CGImage] options:nil error:&theError];
            
            NSLog( @"%@\n%@\n\n\n", theError.description, theError.debugDescription );
            
            
            NSLog(@"GL Error = %u", glGetError());
            _channelUniform[ [input.channel integerValue] ] = glGetUniformLocation(_programId, channel.UTF8String );
            _channelTarget[  [input.channel integerValue] ] = spriteTexture.name;
        }
    }
}

- (void)bindUniforms {
    GLKVector3 resolution = GLKVector3Make( self.view.frame.size.width * self.view.contentScaleFactor, self.view.frame.size.height * self.view.contentScaleFactor, 1. );
    glUniform3fv(_resolutionUniform, 1, &resolution.x );
    
    NSDate* now = [[NSDate alloc] init];
    float currenttime = [now timeIntervalSinceDate:_startTime];
    glUniform1f(_globalTimeUniform, currenttime );
    
    glUniform4f(_mouseUniform, _mouse.x * self.view.contentScaleFactor, _mouse.y * self.view.contentScaleFactor, _mouse.z * self.view.contentScaleFactor, _mouse.w * self.view.contentScaleFactor );
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:kCFCalendarUnitYear | kCFCalendarUnitMonth | kCFCalendarUnitDay | kCFCalendarUnitHour | kCFCalendarUnitMinute | kCFCalendarUnitSecond fromDate:now];
    glUniform4f(_dateUniform, components.year, components.month, components.day, (components.hour * 60 * 60) + (components.minute * 60) + components.second);
    
    for( int i=0; i<4; i++ )  {
        glUniform1i(_channelUniform[i], i);
    }
}

- (void)dealloc {
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}


#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self bindUniforms];
    
    glUseProgram(_programId);
    
    for( int i=0; i<4; i++ )  {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _channelTarget[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    }
    
    glBindVertexArrayOES(_vertexArray);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
}

#pragma mark - GLKViewControllerDelegate

- (void)update {
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch1 = [touches anyObject];
    CGPoint touchLocation = [touch1 locationInView:self.view];
    _mouse.x = _mouse.z = touchLocation.x;
    _mouse.y = _mouse.w = self.view.layer.frame.size.height-touchLocation.y;
    
    _mouseDown = YES;
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    _mouseDown = YES;
    
    UITouch *touch1 = [touches anyObject];
    CGPoint touchLocation = [touch1 locationInView:self.view];
    _mouse.x = touchLocation.x;
    _mouse.y = self.view.layer.frame.size.height-touchLocation.y;
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    _mouseDown = YES;
    _mouse.z = -fabsf(_mouse.z);
    _mouse.w = -fabsf(_mouse.w);
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _mouseDown = YES;
    _mouse.z = -fabsf(_mouse.z);
    _mouse.w = -fabsf(_mouse.w);
}

@end
