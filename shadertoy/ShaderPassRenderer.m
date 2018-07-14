//
//  ShaderPassRenderer.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 23/01/16.
//  Copyright © 2016 Reinder Nijhoff. All rights reserved.
//

#import "ShaderPassRenderer.h"
#import "ShaderInput.h"
#import "VRManager.h"
#import "GLUtils.h"
#import "TextureHelper.h"

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "Utils.h"

@interface ShaderPassRenderer () {
    VRSettings* _vrSettings;
    ShaderSettings* _shaderSettings;
    APIShaderPass* _shaderPass;
    NSMutableArray *_shaderInputs;
    
    GLuint _programId;
    GLuint _positionSlot;
    
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexArray;
    
    float _iSampleRate;
    float *_channelResolution;
    float *_channelTime;
    GLKVector3 _resolution;
    float _time;
    NSDate *_date;
    GLKVector4 _mouse;
    int _frame;
    float _deltaTime;
    
    float _ifFragCoordScale;
    float _ifFragCoordOffsetXY[2];
    
    GLuint _frameBuffer;
    GLuint _renderTexture0, _renderTexture1;
    bool _currentRenderTexture;
    bool _renderToBuffer;
    int _renderBufferWidth, _renderBufferHeight;
    
    GLuint _copyProgramId;
    GLuint _copyRenderTexture;
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

#pragma mark - Settings

- (void) setShaderSettings:(ShaderSettings *)shaderSettings {
    _shaderSettings = shaderSettings;
}

- (void) initRenderBuffers {
    if( [_shaderPass.type isEqualToString:@"buffer"] ) {
        _renderToBuffer = true;
        _frameBuffer = [GLUtils createRenderBuffer];
        _renderBufferWidth = _renderBufferHeight = -1;
        
        glGenTextures(1, &_renderTexture0);
        glGenTextures(1, &_renderTexture1);
        glGenTextures(1, &_copyRenderTexture);
    }
}

- (BOOL) createShaderProgram:(APIShaderPass *)shaderPass commonPass:(APIShaderPass *)commonPass theError:(NSString **)error {
    _shaderPass = shaderPass;
    
    if (![shaderPass.code containsString:@"mainVR"]) {
        _vrSettings = NULL;
    }
    
    NSString *VertexShaderCode;
    
    if( _vrSettings ) {
        VertexShaderCode = [_vrSettings getVertexShaderCode];
    } else {
        VertexShaderCode = [[NSString alloc] readFromFile:@"/shaders/vertex_main" ofType:@"glsl"];
    }
    
    NSString *FragmentShaderCode = [[NSString alloc] readFromFile:@"/shaders/fragment_base_uniforms" ofType:@"glsl"];
    
    bool channelsUsed[4];
    for( int i=0; i<4; i++ ) {
        channelsUsed[i] = false;
    }
    for( APIShaderPassInput* input in shaderPass.inputs )  {
        channelsUsed[[input.channel intValue]] = true;
        if( [input.ctype isEqualToString:@"cubemap"] ) {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform highp samplerCube iChannel%@;\n", input.channel];
        } else if( [input.ctype isEqualToString:@"volume"] ) {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform highp sampler3D iChannel%@;\n", input.channel];
        } else {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform highp sampler2D iChannel%@;\n", input.channel];
        }
    }
    for( int i=0; i<4; i++ ) {
        if( !channelsUsed[i] ) {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform highp sampler2D iChannel%d;\n", i];
        }
    }
    
    if(commonPass != nil && ![commonPass.code isEqualToString:@""]) {
        FragmentShaderCode = [FragmentShaderCode stringByAppendingString:[[@"\n\n" stringByAppendingString:commonPass.code] stringByAppendingString:@"\n\n"]];
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
    
    int programId = [GLUtils compileShader:VertexShaderCode fragmentShaderCode:FragmentShaderCode theError:error];
    if( programId < 0 ) {
        return NO;
    }
    _programId = programId;
    
    _positionSlot = glGetAttribLocation(_programId, "position");
    
    [GLUtils createVAO:&_vertexArray buffer:&_vertexBuffer index:&_indexBuffer];
    [self initShaderPassInputs];
    [self initRenderBuffers];
    [self initCopyProgram];
    
    return YES;
}

- (GLuint) getLoc:(NSString *)key program:(GLuint)program {
   // NSLog(@"%@ %d", key, glGetUniformLocation(program, key.UTF8String));
    return glGetUniformLocation(program, key.UTF8String);
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
        
        _copyProgramId = [GLUtils compileShader:VertexShaderCode fragmentShaderCode:FragmentShaderCode theError:&error];
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
    
    glUniform1i([self getLoc:@"sourceTexture" program:_copyProgramId], 0);
    glUniform2f([self getLoc:@"sourceResolution" program:_copyProgramId], (float)sw, (float)sh);
    glUniform2f([self getLoc:@"targetResolution" program:_copyProgramId], (float)tw, (float)th);
    
    glActiveTexture(GL_TEXTURE0 );
    glBindTexture(GL_TEXTURE_2D, source);
    
    glBindVertexArray(_vertexArray);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, drawFboId);
}

- (void) setResolution:(float)x y:(float)y {
    _resolution = GLKVector3Make( x,y, 1. );
    
    if( _renderToBuffer && ((int)x != _renderBufferWidth || (int)y != _renderBufferHeight)) {
        int oldBufferWidth = _renderBufferWidth;
        int oldBufferHeight = _renderBufferHeight;
        
        if( oldBufferWidth >= 0 && oldBufferHeight >=0 ) {
            glBindTexture(GL_TEXTURE_2D, _copyRenderTexture);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, oldBufferWidth, oldBufferHeight, 0,GL_RGBA, GL_HALF_FLOAT, NULL);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
        
        _renderBufferWidth = (int)x;
        _renderBufferHeight = (int)y;
        
        [self copyTexture:_renderTexture0 target:_copyRenderTexture sw:oldBufferWidth sh:oldBufferHeight tw:oldBufferWidth th:oldBufferHeight];
        glBindTexture(GL_TEXTURE_2D, _renderTexture0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, _renderBufferWidth, _renderBufferHeight, 0,GL_RGBA, GL_HALF_FLOAT, NULL);
        [self copyTexture:_copyRenderTexture target:_renderTexture0 sw:oldBufferWidth sh:oldBufferHeight tw:_renderBufferWidth th:_renderBufferHeight];
        
        [self copyTexture:_renderTexture1 target:_copyRenderTexture sw:oldBufferWidth sh:oldBufferHeight tw:oldBufferWidth th:oldBufferHeight];
        glBindTexture(GL_TEXTURE_2D, _renderTexture1);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, _renderBufferWidth, _renderBufferHeight, 0,GL_RGBA, GL_HALF_FLOAT, NULL);
        [self copyTexture:_copyRenderTexture target:_renderTexture1 sw:oldBufferWidth sh:oldBufferHeight tw:_renderBufferWidth th:_renderBufferHeight];
    }
}

