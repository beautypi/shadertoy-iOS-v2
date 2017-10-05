//
//  VRManager.h
//  Shadertoy
//
//  Created by Reinder Nijhoff on 30/09/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "VRSettings.h"

@interface VRManager : NSObject

+(BOOL) isARKitSupported;
+(BOOL) isCameraTextureSupported;
    
+(GLKVector3) getDevicePosition:(VRSettings *)settings;
+(GLKMatrix3) getDeviceRotationMatrix:(VRSettings *)settings;
    
+(CVPixelBufferRef) capturedImage;
    
+(void) setInputActive:(bool)active;
+(void) deActivate;
    
@end
