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

@interface ShaderCanvasViewController () {
    APIShaderPass* _shaderPass;
    
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
    
    GLuint _ifFragCoordOffsetUniform;
    
    GLKVector4 _mouse;
    BOOL _mouseDown;
    NSDate *_startTime;
    float *_channelTime;
    float *_channelResolution;
    GLKTextureInfo *_channelTextureInfo[4];
    BOOL _channelTextureUseNearest[4];
    
    float _ifFragCoordScale;
    float _ifFragCoordOffsetXY[2];
    
    BOOL _running;
    BOOL _forceDrawInRect;
    float _totalTime;
    UILabel *_globalTimeLabel;
    
    void (^_grabImageCallBack)(UIImage *image);
}

@property (strong, nonatomic) EAGLContext *context;

@end

@implementation ShaderCanvasViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self allocChannels];
    _programId = 0;
}

- (void)dealloc {
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
    
    free(_channelTime);
    free(_channelResolution);
}

#pragma mark - View lifecycle

- (BOOL) createShaderProgram:(APIShaderPass *)shaderPass theError:(NSString **)error {
    GLuint VertexShaderID = glCreateShader(GL_VERTEX_SHADER);
    GLuint FragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
    
    NSString *VertexShaderCode = [[NSString alloc] readFromFile:@"/shaders/vertex_main" ofType:@"glsl"];
    
    char const * VertexSourcePointer = [VertexShaderCode UTF8String];
    glShaderSource(VertexShaderID, 1, &VertexSourcePointer , NULL);
    glCompileShader(VertexShaderID);
    
    NSString *FragmentShaderCode = [[NSString alloc] readFromFile:@"/shaders/fragment_base_uniforms" ofType:@"glsl"];
    
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
    } else {
        FragmentShaderCode = [FragmentShaderCode stringByAppendingString:[[NSString alloc] readFromFile:@"/shaders/fragment_main_vr" ofType:@"glsl"]];
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
    return YES;
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
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (const GLvoid *) 0);
    
    glBindVertexArrayOES(0);
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    glDeleteProgram(_programId);
    
    for( int i=0; i<4; i++ )  {
        if( _channelTextureInfo[i] ) {
            GLuint name = _channelTextureInfo[i].name;
            glDeleteTextures(1, &name);
        }
    }
}

- (void)allocChannels {
    _channelTime = malloc(sizeof(float) * 4);
    _channelResolution = malloc(sizeof(float) * 12);
    
    memset (_channelTime,0,sizeof(float) * 4);
    memset (_channelResolution,0,sizeof(float) * 12);
    
    memset (_channelTextureInfo,0,sizeof(GLKTextureInfo *) * 4);
    memset (_channelTextureUseNearest,0,sizeof(BOOL) * 4);
    
    memset (&_channelUniform[0],99,sizeof(GLuint) * 4);
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
    
    // video, music, webcam and keyboard is not implemented, so deliver dummy textures instead
    for (APIShaderPassInput* input in _shaderPass.inputs)  {
        if( [input.ctype isEqualToString:@"video"] ) {
            input.src = [input.src stringByReplacingOccurrencesOfString:@".webm" withString:@".png"];
            input.src = [input.src stringByReplacingOccurrencesOfString:@".ogv" withString:@".png"];
            input.ctype = @"texture";
        }
        if( [input.ctype isEqualToString:@"music"] || [input.ctype isEqualToString:@"webcam"] || [input.ctype isEqualToString:@"keyboard"] ) {
            input.src = [[@"/presets/" stringByAppendingString:input.ctype] stringByAppendingString:@".png"];
            input.ctype = @"texture";
        }
    }
    
    for (APIShaderPassInput* input in _shaderPass.inputs)  {
        NSString* channel = [NSString stringWithFormat:@"iChannel%@", input.channel];
        int c = MAX( MIN( (int)[input.channel integerValue], 3 ), 0);
        
        if( [input.ctype isEqualToString:@"texture"] ) {
            // load texture to channel
            NSError *theError;
            
            NSString* file = [[@"." stringByAppendingString:input.src] stringByReplacingOccurrencesOfString:@".jpg" withString:@".png"];
            file = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:file];
            glGetError();
            
            GLKTextureInfo *spriteTexture = [GLKTextureLoader textureWithContentsOfFile:file options:@{GLKTextureLoaderGenerateMipmaps: [NSNumber numberWithBool:YES]} error:&theError];
            
            _channelUniform[ c ] = glGetUniformLocation(_programId, channel.UTF8String );
            _channelTextureInfo[ c ] = spriteTexture;
            _channelResolution[ c*3 ] = [spriteTexture width];
            _channelResolution[ c*3+1 ] = [spriteTexture height];
            
            if( [input.src containsString:@"tex14.png"] || [input.src containsString:@"tex15.png"] ) {
                _channelTextureUseNearest[ c ] = YES;
            }
        }
        if( [input.ctype isEqualToString:@"cubemap"] ) {
            // load texture to channel
            NSError *theError;
            
            NSString* file = [@"." stringByAppendingString:input.src];
            file = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:file];
            glGetError();
            
            GLKTextureInfo *spriteTexture = [GLKTextureLoader cubeMapWithContentsOfFile:file options:@{GLKTextureLoaderGenerateMipmaps: [NSNumber numberWithBool:YES]} error:&theError];
            
            _channelUniform[ c ] = glGetUniformLocation(_programId, channel.UTF8String );
            _channelTextureInfo[  c ] = spriteTexture;
        }
    }
}

