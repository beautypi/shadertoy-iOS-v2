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
#import "UIImageView+WebCache.h"
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

- (void) viewWillAppear:(BOOL)animated {
    _shaderImageView.contentMode = UIViewContentModeScaleAspectFill;
    [_shaderImageView sd_setImageWithURL:[_shader getPreviewImageUrl]];
    
    [_shaderName setText:_shader.shaderName];
    [_shaderUserName setText:_shader.username];
    [_shaderDescription setText:[[_shader.shaderDescription stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"] stripHtml]];
    [_shaderCompileInfoButton setHidden:YES];
    [_shaderCompileInfoButton setTintColor:[UIColor blackColor]];
    
    [_shaderTouchPossible setHidden:![_shader useMouse]];
    [_shaderCompiling setTextColor:[UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f]];
    
    [_shaderPlayerPlay setTintColor:[UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f]];
    
    [self layoutCanvasView];
    [super viewWillAppear:animated];
}


- (CGSize)get_visible_size {
    CGSize result;
    CGSize size = [[UIScreen mainScreen] bounds].size;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if( (orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight) ) {
        result.width = size.width;
        result.height = size.height;
    } else {
        result.width = size.height;
        result.height = size.width;
    }
    
    size = [[UIApplication sharedApplication] statusBarFrame].size;
    result.height -= MIN(size.width, size.height);
    
    if( self.tabBarController != nil ) {
        size = self.tabBarController.tabBar.frame.size;
        result.height -= MIN(size.width, size.height);
    }
    
    return result;
}

- (void) layoutCanvasView {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    CGRect frame = _shaderImageView.layer.frame;
    
    if( (orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight) ) {
        //Landscape mode
        CGSize size = [self get_visible_size];
        frame.size.height = MIN( frame.size.height, size.height );
        _shaderImageView.layer.frame = frame;
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
    } else {
        [[self navigationController] setNavigationBarHidden:NO animated:YES];
    }
    _shaderView.frame = frame;
    
    if( !_exporting ) {
        [_shaderCanvasViewController forceDraw];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [self layoutCanvasView];
    
    if( _firstView ) {
        _firstView = NO;
        [self compileShader];
    }
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self layoutCanvasView];
}

#pragma mark - Compile shader, setup canvas

- (void) setShaderObject:(APIShaderObject *)shader {
    _shader = shader;
    
    // invalidate, will refresh next view
    APIShaderRepository* _repository = [[APIShaderRepository alloc] init];
    [_repository invalidateShader:_shader.shaderId];
    
    // add shader canvas
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    _shaderCanvasViewController = (ShaderCanvasViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderCanvasViewController"];
    
    [self addChildViewController:_shaderCanvasViewController];
    
    _shaderView = _shaderCanvasViewController.view;
    [_shaderView setHidden:YES];
    
    [self.view addSubview:_shaderView];
    [self.view sendSubviewToBack:_shaderView];
    [self layoutCanvasView];
}

- (void) compileShader {
    // compile image shader
    NSString *error;
    if( [_shaderCanvasViewController compileShaderPass:_shader.imagePass theError:&error] ) {
        
        [_shaderCanvasViewController start];
        [_shaderView setHidden:NO];
        
        NSString *headerComment = [_shader getHeaderComments];
        [_shaderCompileInfoButton bk_addEventHandler:^(id sender) {
            UIAlertView* alert = [[UIAlertView alloc]  initWithTitle:@"Header comments" message:headerComment delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alert show];
        } forControlEvents:UIControlEventTouchDown];
        
        __weak typeof (self) weakSelf = self;
        [UIView transitionWithView:weakSelf.view duration:0.5f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [weakSelf.shaderCompiling setHidden:YES];
            [_shaderPlayerContainer setHidden:NO];
            [_shaderImageView setAlpha:0.f];
            
            if( ![headerComment isEqualToString:@""] ) {
                [_shaderCompileInfoButton setHidden:NO];
            }
        } completion:^(BOOL finished) {
            [_shaderCanvasViewController setTimeLabel:_shaderPlayerTime];
            [_shaderImageView setHidden:YES];
            [self.navigationItem setRightBarButtonItem:_shaderShareButton animated:NO];
            
            _compiled = YES;
        }];
    } else {
        [_shaderCompiling setText:@"Shader error"];
        [_shaderCompiling setTextColor:[UIColor redColor]];
        
        [_shaderCompileInfoButton setTintColor:[UIColor redColor]];
        [_shaderCompileInfoButton setHidden:NO];
        [_shaderCompileInfoButton bk_addEventHandler:^(id sender) {
            UIAlertView* alert = [[UIAlertView alloc]  initWithTitle:@"Shader error" message:error delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alert show];
        } forControlEvents:UIControlEventTouchDown];
    }
}

#pragma mark - UI

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
    if( _exporting || !_compiled ) return;
    
    [_shaderPlayerPlay setSelected:YES];
    [_shaderCanvasViewController pause];
    
    _exporting = YES;
    
    UIAlertView* alert = [UIAlertView bk_alertViewWithTitle:@"Share shader" message:@"You can render an animated GIF of this shader and share it using email.\nAt the moment, it is not possible to share an animated GIF using twitter or facebook."];
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

#pragma mark - Export image

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
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self addAnimationFrameToArray:0 time:[_shaderCanvasViewController getIGlobalTime]complete:^(NSURL *fileURL) {
                [alert dismissWithClickedButtonIndex:0 animated:YES];
                
                [weakSelf shareText:text andImage:[NSData dataWithContentsOfURL:fileURL] andUrl:url];
                [shaderCanvasViewController setDefaultCanvasScaleFactor];
            }];
        });
    } else {
        // normal export
        UIAlertView* alert = [UIAlertView bk_alertViewWithTitle:@"Exporting HQ image"];
        [alert show];
        
        [_shaderCanvasViewController setCanvasScaleFactor: 2.f * 1280.f / self.view.frame.size.width ];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_shaderCanvasViewController renderOneFrame:[_shaderCanvasViewController getIGlobalTime] success:^(UIImage *image) {
                UIImage *scaledImage = [image resizedImageByMagick:@"1280x1280"];
                [alert dismissWithClickedButtonIndex:0 animated:YES];
                
                [weakSelf shareText:text andImage:(NSData *)scaledImage andUrl:url];
                [shaderCanvasViewController setDefaultCanvasScaleFactor];
            }];
        });
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
