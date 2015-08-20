//
//  ShaderViewController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "ShaderViewController.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "ShaderCanvasViewController.h"
#import "NSString_stripHtml.h"

@interface ShaderViewController () {
    ShaderObject* _shader;
    UIView* _shaderView;
    BOOL _firstView;
}

@end

@implementation ShaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _firstView = YES;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) setShaderObject:(ShaderObject *)shader {
    _shader = shader;
}

- (void) viewWillAppear:(BOOL)animated {
    _shaderImageView.contentMode = UIViewContentModeScaleAspectFill;
    [_shaderImageView setImageWithURL:[_shader getPreviewImageUrl]];
    
    [_shaderName setText:_shader.shaderName];
    [_shaderUserName setText:_shader.username];
    [_shaderDescription setText:[[_shader.shaderDescription stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"] stripHtml]];
    
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
    
    if (self.navigationController != nil && false) {
        size = self.navigationController.navigationBar.frame.size;
        result.height -= MIN(size.width, size.height);
    }
    
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
    ShaderCanvasViewController* viewController = (ShaderCanvasViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderCanvasViewController"];
    
    [self addChildViewController:viewController];
    _shaderView = viewController.view;
    [self.view addSubview:viewController.view];
    
    [self layoutCanvasView];
    
    [viewController updateWithShaderObject:_shader];
  //  [self.navigationController pushViewController:viewController animated:YES];
    
    [_shaderImageView setImage:nil];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self layoutCanvasView];
}


@end
