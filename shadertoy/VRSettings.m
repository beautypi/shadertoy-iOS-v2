//
//  VRSettings.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/09/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import "VRSettings.h"
#import "Utils.h"

@implementation VRSettings
@synthesize renderMode, inputMode;


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
    
    if( inputMode == VR_INPUT_DEVICE  || inputMode == VR_INPUT_ARKIT ) {
        fragmentShaderCode = [fragmentShaderCode stringByAppendingString:@"#define VR_SETTINGS_DEVICE_ORIENTATION 1\n\n"];
    }
    
    fragmentShaderCode = [fragmentShaderCode stringByAppendingString:@"\n\n"];
    
    fragmentShaderCode = [fragmentShaderCode stringByAppendingString:[[NSString alloc] readFromFile:@"/shaders/fragment_main_vr" ofType:@"glsl"]];
    
    return fragmentShaderCode;
}

@end
