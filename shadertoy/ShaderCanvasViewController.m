//
//  ShaderCanvasViewController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "ShaderCanvasViewController.h"
#import "ShaderInput.h"
#import "ShaderPassRenderer.h"
#import "VRManager.h"

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "Utils.h"

@interface ShaderCanvasViewController () {
    NSMutableArray* _shaderPasses;
    bool _soundPass;
    
    GLKVector4 _mouse;
    BOOL _mouseDown;
    NSDate *_startTime;
    
    float _ifFragCoordScale;
    float _ifFragCoordOffsetXY[2];
    
    BOOL _running;
    BOOL _forceDrawInRect;
    float _totalTime;
    UILabel *_globalTimeLabel;
    int _frame;
    
    NSDate* _renderDate;
    VRSettings *_vrSettings;
    ShaderSettings * _shaderSettings;
    
    void (^_grabImageCallBack)(UIImage *image);
    unsigned char _keyboardBuffer[256*2];
}

@property (strong, nonatomic) EAGLContext *context;

@end

@implementation ShaderCanvasViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _shaderPasses = [[NSMutableArray alloc] init];
    memset( &_keyboardBuffer[0], 0, sizeof(unsigned char)*256*2 );
}

- (void)dealloc {
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
    
    _shaderPasses = nil;
}

#pragma mark - View lifecycle

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark - VR

- (void) setVRSettings:(VRSettings *)vrSettings {
    _vrSettings = vrSettings;
}

#pragma mark - Settings

- (void) setShaderSettings:(ShaderSettings *)shaderSettings {
    _shaderSettings = shaderSettings;
    [self setDefaultCanvasScaleFactor];
    if( [_shaderPasses count] > 1 ) {
        [self rewind];
    }
}

#pragma mark - ShaderCanvasViewController

- (BOOL) compileShader:(APIShaderObject *)shader soundPass:(bool)soundPass theError:(NSString **)error {
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.context) {
        *error = @"Failed to create ES context";
        return NO;
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    _soundPass = soundPass;
    
    if( soundPass ) {
        ShaderPassRenderer* passRenderer = [[ShaderPassRenderer alloc] init];
        if( ![passRenderer createShaderProgram:shader.soundPass commonPass:shader.commonPass theError:error] ) {
            [self tearDownGL];
            return NO;
        }
        [_shaderPasses addObject:passRenderer];
    } else {
        for (APIShaderPass* pass in shader.bufferPasses) {
            ShaderPassRenderer* bufferPassRenderer = [[ShaderPassRenderer alloc] init];
            [bufferPassRenderer setVRSettings:_vrSettings];

            if( ![bufferPassRenderer createShaderProgram:pass commonPass:shader.commonPass theError:error] ) {
                [self tearDownGL];
                return NO;
            }
            [_shaderPasses addObject:bufferPassRenderer];
        }
        
        ShaderPassRenderer* passRenderer = [[ShaderPassRenderer alloc] init];
        [passRenderer setVRSettings:_vrSettings];
        
        if( ![passRenderer createShaderProgram:shader.imagePass commonPass:shader.commonPass theError:error] ) {
            [self tearDownGL];
            return NO;
        }
        [_shaderPasses addObject:passRenderer];
    }
    
    if([shader.bufferPasses count]) {
        self.preferredFramesPerSecond = [shader useKeyboard]?60.:20.;
    } else if(_vrSettings && _vrSettings.inputMode == VR_INPUT_DEVICE) {
        self.preferredFramesPerSecond = 60.;
    } else {
        self.preferredFramesPerSecond = 20.;
    }
    _running = NO;
    _frame = 0;
    
    [self setDefaultCanvasScaleFactor];
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
    
    for (ShaderPassRenderer* pass in _shaderPasses) {
        [pass start];
    }
    if( _vrSettings ) {
        [VRManager setInputActive:true];
    }
}

- (void)pause {
    _totalTime = [self getIGlobalTime];
    _running = NO;
    for (ShaderPassRenderer* pass in _shaderPasses) {
        [pass pauseInputs];
    }
    if( _vrSettings ) {
        [VRManager setInputActive:false];
    }
}

- (void)play {
    _running = YES;
    _startTime = [NSDate date];
    for (ShaderPassRenderer* pass in _shaderPasses) {
        [pass resumeInputs];
    }
    if( _vrSettings ) {
        [VRManager setInputActive:true];
    }
}

- (void)rewind {
    _startTime = [NSDate date];
    _totalTime = 0.f;
    _frame = -2;
    _forceDrawInRect = YES;
    for (ShaderPassRenderer* pass in _shaderPasses) {
        [pass rewind];
    }
}

- (void) pauseInputs {
    for (ShaderPassRenderer* pass in _shaderPasses) {
        [pass pauseInputs];
    }
}

- (void) resumeInputs {
    for (ShaderPassRenderer* pass in _shaderPasses) {
        [pass resumeInputs];
    }
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
    if( _soundPass ) {
        return 1.f;
    } else if( _vrSettings ) {
        return _vrSettings.quality==VR_QUALITY_HIGH?2.f:_vrSettings.quality==VR_QUALITY_NORMAL?1.f:.5f;
    } else if( _shaderSettings && _shaderSettings.quality == SHADER_QUALITY_HIGH ) {
        return 2.f;
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
    if( !_running && !_forceDrawInRect) return;
    _forceDrawInRect = NO;
    
    NSDate* date = [NSDate date];
    if( !_running ) {
        date = [NSDate dateWithTimeInterval:[self getIGlobalTime] sinceDate:_startTime];
    }
    NSDate *now = [NSDate date];
    float deltaTime = (float)[now timeIntervalSinceDate:_renderDate];
    if( deltaTime > 1.f/20.f ) {
        deltaTime = 1.f/20.f;
    }
    
    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    for (ShaderPassRenderer* pass in _shaderPasses) {
        [pass setResolution:((float)width / _ifFragCoordScale) y:((float)height / _ifFragCoordScale)];
        [pass setFragCoordScale:_ifFragCoordScale andXOffset:_ifFragCoordOffsetXY[0] andYOffset:_ifFragCoordOffsetXY[1]];
        [pass setMouse:_mouse];
        [pass setTime:[self getIGlobalTime]];
        [pass setDate:date];
        [pass setFrame:(_frame>0?_frame:0)];
        [pass setTimeDelta:deltaTime];
        [pass updateShaderInputs:&_keyboardBuffer[0]];
 
        [pass render:_shaderPasses];
        
        [pass nextFrame];
    }    
    _frame++;
    _renderDate = now;
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
    _mouse.x = _mouse.z = (touchLocation.x) / self.view.frame.size.width;
    _mouse.y = _mouse.w = (self.view.layer.frame.size.height-touchLocation.y) / self.view.frame.size.height;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    _mouseDown = YES;
    _forceDrawInRect = YES;
    
    UITouch *touch1 = [touches anyObject];
    CGPoint touchLocation = [touch1 locationInView:self.view];
    _mouse.x = (touchLocation.x) / self.view.frame.size.width;
    _mouse.y = (self.view.layer.frame.size.height-touchLocation.y) / self.view.frame.size.height;
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

#pragma mark - Keyboard input

- (void)updateKeyboardBufferDown:(int)v {
    _keyboardBuffer[v] = 255;
    _keyboardBuffer[v+256] = 255 - _keyboardBuffer[v+256];
}

- (void)updateKeyboardBufferUp:(int)v {
    _keyboardBuffer[v] = 0;
}

@end
