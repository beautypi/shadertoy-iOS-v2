//
//  VRSettings.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/09/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, VRSettingsRenderMode) {
    VR_FULL_SCREEN,
    VR_SPLIT_SCREEN,
    VR_CROSS_EYE,
    VR_CYAN_RED,
};
typedef NS_ENUM(NSUInteger, VRSettingsInput) {
    VR_INPUT_NONE,
    VR_INPUT_DEVICE,
    VR_INPUT_TOUCH
};

@interface VRFieldOfViewInit : NSObject

@property (atomic) float upDegrees;
@property (atomic) float rightDegrees;
@property (atomic) float downDegrees;
@property (atomic) float leftDegrees;

@end



@interface VREyeParameters : NSObject {
@public
    float eyeTranslation[3];
}

@property (nonatomic, strong) VRFieldOfViewInit *currentFieldOfView;
@property (atomic) CGRect renderRect;

@end



@interface VRPositionState : NSObject {
@public
    float orientation[4];
}

-(void) setRotation:(float)roll pitch:(float)pitch yaw:(float)yaw;
-(void) updateRotationFromDeviceMotion;

@end



@interface VRSettings : NSObject

@property (nonatomic, strong) VREyeParameters *leftEyeParams;
@property (nonatomic, strong) VREyeParameters *rightEyeParams;
@property (nonatomic, strong) VRPositionState *positionState;
@property (atomic) VRSettingsRenderMode renderMode;
@property (atomic) VRSettingsInput inputMode;

@end
