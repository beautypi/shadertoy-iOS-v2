//
//  GLView.swift
//  MetalPlayground
//
//  Created by qiudong on 2021/6/18.
//  Copyright © 2021 Dom Chiu. All rights reserved.
//

#if os(macOS)
import Cocoa
import OpenGL

#elseif os(iOS)
import UIKit
import OpenGLES

#endif //#if os(macOS)

#if os(macOS)
class GLView : NSView, GLRenderer {
    func didCreateGLContext() {
        let attrs: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFADoubleBuffer),
            UInt32(NSOpenGLPFADepthSize), 32,
            UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersion4_1Core),
            0];
        let pixelFormat = NSOpenGLPixelFormat(attributes: attrs);
        _glCtx = NSOpenGLContext(format: pixelFormat!, share: nil);
        _glCtx?.makeCurrentContext();
        if let r = self.renderer
        {
            r.didCreateGLContext();
        }
    }
    
    func willReleaseGLContext() {
        if let r = self.renderer
        {
            r.willReleaseGLContext();
        }
    }
    
    func didResumeRendering() {
        if let r = self.renderer
        {
            r.didResumeRendering();
        }
    }
    
    func willPauseRendering() {
        if let r = self.renderer
        {
            r.willPauseRendering();
        }
    }
    
    func render(timestamp: Float, frameCount: Int) {
        guard let glCtx = _glCtx else { return; }
        if (glCtx.view == nil)
        {
            glCtx.clearDrawable();
            glCtx.view = self;
        }
        glCtx.makeCurrentContext();
        CHECK_GL_ERROR();

        let dirtyRect: NSRect = NSRect(x: 0, y: 0, width: self.frame.width * self.layer!.contentsScale, height: self.frame.height * self.layer!.contentsScale);
        let R = Float(sin(timestamp) + 1.0) * 0.5;
        let G = Float(cos(timestamp) + 1.0) * 0.5;
        let B = Float(0.2);

        glViewport(GLint(dirtyRect.minX), GLint(dirtyRect.minY), GLint(dirtyRect.width) / 2, GLint(dirtyRect.height) / 2);
//        glEnable(GLenum(GL_DEPTH_TEST));
//        glClearDepthf(1.0);
        glClearColor(R, G, B, 1.0);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        CHECK_GL_ERROR();

        if let r = self.renderer
        {
            r.render(timestamp: timestamp);
        }

        glCtx.flushBuffer();
        NSOpenGLContext.clearCurrentContext();
    }
    
    override func viewDidEndLiveResize() {
        guard let glCtx = _glCtx else { return; }
        glCtx.clearDrawable();
        glCtx.view = nil;
    }
    
    override func viewDidChangeBackingProperties() {
        if (_glRenderLoop != nil) { return; }
        _glRenderLoop = GLRenderLoop(renderer: self, runLoop: .current, runLoopMode: .default);
        _glRenderLoop?.resume();
    }
    
    override func viewWillDraw() {
        guard let glCtx = _glCtx else { return; }
        glCtx.clearDrawable();
        glCtx.view = nil;
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if let _ = newWindow
        {
            _glRenderLoop?.resume();
        }
        else
        {
            _glRenderLoop?.pause();
        }
    }
    
    deinit {
        //print("#GLView# dealloc");
        self.renderer = nil;
        _glCtx = nil;
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect);
        self.wantsBestResolutionOpenGLSurface = true;
        
        _eaglLayer = self.layer as! CAEAGLLayer;
        _eaglLayer?.isOpaque = true;
        _eaglLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false, kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8];
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.wantsBestResolutionOpenGLSurface = true;
        
        _eaglLayer = self.layer as! CAEAGLLayer;
        _eaglLayer?.isOpaque = true;
        _eaglLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false, kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8];
    }

