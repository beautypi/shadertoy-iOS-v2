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

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ShaderViewController () {
    APIShaderObject* _shader;
    UIView* _shaderView;
    ShaderCanvasViewController* _shaderCanvasViewController;
    BOOL _firstView;
    
    NSMutableArray *_gifImageArray;
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

static NSUInteger const kFrameCount = 30;
static float const kFrameDelay = 0.08f;

- (NSURL *) makeAnimatedGif {
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: [NSNumber numberWithFloat:kFrameDelay], // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              }
                                      };
    
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
        
        if( frameNumber < kFrameCount-1 ) {
            [weakSelf addAnimationFrameToArray:(frameNumber+1) time:(time + kFrameDelay) complete:complete];
        } else {
            complete([self makeAnimatedGif]);
        }
    }];
}

- (IBAction)shaderShareClick:(id)sender {
    [_shaderPlayerPlay setSelected:YES];
    [_shaderCanvasViewController pause];
    
    [self exportImage:YES];
}

- (void)exportImage:(BOOL) asGif {
    
    NSString *text = [[[[@"Check out this \"" stringByAppendingString:_shader.shaderName] stringByAppendingString:@"\" shader by "] stringByAppendingString:_shader.username] stringByAppendingString:@" on @Shadertoy"];
    NSURL *url = [_shader getShaderUrl];
    ShaderCanvasViewController *shaderCanvasViewController = _shaderCanvasViewController;
    
    __weak typeof (self) weakSelf = self;
    
    _gifImageArray = [[NSMutableArray alloc] initWithCapacity:kFrameCount];
    
    if( asGif ) {
        // gif export
        [_shaderCanvasViewController setCanvasScaleFactor: 640.f / self.view.frame.size.width ];
        
        [self addAnimationFrameToArray:0 time:[_shaderCanvasViewController getIGlobalTime]complete:^(NSURL *fileURL) {
            
            [weakSelf shareText:text andImage:[NSData dataWithContentsOfURL:fileURL] andUrl:url];
            [shaderCanvasViewController setDefaultCanvasScaleFactor];
        }];
    } else {
        // normal export
        [_shaderCanvasViewController setCanvasScaleFactor: 2.f * 960.f / self.view.frame.size.width ];
        
        [_shaderCanvasViewController renderOneFrame:[_shaderCanvasViewController getIGlobalTime] success:^(UIImage *image) {
            UIImage *scaledImage = [image resizedImageByMagick:@"960x960"]; //   ][image resizedImageToFitInSize:CGSizeMake(320.f, 320.f) scaleIfSmaller:NO];
            
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
    
    [self presentViewController:activityController animated:YES completion:nil];
}

@end