- (void)bindUniforms {
    GLKVector3 resolution = GLKVector3Make( self.view.frame.size.width * self.view.contentScaleFactor / _ifFragCoordScale, self.view.frame.size.height * self.view.contentScaleFactor / _ifFragCoordScale, 1. );
    glUniform3fv(_resolutionUniform, 1, &resolution.x );
    glUniform1f(_globalTimeUniform, [self getIGlobalTime] );
    glUniform4f(_mouseUniform,
                _mouse.x * self.view.contentScaleFactor  / _ifFragCoordScale,
                _mouse.y * self.view.contentScaleFactor  / _ifFragCoordScale,
                _mouse.z * self.view.contentScaleFactor  / _ifFragCoordScale,
                _mouse.w * self.view.contentScaleFactor  / _ifFragCoordScale);
    glUniform3fv(_channelResolutionUniform, 4, _channelResolution);
    glUniform2fv(_ifFragCoordOffsetUniform, 1, _ifFragCoordOffsetXY);
    
    NSDate* date = [NSDate date];
    if( !_running ) {
        date = [NSDate dateWithTimeInterval:[self getIGlobalTime] sinceDate:_startTime];
    }
    NSDateComponents *components = [[NSCalendar currentCalendar] components:kCFCalendarUnitYear | kCFCalendarUnitMonth | kCFCalendarUnitDay | kCFCalendarUnitHour | kCFCalendarUnitMinute | kCFCalendarUnitSecond fromDate:date];
    glUniform4f(_dateUniform, components.year, components.month, components.day, (components.hour * 60 * 60) + (components.minute * 60) + components.second);
    
    for( int i=0; i<4; i++ )  {
        if( _channelUniform[i] < 99 ) {
            glUniform1i(_channelUniform[i], i);
        }
    }
}

#pragma mark - ShaderCanvasViewController

- (BOOL)compileShaderPass:(APIShaderPass *)shader theError:(NSString **)error {
    _shaderPass = shader;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        *error = @"Failed to create ES context";
        return NO;
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    [self createBuffers];
    if( [self createShaderProgram:_shaderPass theError:error] ) {
        [self findUniforms];
        
        self.preferredFramesPerSecond = 20.;
        _running = NO;
        [self setDefaultCanvasScaleFactor];
    } else {
        [self tearDownGL];
        return NO;
    }
    return YES;
}

#pragma mark - User Interface delegate

- (void) setFragCoordScale:(float)scale andXOffset:(float)xOffset andYOffset:(float)yOffset {
    _ifFragCoordScale = scale;
    _ifFragCoordOffsetXY[0] = xOffset;
    _ifFragCoordOffsetXY[1] = yOffset;
}

