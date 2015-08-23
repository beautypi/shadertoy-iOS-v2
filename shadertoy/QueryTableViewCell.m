//
//  QueryTableViewCellIphone.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "QueryTableViewCell.h"
#import "AFNetworking.h"
#import "APIShadertoy.h"
#import "UIImageView+AFNetworking.h"

@implementation UIImageView (AFNetworkingFadeInAdditions)

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage fadeInWithDuration:(CGFloat)duration {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPShouldHandleCookies:NO];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    __weak typeof (self) weakSelf = self;
    
    [self setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (!request) // image was cached
            [weakSelf setImage:image];
        else
            [UIView transitionWithView:weakSelf duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                [weakSelf setImage:image];
            } completion:nil];
    } failure:nil];
}

@end

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
    
    [_shaderImageView setImageWithURL:[shader getPreviewImageUrl] placeholderImage:nil fadeInWithDuration:0.5f];

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
        [_shaderImageView cancelImageRequestOperation];
        [_shader cancelShaderRequestOperation];
    }
}

@end
