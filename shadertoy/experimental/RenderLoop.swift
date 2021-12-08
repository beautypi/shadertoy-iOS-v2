//
//  RenderLoop.swift
//  MetalPlayground
//
//  Created by qiudong on 2021/6/6.
//  Copyright © 2021 Dom Chiu. All rights reserved.
//

import QuartzCore

protocol RenderLoopDelegate : AnyObject {
    func onCreate();
    
    func onResume();
    
    func onPause();
    
    func onDestroy();
    
    func onRender(_ renderLoop: RenderLoop);
}

extension RunLoop {
    @objc
    func callBlock(_ object: Any?) {
        if let block = object as? (() -> Void)
        {
            block();
        }
    }

    func runBlock(_ block: @escaping (() -> Void)) {
        if #available(iOS 10.0, *) {
            self.perform(block)
        } else {
            // Fallback on earlier versions
            self.perform(#selector(self.callBlock(_:)), target: self, argument: block, order: 0, modes: [.common]);
        };
    }
}

class RenderLoop : NSObject {
    var timestamp: CFTimeInterval
    {
        get
        {
            if let displayLink = _displayLink
            {
                if (_timeElapsedBase >= 0.0)
                {
                    if (_timestampStart >= 0.0)
                    {
                        #if os(iOS)
                        var now = displayLink.timestamp;
                        return _timeElapsedBase + now - _timestampStart;
                        #elseif os(macOS)
                        var now = CVTimeStamp();
                        CVDisplayLinkGetCurrentTime(displayLink, &now);
                        return _timeElapsedBase + Double(now.videoTime) / Double(now.videoTimeScale) - _timestampStart;
                        #endif
                    }
                    else
                    {
                        return _timeElapsedBase;
                    }
                }
            }
            return 0.0;
        }
    }
    
    var frameCount: Int
    {
        get { return _frameCount; }
    }
    private var _frameCount: Int = 0
    
    var fsm: RenderFSM {
        get { return _fsm; }
    }
    
    func onCreate() {
        guard let r = delegate else { return; }
        r.onCreate();
    }
    
    func onResume() {
        guard let r = delegate else { return; }
        r.onResume();
    }
    
    func onPause() {
        guard let r = delegate else { return; }
        r.onPause();
    }
    
    func onDestroy() {
        _timestampStart = -1.0;
        _timeElapsedBase = -1.0;
        guard let r = delegate else { return; }
        r.onDestroy();
    }
    #if os(macOS)
    @objc
    func onRender(_ displayLink: CVDisplayLink, _ timeStamp: CFTimeInterval) {
        if (_timeElapsedBase < 0.0)
        {
            _frameCount = 0;
            _timestampStart = timeStamp;
            _timeElapsedBase = 0.0;
        }
        else if (_timestampStart < 0.0)
        {
            _frameCount = 0;
            _timestampStart = timeStamp;
        }
        else
        {
            _frameCount += 1;
        }
        guard let r = delegate else { return; }
        r.onRender(self);
    }
    #elseif os(iOS)
    @objc
    func onRender(_ displayLink: CADisplayLink) {
        if (_timeElapsedBase < 0.0)
        {
            _frameCount = 0;
            _timestampStart = displayLink.timestamp;
            _timeElapsedBase = 0.0;
        }
        else if (_timestampStart < 0.0)
        {
            _frameCount = 0;
            _timestampStart = displayLink.timestamp;
        }
        else
        {
            _frameCount += 1;
        }
        guard let r = delegate else { return; }
        r.onRender(self);
    }
    #endif
    deinit {
//        print("#List#Cache#Leak# RenderLoop.deinit (\(self.hash))");
    }
    
    init(delegate: RenderLoopDelegate, runLoop: RunLoop, completionBlock: (() -> Void)? = nil) {
        self.delegate = delegate;
        _runLoop = runLoop;
        _fsm = RenderFSM();
        
        super.init();
        print("#List#Cache#Leak# RenderLoop.init (\(self.hash))");
        create(true, completionBlock: completionBlock);
    }

    func resetTimeStamp() {
        _timestampStart = -1;
        _timeElapsedBase = -1;
    }
    
    @objc
    func transitToReady(completionBlock: (() -> Void)? = nil) {
        self.onCreate();
        self._fsm.transitState(newState: .Ready);
        
        if let block = completionBlock
        {
            block();
        }
    }
    
    @objc
    func transitToRun(completionBlock: (() -> Void)? = nil) {
        self.onResume();
        self._fsm.transitState(newState: .Run);
        
        if let block = completionBlock
        {
            block();
        }
    }
    
    @objc
    func transitToNotInitialized(completionBlock: (() -> Void)? = nil) {
        self.onCreate();
        self._fsm.transitState(newState: .NotInitialized);
        
        if let block = completionBlock
        {
            block();
        }
    }
    
    func runAsync(_ block: @escaping () -> Void) {
        _runLoop.runBlock(block);
    }
    
