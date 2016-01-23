//
//  ShaderPassRenderer.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 23/01/16.
//  Copyright © 2016 Reinder Nijhoff. All rights reserved.
//

#import "ShaderPassRenderer.h"
#import "ShaderCanvasInputController.h"

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#import "Utils.h"

const float Vertices[] = {
    1, -1, 0,
    1,  1, 0,
    -1,  1, 0,
    -1, -1, 0
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

@interface ShaderPassRenderer () {
    VRSettings* _vrSettings;
    APIShaderPass* _shaderPass;
    
    GLuint _programId;
    
    GLuint _positionSlot;
    GLuint _resolutionUniform;
    GLuint _globalTimeUniform;
    GLuint _mouseUniform;
    GLuint _dateUniform;
    
    GLuint _sampleRateUniform;
    float _iSampleRate;
    GLuint _channelResolutionUniform;
    float *_channelResolution;
    GLuint _channelTimeUniform;
    float *_channelTime;
    GLuint _channelUniform[4];
    
    NSMutableArray *_shaderInputs;
    GLuint _ifFragCoordOffsetUniform;
    
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexArray;
    
    GLKVector3 _resolution;
    float _iGlobalTime;
    NSDate *_date;
    GLKVector4 _mouse;
    float _ifFragCoordScale;
    float _ifFragCoordOffsetXY[2];
}
@end


@implementation ShaderPassRenderer


- (id) init {
    self = [super init];
    [self allocChannels];
    _programId = 0;
    
    return self;
}

#pragma mark - VR

- (void) setVRSettings:(VRSettings *)vrSettings {
    _vrSettings = vrSettings;
}

- (void)createBuffers {
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);
}

- (BOOL) createShaderProgram:(APIShaderPass *)shaderPass theError:(NSString **)error {
    _shaderPass = shaderPass;
    
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    
    NSString *VertexShaderCode;
    
    if( _vrSettings ) {
        VertexShaderCode = [_vrSettings getVertexShaderCode];
    } else {
        VertexShaderCode = [[NSString alloc] readFromFile:@"/shaders/vertex_main" ofType:@"glsl"];
    }
    
    char const * VertexSourcePointer = [VertexShaderCode UTF8String];
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
    glCompileShader(VertexShaderID);
    
    NSString *FragmentShaderCode =[[NSString alloc] readFromFile:@"/shaders/fragment_base_uniforms" ofType:@"glsl"];
    
    for( APIShaderPassInput* input in shaderPass.inputs )  {
        if( [input.ctype isEqualToString:@"cubemap"] ) {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform mediump samplerCube iChannel%@;\n", input.channel];
        } else {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform mediump sampler2D iChannel%@;\n", input.channel];
        }
    }
    
    NSString *code = shaderPass.code;
    code = [code stringByReplacingOccurrencesOfString:@"precision " withString:@"//precision "];
    
    FragmentShaderCode = [FragmentShaderCode stringByAppendingString:code];
    
    if( [shaderPass.type isEqualToString:@"sound"] ) {
        FragmentShaderCode = [FragmentShaderCode stringByAppendingString:[[NSString alloc] readFromFile:@"/shaders/fragment_main_sound" ofType:@"glsl"]];
    } else if( _vrSettings ) {
        FragmentShaderCode = [FragmentShaderCode stringByAppendingString:[_vrSettings getFragmentShaderCode]];
    } else {
        FragmentShaderCode = [FragmentShaderCode stringByAppendingString:[[NSString alloc] readFromFile:@"/shaders/fragment_main_image" ofType:@"glsl"]];
    }
    
    char const * FragmentSourcePointer = [FragmentShaderCode UTF8String];
    glShaderSource(FragmentShaderID, 1, &FragmentSourcePointer , NULL);
    glCompileShader(FragmentShaderID);
    
    GLint logLength;
    glGetShaderiv(FragmentShaderID, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(FragmentShaderID, logLength, &logLength, log);
        *error = [NSString stringWithFormat:@"%s", log];
        free(log);
        
        return NO;
    }
    
    _programId = glCreateProgram();
    glAttachShader(_programId, VertexShaderID);
    glAttachShader(_programId, FragmentShaderID);
    glLinkProgram(_programId);
    
    glDeleteShader(VertexShaderID);
    glDeleteShader(FragmentShaderID);
    
    glGetProgramiv(_programId, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(_programId, logLength, &logLength, log);
        *error = [NSString stringWithFormat:@"%s", log];
        free(log);
        
        return NO;
    }
    
    [self createBuffers];
    [self findUniforms];
    [self initShaderPassInputs];
    
    return YES;
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
    
    _ifFragCoordOffsetUniform = glGetUniformLocation(_programId, "ifFragCoordOffsetUniform");
    
    
    for (APIShaderPassInput* input in _shaderPass.inputs)  {
        NSString* channel = [NSString stringWithFormat:@"iChannel%@", input.channel];
        int c = MAX( MIN( (int)[input.channel integerValue], 3 ), 0);
        _channelUniform[ c ] = glGetUniformLocation(_programId, channel.UTF8String );
    }
}