- (float) getWidth {
    return (float) _renderBufferWidth;
}

- (float) getHeight {
    return (float) _renderBufferHeight;
}

- (float) getDepth {
    return 1.f;
}

- (void) setTime:(float)time {
    _time = time;
}

- (float) getTime {
    return _time;
}

- (void)bindUniforms {
    for( ShaderInput* shaderInput in _shaderInputs ) {
        _channelResolution[ [shaderInput getChannel]*3 + 0 ] = [shaderInput getWidth];
        _channelResolution[ [shaderInput getChannel]*3 + 1 ] = [shaderInput getHeight];
        _channelResolution[ [shaderInput getChannel]*3 + 2 ] = [shaderInput getDepth];
        _channelTime[ [shaderInput getChannel] ] = [shaderInput getTime];
    }
    
    glUniform3fv( [self getLoc:@"iResolution" program:_programId], 1, &_resolution.x );
    glUniform1f( [self getLoc:@"iTime" program:_programId], [self getTime] );
    glUniform1f( [self getLoc:@"iGlobalTime" program:_programId], [self getTime] );
    glUniform4f( [self getLoc:@"iMouse" program:_programId], _mouse.x * _resolution.x, _mouse.y * _resolution.y, _mouse.z * _resolution.x, _mouse.w * _resolution.y);
    glUniform1fv( [self getLoc:@"iChannelTime" program:_programId], 4, _channelTime );
    glUniform3fv( [self getLoc:@"iChannelResolution" program:_programId], 4, _channelResolution);
    glUniform1i( [self getLoc:@"iFrame" program:_programId], _frame);
    glUniform1f( [self getLoc:@"iTimeDelta" program:_programId], _deltaTime);
    
    glUniform1f( [self getLoc:@"iFrameRate" program:_programId], 1.f/_deltaTime);
    glUniform1f( [self getLoc:@"iSampleRate" program:_programId], 22000.f);
    
    glUniform2fv( [self getLoc:@"ifFragCoordOffsetUniform" program:_programId], 1, _ifFragCoordOffsetXY);
    if( _vrSettings ) {
        GLKMatrix3 mat = [VRManager getDeviceRotationMatrix:_vrSettings];
        GLKVector3 pos = [VRManager getDevicePosition:_vrSettings];
        glUniformMatrix3fv( [self getLoc:@"iDeviceRotationUniform" program:_programId], 1, false, &mat.m00);
        glUniform3f( [self getLoc:@"iDevicePositionUniform" program:_programId], pos.x, pos.y, pos.z );
    }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:kCFCalendarUnitYear | kCFCalendarUnitMonth | kCFCalendarUnitDay | kCFCalendarUnitHour | kCFCalendarUnitMinute | kCFCalendarUnitSecond fromDate:_date];
    double seconds = [_date timeIntervalSince1970];
    glUniform4f( [self getLoc:@"iDate" program:_programId], components.year, components.month, components.day, (components.hour * 60 * 60) + (components.minute * 60) + components.second + (seconds - floor(seconds)) );
    
    glUniform1i( [self getLoc:@"iChannel0" program:_programId], 0);
    glUniform1i( [self getLoc:@"iChannel1" program:_programId], 1);
    glUniform1i( [self getLoc:@"iChannel2" program:_programId], 2);
    glUniform1i( [self getLoc:@"iChannel3" program:_programId], 3);
    
    glUniform1f( [self getLoc:@"iChannel[0].time" program:_programId],       _channelTime[0] );
    glUniform1f( [self getLoc:@"iChannel[1].time" program:_programId],       _channelTime[1] );
    glUniform1f( [self getLoc:@"iChannel[2].time" program:_programId],       _channelTime[2] );
    glUniform1f( [self getLoc:@"iChannel[3].time" program:_programId],       _channelTime[3] );
    glUniform3f( [self getLoc:@"iChannel[0].resolution" program:_programId], _channelResolution[0], _channelResolution[ 1], _channelResolution[ 2] );
    glUniform3f( [self getLoc:@"iChannel[1].resolution" program:_programId], _channelResolution[3], _channelResolution[ 4], _channelResolution[ 5] );
    glUniform3f( [self getLoc:@"iChannel[2].resolution" program:_programId], _channelResolution[6], _channelResolution[ 7], _channelResolution[ 8] );
    glUniform3f( [self getLoc:@"iChannel[3].resolution" program:_programId], _channelResolution[9], _channelResolution[10], _channelResolution[11] );
}

