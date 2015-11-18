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

@synthesize renderMode, rightEyeParams, leftEyeParams, inputMode, positionState;

- (id)init {
    self = [super init];
    if(self){
    }
    return self;
}

-(NSString *) getVertexShaderCode {
    NSString *vertexShaderCode = [[NSString alloc] readFromFile:@"/shaders/vertex_main" ofType:@"glsl"];
    return vertexShaderCode;
}

-(NSString *) getFragmentShaderCode {
    NSString *fragmentShaderCode = [[NSString alloc] readFromFile:@"/shaders/fragment_main_vr" ofType:@"glsl"];
    return fragmentShaderCode;
}



@end
