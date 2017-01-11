//
//  ShaderSettings.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 24/07/16.
//  Copyright © 2016 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ShaderSettingsQuality) {
    SHADER_QUALITY_NORMAL,
    SHADER_QUALITY_HIGH
};

@interface ShaderSettings : NSObject

@property (atomic) ShaderSettingsQuality quality;

@end
