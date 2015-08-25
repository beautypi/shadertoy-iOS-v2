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
#import "UIImage+ResizeMagick.h"
#import "BlocksKit.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "MBProgressHUD.h"

@interface ShaderViewController () {
    APIShaderObject* _shader;
    UIView* _shaderView;
    ShaderCanvasViewController* _shaderCanvasViewController;
    
    BOOL _firstView;
    BOOL _exporting;
    BOOL _compiled;
    
    NSMutableArray *_gifImageArray;
    UIProgressView *_gifImageProgressView;
}
@end

@implementation ShaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _firstView = YES;
    
    _exporting = NO;
    _compiled = NO;
    
    self.navigationItem.rightBarButtonItem = nil;
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
    [_shaderCanvasViewController forceDraw];
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
            [self.navigationItem setRightBarButtonItem:_shaderShareButton animated:YES];
            _compiled = YES;
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

static NSUInteger const kFrameCount = 32;
static float const kFrameDelay = 0.085f;

- (NSURL *) makeAnimatedGif {
    NSDictionary *fileProperties = @{(__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             } };
    
    NSDictionary *frameProperties = @{(__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: [NSNumber numberWithFloat:kFrameDelay],
                                              }};
    
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:@"animated.gif"];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for ( int i=0; i<kFrameCount; i++ ) {
        UIImage* image = [_gifImageArray objectAtIndex:i];
        CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    return fileURL;
}

- (void) addAnimationFrameToArray:(int)frameNumber time:(float)time complete:(void (^)(NSURL *fileURL))complete {
    __weak typeof (self) weakSelf = self;
    
    [_shaderCanvasViewController renderOneFrame:time success:^(UIImage *image) {
        UIImage *scaledImage = [image resizedImageByMagick:@"480x480"]; // [image resizedImageToFitInSize:CGSizeMake(230.f, 230.f) scaleIfSmaller:NO];
        [_gifImageArray insertObject:scaledImage atIndex:frameNumber];
        
        [_gifImageProgressView setProgress:(float)frameNumber/(float)kFrameCount animated:NO];
        
        if( frameNumber < kFrameCount-1 ) {
            [weakSelf addAnimationFrameToArray:(frameNumber+1) time:(time + kFrameDelay) complete:complete];
        } else {
            complete([self makeAnimatedGif]);
        }
    }];
}

- (IBAction)shaderShareClick:(id)sender {
    if( _exporting || !_compiled ) return;
    
    [_shaderPlayerPlay setSelected:YES];
    [_shaderCanvasViewController pause];
    
    _exporting = YES;
    
    UIAlertView* alert = [UIAlertView bk_alertViewWithTitle:@"Share shader" message:@"You can render an animated GIF of this shader and share it using email.\nAt the moment, it is not possible to share an animated GIF using twitter or facebook :("];
    [alert bk_addButtonWithTitle:@"Export animated GIF image" handler:^{
        [self exportImage:YES];
    }];
    [alert bk_addButtonWithTitle:@"Export HQ image (twitter/facebook)" handler:^{
        [self exportImage:NO];
    }];
    [alert bk_addButtonWithTitle:@"Cancel" handler:^{
        _exporting = NO;
    }];
    
    [alert show];
}

- (void)exportImage:(BOOL) asGif {
    
    NSString *text = [[[[@"Check out this \"" stringByAppendingString:_shader.shaderName] stringByAppendingString:@"\" shader by "] stringByAppendingString:_shader.username] stringByAppendingString:@" on @Shadertoy"];
    NSURL *url = [_shader getShaderUrl];
    ShaderCanvasViewController *shaderCanvasViewController = _shaderCanvasViewController;
    
    __weak typeof (self) weakSelf = self;
    
    _gifImageArray = [[NSMutableArray alloc] initWithCapacity:kFrameCount];
    
    if( asGif ) {
        // gif export
        UIAlertView* alert = [UIAlertView bk_alertViewWithTitle:@"Exporting GIF"];
        _gifImageProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        _gifImageProgressView.frame = CGRectMake(0, 0, 200, 15);
        _gifImageProgressView.bounds = CGRectMake(0, 0, 200, 15);
        _gifImageProgressView.backgroundColor = [UIColor darkGrayColor];
        
        [_gifImageProgressView setUserInteractionEnabled:NO];
        [_gifImageProgressView setTrackTintColor:[UIColor darkGrayColor]];
        [_gifImageProgressView setProgressTintColor:[UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f]];
        [_gifImageProgressView setProgress:0.f animated:NO];
        
        [alert setValue:_gifImageProgressView forKey:@"accessoryView"];
        [alert show];
        
        [_shaderCanvasViewController setCanvasScaleFactor: 2.f*480.f / self.view.frame.size.width ];
        
        [self addAnimationFrameToArray:0 time:[_shaderCanvasViewController getIGlobalTime]complete:^(NSURL *fileURL) {
            [alert dismissWithClickedButtonIndex:0 animated:YES];
            
            [weakSelf shareText:text andImage:[NSData dataWithContentsOfURL:fileURL] andUrl:url];
            [shaderCanvasViewController setDefaultCanvasScaleFactor];
        }];
    } else {
        // normal export
        UIAlertView* alert = [UIAlertView bk_alertViewWithTitle:@"Exporting HQ image"];
        [alert show];
        
        [_shaderCanvasViewController setCanvasScaleFactor: 2.f * 1280.f / self.view.frame.size.width ];
        
        [_shaderCanvasViewController renderOneFrame:[_shaderCanvasViewController getIGlobalTime] success:^(UIImage *image) {
            UIImage *scaledImage = [image resizedImageByMagick:@"1280x1280"];
            [alert dismissWithClickedButtonIndex:0 animated:YES];
            
            [weakSelf shareText:text andImage:(NSData *)scaledImage andUrl:url];
            [shaderCanvasViewController setDefaultCanvasScaleFactor];
        }];
    }
}

- (void)shareText:(NSString *)text andImage:(NSData *)image andUrl:(NSURL *)url {
    NSMutableArray *sharingItems = [NSMutableArray new];
    
    if (text) {
        [sharingItems addObject:text];
    }
    if (image) {
        [sharingItems addObject:image];
    }
    if (url) {
        [sharingItems addObject:url];
    }
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:sharingItems applicationActivities:nil];
    
    [self presentViewController:activityController animated:YES completion:^{}];
    
    _exporting = NO;
}

@end
