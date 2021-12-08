//
//  ShaderToyProcessor.swift
//  ShaMderToy
//
//  Created by qiudong on 2021/8/18.
//

protocol STProcessorProtocol: Hashable {
    var targetTexture: GLuint { get }
    var resolution: MTLSize { get }
    var time: TimeInterval { get }
    
    @discardableResult
    func process(timestamp: Float, frameCount: Int, width: GLint, height: GLint) -> Bool
}

class STProcessor: NSObject, STProcessorProtocol {
    var targetTexture: GLuint {
        get { return 0; }
    }
    
    var resolution: MTLSize {
        get { return MTLSize(width: 0, height: 0, depth: 0); }
    }

    var time: TimeInterval {
        get { return TimeInterval(_timestamp); }
    }
    
    @discardableResult
    func process(timestamp: Float, frameCount: Int, width: GLint, height: GLint) -> Bool {
        _timestamp = timestamp;
        return false;
    }
    
    private var _timestamp: Float = 0.0
}
