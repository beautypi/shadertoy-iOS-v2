//
//  GLView.swift
//  MetalPlayground
//
//  Created by qiudong on 2021/6/16.
//  Copyright © 2021 Dom Chiu. All rights reserved.
//

#if os(macOS)
import Cocoa
import OpenGL

#elseif os(iOS)
import UIKit
import OpenGLES

#endif

@objc
protocol GLRenderer : AnyObject {
    func createGLObjectsIfNecessary();
    func releaseGLObjectsIfNecessary();
    func didResumeRendering();
    func willPauseRendering();
//    func didCanvasResize(newViewport: CGRect);
    func render(timestamp: Float, frameCount: Int);
    
    @objc
    optional func preRender(timestamp: Float, frameCount: Int);
    
    @objc
    optional func postRender(timestamp: Float, frameCount: Int);
}

class GLRenderLoop : NSObject, RenderLoopDelegate {
    private let GLContextTLSKey = "GLContext";
    
    func resetTimeStamp() {
        _renderLoop?.resetTimeStamp();
    }
    
    func onCreate() {
//        //print("#GLRenderLoop# onCreate");
        #if os(macOS)
        if let ctx = Thread.current.threadDictionary[GLContextTLSKey]
        {
            _glContext = ctx as? NSOpenGLContext;
        }
        else
        {
            let attrs: [NSOpenGLPixelFormatAttribute] = [
                UInt32(NSOpenGLPFADoubleBuffer),
                UInt32(NSOpenGLPFADepthSize), 24,
                UInt32(NSOpenGLPFAAllowOfflineRenderers),
                // Must specify the 3.2 Core Profile to use OpenGL 3.2
                UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersion3_2Core),
                0];
            let pixelformat = NSOpenGLPixelFormat(attributes: attrs);
            _glContext = NSOpenGLContext(format: pixelformat!, share: nil);
            
            Thread.current.threadDictionary[GLContextTLSKey] = _glContext;
        }
        #elseif os(iOS)
        if let ctx = Thread.current.threadDictionary[GLContextTLSKey]
        {
            _glContext = ctx as? CVEAGLContext;
        }
        else
        {
            _glContext = CVEAGLContext(api: .openGLES3);
            Thread.current.threadDictionary[GLContextTLSKey] = _glContext;
        }
        #endif //#if os(macOS)
        beginWithGLContext();
        if let r = self.renderer
        {
            r.createGLObjectsIfNecessary();
        }
        endWithGLContext();
    }
    
    func onResume() {
//        //print("#GLRenderLoop# onResume");
        beginWithGLContext();
        if let r = self.renderer
        {
            r.didResumeRendering();
        }
        endWithGLContext();
    }
    
    func onPause() {
//        //print("#GLRenderLoop# onPause");
        #if os(macOS)
        _glContext?.makeCurrentContext();
        #elseif os(iOS)
        CVEAGLContext.setCurrent(_glContext);
        #endif //#if os(macOS)
        if let r = self.renderer
        {
            r.willPauseRendering();
        }
        glFinish();
    }
    
    func onDestroy() {
//        //print("#GLRenderLoop# onDestroy");
        beginWithGLContext();
        if let r = self.renderer
        {
            r.releaseGLObjectsIfNecessary();
        }
        glFinish();
        endWithGLContext();
        _glContext = nil;
    }
    
    func onRender(_ renderLoop: RenderLoop) {
//        //print("#GLRenderLoop# onRender");
        guard let r = self.renderer
        else
        {
            return;
        }
        let timestamp = Float(renderLoop.timestamp);
        let frameCount = renderLoop.frameCount;
        r.preRender?(timestamp: timestamp, frameCount: frameCount);
        beginWithGLContext();
        r.render(timestamp: timestamp, frameCount: frameCount);
        #if os(iOS)
        _glContext?.presentRenderbuffer(Int(GL_RENDERBUFFER));
        #endif //#if os(iOS)
        endWithGLContext();
        r.postRender?(timestamp: timestamp, frameCount: frameCount);
    }
    
    func pause() {
        //print("#GLRenderLoop# Begin pause");
        _renderLoop?.pause(true);
        //print("#GLRenderLoop# End pause");
    }
    
    func resume() {
        //print("#GLRenderLoop# Begin resume");
        _renderLoop?.start(true);
        //print("#GLRenderLoop# End resume");
    }
    
    func destroy() {
        //print("#GLRenderLoop# Begin destroy");
        _renderLoop?.destroy();
        //print("#GLRenderLoop# End destroy");
    }
    
    func performActionAsync(_ callback: @escaping (Any?) -> Void, args: Any?) {
        _renderLoop?.runAsync {
            self.beginWithGLContext();
            callback(args);
            self.endWithGLContext();
        }
    }
    
    func beginWithGLContext() {
        #if os(macOS)
        _prevGLContext = NSOpenGLContext.current;
        _glContext?.makeCurrentContext();
        CGLLockContext((_glContext?.cglContextObj)!);
        #elseif os(iOS)
        _prevGLContext = CVEAGLContext.current();
        CVEAGLContext.setCurrent(_glContext);
        #endif //#if os(macOS)
        CHECK_GL_ERROR();
    }
    
    func endWithGLContext() {
        #if os(macOS)
        NSOpenGLContext.clearCurrentContext();
        CGLUnlockContext((_glContext?.cglContextObj)!);
        if let prevCtx = _prevGLContext
        {
            prevCtx.makeCurrentContext();
            CGLLockContext((prevCtx.cglContextObj)!);
        }
        #elseif os(iOS)
        if let prevCtx = _prevGLContext
        {
            CVEAGLContext.setCurrent(prevCtx);
        }
        #endif //#if os(macOS)
        CHECK_GL_ERROR();
    }
    
    deinit {
//        print("#List#Cache#Leak# GLRenderLoop.deinit (\(self.hash))");
        self.renderer = nil;
    }
    
    required init(renderer: GLRenderer, renderRunLoop: RunLoop) {
        super.init();
//        print("#List#Cache#Leak# GLRenderLoop.init (\(self.hash))");
        self.renderer = renderer;
        _renderLoop = RenderLoop(delegate: self, runLoop: renderRunLoop);
    }
    
    weak var renderer: GLRenderer? = nil;
    private var _renderLoop: RenderLoop? = nil
    #if os(macOS)
    private var _glContext: NSOpenGLContext?
    private var _prevGLContext: NSOpenGLContext?
    #elseif os(iOS)
    private var _glContext: CVEAGLContext?
    private var _prevGLContext: CVEAGLContext?
    #endif //#if os(macOS)
}
