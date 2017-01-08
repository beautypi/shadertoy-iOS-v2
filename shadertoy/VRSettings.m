//
//  VRSettings.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/09/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import "VRSettings.h"
#import "Utils.h"
#import <CoreMotion/CoreMotion.h>

@interface VRSettings() {
    GLKMatrix3 deviceRotationMatrix;
    bool inputActive;
}
@end;

@implementation VRSettings

@synthesize renderMode, inputMode;

- (id)init {
    self = [super init];
    if(self){
        self.inputActive = true;
    }
    return self;
}

+ (CMMotionManager*)sharedMotionManager{
    
    static CMMotionManager *_sharedMotionManagerInstance;
    if(!_sharedMotionManagerInstance) {
        static dispatch_once_t oncePredicate;
        dispatch_once(&oncePredicate, ^{
            _sharedMotionManagerInstance = [[CMMotionManager alloc] init];
            if (_sharedMotionManagerInstance.deviceMotionAvailable) {
                _sharedMotionManagerInstance.deviceMotionUpdateInterval = 1.0/60.0;
                [_sharedMotionManagerInstance startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
//                [_sharedMotionManagerInstance startDeviceMotionUpdates];
            }
        });
    }
    
    return _sharedMotionManagerInstance;
}

-(NSString *) getVertexShaderCode {
    NSString *vertexShaderCode = [[NSString alloc] readFromFile:@"/shaders/vertex_main" ofType:@"glsl"];
    return vertexShaderCode;
}

-(NSString *) getFragmentShaderCode {
    NSString *fragmentShaderCode = @"\n\n";
    
    switch (renderMode) {
        case VR_CYAN_RED:            
            fragmentShaderCode = [fragmentShaderCode stringByAppendingString:@"#define VR_SETTINGS_RED_CYAN 1\n\n"];
            break;
        case VR_SPLIT_SCREEN:
            fragmentShaderCode = [fragmentShaderCode stringByAppendingString:@"#define VR_SETTINGS_CARDBOARD 1\n\n"];
            break;
        case VR_CROSS_EYE:
            fragmentShaderCode = [fragmentShaderCode stringByAppendingString:@"#define VR_SETTINGS_CROSS_EYE 1\n\n"];
            break;
        default:
        case VR_FULL_SCREEN:
            fragmentShaderCode = [fragmentShaderCode stringByAppendingString:@"#define VR_SETTINGS_FULLSCREEN 1\n\n"];
            break;
    }
    
    if( inputMode == VR_INPUT_DEVICE ) {
        fragmentShaderCode = [fragmentShaderCode stringByAppendingString:@"#define VR_SETTINGS_DEVICE_ORIENTATION 1\n\n"];        
    }
    
    fragmentShaderCode = [fragmentShaderCode stringByAppendingString:@"\n\n"];
    
    fragmentShaderCode = [fragmentShaderCode stringByAppendingString:[[NSString alloc] readFromFile:@"/shaders/fragment_main_vr" ofType:@"glsl"]];
    
    return fragmentShaderCode;
}

-(GLKVector3) getDeviceRotation {
   
   CMAttitude * attitude = [[[VRSettings sharedMotionManager] deviceMotion] attitude];
    
    return GLKVector3Make(attitude.pitch, attitude.yaw, attitude.roll);
}


-(GLKMatrix3) getDeviceRotationMatrix {
    if(!inputActive) {
        return deviceRotationMatrix;
    }
    
    CMRotationMatrix m = [[[[VRSettings sharedMotionManager] deviceMotion] attitude] rotationMatrix];
    GLKMatrix3 glkm = GLKMatrix3Make(m.m11, m.m12, m.m13, m.m21, m.m22, m.m23, m.m31, m.m32, m.m33 );
    
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

-(void) setInputActive:(bool)active {
    inputActive = active;
}
@end
