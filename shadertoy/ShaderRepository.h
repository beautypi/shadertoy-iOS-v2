//
//  ShaderRepository.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShaderObject.h"

@interface ShaderRepository : NSObject

- (ShaderObject *) getShader:(NSString *)shaderId success:(void (^)(ShaderObject *shader))success;

@end
