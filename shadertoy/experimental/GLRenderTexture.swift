//
//  GLRenderTexture.swift
//  MetalPlayground
//
//  Created by Dom Chiu on 2021/6/19.
//  Copyright © 2021 Dom Chiu. All rights reserved.
//

#if os(macOS)
import Cocoa
import OpenGL

#elseif os(iOS)
import UIKit
import OpenGLES

#endif //#if os(macOS)

class GLRenderTexture {
    var bytesLength: Int {
        return Int(_width * _height * _depth) * ComponentsOfColorSpace(_format) * BytesOfBitFormat(_dataType);//TODO:
    }

    func blit() {
        glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING), &_prevFramebuffer);
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _framebuffer);
    }

    func unblit() {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLuint(_prevFramebuffer));
        CHECK_GL_ERROR();
    }

    func copyPixelData(data: UnsafeMutableRawPointer, offset: Int, length: Int) -> Int {
        if (_width <= 0 || _height <= 0)
        {
            print("GLRenderTexture::copyPixelData() Error : _width = %d, _height = %d", _width, _height);
        }
        glReadPixels(0, 0, _width, _height, _format, _dataType, data + offset);///!!!
        CHECK_GL_ERROR();
        glFlush();
        return self.bytesLength;
    }

//    func copyPixelDataFromPBO(offset: Int, length: Int) -> UnsafeMutableRawPointer? {
//        let success = GL_FALSE;
//        var pixels: UnsafeMutableRawPointer;
//        if (_isPBOSupported)
//        {
//            var prevPboBinding: GLint;
//            glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &prevPboBinding);
//
//            glReadBuffer(GL_COLOR_ATTACHMENT0);
//            glBindBuffer(GL_PIXEL_PACK_BUFFER, _pboIDs[_pboIndex]);
//            glReadPixels(0, 0, _width, _height, GL_RGBA, GL_UNSIGNED_BYTE, 0);
//
//            _pboIndex = (_pboIndex + 1) % 2;
//            glBindBuffer(GL_PIXEL_PACK_BUFFER, _pboIDs[_pboIndex]);
//            pixels = (GLubyte*) glMapBufferRange(GL_PIXEL_PACK_BUFFER, 0, bytesLength(), GL_MAP_READ_BIT);
//            CHECK_GL_ERROR();
//            if (pixels)
//            {
//                success = glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
//            }
//            CHECK_GL_ERROR();
//            glBindBuffer(GL_PIXEL_PACK_BUFFER, prevPboBinding);
//        }
//        print("GLRenderTexture::copyPixelDataFromPBO : success = \(success)");
//        return  (GL_TRUE == success) ? pixels : UnsafeMutableRawPointer(bitPattern: 0);
//    }
    
    deinit {
//        print("#List#Cache#Leak# GLRenderTexture.deinit ");
        releaseGLObjects();
    }

    init(texture: GLuint, textureTarget: GLenum, width: GLint, height: GLint, depth: GLint, internalFormat: GLint, format: GLenum, dataType: GLenum, wrapS: GLint, wrapT: GLint, enableDepthTest: Bool)
    {
//        print("#List#Cache#Leak# GLRenderTexture.init 1");
        _framebuffer = 0;
        _texture = texture;
        _textureTarget = textureTarget;
        _ownTexture = texture <= 0;
        _width = 0;
        _height = 0;
        _depth = 0;
        _format = format;
        _internalFormat = internalFormat;
        _dataType = dataType;
        _wrapS = wrapS;
        _wrapT = wrapT;
        //_pboIDs{0,0}
        //_pboIndex = 0;
        _enableDepthTest = enableDepthTest;

//    #if !defined(TARGET_OS_OSX) || TARGET_OS_OSX == 0
//        const char* extensions = (const char*) glGetString(GL_EXTENSIONS);
//        ALOGE("GL Extensions : %s", extensions);
//    //    _isPBOSupported = true;///!!!(NULL != strstr(extensions, "pixel_buffer_object"));
//    #endif
        if (0 != resizeIfNecessary(width, height, depth))
        {
            releaseGLObjects();
        }
        else
        {
            var prevRenderbuffer: GLint = 0;
            var prevTexture2D: GLint = 0;
            var prevTexture3D: GLint = 0;
            var prevTextureCubemap: GLint = 0;
            glGetIntegerv(GLenum(GL_RENDERBUFFER_BINDING), &prevRenderbuffer);
            glGetIntegerv(GLenum(GL_TEXTURE_BINDING_2D), &prevTexture2D);
            glGetIntegerv(GLenum(GL_TEXTURE_BINDING_3D), &prevTexture3D);
            glGetIntegerv(GLenum(GL_TEXTURE_BINDING_CUBE_MAP), &prevTextureCubemap);
//    #if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
//            var prevTextureExternal: GLint;
//            glGetIntegerv(GL_TEXTURE_BINDING_EXTERNAL_OES, &prevTextureExternal);
//    #endif
            var prevFramebuffer: GLint = 0;
            glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING), &prevFramebuffer);

            glBindTexture(_textureTarget, _texture);
            glTexParameteri(_textureTarget, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);//GL_LINEAR//GL_NEAREST
            glTexParameteri(_textureTarget, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);//GL_LINEAR//GL_NEAREST
            glTexParameteri(_textureTarget, GLenum(GL_TEXTURE_WRAP_S), _wrapS);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            glTexParameteri(_textureTarget, GLenum(GL_TEXTURE_WRAP_T), _wrapT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
            glPixelStorei(GLenum(GL_PACK_ALIGNMENT), 1);
            glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT), 1);
            
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLuint(prevFramebuffer));
            glBindRenderbuffer(GLenum(GL_RENDERBUFFER), GLuint(prevRenderbuffer));
            glBindTexture(GLenum(GL_TEXTURE_2D), GLuint(prevTexture2D));
            glBindTexture(GLenum(GL_TEXTURE_3D), GLuint(prevTexture3D));
            glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), GLuint(prevTextureCubemap));
