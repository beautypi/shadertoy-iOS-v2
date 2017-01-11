//
//  ShaderViewController.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "APIShaderObject.h"
#import "VRSettings.h"
#import "ShaderSettings.h"

typedef NS_ENUM(NSUInteger, ShaderViewMode) {
    VIEW_FULLSCREEN_IF_LANDSCAPE,
    VIEW_FULLSCREEN
};

@interface ShaderViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *shaderImageView;
@property (strong, nonatomic) IBOutlet UILabel *shaderName;
@property (strong, nonatomic) IBOutlet UILabel *shaderUserName;
@property (strong, nonatomic) IBOutlet UILabel *shaderDescription;
@property (strong, nonatomic) IBOutlet UILabel *shaderTouchPossible;

@property (strong, nonatomic) IBOutlet UILabel *shaderCompiling;
@property (strong, nonatomic) IBOutlet UIButton *shaderCompileInfoButton;
@property (strong, nonatomic) IBOutlet UIButton *shaderVRButton;
@property (strong, nonatomic) IBOutlet UIButton *shaderHDButton;

@property (strong, nonatomic) IBOutlet UIButton *shaderPlayerRewind;
@property (strong, nonatomic) IBOutlet UIButton *shaderPlayerPlay;
@property (strong, nonatomic) IBOutlet UILabel *shaderPlayerTime;
@property (strong, nonatomic) IBOutlet UIView *shaderPlayerContainer;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *shaderShareButton;
@property (strong, nonatomic) IBOutlet UIView *shaderInputButtonView;
@property (strong, nonatomic) IBOutlet UIView *shaderInputSpaceview;

@property (strong, nonatomic) IBOutlet UIButton *keyboardSpaceButton;
@property (strong, nonatomic) IBOutlet UIButton *keyboardLeftButton;
@property (strong, nonatomic) IBOutlet UIButton *keyboardUpButton;
@property (strong, nonatomic) IBOutlet UIButton *keyboardDownButton;
@property (strong, nonatomic) IBOutlet UIButton *keyboardRightButton;

- (void) setShaderObject:(APIShaderObject *)shader;
- (void) setVRSettings:(VRSettings *)vrSettings;
- (void) setShaderSettings:(ShaderSettings *)shaderSettings;

@end