//    override func draw(_ dirtyRect: NSRect) {
//        guard let glCtx = _glCtx else { return; }
//        glCtx.clearDrawable();
//        glCtx.view = self;
//        glCtx.makeCurrentContext();
//        CHECK_GL_ERROR();
//
//        glViewport(GLint(dirtyRect.minX), GLint(dirtyRect.minY), GLint(dirtyRect.width), GLint(dirtyRect.height));
//        glClearColor(0.0, 0.0, 0.0, 1.0);
//        glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
//        CHECK_GL_ERROR();
//
//        if let r = self.renderer
//        {
//            r.render(timestamp: <#T##Float#>)
//        }
//
//        glCtx.flushBuffer();
//        NSOpenGLContext.clearCurrentContext();
//    }
    
    var renderer: GLRenderer? = nil
    
    var _glRenderLoop: GLRenderLoop? = nil
    
    private static var _renderRunLoop: RunLoop? = nil
    
    @objc
    static func createRenderRunLoop(_ object: Any?) {
        _renderRunLoop = RunLoop.current;
        if let semaphore = object as? DispatchSemaphore?
        {
            semaphore?.signal();
        }
        print("#testDisplayLink# Before run");
        _renderRunLoop!.run();
        print("#testDisplayLink# After run");
    }
    
    private static lazy let renderRunLoop = { () -> RunLoop in
        let semaphore = DispatchSemaphore(value: 1);
        let thread = Thread(target: Self, selector: #selector(Self.createRenderRunLoop(_:)), object: semaphore);
        thread.start();
        print("#testDisplayLink# Before wait");
        semaphore.wait();
        print("#testDisplayLink# After wait");
        return _renderRunLoop;
    }()
    
    private var _glCtx: NSOpenGLContext? = nil
    private var _pixelFormat: NSOpenGLPixelFormat? = nil
}
#elseif os(iOS)
@objc
class GLView : UIView, GLRenderer {
    func resetTimeStamp() {
        _glRenderLoop?.resetTimeStamp();
    }
    
    func releaseGLObjectsIfNecessary() {
//        print("#List#Cache#Leak# GLView.releaseGLObjectsIfNecessary (\(self.hash))");
        if let r = self.renderer
        {
            r.releaseGLObjectsIfNecessary();
        }
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
//        glDeleteRenderbuffers(1, &_depthBuffer);
//        _depthBuffer = 0;
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }

    func createGLObjectsIfNecessary() {
//        print("#List#Cache#Leak# GLView.createGLObjectsIfNecessary (\(self.hash))");
        glGenFramebuffers(1, &_frameBuffer);
        glGenRenderbuffers(1, &_renderBuffer);
//        glGenRenderbuffers(1, &_depthBuffer);
        CHECK_GL_ERROR();
        bindLayer();
        if let r = self.renderer
        {
            r.createGLObjectsIfNecessary();
        }
    }
    
    func didResumeRendering() {
        //print("#GLView# didResumeRendering");
        if let r = self.renderer
        {
            r.didResumeRendering();
        }
    }
    
    func willPauseRendering() {
        //print("#GLView# willPauseRendering");
        if let r = self.renderer
        {
            r.willPauseRendering();
        }
    }
    
    func preRender(timestamp: Float, frameCount: Int) {
        if let r = self.renderer
        {
            r.preRender?(timestamp: timestamp, frameCount: frameCount);
        }
    }
    
    func postRender(timestamp: Float, frameCount: Int) {
        if let r = self.renderer
        {
            r.postRender?(timestamp: timestamp, frameCount: frameCount);
        }
    }
    
    func render(timestamp: Float, frameCount: Int) {
//        print("#GLView#Reuse# glView[\(self.hashValue)] render with \((renderer as AnyObject).hash!)");
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _frameBuffer);
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _renderBuffer);
        glViewport(0, 0, self.canvasWidth, self.canvasHeight);
