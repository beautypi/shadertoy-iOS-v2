//
//  ShaderPassRenderer.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 23/01/16.
//  Copyright © 2016 Reinder Nijhoff. All rights reserved.
//

#import "ShaderPassRenderer.h"
#import "ShaderInput.h"

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
    GLuint _timeDeltaUniform;            // render time (in seconds)
    GLuint _frameUniform;                // shader playback frame
    GLuint _deviceRotationUniform;
    
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
    int _frame;
    float _deltaTime;
    
    GLuint _frameBuffer;
    GLuint _renderTexture0, _renderTexture1;
    bool _currentRenderTexture;
    bool _renderToBuffer;
    int _renderBufferWidth, _renderBufferHeight;
    
    GLuint _copyProgramId;
    GLuint _copyRenderTexture;
    GLuint _copyResolutionSourceUniform;
    GLuint _copyResolutionTargetUniform;
    GLuint _copyTextureUniform;
}

@end


@implementation ShaderPassRenderer

- (id) init {
    self = [super init];
    [self allocChannels];
    _programId = 0;
    _renderToBuffer = false;
    _currentRenderTexture = true;
    
    return self;
}

#pragma mark - VR

- (void) setVRSettings:(VRSettings *)vrSettings {
    _vrSettings = vrSettings;
}

