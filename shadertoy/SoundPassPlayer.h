//
//  SoudPassPlayer.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 31/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SoundPassPlayer : NSObject

- (void) fillSoundBufferFromImage:(UIImage *)image block:(NSInteger)block;
- (void) prepareToPlay;
- (void) play;

@end
