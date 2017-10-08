//
//  SoundStreamHelper.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 03/09/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShaderInput.h"

@interface SoundStreamHelper : NSObject

- (id) initWithShaderInput:(ShaderInput *) shaderInput;

- (void) playUrl:(NSString*) url;

- (void) pause;
- (void) play;
- (void) rewindTo:(double)time;
- (float) getTime;

- (void) updateSpectrum:(unsigned char *)data;

@end