- (void) initVertexBuffer {
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

- (void) initRenderBuffers {
    if( [_shaderPass.type isEqualToString:@"buffer"] ) {
        _renderToBuffer = true;
        GLint drawFboId;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &drawFboId);
        
        glGenFramebuffers(1, &_frameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        
        _renderBufferWidth = _renderBufferHeight = -1;
        
        glGenTextures(1, &_renderTexture0);
        glGenTextures(1, &_renderTexture1);
        glGenTextures(1, &_copyRenderTexture);
        
        glBindFramebuffer(GL_FRAMEBUFFER, drawFboId);
    }
}

- (int) compileShader:(NSString *)VertexShaderCode fragmentShaderCode:(NSString *)FragmentShaderCode theError:(NSString **)error {
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    
    char const * VertexSourcePointer = [VertexShaderCode UTF8String];
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
    glCompileShader(VertexShaderID);
    
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
    
    return (int)programId;
}

- (BOOL) createShaderProgram:(APIShaderPass *)shaderPass theError:(NSString **)error {
    _shaderPass = shaderPass;
    
    NSString *VertexShaderCode;
    
    if( _vrSettings ) {
        VertexShaderCode = [_vrSettings getVertexShaderCode];
    } else {
        VertexShaderCode = [[NSString alloc] readFromFile:@"/shaders/vertex_main" ofType:@"glsl"];
    }
    
    
    NSString *FragmentShaderCode =[[NSString alloc] readFromFile:@"/shaders/fragment_base_uniforms" ofType:@"glsl"];
    
    bool channelsUsed[4];
    for( int i=0; i<4; i++ ) {
        channelsUsed[i] = false;
    }
    for( APIShaderPassInput* input in shaderPass.inputs )  {
        channelsUsed[[input.channel intValue]] = true;
        if( [input.ctype isEqualToString:@"cubemap"] ) {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform mediump samplerCube iChannel%@;\n", input.channel];
        } else {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform mediump sampler2D iChannel%@;\n", input.channel];
        }
    }
    for( int i=0; i<4; i++ ) {
        if( !channelsUsed[i] ) {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform mediump sampler2D iChannel%d;\n", i];
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
    
    int programId = [self compileShader:VertexShaderCode fragmentShaderCode:FragmentShaderCode theError:error];
    if( programId < 0 ) {
        return NO;
    }
    _programId = programId;
    
    [self findUniforms];
    
    [self initVertexBuffer];
    [self initShaderPassInputs];
    [self initRenderBuffers];
    [self initCopyProgram];
    
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
    _timeDeltaUniform = glGetUniformLocation(_programId, "iTimeDelta");
    _frameUniform = glGetUniformLocation(_programId, "iFrame");
    _ifFragCoordOffsetUniform = glGetUniformLocation(_programId, "ifFragCoordOffsetUniform");
    _deviceRotationUniform = glGetUniformLocation(_programId, "iDeviceRotationUniform");
    
    for (APIShaderPassInput* input in _shaderPass.inputs) {
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

- (void) setFrame:(int) frame {
    _frame = frame;
}

- (void) setTimeDelta:(float)deltaTime {
    _deltaTime = deltaTime;
}

- (void) initCopyProgram {
    if( [_shaderPass.type isEqualToString:@"buffer"] ) {
        NSString *VertexShaderCode = [[NSString alloc] readFromFile:@"/shaders/vertex_main" ofType:@"glsl"];
        NSString *FragmentShaderCode =[[NSString alloc] readFromFile:@"/shaders/fragment_main_copy" ofType:@"glsl"];
        NSString *error;
        
        _copyProgramId = [self compileShader:VertexShaderCode fragmentShaderCode:FragmentShaderCode theError:&error];
        
        _copyResolutionSourceUniform = glGetUniformLocation(_copyProgramId, "sourceResolution");
        _copyResolutionTargetUniform = glGetUniformLocation(_copyProgramId, "targetResolution");
        _copyTextureUniform = glGetUniformLocation(_copyProgramId, "sourceTexture");
    }
}

- (void) copyTexture:(GLuint)source target:(GLuint)target sw:(int)sw sh:(int)sh tw:(int)tw th:(int)th {
    if( sw <= 0 || sh <= 0 ) return;
    
    GLint drawFboId = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &drawFboId);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, target, 0);
    
    glViewport(0, 0, tw, th);
    
    glUseProgram(_copyProgramId);
    
    glUniform1i(_copyTextureUniform, 0);
    glUniform2f(_copyResolutionSourceUniform, (float)sw, (float)sh);
    glUniform2f(_copyResolutionTargetUniform, (float)tw, (float)th);
    
    glActiveTexture(GL_TEXTURE0 );
    glBindTexture(GL_TEXTURE_2D, source);
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (const GLvoid *) 0);
    
    glBindVertexArrayOES(_vertexArray);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, drawFboId);
}

- (void) setResolution:(float)x y:(float)y {
    _resolution = GLKVector3Make( x,y, 1. );
    
    if( _renderToBuffer && ((int)x != _renderBufferWidth || (int)y != _renderBufferHeight)) {
        int oldBufferWidth = _renderBufferWidth;
        int oldBufferHeight = _renderBufferHeight;
        
        if( oldBufferWidth >= 0 && oldBufferHeight >=0 ) {
            glBindTexture(GL_TEXTURE_2D, _copyRenderTexture);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, oldBufferWidth, oldBufferHeight, 0,GL_RGBA, GL_HALF_FLOAT_OES, NULL);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
        
        _renderBufferWidth = (int)x;
        _renderBufferHeight = (int)y;
        
        [self copyTexture:_renderTexture0 target:_copyRenderTexture sw:oldBufferWidth sh:oldBufferHeight tw:oldBufferWidth th:oldBufferHeight];
        glBindTexture(GL_TEXTURE_2D, _renderTexture0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _renderBufferWidth, _renderBufferHeight, 0,GL_RGBA, GL_HALF_FLOAT_OES, NULL);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        [self copyTexture:_copyRenderTexture target:_renderTexture0 sw:oldBufferWidth sh:oldBufferHeight tw:_renderBufferWidth th:_renderBufferHeight];
        
        [self copyTexture:_renderTexture1 target:_copyRenderTexture sw:oldBufferWidth sh:oldBufferHeight tw:oldBufferWidth th:oldBufferHeight];
        glBindTexture(GL_TEXTURE_2D, _renderTexture1);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _renderBufferWidth, _renderBufferHeight, 0,GL_RGBA, GL_HALF_FLOAT_OES, NULL);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        [self copyTexture:_copyRenderTexture target:_renderTexture1 sw:oldBufferWidth sh:oldBufferHeight tw:_renderBufferWidth th:_renderBufferHeight];
    }
}

- (float) getWidth {
    return (float) _renderBufferWidth;
}

- (float) getHeight {
    return (float) _renderBufferHeight;
}

- (void) setIGlobalTime:(float)iGlobalTime {
    _iGlobalTime = iGlobalTime;
}

- (float) getIGlobalTime {
    return _iGlobalTime;
}

