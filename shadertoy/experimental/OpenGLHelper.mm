//
//  OpenGLHelper.cpp
//  ShaMderToy
//
//  Created by Dom Chiu on 2021/8/2.
//

#include "OpenGLHelper.h"
#if TARGET_OS_IOS
#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/gltypes.h>
#endif
#include <stdlib.h>

void createOrUpdateTexture(GLuint* pTextureID, GLint width, GLint height, GLubyte** pTextureData, GLsizei* pTextureDataSize, void(*dataSetter)(GLubyte* data, GLint pow2Width, GLint pow2Height, void* userData), void* userData)
{
    GLsizei pow2Width = (GLsizei) width;///nextPOT(width);
    GLsizei pow2Height = (GLsizei) height;///nextPOT(height);
    
    GLubyte* textureData = NULL;
    if (NULL == pTextureData)
    {
        pTextureData = &textureData;
    }
    GLsizei textureDataSize = 0;
    if (NULL == pTextureDataSize)
    {
        pTextureDataSize = &textureDataSize;
    }
    
    if (0 == *pTextureID)
    {
        glGenTextures(1, pTextureID);
    }
    glBindTexture(GL_TEXTURE_2D, *pTextureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);//GL_LINEAR//GL_NEAREST//GL_LINEAR_MIPMAP_LINEAR
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);//GL_CLAMP_TO_EDGE);//GL_REPEAT
    
    bool isOwnerOfData = true;
    if (NULL == *pTextureData)
    {
        *pTextureDataSize = pow2Width * pow2Height * 4;
        *pTextureData = (GLubyte*) malloc(*pTextureDataSize);
    }
    else if (*pTextureDataSize < pow2Height * pow2Width * 4)
    {
        free(*pTextureData);
        *pTextureDataSize = pow2Width * pow2Height * 4;
        *pTextureData = (GLubyte*) malloc(*pTextureDataSize);
    }
    else
    {
        isOwnerOfData = false;
    }
    
    if (dataSetter)
    {
        dataSetter(*pTextureData, pow2Width, pow2Height, userData);
    }
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)pow2Width, (GLsizei)pow2Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, *pTextureData);
    
    if (isOwnerOfData)
    {
        free(*pTextureData);
    }
//    glGenerateMipmap(GL_TEXTURE_2D);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

void createOrUpdateCubemapTexture(GLuint* pTextureID, GLint width, GLint height, GLubyte** pTextureData, GLsizei* pTextureDataSize, void(*dataSetter)(GLubyte* data, GLint pow2Width, GLint pow2Height, void* userData), void* userData)
{
    GLsizei pow2Width = (GLsizei) width;///nextPOT(width);
    GLsizei pow2Height = (GLsizei) height;///nextPOT(height);
    
    GLubyte* textureData = NULL;
    if (NULL == pTextureData)
    {
        pTextureData = &textureData;
    }
    GLsizei textureDataSize = 0;
    if (NULL == pTextureDataSize)
    {
        pTextureDataSize = &textureDataSize;
    }
    
    if (0 == *pTextureID)
    {
        glGenTextures(1, pTextureID);
    }
    glBindTexture(GL_TEXTURE_CUBE_MAP, *pTextureID);
    
    bool isOwnerOfData = true;
    if (NULL == *pTextureData)
    {
        *pTextureDataSize = pow2Width * pow2Height * 4;
        *pTextureData = (GLubyte*) malloc(*pTextureDataSize);
    }
    else if (*pTextureDataSize < pow2Height * pow2Width * 4)
    {
        free(*pTextureData);
        *pTextureDataSize = pow2Width * pow2Height * 4;
        *pTextureData = (GLubyte*) malloc(*pTextureDataSize);
    }
    else
    {
        isOwnerOfData = false;
    }
    
    if (dataSetter)
    {
        dataSetter(*pTextureData, pow2Width, pow2Height, userData);
    }
    
    GLubyte* pData = *pTextureData;
    const int ByteStride = 4 * pow2Width * pow2Width;
    for (int iFace = 0; iFace < 6; iFace++)
    {
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + iFace, 0, GL_RGBA, (GLsizei)pow2Width, (GLsizei)pow2Width, 0, GL_RGBA, GL_UNSIGNED_BYTE, pData);
        pData += ByteStride;
    }
    
    if (isOwnerOfData)
    {
        free(*pTextureData);
    }
