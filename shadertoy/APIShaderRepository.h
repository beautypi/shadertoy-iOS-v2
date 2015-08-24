//
//  ShaderRepository.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIShaderObject.h"

@interface APIShaderRepository : NSObject

- (APIShaderObject *) getShader:(NSString *)shaderId success:(void (^)(APIShaderObject *shader))success;
- (void) invalidateShader:(NSString *)shaderId;

@end