//        glClearColor(1.0 - (timestamp - floor(timestamp)), 0.0, timestamp - floor(timestamp), 1.0);
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        if let r = self.renderer
        {
            r.render(timestamp: timestamp, frameCount: frameCount);
        }
    }
    
    @objc
    func applicationWillResignActive(noti: Notification) {
        //print("#GLView# Begin applicationWillResignActive");
        _glRenderLoop?.pause();
        //print("#GLView# End applicationWillResignActive");
    }
    
    @objc
    func applicationDidBecomeActiveNotification(noti: Notification) {
        //print("#GLView# Begin applicationDidBecomeActiveNotification");
        _glRenderLoop?.resume();
        //print("#GLView# End applicationDidBecomeActiveNotification");
    }
    
    deinit {
//        print("#List#Cache#Leak# GLView dealloc: \(self.hash)");
        self.renderer = nil;
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        print("#List#Cache#Leak# GLView initWithFrame: \(self.hash)");
        _eaglLayer = self.layer as! CAEAGLLayer;
        _eaglLayer?.isOpaque = true;
        _eaglLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false, kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8];
        
        _glRenderLoop = GLRenderLoop(renderer: self, renderRunLoop: Self.renderRunLoop);
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        print("#List#Cache#Leak# GLView initWithCoder: \(self.hash)");
        _eaglLayer = self.layer as! CAEAGLLayer;
        _eaglLayer?.isOpaque = true;
        _eaglLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking: false, kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8];
        
        _glRenderLoop = GLRenderLoop(renderer: self, renderRunLoop: Self.renderRunLoop);
    }

    override func layoutSubviews() {
        //print("#GLView# layoutSubviews");
        super.layoutSubviews();
        
        _glRenderLoop?.performActionAsync({ (args: Any?) in
            self.bindLayer();
        }, args: self);
    }
    
    override func didMoveToSuperview() {
        if let _ = self.superview
        {
            //print("#GLView# Will move onto newWindow");
            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(noti:)), name: UIApplication.willResignActiveNotification, object: nil);
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification(noti:)), name: UIApplication.didBecomeActiveNotification, object: nil);

            if (nil == _glRenderLoop)
            {
                _glRenderLoop = GLRenderLoop(renderer: self, renderRunLoop: Self.renderRunLoop);
            }
            _glRenderLoop?.resume();
        }
        else
        {
            //print("#GLView# Will be removed");
            NotificationCenter.default.removeObserver(self);
            
            if (resetRenderLooperOnViewRemoval)
            {
                _glRenderLoop?.destroy();
                _glRenderLoop = nil;
            }
        }
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        if let _ = newWindow
        {
            _glRenderLoop?.resume();
        }
        else
        {
            _glRenderLoop?.pause();
        }
    }

    override class var layerClass: AnyClass {
        get { return CAEAGLLayer.self; }
    }
    
    func bindLayer() {
//        print("#GLView#Reuse# glView[\(self.hashValue)] bindLayer()");
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _frameBuffer);
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _renderBuffer);
        
        CVEAGLContext.current()?.renderbufferStorage(Int(GL_RENDERBUFFER), from: _eaglLayer);
        CHECK_GL_ERROR();
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &canvasWidth);
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &canvasHeight);
        //print("#GLView# bindLayer (w,h)=(\(width), \(height))")
//        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _depthBuffer);
//        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT24), canvasWidth, canvasHeight);
//        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), _depthBuffer);
        CHECK_GL_ERROR();
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _renderBuffer);
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), _renderBuffer);
        CHECK_GL_ERROR();
        let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER));
        print("glCheckFramebufferStatus()=\(status)");
    }
    
    var canvasWidth: GLint = 0;
    var canvasHeight: GLint = 0;
    
    @objc
    var renderer: GLRenderer? {
        get {
            if (_nextRenderer === _renderer)
            {
                return _renderer;
            }
            
            if let nextRenderer = _nextRenderer
            {
                nextRenderer.createGLObjectsIfNecessary();
                
//                if let currentRenderer = _renderer
//                {
//                    currentRenderer.releaseGLObjectsIfNecessary();
//                }
            }
//            else
//            {
//                _renderer.createGLObjectsIfNecessary();
//            }
            _renderer = _nextRenderer;
            return _renderer;
        }
        
        set(newValue) {
            _nextRenderer = newValue;
        }
    }

    var renderLoop: GLRenderLoop? {
        get {
            return _glRenderLoop;
        }
    }
    
    var resetRenderLooperOnViewRemoval: Bool = true
    
    private var _renderer: GLRenderer? = nil
    private var _nextRenderer: GLRenderer? = nil
    
    private static var _renderRunLoop: RunLoop? = nil
    
    @objc
    static func displayLinkCallback(_ object: Any?) {
    }
    
    @objc
    static func createRenderRunLoop(_ object: Any?) {
        _renderRunLoop = RunLoop.current;
        
        let port = Port();
        _renderRunLoop?.add(port, forMode: .common);
        
        if let semaphore = object as? DispatchSemaphore?
        {
            print("#testDisplayLink# Before signal");
            semaphore?.signal();
            print("#testDisplayLink# After signal");
        }
        _renderRunLoop!.run();
    }
    
    static let renderRunLoop = { () -> RunLoop in
        let semaphore = DispatchSemaphore(value: 0);
        let thread = Thread(target: GLView.self, selector: #selector(Self.createRenderRunLoop(_:)), object: semaphore);
        thread.start();
        print("#testDisplayLink# Before wait");
        semaphore.wait();
        print("#testDisplayLink# After wait");
        return _renderRunLoop!;
    }()
    
    
    private var _eaglLayer: CAEAGLLayer?
    private var _glRenderLoop: GLRenderLoop? = nil
    private var _frameBuffer: GLuint = 0
    private var _renderBuffer: GLuint = 0
//    private var _depthBuffer: GLuint = 0
}
#endif //#if os(macOS)