//    glGenerateMipmap(GL_TEXTURE_2D);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
}

#if defined(TARGET_OS_IOS) && TARGET_OS_IOS != 0
#if !defined(TARGET_OS_OSX) || TARGET_OS_OSX == 0

typedef struct {
    size_t width;
    size_t height;
    CGImageRef cgImage;
} CreateOrUpdateTextureWithBitmapBlockContext;

void createOrUpdateTextureWithBitmap(GLubyte* data, GLint pow2Width, GLint pow2Height, void* userData) {
    CreateOrUpdateTextureWithBitmapBlockContext* context = (CreateOrUpdateTextureWithBitmapBlockContext*) userData;
    size_t width = context->width;
    size_t height = context->height;
    CGImageRef cgImage = context->cgImage;
    delete context;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef cgContext = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextSetFillColorWithColor(cgContext, [UIColor clearColor].CGColor);
    CGContextSetBlendMode(cgContext, kCGBlendModeCopy);
    CGContextSetAlpha(cgContext, 1.0f);
    CGContextFillRect(cgContext, CGRectMake(0, 0, width, height));
    CGContextDrawImage(cgContext, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(cgContext);
    CGImageRelease(cgImage);
}

void loadTextureFromImage(GLuint* pTexture, UIImage* image, CGSize destSize) {
    CGImageRef cgImage = [image CGImage];
    CGImageRetain(cgImage);
    size_t width = (destSize.width == 0 ? CGImageGetWidth(cgImage) : destSize.width);
    size_t height = (destSize.height == 0 ? CGImageGetHeight(cgImage) : destSize.height);
    
    CreateOrUpdateTextureWithBitmapBlockContext* context = new CreateOrUpdateTextureWithBitmapBlockContext;
    context->width = width;
    context->height = height;
    context->cgImage = cgImage;
    
    createOrUpdateTexture(pTexture, (GLint)width, (GLint)height, NULL, NULL, createOrUpdateTextureWithBitmap, context);
}

void loadCubemapTextureFromImage(GLuint* pTexture, UIImage* image, CGSize destSize) {
    CGImageRef cgImage = [image CGImage];
    CGImageRetain(cgImage);
    size_t width = (destSize.width == 0 ? CGImageGetWidth(cgImage) : destSize.width);
    size_t height = (destSize.height == 0 ? CGImageGetHeight(cgImage) : destSize.height);
    
    CreateOrUpdateTextureWithBitmapBlockContext* context = new CreateOrUpdateTextureWithBitmapBlockContext;
    context->width = width;
    context->height = height;
    context->cgImage = cgImage;
    
    createOrUpdateCubemapTexture(pTexture, (GLint)width, (GLint)height, NULL, NULL, createOrUpdateTextureWithBitmap, context);
}

//- (void) loadData:(unsigned char *)data width:(int)width height:(int)height depth:(int)depth channels:(int)channels isFloat:(BOOL)isFloat cubemapLayer:(int)layer {
//    GLenum format=GL_RGBA;
//    GLenum sourceFormat=GL_RGBA;
//    
//    if (channels == 4) {
//        format = isFloat?GL_RGBA16F:GL_RGBA8;
//        sourceFormat=GL_RGBA;
//    }
//    if (channels == 3) {
//        format = isFloat?GL_RGB16F:GL_RGB8;
//        sourceFormat=GL_RGB;
//    }
//    if (channels == 2) {
//        format = isFloat?GL_RG16F:GL_RG8;
//        sourceFormat=GL_RG;
//    }
//    if (channels == 1) {
//        format = isFloat?GL_R16F:GL_R8;
//        sourceFormat=GL_RED;
//    }
//    
//    if( _type == TEXTURECUBE ) {
//        glBindTexture(GL_TEXTURE_CUBE_MAP, _texId);
//        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + layer, 0, format, width, height, 0, sourceFormat, isFloat?GL_FLOAT:GL_UNSIGNED_BYTE, data);
//        glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
//    } else if( _type == TEXTURE3D) {
//        glBindTexture(GL_TEXTURE_3D, _texId);
//        glTexImage3D(GL_TEXTURE_3D, 0, format, width, height, depth, 0, sourceFormat, isFloat?GL_FLOAT:GL_UNSIGNED_BYTE, data);
//        glGenerateMipmap(GL_TEXTURE_3D);
//    } else {
//        glBindTexture(GL_TEXTURE_2D, _texId);
//        glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, sourceFormat, isFloat?GL_FLOAT:GL_UNSIGNED_BYTE, data);
//        glGenerateMipmap(GL_TEXTURE_2D);
//    }
//    
//    _iChannelWidth = (float)width;
//    _iChannelHeight = (float)height;
//    _iChannelDepth = (float)depth;
//    
//    _isInitialised = YES;
//}

bool loadBin3DTextureFile(GLuint* pTexture, NSString* filePath, GLuint* pWidth, GLuint* pHeight, GLuint* pDepth)
{
    FILE* fp = fopen(filePath.UTF8String, "rb+");
    // int signature = [self readInt32:file offset:0];
    int32_t iChannelWidth, iChannelHeight, iChannelDepth;
    uint8_t binNumChannels;
    uint16_t binFormat;
    int bytes = fseek(fp, 4, SEEK_CUR);
    fread(&iChannelWidth, 4, 1, fp);
    fread(&iChannelHeight, 4, 1, fp);
    fread(&iChannelDepth, 4, 1, fp);
    if (pWidth) *pWidth = iChannelWidth;
    if (pHeight) *pHeight = iChannelHeight;
    if (pDepth) *pDepth = iChannelDepth;

    fread(&binNumChannels, 1, 1, fp);
    // unsigned char binLayout = [self readUInt8:file offset:17];
    bytes = fseek(fp, 1, SEEK_CUR);
    fread(&binFormat, 2, 1, fp);

    if ((binNumChannels < 1 && binNumChannels > 4) || (binFormat != 0 && binFormat != 10))
    {
        fclose(fp);
        return  false;
    }
    bool isFloat = (10 == binFormat);

    fseek(fp, 0, SEEK_END);
    long dataSize = ftell(fp) - 20;
    
    unsigned char* data = (unsigned char*)malloc(dataSize);
    fread(data, dataSize, 1, fp);

    GLenum format = GL_RGBA;
    GLenum sourceFormat = GL_RGBA;
    switch (binNumChannels)
    {
        case 4:
            format = isFloat ? GL_RGBA16F : GL_RGBA8;
            sourceFormat = GL_RGBA;
            break;
        case 3:
            format = isFloat ? GL_RGB16F : GL_RGB8;
            sourceFormat = GL_RGB;
            break;
        case 2:
            format = isFloat ? GL_RG16F : GL_RG8;
            sourceFormat = GL_RG;
            break;
        case 1:
            format = isFloat ? GL_R16F : GL_R8;
            sourceFormat = GL_RED;
            break;
        default:
            break;
    }
    
    glBindTexture(GL_TEXTURE_3D, *pTexture);
    glTexImage3D(GL_TEXTURE_3D, 0, format, iChannelWidth, iChannelHeight, iChannelDepth, 0, sourceFormat, isFloat ? GL_FLOAT :  GL_UNSIGNED_BYTE, data);
    glGenerateMipmap(GL_TEXTURE_3D);
    
//        if( _type == TEXTURECUBE ) {
//            glBindTexture(GL_TEXTURE_CUBE_MAP, _texId);
//            glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + layer, 0, format, width, height, 0, sourceFormat, isFloat?GL_FLOAT:GL_UNSIGNED_BYTE, data);
//            glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
//        } else if( _type == TEXTURE3D) {
//
//        } else {
//            glBindTexture(GL_TEXTURE_2D, _texId);
//            glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, sourceFormat, isFloat?GL_FLOAT:GL_UNSIGNED_BYTE, data);
//            glGenerateMipmap(GL_TEXTURE_2D);
//        }

    free(data);
    fclose(fp);
    return true;
}

GLuint createTextureFromImage(UIImage* image, CGSize destSize) {
    GLuint texture = 0;
    loadTextureFromImage(&texture, image, destSize);
    return texture;
}

GLuint createCubemapTextureFromImage(UIImage* image, CGSize destSize) {
    GLuint texture = 0;
    loadCubemapTextureFromImage(&texture, image, destSize);
    return texture;
}

#endif
#endif