- (void) initShaderPassInputs {
    for (APIShaderPassInput* input in _shaderPass.inputs)  {
        ShaderInput* inputController = [[ShaderInput alloc] init];
        [inputController initWithShaderPassInput:input];
        
        [_shaderInputs addObject:inputController];
    }
}

- (NSNumber *) getOutputId {
    if(_shaderPass.outputs && [_shaderPass.outputs count] > 0) {
        return ((APIShaderPassOutput *)[_shaderPass.outputs objectAtIndex:0]).outputId;
    }
    return [NSNumber numberWithInteger:0];
}

- (void)allocChannels {
    _shaderInputs = [[NSMutableArray alloc] initWithCapacity:4];
    
    _channelTime = malloc(sizeof(float) * 4);
    _channelResolution = malloc(sizeof(float) * 12);
    
    memset (_channelTime,0,sizeof(float) * 4);
    memset (_channelResolution,0,sizeof(float) * 12);
}

- (void) dealloc {
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArrays(1, &_vertexArray);
    glDeleteProgram(_programId);
    
    if( _renderToBuffer ) {
        glDeleteTextures(1, &_copyRenderTexture);
        glDeleteProgram(_copyProgramId);
        
        glDeleteFramebuffers(1, &_frameBuffer);
        glDeleteTextures(1, &_renderTexture0);
        glDeleteTextures(1, &_renderTexture1);
    }
    
    for( __strong ShaderInput* shaderInput in _shaderInputs ) {
        shaderInput = nil;
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
    double globalTime = [self getTime];
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:globalTime];
        [shaderInput pause];
    }
}

- (void) resumeInputs {
    double globalTime = [self getTime];
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput rewindTo:globalTime];
        [shaderInput play];
    }
}

- (void)rewind {
    [self setTime:0];
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

- (void) updateShaderInputs:(unsigned char*)keyboardBuffer {
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput update:keyboardBuffer];
    }
}
    
- (void) render:(NSMutableArray *)shaderPasses {
    if( !_programId ) return;
    
    GLint drawFboId = 0;
    if( _renderToBuffer ) {
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &drawFboId);
        glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, [self getNextTexId], 0);
    }
    
    glViewport(0, 0, _resolution.x, _resolution.y);
    
    if( !_renderToBuffer || _frame == 0 ) {
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    
    glUseProgram(_programId);
    
    for( ShaderInput* shaderInput in _shaderInputs ) {
        [shaderInput bindTexture:shaderPasses];
    }
    
    [self bindUniforms];
    
    glBindVertexArray(_vertexArray);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
    
    if( _renderToBuffer ) {
        glBindFramebuffer(GL_FRAMEBUFFER, drawFboId);
    }
}

@end
