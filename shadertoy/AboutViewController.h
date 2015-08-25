//
//  AboutViewController.h
//  shadertoy
//
//  Created by Reinder Nijhoff on 25/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface AboutViewController : UIViewController <MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *aboutText;
@property (strong, nonatomic) IBOutlet UILabel *aboutText2;

- (void)initTabBarItem;

@end