//    #if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
//            glBindTexture(GL_TEXTURE_EXTERNAL_OES, prevTextureExternal);
//    #endif
        }
    }

    convenience init(texture: GLuint, textureTarget: GLenum, width: GLint, height: GLint, depth: GLint, internalFormat: GLint, format: GLenum, dataType: GLenum, enableDepthTest: Bool)
    {
//        print("#List#Cache#Leak# GLRenderTexture.init 2");
        self.init(texture: texture, textureTarget: textureTarget, width: width, height: height, depth: depth, internalFormat: internalFormat, format: format, dataType: dataType, wrapS: GL_REPEAT, wrapT: GL_REPEAT, enableDepthTest: enableDepthTest);
    }

    convenience init(texture: GLuint, textureTarget: GLenum, width: GLint, height: GLint, depth: GLint, enableDepthTest: Bool)
    {
//        print("#List#Cache#Leak# GLRenderTexture.init 3");
        self.init(texture: texture, textureTarget: textureTarget, width: width, height: height, depth: depth, internalFormat: GL_RGBA, format: GLenum(GL_RGBA), dataType: GLenum(GL_UNSIGNED_BYTE), enableDepthTest: enableDepthTest);
    }

    convenience init(width: GLint, height: GLint, depth: GLint, enableDepthTest: Bool)
    {
//        print("#List#Cache#Leak# GLRenderTexture.init 4");
        self.init(texture: 0, textureTarget: GLenum(GL_TEXTURE_2D), width: width, height: height, depth: depth, enableDepthTest: enableDepthTest);
    }
    
    @discardableResult
    func resizeIfNecessary(_ width: GLint, _ height: GLint, _ depth: GLint) -> Int {
        if (_width != width || _height != height || _depth != depth)
        {
            _width = width;
            _height = height;
            _depth = depth;

            var prevRenderbuffer: GLint = 0;
            var prevTexture2D: GLint = 0;
            var prevTexture3D: GLint = 0;
            var prevTextureCubemap: GLint = 0;
            glGetIntegerv(GLenum(GL_RENDERBUFFER_BINDING), &prevRenderbuffer);
            glGetIntegerv(GLenum(GL_TEXTURE_BINDING_2D), &prevTexture2D);
            glGetIntegerv(GLenum(GL_TEXTURE_BINDING_3D), &prevTexture3D);
            glGetIntegerv(GLenum(GL_TEXTURE_BINDING_CUBE_MAP), &prevTextureCubemap);
            
//    #if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
//            var prevTextureExternal: GLint;
//            glGetIntegerv(GL_TEXTURE_BINDING_EXTERNAL_OES, &prevTextureExternal);
//    #endif
            var prevFramebuffer: GLint = 0;
            glGetIntegerv(GLenum(GL_FRAMEBUFFER_BINDING), &prevFramebuffer);

            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _framebuffer);

            if ((_texture != 0 || _cvOpenGLESTextureRef != nil) && _ownTexture)
            {
                glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), _textureTarget, 0, 0);
                #if os(iOS)
                if Self._WithIOSurfaceBackedTexture_
                {
                    if let _ = _cvPixelBufferRef
                    {
                        _cvPixelBufferRef = nil;
                    }
                    if let _ = _cvOpenGLESTextureRef
                    {
                        _cvOpenGLESTextureRef = nil;
                    }
                }
                else
                {
                    glDeleteTextures(1, &_texture);
                }
                #else
                glDeleteTextures(1, &_texture);
                #endif
                _texture = 0;
            }
            CHECK_GL_ERROR();
            if (_enableDepthTest)
            {
                if (_depthTexture > 0)
                {
                    glDeleteTextures(1, &_depthTexture);
                    CHECK_GL_ERROR();
                }
                _depthTexture = 0;
            }
            if (0 != _framebuffer)
            {
                glDeleteFramebuffers(1, &_framebuffer);
            }
            CHECK_GL_ERROR();
            glGenFramebuffers(1, &_framebuffer);
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), _framebuffer);
            if (_ownTexture)
            {
                repeat
                {
                    #if os(iOS)
                    if Self._WithIOSurfaceBackedTexture_
                    {
                        if let eaglCtx = CVEAGLContext.current()
                        {
                            // Swift code: https://stackoverflow.com/questions/33053412/how-to-initialise-cvpixelbufferref-in-swift
                            // https://www.sitepoint.com/using-legacy-c-apis-swift/
                            // https://codbo.cn/blog-222.html
                            if let textureCache = GLRenderTexture.coreVideoTextureCache(eaglCtx)
                            {
                                var status: CVReturn = 0;
                                let empty: CFDictionary? = [:] as CFDictionary;
                                let attrs = [kCVPixelBufferIOSurfacePropertiesKey as String : empty] as CFDictionary;
                                withUnsafeMutablePointer(to: &_cvPixelBufferRef) { (pixelBufferRef: UnsafeMutablePointer<CVPixelBuffer?>) in
                                    status = CVPixelBufferCreate(kCFAllocatorDefault, Int(_width), Int(_height), kCVPixelFormatType_32BGRA as OSType, attrs as CFDictionary?, pixelBufferRef);
                                }
                                status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, _cvPixelBufferRef!, nil, _textureTarget, _internalFormat, _width, _height, _format, _dataType, 0, &_cvOpenGLESTextureRef);
                                if (status == 0)
                                {
                                    _textureTarget = CVOpenGLESTextureGetTarget(_cvOpenGLESTextureRef!);
                                    _texture = CVOpenGLESTextureGetName(_cvOpenGLESTextureRef!);
                                    glBindTexture(_textureTarget, _texture);
                                    break;
                                }
                                else
                                {
                                    _cvPixelBufferRef = nil;
                                    _cvOpenGLESTextureRef = nil;
                                }
                            }
                         //OC Codes: ...
                        }
                    }
                    #else
                    
                    #endif
                    glGenTextures(1, &_texture);
                    glBindTexture(_textureTarget, _texture);
                    //    GLubyte* pixelData = (GLubyte*) malloc(destSize.width * destSize.height * 4);
                    glTexImage2D(_textureTarget, 0, _internalFormat, width, height, 0, _format, _dataType, nil);
                    CHECK_GL_ERROR();
                    let errorNo = glGetError();
                    if (GL_OUT_OF_MEMORY == errorNo)
                    {
                        print("\nOpenGL error \(errorNo) in %s %s %d\n");
                        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLuint(prevFramebuffer));
                        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), GLuint(prevRenderbuffer));
                        glBindTexture(GLenum(GL_TEXTURE_2D), GLuint(prevTexture2D));
                        glBindTexture(GLenum(GL_TEXTURE_3D), GLuint(prevTexture3D));
                        glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), GLuint(prevTextureCubemap));
    //    #if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
    //                    glBindTexture(GLenum(GL_TEXTURE_EXTERNAL_OES), prevTextureExternal);
    //    #endif
                        return -1;
                    }
                } while (false);
                
                glTexParameteri(_textureTarget, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR);//GL_LINEAR//GL_NEAREST
                glTexParameteri(_textureTarget, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR);//GL_LINEAR//GL_NEAREST
                glTexParameteri(_textureTarget, GLenum(GL_TEXTURE_WRAP_S), _wrapS);//GL_CLAMP_TO_EDGE);//GL_REPEAT
                glTexParameteri(_textureTarget, GLenum(GL_TEXTURE_WRAP_T), _wrapT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
                glPixelStorei(GLenum(GL_PACK_ALIGNMENT), 1);
                glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT), 1);
            }
            CHECK_GL_ERROR();
            glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), _textureTarget, _texture, 0);
            var status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER));
