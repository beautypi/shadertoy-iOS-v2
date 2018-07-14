//
//  VRManager.m
//  Shadertoy
//
//  Created by Reinder Nijhoff on 30/09/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import "VRManager.h"
#import "Utils.h"
#import <CoreMotion/CoreMotion.h>
#import <ARKit/ARKit.h>

@implementation VRManager
static GLKMatrix3 deviceRotationMatrix;
static GLKVector3 devicePosition;
static bool inputActive;
static bool arKitPaused;

- (id)init {
    self = [super init];
    if(self){
        inputActive = true;
    }
    return self;
}

+ (CMMotionManager*)sharedMotionManager {
    static CMMotionManager *_sharedMotionManagerInstance;
    if(!_sharedMotionManagerInstance) {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            _sharedMotionManagerInstance = [[CMMotionManager alloc] init];
            if (_sharedMotionManagerInstance.deviceMotionAvailable) {
                _sharedMotionManagerInstance.deviceMotionUpdateInterval = 1.0/60.0;
                [_sharedMotionManagerInstance startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
            }
        });
    }
    
    return _sharedMotionManagerInstance;
}

+ (id)sharedARSession {
    if (@available(iOS 11.0, *)) {
        static ARSession *_sharedARSessionInstance;
        if( [ARWorldTrackingConfiguration isSupported] ) {
            if(!_sharedARSessionInstance) {
                static dispatch_once_t oncePredicate;
                dispatch_once(&oncePredicate, ^{
                    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
                    _sharedARSessionInstance = [[ARSession alloc] init];
                    [_sharedARSessionInstance runWithConfiguration:configuration];
                    arKitPaused = NO;
                });
            }
        }
        if(_sharedARSessionInstance && arKitPaused) {
            ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
            
            [_sharedARSessionInstance runWithConfiguration:configuration options:ARSessionRunOptionResetTracking];
            arKitPaused = NO;
        }
        
        return _sharedARSessionInstance;
    } else {
        return NULL;
    }
}

+(BOOL) isARKitSupported {
    if (@available(iOS 11.0, *)) {
        if( [ARWorldTrackingConfiguration isSupported] ) {
            return true;
        }
    }
    return false;
}

+(BOOL) isCameraTextureSupported {
    return [VRManager isARKitSupported];
}

+(CVPixelBufferRef) capturedImage {
    if(@available(iOS 11.0, *) ) {
        if( [VRManager sharedARSession] ) {
            ARSession * session = (ARSession *)[VRManager sharedARSession];
            
            return [[session currentFrame] capturedImage];
        }
    }
    return NULL;
}

+(GLKVector3) getDevicePosition:(VRSettings *)settings {
    if(!inputActive) {
        return devicePosition;
    }
    
    if(settings.inputMode == VR_INPUT_ARKIT) {
        if(@available(iOS 11.0, *) ) {
            if( [VRManager sharedARSession] ) {
                ARSession * session = (ARSession *)[VRManager sharedARSession];
                matrix_float4x4 mat = [[session currentFrame] camera].transform;
                
                devicePosition.x = mat.columns[3][0];
                devicePosition.y = mat.columns[3][1];
                devicePosition.z = mat.columns[3][2];
            }
        }
    } else {
        devicePosition = GLKVector3Make(0.0f, 0.0f, 0.0f);
    }
    return devicePosition;
}

+(GLKMatrix3) getDeviceRotationMatrix:(VRSettings *)settings {
    if(!inputActive) {
        return deviceRotationMatrix;
    }
    
    GLKMatrix3 glkm = GLKMatrix3Identity;
    BOOL arKitUsed = NO;
    
    if(settings.inputMode == VR_INPUT_ARKIT) {
        if(@available(iOS 11.0, *) ) {
            ARSession * session = (ARSession *)[VRManager sharedARSession];
            if( session ) {
                
                matrix_float4x4 mat = [[session currentFrame] camera].transform;
                
                glkm = GLKMatrix3Make(mat.columns[0][0], mat.columns[0][1], mat.columns[0][2],
                                      mat.columns[1][0], mat.columns[1][1], mat.columns[1][2],
                                      mat.columns[2][0], mat.columns[2][1], mat.columns[2][2]);
                
                glkm = GLKMatrix3Multiply( GLKMatrix3Multiply( GLKMatrix3Make(-1,0,0,    0,0,-1,    0,1,0 ), glkm ),  GLKMatrix3Make(0,-1,0,    1,0,0,    0,0,-1 ) );
                
                deviceRotationMatrix = glkm;
                arKitUsed = YES;
            }
        }
    }
    
    if( !arKitUsed ) {
        CMRotationMatrix m = [[[[VRManager sharedMotionManager] deviceMotion] attitude] rotationMatrix];
        glkm = GLKMatrix3Make(m.m11, m.m12, m.m13, m.m21, m.m22, m.m23, m.m31, m.m32, m.m33 );
        devicePosition = GLKVector3Make(0.0f, 0.0f, 0.0f);
    }
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(orientation == UIInterfaceOrientationPortrait) {
        deviceRotationMatrix = GLKMatrix3Multiply( GLKMatrix3Multiply( GLKMatrix3Make(1,0,0,    0,0,-1,    0,1,0 ), glkm ),  GLKMatrix3Make(0,1,0,    -1,0,0,    0,0,1 ) );
    }
    else if(orientation == UIInterfaceOrientationLandscapeLeft) {
        deviceRotationMatrix = GLKMatrix3Multiply( GLKMatrix3Multiply( GLKMatrix3Make(1,0,0,    0,0,-1,    0,1,0 ), glkm ),  GLKMatrix3Make(-1,0,0,    0,-1,0,    0,0,1 ) );
    }
    else if(orientation == UIInterfaceOrientationLandscapeRight) {
        deviceRotationMatrix = GLKMatrix3Multiply( GLKMatrix3Make(1,0,0,    0,0,-1,    0,1,0 ), glkm );
    } else {
        deviceRotationMatrix = GLKMatrix3Multiply( GLKMatrix3Make(1,0,0,    0,0,-1,    0,1,0 ), glkm );
    }
    
    return deviceRotationMatrix;
}

+(void) setInputActive:(bool)active {
    inputActive = active;
    [self deActivate];
}

+(void) deActivate {
    if(@available(iOS 11.0, *) ) {
        ARSession * session = (ARSession *)[VRManager sharedARSession];
        if( session ) {
            [session pause];
            session = NULL;
        }
        arKitPaused = YES;
    }
}

@end
