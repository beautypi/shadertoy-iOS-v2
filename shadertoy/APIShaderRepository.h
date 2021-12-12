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

+(_Nonnull instancetype) sharedRepo;

- (APIShaderObject *) getShader:(NSString *)shaderId success:(void (^)(APIShaderObject *shader))success;
- (void) invalidateShader:(NSString *)shaderId;

-(NSString* _Nullable ) loadFileFromURL:(NSString*)url completion:(void(^)(NSString*, NSError*, BOOL))completion;

@end
