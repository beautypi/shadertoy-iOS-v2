//
//  ShaderToySoundPass.swift
//  ShaMderToy
//
//  Created by Dom Chiu on 2021/9/12.
//

#if os(macOS)
import GLKit
#elseif os(iOS)
import OpenGLES
#endif //#if os(macOS)

class STSoundPass: STProcessor {
    override func process(timestamp: Float, frameCount: Int, width: GLint, height: GLint) -> Bool {
        super.process(timestamp: timestamp, frameCount: frameCount, width: width, height: height);
        return true;
    }
    
    required init(_ shaderPassModel: APIShaderPass, _ commonPassModel: APIShaderPass?) {
        soundPass = shaderPassModel;
        super.init();
    }
    
    override var hash: Int {
        get {
            return soundPass.hash;
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? STSoundPass
        {
            return other.soundPass.name == self.soundPass.name;
        }
        return false;
    }
    
    private let soundPass: APIShaderPass
}
