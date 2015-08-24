//
//  QueryTableViewCellIphone.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "APIShaderObject.h"

@interface QueryTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *shaderImageView;
@property (strong, nonatomic) IBOutlet UILabel *shaderTitle;
@property (strong, nonatomic) IBOutlet UILabel *shaderInfo;

- (void) layoutForShader:(APIShaderObject *)shader;

@end
