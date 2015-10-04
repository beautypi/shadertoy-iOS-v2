//
//  Utils.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 31/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "APIShaderObject.h"

#ifndef shadertoy_Utils_h
#define shadertoy_Utils_h

void trackEvent( NSString *category, NSString *action, NSString *label );
void trackScreen( NSString *screen );

@interface UIImage (Utils)

- (UIImage *) setShaderWatermarkText:(APIShaderObject *)shader;
- (UIImage *) resizedImageWithMaximumSize: (CGSize) size;

@end


@interface NSString (Utils)

- (NSString *) readFromFile:(NSString *)fileName ofType:(NSString *)type;

@end

#endif
