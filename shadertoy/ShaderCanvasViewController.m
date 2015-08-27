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
    
    GLKVector4 _mouse;
    BOOL _mouseDown;
    NSDate *_startTime;
    float *_channelTime;
    float *_channelResolution;
    GLKTextureInfo *_channelTextureInfo[4];
    BOOL _channelTextureUseNearest[4];
    
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
    [self setDefaultCanvasScaleFactor];
    
    _programId = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (BOOL) createShaderProgram:(APIShaderPass *)shaderPass theError:(NSString **)error {
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
    
    for( APIShaderPassInput* input in shaderPass.inputs )  {
        if( [input.ctype isEqualToString:@"cubemap"] ) {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform mediump samplerCube iChannel%@;\n", input.channel];
        } else {
            FragmentShaderCode = [FragmentShaderCode stringByAppendingFormat:@"uniform mediump sampler2D iChannel%@;\n", input.channel];
        }
    }
    
    FragmentShaderCode = [FragmentShaderCode stringByAppendingString:
                          @" \n \
                          float fwidth(float p){return 0.;}  vec2 fwidth(vec2 p){return vec2(0.);}  vec3 fwidth(vec3 p){return vec3(0.);} \n \
                          float dFdx(float p){return 0.;}  vec2 dFdx(vec2 p){return vec2(0.);}  vec3 dFdx(vec3 p){return vec3(0.);} \n \
                          float dFdy(float p){return 0.;}  vec2 dFdy(vec2 p){return vec2(0.);}  vec3 dFdy(vec3 p){return vec3(0.);} \n \
                          " ];
    
    FragmentShaderCode = [FragmentShaderCode stringByAppendingString:shaderPass.code];
    FragmentShaderCode = [FragmentShaderCode stringByAppendingString:
                          @" \n \
                          void main()  { \n \
                          mainImage(gl_FragColor, gl_FragCoord.xy); \n \
                          gl_FragColor.w = 1.; \n \
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
    GLKVector3 resolution = GLKVector3Make( self.view.frame.size.width * self.view.contentScaleFactor, self.view.frame.size.height * self.view.contentScaleFactor, 1. );
    glUniform3fv(_resolutionUniform, 1, &resolution.x );
    
    glUniform1f(_globalTimeUniform, [self getIGlobalTime] );
    
    glUniform4f(_mouseUniform, _mouse.x * self.view.contentScaleFactor, _mouse.y * self.view.contentScaleFactor, _mouse.z * self.view.contentScaleFactor, _mouse.w * self.view.contentScaleFactor );
    
    glUniform3fv(_channelResolutionUniform, 4, _channelResolution);
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:kCFCalendarUnitYear | kCFCalendarUnitMonth | kCFCalendarUnitDay | kCFCalendarUnitHour | kCFCalendarUnitMinute | kCFCalendarUnitSecond fromDate:[NSDate date]];
    glUniform4f(_dateUniform, components.year, components.month, components.day, (components.hour * 60 * 60) + (components.minute * 60) + components.second);
    
    for( int i=0; i<4; i++ )  {
        if( _channelUniform[i] < 99 ) {
            glUniform1i(_channelUniform[i], i);
        }
    }
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
    
    [self genBuffers];
    if( [self createShaderProgram:_shaderPass theError:error] ) {
        [self findUniforms];
        
        self.preferredFramesPerSecond = 20.;
        _running = NO;
    } else {
        [self tearDownGL];
        return NO;
    }
    return YES;
}

#pragma mark - User Interface delegate

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
}

- (void) setDefaultCanvasScaleFactor {
    [self setCanvasScaleFactor:3.f/4.f];
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
    
    NSLog(@"render %f\n", self.view.contentScaleFactor );
}

#pragma mark - GLKViewControllerDelegate

- (void)update {
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