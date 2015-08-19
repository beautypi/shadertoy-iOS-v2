//
//  ShaderViewController.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "ShaderObject.h"

@interface ShaderViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *shaderImageView;
@property (strong, nonatomic) IBOutlet UILabel *shaderName;
@property (strong, nonatomic) IBOutlet UILabel *shaderUserName;
@property (strong, nonatomic) IBOutlet UILabel *shaderDescription;

- (void) setShaderObject:(ShaderObject *)shader;

@end
