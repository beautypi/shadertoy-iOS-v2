//
//  QueryTableViewCellIphone.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "QueryTableViewCell.h"
#import "AFNetworking.h"
#import "UIImageView+WebCache.h"
#import "APIShadertoy.h"

@interface QueryTableViewCell ()  {
    ShaderObject* _shader;
    NSString* _shaderId;
    BOOL _firstUpdate;
}

@end

@implementation QueryTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [_shaderTitle setText:@""];
    _firstUpdate = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutForShader:(ShaderObject *)shader {
    _shader = shader;
    
    _shaderImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    __weak typeof (self) weakSelf = self;
    [_shaderImageView sd_setImageWithURL:[shader getPreviewImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if( cacheType != SDImageCacheTypeDisk ) {
            [weakSelf.imageView setAlpha:0.f];
            [UIView transitionWithView:weakSelf duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [weakSelf.imageView setAlpha:1.f];
            } completion:nil];
        }
    }];
    
    if( _firstUpdate ) {
        [_shaderTitle setText:shader.shaderName];
        if(shader.likes) [_shaderInfo setText:[@"♡" stringByAppendingString:[shader.likes stringValue]]];
    } else {
        __weak typeof (self) weakSelf = self;
        [UIView transitionWithView:weakSelf duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [weakSelf.shaderTitle setText:shader.shaderName];
            if(shader.likes) [weakSelf.shaderInfo setText:[@"♡" stringByAppendingString:[shader.likes stringValue]]];
        } completion:nil];
    }
    
    _firstUpdate = NO;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if(!newSuperview) {
        // cancel timers
        [_shaderImageView sd_cancelCurrentImageLoad];
        [_shader cancelShaderRequestOperation];
    }
}

@end
