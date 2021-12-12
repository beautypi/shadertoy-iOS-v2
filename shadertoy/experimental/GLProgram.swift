//
//  GLProgram.swift
//  MetalPlayground
//
//  Created by Qiu Dong on 2021/6/20.
//  Copyright © 2021 Dom Chiu. All rights reserved.
//

#if os(macOS)
import OpenGL
import GLKit
#elseif os(iOS)
import OpenGLES
#endif

class GLProgram {
    deinit {
//        print("#List#Cache#Leak# GLProgram.deinit (\(_program.hashValue))");
        glDeleteProgram(_program);
        _program = 0;
    }
    
    init(_ vertexShaderSources: [String], _ fragmentShaderSources: [String]) throws {
        _program = try GLProgram.compileAndLinkShaderProgram(vertexShaderSources, fragmentShaderSources);
//        print("#List#Cache#Leak# GLProgram.init (\(_program.hashValue))");
    }
    
    private var _program: GLuint = 0
    var program: GLuint {
        get { return _program; }
    }
    
    func use() {
        glUseProgram(_program);
    }
    
    static func compileShader(_ shaderSources: [String], type: GLenum) throws -> GLuint {
        CHECK_GL_ERROR();
        let shader = glCreateShader(type);
        CHECK_GL_ERROR();
        var shaderSource: String = "";
        for str in shaderSources
        {
            shaderSource.append(str);
            shaderSource.append("\n");
        }
        shaderSource.withCString { (ptr: UnsafePointer<Int8>) in
            var shaderCStringPointer: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(ptr);
            glShaderSource(shader, GLsizei(1), &shaderCStringPointer, nil);
            CHECK_GL_ERROR();
        };
//        let shaderCString = UnsafeMutablePointer<UInt8>.allocate(capacity: shaderSource.count + 1);
//        var index = 0;
//        for characterValue in shaderSource.utf8
//        {
//            shaderCString[index] = characterValue;
//            index = index + 1;
//        }
//        shaderCString[index] = 0; // Have to add a null termination
//        shaderCString.withMemoryRebound(to: Int8.self, capacity: index+1) { (ptr: UnsafeMutablePointer<Int8>) in
//            var immutablePtr: UnsafePointer<Int8>? = UnsafePointer<Int8>(ptr);
//            glShaderSource(shader, 1, &immutablePtr, nil);
//            CHECK_GL_ERROR();
//        };
        
        glCompileShader(shader);
        CHECK_GL_ERROR();
        var compileSuccess: GLint = 0;
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compileSuccess);
        if (compileSuccess != GL_TRUE)
        {
            let bufsize: GLsizei = 1024;
            var messageBytes: [GLchar] = [GLchar](repeating: 0, count: Int(bufsize));
            var messageLength: GLsizei = 0;
            try messageBytes.withUnsafeMutableBufferPointer { (buffer: inout UnsafeMutableBufferPointer<GLchar>) in
                glGetShaderInfoLog(shader, bufsize, &messageLength, buffer.baseAddress);
                let messageStr = String(cString: buffer.baseAddress!);
                print("#GLProgram# compileShader of type \(type) failed: \(messageStr). messageLength=\(messageLength)");
                glDeleteShader(shader);
                throw GLError.CompileError(type, messageStr);
            };
        }
        
        return shader;
    }

    static func compileAndLinkShaderProgram(_ vertexSources: [String], _ fragmentSources: [String]) throws -> GLuint {
        let vertexShader: GLuint = try compileShader(vertexSources, type: GLenum(GL_VERTEX_SHADER));
        let fragmentShader: GLuint = try compileShader(fragmentSources, type: GLenum(GL_FRAGMENT_SHADER));
        
        let program = glCreateProgram();
        glAttachShader(program, vertexShader);
        glAttachShader(program, fragmentShader);
        glLinkProgram(program);
        
        var linkSuccess: GLint = 0;
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linkSuccess);
        if (linkSuccess != GL_TRUE)
        {
            let bufsize: GLsizei = 1024;
            var messageBytes: [GLchar] = [GLchar](repeating: 0, count: Int(bufsize));
            var messageLength: GLsizei = 0;
            try messageBytes.withUnsafeMutableBufferPointer { (buffer: inout UnsafeMutableBufferPointer<GLchar>) in
                glGetProgramInfoLog(program, bufsize, &messageLength, buffer.baseAddress);
                let messageStr = String(cString: buffer.baseAddress!);
                print("#GLProgram# compileAndLinkShaderProgram failed: \(messageStr). messageLength=\(messageLength)");
                glDetachShader(program, vertexShader);
                glDetachShader(program, fragmentShader);
                glDeleteShader(vertexShader);
                glDeleteShader(fragmentShader);
                throw GLError.LinkError(messageStr);
            };
        }
        
        glDetachShader(program, vertexShader);
        glDeleteShader(vertexShader);
        glDetachShader(program, fragmentShader);
        glDeleteShader(fragmentShader);
        
        return program;
    }
    
    @discardableResult
    func bindUniformSlot(_ name: String, _ key: Int) -> GLint {
        let slotPtr = UnsafeMutablePointer<GLint>.allocate(capacity: 1);
        name.withCString { (cstr: UnsafePointer<Int8>) in
            let uniformIndex: GLint = glGetUniformLocation(_program, cstr);
            slotPtr.assign(repeating: GLint(uniformIndex), count: 1);
            CHECK_GL_ERROR();
//            print("#ShaderToy# \(name) = \(uniformIndex)");
        };
        let slot = slotPtr.pointee;
        slotPtr.deallocate();
        _slotOfKeys[key] = slot;
        _slotOfNames[name] = slot;
        return slot;
    }
    
    @discardableResult
    func bindVertexAttributeSlot(_ name: String, _ key: Int) -> GLint {
        let slotPtr = UnsafeMutablePointer<GLint>.allocate(capacity: 1);
        name.withCString { (cstr: UnsafePointer<Int8>) in
            let attrIndex: GLint = glGetAttribLocation(_program, cstr);
            slotPtr.assign(repeating: GLint(attrIndex), count: 1);
            CHECK_GL_ERROR();
//            print("#ShaderToy# \(name) = \(attrIndex)");
        };
        let slot = slotPtr.pointee;
        slotPtr.deallocate();
        _slotOfKeys[key] = slot;
        _slotOfNames[name] = slot;
        return slot;
    }
    
    func slot(of key: Int) -> GLint {
        if let s = _slotOfKeys[key]
        {
            return s;
        }
        return -1;
    }
    
    func slot(of name: String) -> GLint {
        if let s = _slotOfNames[name]
        {
            return s;
        }
        return -1;
    }
    
    private var _slotOfKeys: [Int:GLint] = [:];
    private var _slotOfNames: [String:GLint] = [:];
}
