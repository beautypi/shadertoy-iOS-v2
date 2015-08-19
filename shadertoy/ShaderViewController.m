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
    [_shaderDescription setText:_shader.shaderDescription];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if( !_firstView ) {
        _shaderView.layer.frame = _shaderImageView.layer.frame;
        return;
    }
    
    _firstView = NO;
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ShaderCanvasViewController* viewController = (ShaderCanvasViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderCanvasViewController"];
    
    viewController.view.layer.frame = _shaderImageView.layer.frame;
    [self addChildViewController:viewController];
    _shaderView = viewController.view;
    [self.view addSubview:viewController.view];
    [viewController updateWithShaderObject:_shader];
  //  [self.navigationController pushViewController:viewController animated:YES];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
        
    _shaderView.layer.frame = _shaderImageView.layer.frame;
}


@end
