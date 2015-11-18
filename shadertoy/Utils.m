//
//  Utils.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 31/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "Utils.h"

#import <GoogleAnalytics/GAI.h>
#import <GoogleAnalytics/GAIFields.h>
#import <GoogleAnalytics/GAIDictionaryBuilder.h>

void trackEvent( NSString *category, NSString *action, NSString *label ) {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category    // Event category (required)
                                                          action:action
                                                           label:label           // Event label
                                                           value:nil] build]];   // Event value
}

void trackScreen( NSString *screen ) {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screen];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

@implementation UIImage (Utils)

- (UIImage *) setShaderWatermarkText:(APIShaderObject *)shader {
    NSString *text = [@"\"" stringByAppendingString:[[shader.shaderName stringByAppendingString:@"\" by "] stringByAppendingString:shader.username]];
    
    CGSize imageSize = self.size;
    
    BOOL large = NO;
    
    if( imageSize.height > 1024.f ) {
        large = YES;
    }
    
    UIColor *textColor = [UIColor colorWithWhite:1.0 alpha:large?.95f:1.f];
    UIFont *font = [UIFont systemFontOfSize:imageSize.height * (large?0.029f:0.045f)];
    NSDictionary *attr = @{NSForegroundColorAttributeName: textColor, NSFontAttributeName: font};
    
    // Create the image
    UIGraphicsBeginImageContext(imageSize);
    [self drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0.0f, 0.0f), imageSize.height * 0.003, [UIColor colorWithWhite:0. alpha:.9].CGColor);
    if( large ) {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:shader.date];
        text = [[text stringByAppendingString:@", "] stringByAppendingString:[NSString stringWithFormat:@"%ld",(long)[components year]]];
        
        [self drawTextInCurrentContext:text attr:attr paddingX:imageSize.height * 0.01 paddingY:imageSize.height * 0.029];
        
        font = [UIFont systemFontOfSize:imageSize.height * 0.015];
        text = [[shader getShaderUrl] absoluteString];
        NSDictionary *attr2 = @{NSForegroundColorAttributeName: textColor, NSFontAttributeName: font};
        [self drawTextInCurrentContext:text attr:attr2 paddingX:imageSize.height * 0.01 paddingY:imageSize.height * 0.01];
    } else {
        [self drawTextInCurrentContext:text attr:attr paddingX:imageSize.height * 0.01 paddingY:imageSize.height * 0.01];
    }
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

- (void) drawTextInCurrentContext:(NSString *)text attr:(NSDictionary *)attr paddingX:(int)paddingX paddingY:(int)paddingY {
    CGSize textSize = [text sizeWithAttributes:attr];
    CGRect textRect = CGRectMake(self.size.width - textSize.width - paddingX, self.size.height - textSize.height - paddingY, textSize.width, textSize.height);
    [text drawInRect:CGRectIntegral(textRect) withAttributes:attr];
}

- (UIImage *) resizedImageWithMaximumSize: (CGSize) size {
    CGImageRef imgRef = [self CGImageWithCorrectOrientation];
    CGFloat original_width  = CGImageGetWidth(imgRef);
    CGFloat original_height = CGImageGetHeight(imgRef);
    CGFloat width_ratio = size.width / original_width;
    CGFloat height_ratio = size.height / original_height;
    CGFloat scale_ratio = width_ratio < height_ratio ? width_ratio : height_ratio;
    CGImageRelease(imgRef);
    return [self drawImageInBounds: CGRectMake(0, 0, round(original_width * scale_ratio), round(original_height * scale_ratio))];
}

- (UIImage *) drawImageInBounds: (CGRect) bounds {
    UIGraphicsBeginImageContext(bounds.size);
    [self drawInRect: bounds];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (CGImageRef) CGImageWithCorrectOrientation {
    if (self.imageOrientation == UIImageOrientationDown) {
        //retaining because caller expects to own the reference
        CGImageRetain([self CGImage]);
        return [self CGImage];
    }
    UIGraphicsBeginImageContext(self.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.imageOrientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, 90 * M_PI/180);
    } else if (self.imageOrientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, -90 * M_PI/180);
    } else if (self.imageOrientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, 180 * M_PI/180);
    }
    
    [self drawAtPoint:CGPointMake(0, 0)];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIGraphicsEndImageContext();
    
    return cgImage;
}

@end


@implementation NSString (Utils)

- (NSString *) readFromFile:(NSString *)fileName ofType:(NSString *)type {
    NSString *txtFilePath = [[NSBundle mainBundle] pathForResource:fileName ofType:type];
    NSString *txtFileContents = [NSString stringWithContentsOfFile:txtFilePath encoding:NSUTF8StringEncoding error:NULL];

    return txtFileContents;
}

@end;