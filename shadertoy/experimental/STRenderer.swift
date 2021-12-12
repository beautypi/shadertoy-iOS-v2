//
//  ShaderToyRenderer.swift
//  MetalPlayground
//
//  Created by Qiu Dong on 2021/6/20.
//  Copyright © 2021 Dom Chiu. All rights reserved.
//

#if os(macOS)
import GLKit
#elseif os(iOS)
import OpenGLES
#endif //#if os(macOS)

@objc
class STRenderer : NSObject, GLRenderer {
    func createGLObjectsIfNecessary() {
        if (_glInited) { return; }
        _glInited = true;
//        print("#List#Cache#Leak# ShaderToyRenderer.createGLObjectsIfNecessary : \((self as AnyObject).hash!)");
        preRender(timestamp: 0, frameCount: 0);
        
        var sourceOfID: [String:STProcessor] = [:];
        var passRenderers: [STProcessor:APIShaderPass] = [:];
        let collectNodes: (APIShaderPass?, APIShaderPass?) -> Void = { (p: APIShaderPass?, commonPass: APIShaderPass?) in
            guard let pass = p
            else
            {
                return;
            }
            let passRenderer = pass.type.intValue == STPassType.sound.rawValue ? STSoundPass(pass, commonPass) : STRenderPass(pass, commonPass);
            passRenderers[passRenderer] = pass;
            for o in pass.outputs
            {
                guard let output = o as? APIShaderPassOutput
                else
                {
                    continue;
                }
                if let ID = output.outputId
                {
                    if (nil == sourceOfID[ID])
                    {
                        sourceOfID[ID] = passRenderer;
                    }
                }
            }
            for i in pass.inputs
            {
                guard let input = i as? APIShaderPassInput
                else
                {
                    continue;
                }
                if (input.type.intValue != STInputType.buffer.rawValue)
                {
                    if let ID = input.inputId
                    {
                        if (nil == sourceOfID[ID])
                        {
                            let source = STInputSource(input);
                            sourceOfID[ID] = source;
                        }
                    }
                }
            }
        }
        for p in _shaderToy.bufferPasses
        {
            collectNodes(p as? APIShaderPass, _shaderToy.commonPass);
        }
        collectNodes(_shaderToy.imagePass, _shaderToy.commonPass);
        collectNodes(_shaderToy.soundPass, _shaderToy.commonPass);

        for (renderer, pass) in passRenderers
        {
            if (pass.inputs.count == 0)
            {
                _shaderDAG.getOrAddNode(renderer);
            }
            else
            {
                var hasNoInput = true;
                for i in pass.inputs
                {
                    guard let input = i as? APIShaderPassInput
                    else
                    {
                        continue;
                    }
                    guard let ID = input.inputId else { continue; }
                    if let source = sourceOfID[ID]
                    {
                        hasNoInput = false;
                        let channel = input.channel.intValue;
                        _shaderDAG.linkNode(from: source, to: renderer, with: channel);
                        
                        if let shaderPass: STRenderPass = renderer as? STRenderPass
                        {
                            shaderPass.setInputTexture(for: channel, with: source.targetTexture);
                            shaderPass.setInputResolution(for: channel, with: source.resolution);
                            shaderPass.setInputTime(for: channel, with: source.time);
                        }
                    }
                    else
                    {
                        print("This Buffer renderer does not have input source");
                    }
                }
                if (hasNoInput)
                {
                    _shaderDAG.getOrAddNode(renderer);
                }
            }
        }
        _shaderDAGActor = _shaderDAG.getGraphActor();
        RUN_ON_GL_ERROR {
//            AppDelegate.recordErrorShader(self.shaderID);
        }
    }
    
    func releaseGLObjectsIfNecessary() {
        if (!_glInited) { return; }
        _glInited = false;
//        print("#List#Cache#Leak# ShaderToyRenderer.releaseGLObjectsIfNecessary : \((self as AnyObject).hash!)");
    }
    
    func didResumeRendering() {
//        print("#ST#Reuse# didResumeRendering by \((self as AnyObject).hash!)");
    }
    
    func willPauseRendering() {
//        print("#ST#Reuse# willPauseRendering by \((self as AnyObject).hash!)");
    }
    
    
    