    @discardableResult
    func create(_ wait: Bool = false, completionBlock: (() -> Void)? = nil) -> Bool {
        if (_fsm.transitState(newState: .Initializing))
        {
            if (nil == _displayLink)
            {
                #if os(macOS)
                let displayID = CGMainDisplayID();
                let result = CVDisplayLinkCreateWithCGDisplay(displayID, &_displayLink);
                if (result == kCVReturnSuccess)
                {
                    let wSelf = Unmanaged.passUnretained(self).toOpaque();
                    CVDisplayLinkSetOutputCallback(_displayLink!, { (displayLink: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, inFlags: CVOptionFlags, outFlags: UnsafeMutablePointer<CVOptionFlags>, context: UnsafeMutableRawPointer?) -> CVReturn in
                        let sSelf: RenderLoop = Unmanaged<RenderLoop>.fromOpaque(context!).takeUnretainedValue();
                        let timeStamp = Double(inOutputTime.pointee.videoTime) / Double(inOutputTime.pointee.videoTimeScale)
                        sSelf.perform({ (args: Any) in
                            sSelf.onRender(displayLink, timeStamp);
                        }, args: displayLink);
                        return kCVReturnSuccess;
                    }, wSelf);
                }
                #elseif os(iOS)
                runAsync {
                    self._displayLink = CADisplayLink(target: self, selector: #selector(self.onRender(_:)));
                    self._displayLink?.isPaused = true;
                    if #available(iOS 15.0, *)
                    {
                        ///!!!TO BE OPTIMIZED: self._displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30.0, maximum: 120.0, __preferred: 60.0);
                    }
                    else if #available(iOS 10.0, *)
                    {
                        self._displayLink?.preferredFramesPerSecond = 60;
                    }
                    else
                    {
                        self._displayLink?.frameInterval = 1;
                    }
                    let currentRL = RunLoop.current;
                    self._displayLink?.add(to: currentRL, forMode: .common);
                }
                #endif
            }

            runAsync {
                self.onCreate();
                self._fsm.transitState(newState: .Ready);
                
                if let block = completionBlock
                {
                    block();
                }
            }
            
            if (wait && _runLoop != RunLoop.current)
            {
                _fsm.waitForState(state: .Ready, breakForAnyChange: true);
            }
            
            return true;
        }
        return false;
    }
    
    @discardableResult
    func start(_ wait: Bool = false, completionBlock: (() -> Void)? = nil) -> Bool {
        if (_fsm.transitState(newState: .Starting))
        {
            #if os(macOS)
            CVDisplayLinkStart(_displayLink!);
            #elseif os(iOS)
            _displayLink?.isPaused = false;
            #endif

            runAsync {
                self.onResume();
                self._fsm.transitState(newState: .Run);
                
                if let block = completionBlock
                {
                    block();
                }
            }

            if (wait && _runLoop != RunLoop.current)
            {
                _fsm.waitForState(state: .Run, breakForAnyChange: true);
            }
            
            return true;
        }
        return false;
    }
    
    @discardableResult
    func pause(_ wait: Bool = false, completionBlock: (() -> Void)? = nil) -> Bool {
        if (_fsm.transitState(newState: .Pausing))
        {
            if let displayLink = _displayLink
            {
                #if os(macOS)
                CVDisplayLinkStop(_displayLink!);
                #elseif os(iOS)
                displayLink.isPaused = true;
                #endif
                if (_timeElapsedBase >= 0.0 && _timestampStart >= 0.0)
                {
                    #if os(macOS)
                    var timeStamp = CVTimeStamp();
                    CVDisplayLinkGetCurrentTime(displayLink, &timeStamp);
                    _timeElapsedBase += (Double(timeStamp.videoTime) / Double(timeStamp.videoTimeScale) - _timestampStart);
                    #elseif os(iOS)
                    _timeElapsedBase += (displayLink.timestamp - _timestampStart);
                    #endif
                    _timestampStart = -1.0;
                }
            }

            runAsync {
                self.onPause();
                self._fsm.transitState(newState: .Ready);
                
                if let block = completionBlock
                {
                    block();
                }
            }
            
            if (wait && _runLoop != RunLoop.current)
            {
                _fsm.waitForState(state: .Ready, breakForAnyChange: true);
            }
            
            return true;
        }
        return false;
    }
    
    @discardableResult
    func destroy(_ wait: Bool = false, completionBlock: (() -> Void)? = nil) -> Bool {
        if (_fsm.transitState(newState: .Releasing))
        {
            runAsync {
                self.onDestroy();
                self._fsm.transitState(newState: .NotInitialized);
                
                if let block = completionBlock
                {
                    block();
                }
                
                if let displayLink = self._displayLink
                {
                    #if os(iOS)
                    displayLink.remove(from: RunLoop.current, forMode: .common);
                    #endif
                    self._displayLink = nil;
                }
            }
            
            if (wait && _runLoop != RunLoop.current)
            {
                _fsm.waitForState(state: .NotInitialized, breakForAnyChange: true);
            }
            
            return true;
        }
        return false;
    }
    
    weak var delegate: RenderLoopDelegate?
    
    private let _fsm: RenderFSM
    
    private var _timeElapsedBase: CFTimeInterval = -1.0;
    private var _timestampStart: CFTimeInterval = -1.0;
#if os(macOS)
    private var _displayLink: CVDisplayLink?
#elseif os(iOS)
    private var _displayLink: CADisplayLink?
#endif
    private let _runLoop: RunLoop
    
    var runLoop: RunLoop {
        get {
            return _runLoop;
        }
    }

    class DemoRenderer : NSObject, RenderLoopDelegate {
        func onCreate() {
            print("#RenderLoop# Renderer.onCreate");
        }
        
        func onDestroy() {
            print("#RenderLoop# Renderer.onDestroy");
        }
        
        func onResume() {
            print("#RenderLoop# Renderer.onResume");
        }
        
        func onPause() {
            print("#RenderLoop# Renderer.onPause");
        }
        
        func onRender(_ renderLoop: RenderLoop) {
            print("#RenderLoop# Renderer.onRender, timestamp=\(renderLoop.timestamp)");
        }
        
        
    }
}
