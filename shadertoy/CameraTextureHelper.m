//
//  CameraTextureHelper.m
//  Shadertoy
//
//  Created by Reinder Nijhoff on 30/09/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import "CameraTextureHelper.h"
#import "VRManager.h"

#import <GLKit/GLKit.h>
#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>

#import "Utils.h"
#import "GLUtils.h"

@interface CameraTextureHelper () {
    GLsizei _textureWidth;
    GLsizei _textureHeight;
    
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    
    GLuint _frameBuffer;
    GLuint _programId;
    
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexArray;
    
    GLuint _tex;
}
    
    @end

@implementation CameraTextureHelper
    
-(id) init {
    self = [super init];
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [EAGLContext currentContext], NULL, &_videoTextureCache);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
    }
    
    NSString *error;
    _programId = [GLUtils compileShader:[[NSString alloc] readFromFile:@"/shaders/vertex_camera_tex" ofType:@"glsl"]
                     fragmentShaderCode:[[NSString alloc] readFromFile:@"/shaders/fragment_camera_tex" ofType:@"glsl"] theError:&error];
    
    NSLog(@"%@", error);
    
    [GLUtils createVAO:&_vertexArray buffer:&_vertexBuffer index:&_indexBuffer];
        
    _frameBuffer = [GLUtils createRenderBuffer];
    return self;
}
    
+(BOOL) isSupported {
    return [VRManager isCameraTextureSupported];
}
    
-(void) update {
    
    CVImageBufferRef pixelBuffer = (CVImageBufferRef)[VRManager capturedImage];
    
    if (CVPixelBufferGetPlaneCount(pixelBuffer) < 2) {
        NSLog(@"pixelBuffer incorrect plane count %@ %zu", pixelBuffer, CVPixelBufferGetPlaneCount(pixelBuffer));
        return;
    }
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    _textureWidth = (GLsizei)width;
    _textureHeight = (GLsizei)height;
    
    if (!_videoTextureCache)
    {
        NSLog(@"No video texture cache");
        return;
    }
 
    [self cleanUpTextures];
    
    CVReturn err;
    glActiveTexture(GL_TEXTURE0);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_LUMINANCE,
                                                       _textureWidth,
                                                       _textureHeight,
                                                       GL_LUMINANCE,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_lumaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glActiveTexture(GL_TEXTURE1);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_LUMINANCE_ALPHA,
                                                       _textureWidth / 2.0,
                                                       _textureHeight / 2.0,
                                                       GL_LUMINANCE_ALPHA,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &_chromaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    GLint drawFboId = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &drawFboId);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    if(!_tex) {
        glGenTextures(1, &_tex);
        glBindTexture(GL_TEXTURE_2D, _tex);
        glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA8, 512, 512);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _tex, 0);
    }
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _tex, 0);
    
    glViewport(0, 0, 512, 512);
    
    glUseProgram(_programId);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_lumaTexture));
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_chromaTexture));
    
    glUniform1i( glGetUniformLocation(_programId, "SamplerY"), 0);
    glUniform1i( glGetUniformLocation(_programId, "SamplerUV"), 1);
    
    
    glBindVertexArray(_vertexArray);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, drawFboId);
}
    
- (void) bindToChannel:(int)channel {
    glActiveTexture(GL_TEXTURE0 + channel);
    glBindTexture(GL_TEXTURE_2D, _tex);
}
    
- (void)dealloc {
    [self cleanUpTextures];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArrays(1, &_vertexArray);
    
    glDeleteFramebuffers(1, &_frameBuffer);
    
    if(_tex) {
        glDeleteTextures(1, &_tex);
    }
    
    glDeleteProgram(_programId);
}
    
- (void)cleanUpTextures {
    if (_lumaTexture)  {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}
    
    @end