//            print("glFramebufferTexture2D status = \(status)");
    //        if (_isPBOSupported)
    //        {
    //            var prevPboBinding: GLint;
    //            glGetIntegerv(GLenum(GL_PIXEL_PACK_BUFFER_BINDING), &prevPboBinding);
    //
    //            if (_pboIDs[0] > 0)
    //            {
    //                glDeleteBuffers(2, _pboIDs);
    //                _pboIDs[0] = _pboIDs[1] = 0;
    //            }
    //
    //            glGenBuffers(2, _pboIDs);
    //            for (int i=0; i<2; ++i)
    //            {
    //                glBindBuffer(GLenum(GL_PIXEL_PACK_BUFFER), _pboIDs[i]);
    //                glBufferData(GLenum(GL_PIXEL_PACK_BUFFER), width * height * 4, NULL, GLenum(GL_DYNAMIC_READ));//GL_STREAM_READ);//
    //                CHECK_GL_ERROR();
    //            }
    //
    //            glBindBuffer(GLenum(GL_PIXEL_PACK_BUFFER), prevPboBinding);
    //        }
            if (_enableDepthTest)
            {
                glGenTextures(1, &_depthTexture);
                glBindTexture(GLenum(GL_TEXTURE_2D), _depthTexture);
                
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST);
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST);
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
                
                glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_DEPTH_COMPONENT32F, width, height, 0, GLenum(GL_DEPTH_COMPONENT), GLenum(GL_FLOAT), nil);
                
                glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_TEXTURE_2D), _depthTexture, 0);
                status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER));
                print("GLRenderTexture glCheckFramebufferStatus()=\(status)");
            }
            
            glBindFramebuffer(GLenum(GL_FRAMEBUFFER), GLuint(prevFramebuffer));
            glBindRenderbuffer(GLenum(GL_RENDERBUFFER), GLuint(prevRenderbuffer));
            glBindTexture(GLenum(GL_TEXTURE_2D), GLuint(prevTexture2D));
            glBindTexture(GLenum(GL_TEXTURE_3D), GLuint(prevTexture3D));
            glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), GLuint(prevTextureCubemap));
