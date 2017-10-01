//
//  CameraTextureHelper.h
//  Shadertoy
//
//  Created by Reinder Nijhoff on 30/09/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CameraTextureHelper : NSObject

+(BOOL) isSupported;
  
-(void) update;
-(void) bindToChannel:(int)channel;
    
@end