- (void)start {
    _running = YES;
    [self rewind];
}

- (void)pause {
    _totalTime = [self getIGlobalTime];
    _running = NO;
}

- (void)play {
    _running = YES;
    _startTime = [NSDate date];
}

- (void)rewind {
    _startTime = [NSDate date];
    _totalTime = 0.f;
    _forceDrawInRect = YES;
}

- (float)getIGlobalTime {
    if( _running ) {
        return _totalTime + [[NSDate date] timeIntervalSinceDate:_startTime];
    } else {
        return _totalTime;
    }
}

- (BOOL)isRunning {
    return _running;
}

- (void) setTimeLabel:(UILabel *)label {
    _globalTimeLabel = label;
}

- (void) renderOneFrame:(float)globalTime success:(void (^)(UIImage *image))success {
    [self pause];
    _totalTime = globalTime;
    _grabImageCallBack = success;
}

- (void)setCanvasScaleFactor:(float)scaleFactor {
    _forceDrawInRect = NO;
    self.view.contentScaleFactor = scaleFactor;
    [self setFragCoordScale:1.f andXOffset:0.f andYOffset:0.f];
}

- (float) getDefaultCanvasScaleFactor {
    if( [_shaderPass.type isEqualToString:@"sound"] ) {
        return 1.f;
    } else {
        // todo: scale factor depending on GPU type?
        return 3.f/4.f;
    }
}

- (void) setDefaultCanvasScaleFactor {
    [self setCanvasScaleFactor:[self getDefaultCanvasScaleFactor]];
    [self forceDraw];
    [(GLKView *)self.view display];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void) forceDraw {
    _forceDrawInRect = YES;
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    if( self.view.hidden ) return;
    if( !_programId ) return;
    if( !_running && !_forceDrawInRect) return;
    _forceDrawInRect = NO;
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(_programId);
    
    [self bindUniforms];
    
    for( int i=0; i<4; i++ )  {
        if( _channelTextureInfo[i] ) {
            glActiveTexture(GL_TEXTURE0 + i);
            glBindTexture(_channelTextureInfo[i].target, _channelTextureInfo[i].name );
            
            if( _channelTextureInfo[i].target == GL_TEXTURE_2D ) {
                // texture 14 and 15 GL_NEAREST
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
                
                if( _channelTextureUseNearest[i] ) {
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
                }
            }
        }
    }
    
    glBindVertexArrayOES(_vertexArray);
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}

#pragma mark - GLKViewControllerDelegate

- (void)update {
    if( [self getIGlobalTime] > 60.f*60.f ) {
        [self rewind];
    }
    if( _globalTimeLabel ) {
        [_globalTimeLabel setText:[NSString stringWithFormat:@"%.2f", [self getIGlobalTime]]];
    }
    
    if(_grabImageCallBack) {
        void (^tmpCallback)(UIImage *image) = _grabImageCallBack;
        _grabImageCallBack = nil;
        _forceDrawInRect = YES;
        UIImage *snapShotImage = [(GLKView *)self.view snapshot];
        tmpCallback(snapShotImage);
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _mouseDown = YES;
    _forceDrawInRect = YES;
    
    UITouch *touch1 = [touches anyObject];
    CGPoint touchLocation = [touch1 locationInView:self.view];
    _mouse.x = _mouse.z = touchLocation.x;
    _mouse.y = _mouse.w = self.view.layer.frame.size.height-touchLocation.y;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    _mouseDown = YES;
    _forceDrawInRect = YES;
    
    UITouch *touch1 = [touches anyObject];
    CGPoint touchLocation = [touch1 locationInView:self.view];
    _mouse.x = touchLocation.x;
    _mouse.y = self.view.layer.frame.size.height-touchLocation.y;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    _mouseDown = YES;
    _forceDrawInRect = YES;
    
    _mouse.z = -fabsf(_mouse.z);
    _mouse.w = -fabsf(_mouse.w);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _mouseDown = YES;
    _forceDrawInRect = YES;
    
    _mouse.z = -fabsf(_mouse.z);
    _mouse.w = -fabsf(_mouse.w);
}

@end