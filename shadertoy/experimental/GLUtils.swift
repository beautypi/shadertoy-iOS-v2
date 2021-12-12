//
//  GLExtensions.swift
//  ShaMderToy
//
//  Created by qiudong on 2021/6/28.
//

#if os(macOS)
import Cocoa
import OpenGL

#elseif os(iOS)
import UIKit
import OpenGLES

#endif

enum GLError : Error {
    case CompileError(_ type: GLenum, _ message: String)
    case LinkError(_ message: String)
    case UnspecifiedError(_ errorCode: GLenum)
}

public func CHECK_GL_ERROR(line: Int = #line, function: String = #function, file: String = #file) {
    let error = glGetError();
    if (error != 0)
    {
        print("OpenGL error=\(error), #\(line) in \(function) \(file)");
    }
}

public func RUN_ON_GL_ERROR(block: () -> Void, line: Int = #line, function: String = #function, file: String = #file) {
    let error = glGetError();
    if (error != 0)
    {
        print("OpenGL error=\(error), #\(line) in \(function) \(file)");
        block();
    }
}

public func THROW_ON_GL_ERROR(line: Int = #line, function: String = #function, file: String = #file) throws {
    let error = glGetError();
    if (error != 0)
    {
        print("OpenGL error=\(error), #\(line) in \(function) \(file)");
        throw GLError.UnspecifiedError(error);
    }
}

func nextPOT(_ xx: CLong) -> CLong
{
    var x = xx - 1;
    x = x | (x >> 1);
    x = x | (x >> 2);
    x = x | (x >> 4);
    x = x | (x >> 8);
    x = x | (x >> 16);
    return x + 1;
}

func ComponentsOfColorSpace(_ colorspace: GLenum) -> Int {
    switch (GLint(colorspace))
    {
    case GL_RGB:
        return 3;
    case GL_RGBA:
        return 4;
    case GL_DEPTH_COMPONENT, GL_ALPHA:
            return 1;
    #if os(iOS)
    case GL_LUMINANCE:
        return 1;
    case GL_LUMINANCE_ALPHA:
        return 2;
    #endif
    default:
        return 4;
    }
}

func BytesOfBitFormat(_ bitformat: GLenum) -> Int {
    switch (GLint(bitformat))
    {
    case GL_UNSIGNED_BYTE:
        return 1;
    case GL_FLOAT,
        GL_SHORT,
        GL_UNSIGNED_SHORT,
        GL_UNSIGNED_SHORT_4_4_4_4,
        GL_UNSIGNED_SHORT_5_6_5,
        GL_UNSIGNED_SHORT_5_5_5_1:
        return 2;
        #if os(iOS)
    case GL_UNSIGNED_SHORT_8_8_APPLE,
        GL_UNSIGNED_SHORT_8_8_REV_APPLE:
        return 2;
        #endif
    default:
        return 0;
    }
}

class GLUtils {
    public static func setTextureParams(textureTarget: GLenum, repeatS: Bool, repeatT: Bool, repeatR: Bool, minFilter: GLint, magFilter: GLint) {
        glTexParameteri(textureTarget, GLenum(GL_TEXTURE_WRAP_S), repeatS ? GL_REPEAT : GL_CLAMP_TO_EDGE);
        glTexParameteri(textureTarget, GLenum(GL_TEXTURE_WRAP_T), repeatT ? GL_REPEAT : GL_CLAMP_TO_EDGE);
        if (GL_TEXTURE_CUBE_MAP == textureTarget || GL_TEXTURE_3D == textureTarget)
        {
            glTexParameteri(textureTarget, GLenum(GL_TEXTURE_WRAP_R), repeatR ? GL_REPEAT : GL_CLAMP_TO_EDGE);
        }
        glTexParameteri(textureTarget, GLenum(GL_TEXTURE_MIN_FILTER), minFilter);
        glTexParameteri(textureTarget, GLenum(GL_TEXTURE_MAG_FILTER), magFilter);
    }
    
    public static func loadTextureData(textureID: GLuint, textureTarget: GLenum, cubemapLayer: Int32, channels: Int, isFloat: Bool, withMipmap: Bool, width: GLsizei, height: GLsizei, depth: GLsizei, pixels: UnsafeRawPointer!) {
        var internalFormat: GLint;
        var format: GLenum;
        let valueType: GLenum = GLenum(isFloat ? GL_FLOAT : GL_UNSIGNED_BYTE);
        switch channels
        {
        case 1:
            internalFormat = isFloat ? GL_R16F : GL_R8;
            format = GLenum(GL_RED);
        case 2:
            internalFormat = isFloat ? GL_RG16F : GL_RG8;
            format = GLenum(GL_RG);
        case 3:
            internalFormat = isFloat ? GL_RGB16F : GL_RGB8;
            format = GLenum(GL_RGB);
        case 4:
            internalFormat = isFloat ? GL_RGBA16F : GL_RGBA8;
            format = GLenum(GL_RGBA);
        default:
            internalFormat = isFloat ? GL_RGBA16F : GL_RGBA8;
            format = GLenum(GL_RGBA);
        }
        
        glBindTexture(textureTarget, textureID);
        
        if (GL_TEXTURE_CUBE_MAP == textureTarget)
        {
            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X + cubemapLayer), 0, internalFormat, width, height, 0, format, valueType, pixels);
            
        }
        else if(GL_TEXTURE_3D == textureTarget)
        {
            glTexImage3D(GLenum(GL_TEXTURE_3D), 0, internalFormat, width, height, depth, 0, format, valueType, pixels);
        }
        else
        {
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, internalFormat, width, height, 0, format, valueType, pixels);
        }
        
        if (withMipmap)
        {
            glGenerateMipmap(textureTarget);
        }
    }
}
