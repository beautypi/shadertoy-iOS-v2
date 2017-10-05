//
//  VRSettings.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/09/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, VRSettingsRenderMode) {
    VR_FULL_SCREEN,
    VR_SPLIT_SCREEN,
    VR_CROSS_EYE,
    VR_CYAN_RED,
};
typedef NS_ENUM(NSUInteger, VRSettingsInput) {
    VR_INPUT_NONE,
    VR_INPUT_DEVICE,
    VR_INPUT_ARKIT,
    VR_INPUT_TOUCH
};
typedef NS_ENUM(NSUInteger, VRSettingsQuality) {
    VR_QUALITY_LOW,
    VR_QUALITY_NORMAL,
    VR_QUALITY_HIGH
};


@interface VRSettings : NSObject

@property (atomic) VRSettingsRenderMode renderMode;
@property (atomic) VRSettingsInput inputMode;
@property (atomic) VRSettingsQuality quality;

-(NSString *) getVertexShaderCode;
-(NSString *) getFragmentShaderCode;

@end