- (void)bindUniforms {
    for( ShaderInput* shaderInput in _shaderInputs ) {
        _channelResolution[ [shaderInput getChannel]*3 + 0 ] = [shaderInput getResolutionWidth];
        _channelResolution[ [shaderInput getChannel]*3 + 1 ] = [shaderInput getResolutionHeight];
    }
    
    glUniform3fv(_resolutionUniform, 1, &_resolution.x );
    glUniform1f(_globalTimeUniform, [self getIGlobalTime] );
    glUniform4f(_mouseUniform, _mouse.x * _resolution.x, _mouse.y * _resolution.y, _mouse.z * _resolution.x, _mouse.w * _resolution.y);
    glUniform3fv(_channelResolutionUniform, 4, _channelResolution);
    glUniform2fv(_ifFragCoordOffsetUniform, 1, _ifFragCoordOffsetXY);
    glUniform1i(_frameUniform, _frame);
    glUniform1f(_timeDeltaUniform, _deltaTime);
    
    if( _deviceRotationUniform > 0 && _vrSettings ) {
//        GLKVector3 attitude = [_vrSettings getDeviceRotation];
//        glUniform3fv( _deviceRotationUniform, 1, &attitude.x );
        GLKMatrix3 mat = [_vrSettings getDeviceRotationMatrix];
        glUniformMatrix3fv(_deviceRotationUniform, 1, false, &mat.m00);
    }
   
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
        ShaderInput* inputController = [[ShaderInput alloc] init];
        [inputController initWithShaderPassInput:input];
        
        [_shaderInputs addObject:inputController];
    }
}

- (NSNumber *) getOutputId {
    return ((APIShaderPassOutput *)[_shaderPass.outputs objectAtIndex:0]).outputId;
}

- (void)allocChannels {
    _shaderInputs = [[NSMutableArray alloc] initWithCapacity:4];
    
    _channelTime = malloc(sizeof(float) * 4);
    _channelResolution = malloc(sizeof(float) * 12);
    
    memset (_channelTime,0,sizeof(float) * 4);
    memset (_channelResolution,0,sizeof(float) * 12);
    
    memset (&_channelUniform[0],99,sizeof(GLuint) * 4);
}

- (void) dealloc {
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    glDeleteProgram(_programId);
    glDeleteProgram(_programId);
    
    if( _renderToBuffer ) {
        glDeleteTextures(1, &_copyRenderTexture);
        glDeleteProgram(_copyProgramId);
        
        glDeleteFramebuffers(1, &_frameBuffer);
        glDeleteTextures(1, &_renderTexture0);
        glDeleteTextures(1, &_renderTexture1);
    }
    
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput stop];
    }
    [_shaderInputs removeAllObjects];
        
    free(_channelTime);
    free(_channelResolution);
}

- (void)start {
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:0];
        [shaderInput play];
    }
}
- (void) pauseInputs {
    double globalTime = [self getIGlobalTime];
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:globalTime];
        [shaderInput pause];
    }
}

- (void) resumeInputs {
    double globalTime = [self getIGlobalTime];
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:globalTime];
        [shaderInput play];
    }
}

- (void)rewind {
    [self setIGlobalTime:0];
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:0];
    }
}

- (GLuint) getCurrentTexId {
    return _currentRenderTexture?_renderTexture1:_renderTexture0;
}

- (GLuint) getNextTexId {
    return _currentRenderTexture?_renderTexture0:_renderTexture1;
}

- (void) nextFrame {
    _currentRenderTexture = !_currentRenderTexture;
}

- (void) render:(NSMutableArray *)shaderPasses keyboardBuffer:(unsigned char*)keyboardBuffer {
    if( !_programId ) return;
    
    GLint drawFboId = 0;
    if( _renderToBuffer ) {
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &drawFboId);
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, [self getNextTexId], 0);
    }
    
    glViewport(0, 0, _resolution.x, _resolution.y);
    
    if( !_renderToBuffer ) {
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    
    glUseProgram(_programId);
    
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput bindTexture:shaderPasses keyboardBuffer:keyboardBuffer];
    }
    
    [self bindUniforms];
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (const GLvoid *) 0);
    
    glBindVertexArrayOES(_vertexArray);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    if( _renderToBuffer ) {
        glBindFramebuffer(GL_FRAMEBUFFER, drawFboId);
    }
}

@end
