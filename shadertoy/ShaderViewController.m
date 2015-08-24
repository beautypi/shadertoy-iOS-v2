//
//  ShaderViewController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "ShaderViewController.h"
#import "AFNetworking.h"
#import "ShaderCanvasViewController.h"
#import "NSString_stripHtml.h"
#import "APIShaderRepository.h"
#import "BlocksKit+UIKit.h"
#import "UIImageView+AFNetworking.h"

@interface ShaderViewController () {
    APIShaderObject* _shader;
    UIView* _shaderView;
    ShaderCanvasViewController* _shaderCanvasViewController;
    BOOL _firstView;
}

@end

@implementation ShaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _firstView = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) setShaderObject:(APIShaderObject *)shader {
    _shader = shader;
    
    // invalidate, will refresh next view
    APIShaderRepository* _repository = [[APIShaderRepository alloc] init];
    [_repository invalidateShader:_shader.shaderId];
}

- (void) viewWillAppear:(BOOL)animated {
    _shaderImageView.contentMode = UIViewContentModeScaleAspectFill;
    [_shaderImageView setImageWithURL:[_shader getPreviewImageUrl]];
    
    [_shaderName setText:_shader.shaderName];
    [_shaderUserName setText:_shader.username];
    [_shaderDescription setText:[[_shader.shaderDescription stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"] stripHtml]];
    [_shaderLikesInfo setText:[@"♡" stringByAppendingString:[_shader.likes stringValue]]];
    [_shaderCompileInfoButton setHidden:YES];
    [_shaderTouchPossible setHidden:![_shader.imagePass.code containsString:@"iMouse"]];
    [_shaderCompiling setTextColor:[UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f]];
    
    [_shaderPlayerPlay setTintColor:[UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f]];
    
    [self layoutCanvasView];
}


- (CGSize)get_visible_size {
    CGSize result;
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight)) {
        result.width = size.width;
        result.height = size.height;
    }
    else {
        result.width = size.height;
        result.height = size.width;
    }
    
    size = [[UIApplication sharedApplication] statusBarFrame].size;
    result.height -= MIN(size.width, size.height);
    
    // hide navigationbar in landscape
    //    if (self.navigationController != nil ) {
    //        size = self.navigationController.navigationBar.frame.size;
    //        result.height -= MIN(size.width, size.height);
    //    }
    
    if (self.tabBarController != nil) {
        size = self.tabBarController.tabBar.frame.size;
        result.height -= MIN(size.width, size.height);
    }
    
    return result;
}

- (void) layoutCanvasView {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    CGRect frame = _shaderImageView.layer.frame;
    
    if ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight)) {
        //Landscape mode
        CGSize size = [self get_visible_size];
        frame.size.height = MIN( frame.size.height, size.height );
        _shaderImageView.layer.frame = frame;
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
    } else {
        [[self navigationController] setNavigationBarHidden:NO animated:YES];
    }
    _shaderView.frame = frame;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if( !_firstView ) {
        [self layoutCanvasView];
        return;
    }
    
    _firstView = NO;
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    _shaderCanvasViewController = (ShaderCanvasViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderCanvasViewController"];
    
    [self addChildViewController:_shaderCanvasViewController];
    [_shaderCanvasViewController setTimeLabel:_shaderPlayerTime];
    
    _shaderView = _shaderCanvasViewController.view;
    [_shaderView setHidden:YES];
    [self.view addSubview:_shaderCanvasViewController.view];
    
    [self layoutCanvasView];
    
    NSString *error;
    if( [_shaderCanvasViewController compileShaderObject:_shader theError:&error] ) {
        [_shaderCanvasViewController start];
        
        __weak typeof (self) weakSelf = self;
        [UIView transitionWithView:weakSelf.view duration:0.5f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [weakSelf.shaderCompiling setHidden:YES];
        } completion:^(BOOL finished) {
            [_shaderView setHidden:NO];
            [_shaderImageView setImage:nil];
            [_shaderPlayerContainer setHidden:NO];
        }];
    } else {
        [_shaderCompiling setText:@"Shader error"];
        [_shaderCompiling setTextColor:[UIColor redColor]];
        [_shaderLikesInfo setHidden:YES];
        
        [_shaderCompileInfoButton setTintColor:[UIColor redColor]];
        [_shaderCompileInfoButton setHidden:NO];
        [_shaderCompileInfoButton bk_addEventHandler:^(id sender) {
            UIAlertView* alert = [[UIAlertView alloc]  initWithTitle:@"Shader error" message:error delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alert show];
        } forControlEvents:UIControlEventTouchDown];
    }
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self layoutCanvasView];
}

- (IBAction)shaderPlayerRewindClick:(id)sender {
    [_shaderCanvasViewController rewind];
}

- (IBAction)shaderPlayerPlayClick:(id)sender {
    if( [_shaderCanvasViewController isRunning] ) {
        [_shaderPlayerPlay setSelected:YES];
        [_shaderCanvasViewController pause];
    } else {
        [_shaderPlayerPlay setSelected:NO];
        [_shaderCanvasViewController play];
    }
}

- (IBAction)shaderShareClick:(id)sender {
}

@end