//    #if defined(TARGET_OS_ANDROID) && TARGET_OS_ANDROID != 0
//            glBindTexture(GLenum(GL_TEXTURE_EXTERNAL_OES), prevTextureExternal);
//    #endif
        }
        return 0;
    }
    
    func withinTextureBinding(_ handler: (_ texture: GLuint) -> Void) {
        var prevTextureBinding: GLint = 0;
        glGetIntegerv(GLenum(GL_TEXTURE_BINDING_2D), &prevTextureBinding);
        glBindTexture(GLenum(GL_TEXTURE_2D), _texture);
        handler(_texture);
        glBindTexture(GLenum(GL_TEXTURE_2D), GLuint(prevTextureBinding));
    }
    
    func releaseGLObjects() {
        if (_texture != 0 && _ownTexture)
        {
            glDeleteTextures(1, &_texture);
            _texture = 0;
        }

        if (_framebuffer != 0)
        {
            glDeleteFramebuffers(1, &_framebuffer);
            _framebuffer = 0;
        }

    //    if (_pboIDs[0] || _pboIDs[1])
    //    {
    //        glDeleteBuffers(2, _pboIDs);
    //        _pboIDs[0] = _pboIDs[1] = 0;
    //    }
        
        if (_enableDepthTest)
        {
            glDeleteTextures(1, &_depthTexture);
            _depthTexture = 0;
        }

        _cvPixelBufferRef = nil;
        _cvOpenGLESTextureRef = nil;
    }
    
    public var texture: GLuint {
        get { return _texture; }
    }
    
    private var _prevFramebuffer: GLint = 0
    private var _framebuffer: GLuint = 0
    
    private var _texture: GLuint = 0
    private var _textureTarget: GLenum = GLenum(GL_TEXTURE_2D)
    private var _ownTexture: Bool = true
    
    #if os(iOS)
    public static func coreVideoTextureCache(_ eaglContext: CVEAGLContext) -> CVOpenGLESTextureCache? {
        let cacheItem = coreVideoTextureCaches[eaglContext.hash];
        if let cache: CVOpenGLESTextureCache? = cacheItem
        {
            return cache;
        }
        var cache: CVOpenGLESTextureCache?
        let status = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, eaglContext, nil, &cache);
        if (status == 0)
        {
            coreVideoTextureCaches[eaglContext.hash] = cache;
        }
        return cache;
    }
    
    public static func pruneCoreVideoTextureCache(_ eaglContext: CVEAGLContext) {
        let cacheItem = coreVideoTextureCaches[eaglContext.hash];
        if let cache_: CVOpenGLESTextureCache? = cacheItem, let cache = cache_
        {
            CVOpenGLESTextureCacheFlush(cache, 0);
            coreVideoTextureCaches.removeValue(forKey: eaglContext.hash);
        }
    }
    
    var width: GLint { get { return _width; } }
    var height: GLint { get { return _height; } }
    var depth: GLint { get { return _depth; } }
    
    private static var coreVideoTextureCaches: [Int:CVOpenGLESTextureCache?] = [:];
    
    private var _cvOpenGLESTextureRef: CVOpenGLESTexture? = nil
    private var _cvPixelBufferRef: CVPixelBuffer? = nil
    #endif
    
    private var _enableDepthTest: Bool = false
    private var _depthTexture: GLuint = 0
    
    private var _width: GLint = 0
    private var _height: GLint = 0
    private var _depth: GLint = 0

    private var _format: GLenum
    private var _internalFormat: GLint
    private var _dataType: GLenum

    private var _wrapS: GLint
    private var _wrapT: GLint
//    private var _isPBOSupported: bool
//    GLuint _pboIDs[2];
//    private var _pboIndex: int
    private static let _WithIOSurfaceBackedTexture_ = false
}