- (void) setFragCoordScale:(float)scale andXOffset:(float)xOffset andYOffset:(float)yOffset {
    _ifFragCoordScale = scale;
    _ifFragCoordOffsetXY[0] = xOffset;
    _ifFragCoordOffsetXY[1] = yOffset;
}

- (void) setMouse:(GLKVector4) mouse {
    _mouse = mouse;
}

- (void) setDate:(NSDate *)date {
    _date = date;
}

- (void) setResolution:(float)x y:(float)y {
    _resolution = GLKVector3Make( x,y, 1. );
}

- (void) setIGlobalTime:(float)iGlobalTime {
    _iGlobalTime = iGlobalTime;
}

- (float) getIGlobalTime {
    return _iGlobalTime;
}

- (void)bindUniforms {
    glUniform3fv(_resolutionUniform, 1, &_resolution.x );
    glUniform1f(_globalTimeUniform, [self getIGlobalTime] );
    glUniform4f(_mouseUniform, _mouse.x * _resolution.x, _mouse.y * _resolution.y, _mouse.z * _resolution.x, _mouse.w * _resolution.y);
    glUniform3fv(_channelResolutionUniform, 4, _channelResolution);
    glUniform2fv(_ifFragCoordOffsetUniform, 1, _ifFragCoordOffsetXY);
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:kCFCalendarUnitYear | kCFCalendarUnitMonth | kCFCalendarUnitDay | kCFCalendarUnitHour | kCFCalendarUnitMinute | kCFCalendarUnitSecond fromDate:_date];
    double seconds = [_date timeIntervalSince1970];
    glUniform4f(_dateUniform, components.year, components.month, components.day, (components.hour * 60 * 60) + (components.minute * 60) + components.second + (seconds - floor(seconds)) );
    
    for( int i=0; i<4; i++ )  {
        if( _channelUniform[i] < 99 ) {
            glUniform1i(_channelUniform[i], i);
        }
    }
}

- (void) initShaderPassInputs {
    for (APIShaderPassInput* input in _shaderPass.inputs)  {
        ShaderCanvasInputController* inputController = [[ShaderCanvasInputController alloc] init];
        [inputController initWithShaderPassInput:input];
        
        [_shaderInputs addObject:inputController];
    }
}

- (void)allocChannels {
    _shaderInputs = [[NSMutableArray alloc] initWithCapacity:4];
    
    _channelTime = malloc(sizeof(float) * 4);
    _channelResolution = malloc(sizeof(float) * 12);
    
    memset (_channelTime,0,sizeof(float) * 4);
    memset (_channelResolution,0,sizeof(float) * 12);
    
    memset (&_channelUniform[0],99,sizeof(GLuint) * 4);
    
    free(_channelTime);
    free(_channelResolution);
}

- (void) dealloc {
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    glDeleteProgram(_programId);
}

- (void)start {
    for( ShaderCanvasInputController* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:0];
        [shaderInput play];
    }
}
- (void) pauseInputs {
    double globalTime = [self getIGlobalTime];
    for( ShaderCanvasInputController* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:globalTime];
        [shaderInput pause];
    }
}

- (void) resumeInputs {
    double globalTime = [self getIGlobalTime];
    for( ShaderCanvasInputController* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:globalTime];
        [shaderInput play];
    }
}

- (void)rewind {
    [self setIGlobalTime:0];
    for( ShaderCanvasInputController* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:0];
    }
}

- (void) render {
    if( !_programId ) return;
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(_programId);
    
    [self bindUniforms];
    
    for( ShaderCanvasInputController* shaderInput in _shaderInputs ) {
        [shaderInput bindTexture];
    }
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (const GLvoid *) 0);
    
    
    glBindVertexArrayOES(_vertexArray);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}

@end
