//
//  TextureHelper.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 25/05/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShaderInput.h"

@interface TextureHelper : NSObject

- (id) initWithType:(ShaderInputType)type vFlip:(bool)vFlip sRGB:(bool)sRGB wrapMode:(ShaderInputWrapMode)wrapMode filterMode:(ShaderInputFilterMode)filterMode;

- (void) loadFromFile:(NSString *)file;
- (void) loadFromURL:(NSString *)url;
- (void) loadData:(unsigned char *)data width:(int)width height:(int)height depth:(int)depth channels:(int)channels isFloat:(BOOL)isFloat cubemapLayer:(int)layer;
- (void) loadData:(unsigned char *)data width:(int)width height:(int)height depth:(int)depth channels:(int)channels isFloat:(BOOL)isFloat;
- (void) createEmpty:(int)width height:(int)height;
    
- (void) update;
- (void) bindToChannel:(int)channel;

- (float) getWidth;
- (float) getHeight;
- (float) getDepth;

+ (int) getMipLevels:(int)width height:(int)height;
+ (void) setGLTexParameters:(GLuint)target type:(ShaderInputType)type wrapMode:(ShaderInputWrapMode)wrapMode filterMode:(ShaderInputFilterMode)filterMode;

- (ShaderInputType) getType;
- (ShaderInputFilterMode) getFilterMode;
- (GLuint) getTexId;
    
@end