    func preRender(timestamp: Float, frameCount: Int) {
//        print("#Crash# ShaderToyRenderer.preRender() of \(_shaderToy.shaderId)");
    }
    
    func postRender(timestamp: Float, frameCount: Int) {
//        print("#Crash# ShaderToyRenderer.postRender() of \(_shaderToy.shaderId!)");
//        AppDelegate.endTestingShader(shaderID);
    }

    func render(timestamp: Float, frameCount: Int) {
//#if os(iOS)
//        let glContext = CVEAGLContext.current();
//        print("#ST#Reuse# render by \((self as AnyObject).hash!) in context{\(glContext!.hash)}");
//#endif //#if os(iOS)
        var w, h: GLint;
        var viewport = [GLint](repeating: 0, count: 4);
        viewport.withUnsafeMutableBufferPointer { (p: inout UnsafeMutableBufferPointer<GLint>) in
            glGetIntegerv(GLenum(GL_VIEWPORT), p.baseAddress);
        }
        w = viewport[2];
        h = viewport[3];
//        let viewport = UnsafeMutablePointer<GLint>.allocate(capacity: MemoryLayout<GLint>.stride * 4);
//        glGetIntegerv(GLenum(GL_VIEWPORT), viewport);
//        let w = viewport.advanced(by: 2).pointee;
//        let h = viewport.advanced(by: 3).pointee;

//        TimeProfilerBeginFunction(nil, 0);
        
        if let actor = _shaderDAGActor
        {
            actor.beginAction( { (node, actor) in
                node.enumerateInDeterminedDependencies { (source: STProcessor, channel: Int) in
                    let shaderProcessor = node.item as STProcessor
                    if let soundPass: STSoundPass = shaderProcessor as? STSoundPass
                    {
                        
                    }
                    else if let shaderPass: STRenderPass = shaderProcessor as? STRenderPass
                    {
                        shaderPass.setInputTexture(for: channel, with: source.targetTexture);
                        shaderPass.setInputResolution(for: channel, with: source.resolution);
                        shaderPass.setInputTime(for: channel, with: source.time);
                    }
                }
                if (node.item.process(timestamp: timestamp, frameCount: frameCount, width: w, height: h))
                {
                    actor.finishNode(node.item);
                }
                else if (!self._errorNotified)
                {
                    ///!!!NotificationCenter.default.post(name: NSNotification.Name(Self.ShaderToyErrorNotification), object: self.shaderID);
                    self._errorNotified = true;
                }
            });
        }

//        TimeProfilerEndFunction(nil);
//        TimeProfilerAddFPSCheckPoint(nil, 0);
//        let timeProfilerResult = TimeProfilerGetResult(nil, 0);
//        let fps = TimeProfilerGetFPS(nil, 0);
//        print("#TimeProfile# ShaderToyRenderer.render: FPS=\(fps), frameTime=\(timeProfilerResult.elapsedSeconds) / \(timeProfilerResult.frameCounter) = \(timeProfilerResult.elapsedSeconds / Double(timeProfilerResult.frameCounter))");
        RUN_ON_GL_ERROR {
//            AppDelegate.recordErrorShader(self.shaderID);
        }
    }
    
    var shaderID: String {
        get {
            return _shaderToy.shaderId;
        }
    }
    
    var shaderName: String {
        get {
            return _shaderToy.shaderName;
        }
    }
    
    deinit {
//        print("#List#Cache#Leak# ShaderToyRenderer.deinit : \((self as AnyObject).hash!)");
        releaseGLObjectsIfNecessary();
    }

    @objc
    required init(_ shaderToy: APIShaderObject) {
        _shaderToy = shaderToy;
        _shaderDAG = BaseDAG<STProcessor>(nil);
//        print("#List#Cache#Leak# ShaderToyRenderer.init : \((self as AnyObject).hash!)");
    }
    
    private var _glInited: Bool = false
    
    private var _shaderToy: APIShaderObject
    
    private var _shaderDAG: BaseDAG<STProcessor>
    private var _shaderDAGActor: BaseDAG<STProcessor>.Actor? = nil
    
    private var _errorNotified: Bool = false
}
