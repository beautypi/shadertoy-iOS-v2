//
//  ShaderCanvasViewController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "ShaderCanvasViewController.h"
#import "ShaderCanvasInputController.h"
#import "ShaderPassRenderer.h"

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#import "Utils.h"

@interface ShaderCanvasViewController () {
    ShaderPassRenderer* _shaderPassRenderer;
    
    GLKVector4 _mouse;
    BOOL _mouseDown;
    NSDate *_startTime;
    
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
    
    _shaderPassRenderer = [[ShaderPassRenderer alloc] init];
}

- (void)dealloc {
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
    
    _shaderPassRenderer = nil;
}

#pragma mark - View lifecycle

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
}

#pragma mark - VR

- (void) setVRSettings:(VRSettings *)vrSettings {
    [_shaderPassRenderer setVRSettings:vrSettings];
}

#pragma mark - ShaderCanvasViewController

- (BOOL)compileShaderPass:(APIShaderPass *)shaderPass theError:(NSString **)error {
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        *error = @"Failed to create ES context";
        return NO;
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    if( [_shaderPassRenderer createShaderProgram:shaderPass theError:error] ) {
        
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
    
    [_shaderPassRenderer start];
}

- (void)pause {
    _totalTime = [self getIGlobalTime];
    _running = NO;
    
    [_shaderPassRenderer pauseInputs];
}

- (void)play {
    _running = YES;
    _startTime = [NSDate date];
    
    [_shaderPassRenderer resumeInputs];
}

- (void)rewind {
    _startTime = [NSDate date];
    _totalTime = 0.f;
    _forceDrawInRect = YES;
    
    [_shaderPassRenderer rewind];
}


- (void) pauseInputs {
    [_shaderPassRenderer pauseInputs];
}

- (void) resumeInputs {
    [_shaderPassRenderer resumeInputs];
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
    //    if( [_shaderPass.type isEqualToString:@"sound"] ) {
    //        return 1.f;
    //    } else {
    // todo: scale factor depending on GPU type?
    return 3.f/4.f;
    //    }
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
    
    [_shaderPassRenderer setFragCoordScale:_ifFragCoordScale andXOffset:_ifFragCoordOffsetXY[0] andYOffset:_ifFragCoordOffsetXY[1]];
    [_shaderPassRenderer setMouse:_mouse];
    [_shaderPassRenderer setIGlobalTime:[self getIGlobalTime]];
    [_shaderPassRenderer setDate:date];
    [_shaderPassRenderer setResolution:(self.view.frame.size.width * self.view.contentScaleFactor / _ifFragCoordScale) y:(self.view.frame.size.height * self.view.contentScaleFactor / _ifFragCoordScale)];
    [_shaderPassRenderer render];
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

@end