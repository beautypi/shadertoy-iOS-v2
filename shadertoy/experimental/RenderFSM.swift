//
//  RenderLooper.swift
//  MetalPlayground
//
//  Created by Qiu Dong on 2021/6/2.
//  Copyright © 2021 Dom Chiu. All rights reserved.
//

import Foundation

/**
 * NotInitialized -> initializing -- 'onCreate' -> Ready
 * Ready -> starting -- 'onResume' -> Run
 * Run -> pausing -- ‘onPause' -> Ready
 * Ready > releasing -> 'onRelease' -> NotInitialized
 * Run > releasing -> 'onRelease' -> NotInitialized
 */
class RenderFSM {
    enum State {
        case NotInitialized
        case Initializing
        case Ready
        case Starting
        case Run
        case Pausing
        case Releasing
    }

    @discardableResult
    func transitState(newState: State) -> Bool {
        _cond.lock();
//        print("#RenderLoop#FSM# Going to change state from \(_state) to \(newState)");
        defer { _cond.unlock(); }

        switch (newState)
        {
        case .Initializing:
            if (_state != .NotInitialized)
            {
                return false;
            }
        case .Starting:
            if (_state != .Ready)
            {
                return false;
            }
        case .Run:
            if (_state != .Starting)
            {
                return false;
            }
        case .Pausing:
            if (_state != .Run)
            {
                return false;
            }
        case .Ready:
            if (_state != .Initializing && _state != .Pausing)
            {
                return false;
            }
        case .Releasing:
            if (_state != .Ready && _state != .Run)
            {
                return false;
            }
        case .NotInitialized:
            if (_state != .Releasing)
            {
                return false;
            }
        }
//        print("#RenderLoop#FSM# State change success");
        _state = newState;
        _cond.broadcast();
        return true;
    }
    
    func waitForState(state: State, breakForAnyChange: Bool = false) -> Void {
        _cond.lock();
        defer { _cond.unlock(); }
        let prevState = _state;
        // Break if: (break & _state != prevState) || (_state == state)
        while ((_state != state) && (!breakForAnyChange || _state == prevState))
        {
            _cond.wait();
        }
    }
    
    @discardableResult
    func waitForState(state: State, until limit: Date) -> Bool {
        _cond.lock();
        defer { _cond.unlock(); }
        var result: Bool = false;
        while (_state != state)
        {
            result = _cond.wait(until: limit);
        }
        return result;
    }
    
    required init() {
        _state = .NotInitialized;
        _cond = NSCondition();
    }
    
    public var state: State {
        get { return _state; }
    }

    private var _state: State = .NotInitialized
    
    private var _cond: NSCondition
}
