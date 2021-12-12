//
//  OpenGLHelper.hpp
//  ShaMderToy
//
//  Created by Dom Chiu on 2021/8/2.
//

#ifndef OpenGLHelper_hpp
#define OpenGLHelper_hpp

#include <TargetConditionals.h>

#if TARGET_OS_OSX

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

#elif TARGET_OS_IOS
    
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
    
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if TARGET_OS_OSX

GLuint createTextureFromImage(NSImage* image, CGSize destSize);

void loadTextureFromImage(GLuint* pTexture, NSImage* image, CGSize destSize);

#elif TARGET_OS_IOS

GLuint createTextureFromImage(UIImage* image, CGSize destSize);

GLuint createCubemapTextureFromImage(UIImage* image, CGSize destSize);

void loadTextureFromImage(GLuint* pTexture, UIImage* image, CGSize destSize);

void loadCubemapTextureFromImage(GLuint* pTexture, UIImage* image, CGSize destSize);

bool loadBin3DTextureFile(GLuint* pTexture, NSString* filePath, GLuint* pWidth, GLuint* pHeight, GLuint* pDepth);

#endif

void createOrUpdateTextureWithBitmap(GLubyte* data, GLint pow2Width, GLint pow2Height, void* userData);

void createOrUpdateTexture(GLuint* pTextureID, GLint width, GLint height, GLubyte** pTextureData, GLsizei* pTextureDataSize, void(*dataSetter)(GLubyte* data, GLint pow2Width, GLint pow2Height, void* userData), void* userData);

void createOrUpdateCubemapTexture(GLuint* pTextureID, GLint width, GLint height, GLubyte** pTextureData, GLsizei* pTextureDataSize, void(*dataSetter)(GLubyte* data, GLint pow2Width, GLint pow2Height, void* userData), void* userData);

#ifdef __cplusplus
}
#endif

#endif /* OpenGLHelper_hpp */
