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
#import "BlocksKit.h"
#import "VRManager.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "Utils.h"
#import "defines.h"

#import "SoundPassPlayer.h"

@interface ShaderViewController () {
    APIShaderObject* _shader;
    SoundPassPlayer* _soundPassPlayer;
    VRSettings* _vrSettings;
    ShaderSettings* _shaderSettings;
    
    UIView* _imageShaderView;
    ShaderCanvasViewController* _imageShaderViewController;
    
    UIView* _soundShaderView;
    ShaderCanvasViewController* _soundShaderViewController;
    
    BOOL _firstView;
    BOOL _exporting;
    BOOL _compiled;
    
    NSMutableArray *_exportImageArray;
    UIProgressView *_progressView;
    
    ShaderViewMode _viewMode;
}
@end

@implementation ShaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _firstView = YES;
    _exporting = NO;
    _compiled = NO;
    _viewMode = VIEW_FULLSCREEN_IF_LANDSCAPE;
    
    self.navigationItem.rightBarButtonItem = nil;
    
    [_shaderCompileInfoButton setHidden:YES];
    [_shaderCompileInfoButton setTintColor:[UIColor blackColor]];
    [_shaderCompiling setTextColor:[UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f]];
    [_shaderPlayerPlay setTintColor:[UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self.shaderInputButtonView setHidden:YES];
    [self.shaderInputSpaceview setHidden:YES];
    [self initButtonEvents];
}

- (void)appDidBecomeActive:(NSNotification *)notification {
    if (self.isViewLoaded && self.view.window) {
        // viewController is visible
        [_imageShaderViewController forceDraw];
        [self playSoundSyncedWithShader];
        [_imageShaderViewController resumeInputs];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    _shaderImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [_shaderImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[_shader getPreviewImageUrl]] placeholderImage:nil success:nil failure:nil];
    
    
    [_shaderName setText:_shader.shaderName];
    [_shaderUserName setText:_shader.username];
    [_shaderDescription setText:[[_shader.shaderDescription stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"] stripHtml]];
    
    [_shaderTouchPossible setHidden:![_shader useMouse]];
    
    [self layoutCanvasView];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [VRManager deActivate];
    [_soundPassPlayer stop];
    [_imageShaderViewController pauseInputs];
    [super viewWillDisappear:animated];
}

- (void) layoutCanvasView {
    BOOL landscape = ( [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) || ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight);
    CGRect frame;
    
    if( landscape ) {
        frame = CGRectMake( 0, _shaderImageView.frame.origin.y, [[UIScreen mainScreen] bounds].size.width, landscape?[[UIScreen mainScreen] bounds].size.height:[[UIScreen mainScreen] bounds].size.width/16.f*9.f);
    } else {
        frame = _shaderImageView.frame;
    }
    
    if( !CGRectEqualToRect( frame, _imageShaderView.frame) ) {
        if( landscape ) {
            if( _viewMode == VIEW_FULLSCREEN_IF_LANDSCAPE ) {
                [[self.tabBarController tabBar] setHidden:YES];
            }
            [[self navigationController] setNavigationBarHidden:YES animated:YES];
            
            bool keyboard = [_shader useKeyboard];
            [self.shaderInputButtonView setHidden:!keyboard];
            [self.shaderInputSpaceview setHidden:!keyboard];
        } else {
            [[self navigationController] setNavigationBarHidden:NO animated:YES];
            [[self.tabBarController tabBar] setHidden:NO];
            
            [self.shaderInputButtonView setHidden:YES];
            [self.shaderInputSpaceview setHidden:YES];
        }
        if( !_exporting ) {
            [_imageShaderView setFrame:frame];
            [_imageShaderViewController forceDraw];
        }
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self layoutCanvasView];
    
    if( _firstView ) {
        _firstView = NO;
        
        if( _shader.soundPass ) {
            [self compileSoundShader];
        } else {
            [self compileImageShader];
        }
    } else {
        [self playSoundSyncedWithShader];
        [_imageShaderViewController resumeInputs];
    }
    
    trackScreen(@"Shader");
    trackEvent(@"ShaderView", @"viewDidAppear", _shader.shaderId);
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutCanvasView];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _shader = nil;
    _soundPassPlayer = nil;
    
    _imageShaderView = nil;
    _imageShaderViewController = nil;
    
    _soundShaderView = nil;
    _soundShaderViewController = nil;
}

- (UIAlertController *) createProgressAlert:(NSString *)title {
    UIAlertController *myAlertController = [UIAlertController alertControllerWithTitle:title message:@"Exporting ..." preferredStyle:UIAlertControllerStyleAlert ];
    
    UIViewController *viewController = [[UIViewController alloc]init];
    
    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressView.frame = CGRectMake(10, 35, 250, 15);
    _progressView.bounds = CGRectMake(0, 0, 250, 15);
    _progressView.backgroundColor = [UIColor darkGrayColor];
    
    [_progressView setUserInteractionEnabled:NO];
    [_progressView setTrackTintColor:[UIColor darkGrayColor]];
    [_progressView setProgressTintColor:[UIColor colorWithRed:1.f green:0.5f blue:0.125f alpha:1.f]];
    [_progressView setProgress:0.f animated:NO];
    
    [viewController.view addSubview:_progressView];
    
    [myAlertController setValue:viewController forKey:@"contentViewController"];
    return myAlertController;
}

#pragma mark - Compile shader, setup canvas

- (void) setShaderObject:(APIShaderObject *)shader {
    _shader = shader;
    
    // invalidate, will refresh next view
    APIShaderRepository* _repository = [[APIShaderRepository alloc] init];
    [_repository invalidateShader:_shader.shaderId];
    
    // add image shader canvas
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    _imageShaderViewController = (ShaderCanvasViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderCanvasViewController"];
    _imageShaderView = _imageShaderViewController.view;
    [self addChildViewController:_imageShaderViewController];
    [self.view addSubview:_imageShaderView];
    
    [_imageShaderView setHidden:YES];
    [self.view sendSubviewToBack:_imageShaderView];
    
    [self layoutCanvasView];
}

- (void) compileShader:(bool)soundPass vc:(ShaderCanvasViewController *)shaderViewController success:(void (^)(void))success {
    [self bk_performBlock:^(id obj) {
        NSString *error;
        
        if( [shaderViewController compileShader:self->_shader soundPass:soundPass theError:&error] ) {
            [self bk_performBlock:^(id obj) {
                success();
            } afterDelay:0.05f];
        } else {
            [self->_shaderCompiling setText:@"Shader error"];
            [self->_shaderCompiling setTextColor:[UIColor redColor]];
            
            [self->_shaderCompileInfoButton setTintColor:[UIColor redColor]];
            [self->_shaderCompileInfoButton setHidden:NO];
            [self->_shaderCompileInfoButton bk_addEventHandler:^(id sender) {
                UIAlertController *myAlertController = [UIAlertController alertControllerWithTitle:@"Shader error" message:error preferredStyle:UIAlertControllerStyleAlert ];
                [myAlertController addAction: [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                               {
                                                   [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                               }]];
                [self presentViewController:myAlertController animated:YES completion:nil];
            } forControlEvents:UIControlEventTouchDown];
        }
    } afterDelay:0.05f];
}

- (void) compileImageShader {
    [_shaderCompiling setText:@"Compiling shader..."];
    
    __weak typeof (self) weakSelf = self;
    
    [self compileShader:false vc:_imageShaderViewController success:^{
        [self->_imageShaderViewController start];
        [weakSelf playSoundSyncedWithShader];
        [self->_imageShaderView setHidden:NO];
        [self->_imageShaderView setAutoresizingMask:UIViewAutoresizingNone];
        
        [self bk_performBlock:^(id obj) {
            NSString *headerComment = [self->_shader getHeaderComments];
            [self->_shaderCompileInfoButton bk_addEventHandler:^(id sender) {
                UIAlertController *myAlertController = [UIAlertController alertControllerWithTitle:@"Header comments" message:headerComment preferredStyle:UIAlertControllerStyleAlert ];
                [myAlertController addAction: [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                               {
                                                   [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                                   
                                               }]];
                [weakSelf presentViewController:myAlertController animated:YES completion:nil];
            } forControlEvents:UIControlEventTouchDown];
            
            [UIView transitionWithView:weakSelf.view duration:0.5f options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                [self->_shaderCompiling setHidden:YES];
                [self->_shaderPlayerContainer setHidden:NO];
                [self->_shaderImageView setAlpha:0.f];
                [self->_imageShaderViewController setTimeLabel:_shaderPlayerTime];
                
                if( ![headerComment isEqualToString:@""] ) {
                    [self->_shaderCompileInfoButton setHidden:NO];
                }
                if( [self->_shader vrImplemented] && !_vrSettings ) {
                    [self->_shaderVRButton setHidden:NO];
                } else if( !self->_shaderSettings || (_shaderSettings && _shaderSettings.quality != SHADER_QUALITY_HIGH)) {
                    [self->_shaderHDButton setHidden:NO];
                }
            } completion:^(BOOL finished) {
                [self->_shaderImageView setHidden:YES];
                [weakSelf.view bringSubviewToFront:self->_imageShaderView];
                [weakSelf.view bringSubviewToFront:weakSelf.shaderInputButtonView];
                [weakSelf.view bringSubviewToFront:weakSelf.shaderInputSpaceview];
                [weakSelf.navigationItem setRightBarButtonItem:self->_shaderShareButton animated:NO];
                
                self->_compiled = YES;
            }];
        } afterDelay:0.1f];
    }];
}

- (void) compileSoundShader {
    [_shaderCompiling setText:@"Compiling sound shader..."];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    _soundShaderViewController = (ShaderCanvasViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderCanvasViewController"];
    _soundShaderView = _soundShaderViewController.view;
    [self addChildViewController:_soundShaderViewController];
    [self.view addSubview:_soundShaderView];
    
    [_soundShaderView setFrame:CGRectMake(0, -256, 256, 256)];
    [_soundShaderView setAutoresizingMask:UIViewAutoresizingNone];
    
    _soundPassPlayer = [[SoundPassPlayer alloc] init];
    
    __weak typeof (self) weakSelf = self;
    [self compileShader:true vc:_soundShaderViewController success:^{
        [self->_soundShaderViewController setDefaultCanvasScaleFactor];
        [weakSelf renderSoundShaderFrame:0 complete:^{
            [self->_soundPassPlayer prepareToPlay];
            
            [self->_soundShaderView removeFromSuperview];
            [self->_soundShaderViewController removeFromParentViewController];
            self->_soundShaderView = nil;
            self->_soundShaderViewController = nil;
            
            [weakSelf compileImageShader];
        }];
    }];
}

- (void) renderSoundShaderFrame:(int)frameNumber complete:(void (^)(void))complete {
    __weak typeof (self) weakSelf = self;
    
    [_shaderCompiling setText:[NSString stringWithFormat:@"Filling sound buffer... (%d/10)", (frameNumber+1)]];
    [_soundShaderViewController setFragCoordScale:1.f andXOffset:(double)(frameNumber*256*256)/11025.0 andYOffset:0.f];
    
    [_soundShaderViewController renderOneFrame:0.f success:^(UIImage *image) {
        [self->_soundPassPlayer fillSoundBufferFromImage:image block:frameNumber];
        if( frameNumber < 9 ) {
            [weakSelf renderSoundShaderFrame:(frameNumber+1) complete:complete];
        } else {
            complete();
        }
    }];
}

- (void) playSoundSyncedWithShader {
    if( [_imageShaderViewController isRunning] ) {
        [_soundPassPlayer setTime:[_imageShaderViewController getIGlobalTime]];
        [_soundPassPlayer play];
    } else {
        [_soundPassPlayer stop];
    }
}

#pragma mark - Settings

- (void) setShaderSettings:(ShaderSettings *)shaderSettings {
    _shaderSettings = shaderSettings;
    [_imageShaderViewController setShaderSettings:_shaderSettings];
}

- (IBAction)shaderHDClick:(id)sender {
    __weak typeof (self) weakSelf = self;
    
    UIAlertController *myAlertController = [UIAlertController alertControllerWithTitle:@"Quality Settings" message:@"You can run this shader in HD.\n\nWarning: most likely the shader will run very slow and running the shader in HD will drain the battery fast." preferredStyle:UIAlertControllerStyleAlert ];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"High Quality" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [weakSelf startHD];
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }]];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }]];
    [self presentViewController:myAlertController animated:YES completion:nil];
}

- (void)startHD {
    ShaderSettings * shaderSettings = [[ShaderSettings alloc] init];
    shaderSettings.quality = SHADER_QUALITY_HIGH;
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController* viewController = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderViewController"];
    
    [((ShaderViewController *)viewController) setShaderObject:_shader];
    [((ShaderViewController *)viewController) setShaderSettings:shaderSettings];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - VR

- (void) setVRSettings:(VRSettings *)vrSettings {
    _vrSettings = vrSettings;
    [_imageShaderViewController setVRSettings:vrSettings];
}

- (IBAction)shaderVRClick:(id)sender {
    VRSettings *vrSettings = [[VRSettings alloc] init];
    
    [self vrChooseRenderMode:vrSettings];
}

- (void) vrChooseRenderMode:(VRSettings *)vrSettings {
    __weak typeof (self) weakSelf = self;
    
    UIAlertController *myAlertController = [UIAlertController alertControllerWithTitle:@"VR Settings" message:@"Choose render mode:" preferredStyle:UIAlertControllerStyleAlert ];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Cardboard" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       vrSettings.renderMode = VR_SPLIT_SCREEN;
                                       // always use device rotation as input for cardboard
                                       // [self vrChooseInput:vrSettings];
                                       vrSettings.inputMode = VR_INPUT_DEVICE;
                                       [weakSelf vrChooseQuality:vrSettings];
                                       
                                   }]];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Cross-eyed stereo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       vrSettings.renderMode = VR_CROSS_EYE;
                                       [weakSelf vrChooseInput:vrSettings];
                                       
                                   }]];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Anaglyph (cyan/red)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       vrSettings.renderMode = VR_CYAN_RED;
                                       [weakSelf vrChooseInput:vrSettings];
                                       
                                   }]];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Fullscreen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       vrSettings.renderMode = VR_FULL_SCREEN;
                                       [weakSelf vrChooseInput:vrSettings];
                                       
                                   }]];
    [self presentViewController:myAlertController animated:YES completion:nil];
}

- (void) vrChooseInput:(VRSettings *)vrSettings {
    __weak typeof (self) weakSelf = self;
    
    UIAlertController *myAlertController = [UIAlertController alertControllerWithTitle:@"VR Settings" message:@"Choose input:" preferredStyle:UIAlertControllerStyleAlert ];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Touch" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       vrSettings.inputMode = VR_INPUT_TOUCH;
                                       [weakSelf vrChooseQuality:vrSettings];
                                       
                                   }]];
    if( [VRManager isARKitSupported] ) {
        [myAlertController addAction: [UIAlertAction actionWithTitle:@"Device rotation & position" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                       {
                                           [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                           vrSettings.inputMode = VR_INPUT_ARKIT;
                                           [weakSelf vrChooseQuality:vrSettings];
                                           
                                       }]];
        
    } else {
        [myAlertController addAction: [UIAlertAction actionWithTitle:@"Device rotation" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                       {
                                           [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                           vrSettings.inputMode = VR_INPUT_DEVICE;
                                           [weakSelf vrChooseQuality:vrSettings];
                                           
                                       }]];
    }
    [self presentViewController:myAlertController animated:YES completion:nil];
}

- (void) vrChooseQuality:(VRSettings *)vrSettings {
    __weak typeof (self) weakSelf = self;
    
    UIAlertController *myAlertController = [UIAlertController alertControllerWithTitle:@"VR Settings" message:@"Choose render quality:" preferredStyle:UIAlertControllerStyleAlert ];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"High Quality" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       vrSettings.quality = VR_QUALITY_HIGH;
                                       [weakSelf vrStart:vrSettings];
                                       
                                   }]];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Normal Quality" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       vrSettings.quality = VR_QUALITY_NORMAL;
                                       [weakSelf vrStart:vrSettings];
                                       
                                   }]];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Low Quality" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       vrSettings.quality = VR_QUALITY_LOW;
                                       [weakSelf vrStart:vrSettings];
                                       
                                   }]];
    [self presentViewController:myAlertController animated:YES completion:nil];
}

- (void) vrStart:(VRSettings *)vrSettings {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    UIViewController* viewController = (UIViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"ShaderViewController"];
    
    [((ShaderViewController *)viewController) setShaderObject:_shader];
    [((ShaderViewController *)viewController) setVRSettings:vrSettings];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - UI

- (IBAction)shaderPlayerRewindClick:(id)sender {
    [_imageShaderViewController rewind];
    [self playSoundSyncedWithShader];
}

- (IBAction)shaderPlayerPlayClick:(id)sender {
    if( [_imageShaderViewController isRunning] ) {
        [_shaderPlayerPlay setSelected:YES];
        [_imageShaderViewController pause];
    } else {
        [_shaderPlayerPlay setSelected:NO];
        [_imageShaderViewController play];
    }
    [self playSoundSyncedWithShader];
}

- (IBAction)shaderShareClick:(id)sender {
    if( _exporting || !_compiled ) return;
    
    [_shaderPlayerPlay setSelected:YES];
    [_imageShaderViewController pause];
    [self playSoundSyncedWithShader];
    
    if( [_shader useMultiPass] ) {
        NSString *text = [[[[@"Check out this \"" stringByAppendingString:_shader.shaderName] stringByAppendingString:@"\" shader by "] stringByAppendingString:_shader.username] stringByAppendingString:@" on @Shadertoy"];
        NSURL *url = [_shader getShaderUrl];
        [self shareText:text andImage:NULL andUrl:url];
        return;
    }
    
    _exporting = YES;
    
    UIAlertController *myAlertController = [UIAlertController alertControllerWithTitle:@"Share shader" message:@"You can render an animated GIF of this shader and share it using email.\nAt the moment, it is not possible to share an animated GIF using twitter or facebook." preferredStyle:UIAlertControllerStyleAlert ];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Export animated GIF image" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [self exportImage:YES];
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }]];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Export HQ image" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       [self exportImage:NO];
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }]];
    [myAlertController addAction: [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                                   {
                                       self->_exporting = NO;
                                       [myAlertController dismissViewControllerAnimated:YES completion:nil];
                                       
                                   }]];
    [self presentViewController:myAlertController animated:YES completion:nil];
}

#pragma mark - Export animated gif

static NSUInteger const kFrameCount = ImageExportGIFFrameCount;
static float const kFrameDelay = ImageExportGIFFrameDelay;

- (NSURL *) composeAnimatedGif {
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
        UIImage* image = [_exportImageArray objectAtIndex:i];
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
    
    [_imageShaderViewController renderOneFrame:time success:^(UIImage *image) {
        UIImage *scaledImage = [[image resizedImageWithMaximumSize:CGSizeMake(ImageExportGIFWidth, ImageExportGIFWidth)] setShaderWatermarkText:self->_shader];
        [self->_exportImageArray insertObject:scaledImage atIndex:frameNumber];
        
        [self->_progressView setProgress:(float)(frameNumber+1)/(float)kFrameCount animated:NO];
        
        if( frameNumber < kFrameCount-1 ) {
            [weakSelf addAnimationFrameToArray:(frameNumber+1) time:(time + kFrameDelay) complete:complete];
        } else {
            complete([self composeAnimatedGif]);
        }
    }];
}

#pragma mark - Export HQ image

static float const exportHQWidth = ImageExportHQWidth;
static int const exportHQTiles = ImageExportHQWidthTiles;
static float const exportTileWidth = 2.f * exportHQWidth / ((float)exportHQTiles);
static float const exportTileHeight = exportTileWidth * 9.f/16.f;

- (UIImage *) composeHQImage {
    CGSize size = CGSizeMake( 2.f * exportHQWidth, 2.f * exportHQWidth * 9.f/16.f );
    UIGraphicsBeginImageContextWithOptions(size, YES, 1.f);
    
    for( int frameNumber=0; frameNumber<exportHQTiles*exportHQTiles; frameNumber++ ){
        float x = (float)((int)(frameNumber/exportHQTiles)) * exportTileWidth;
        float y = (float)(exportHQTiles-1-(int)(frameNumber%exportHQTiles)) * exportTileHeight;
        UIImage* currentImage = [_exportImageArray objectAtIndex:frameNumber];
        [currentImage drawInRect:CGRectMake(x, y, exportTileWidth, exportTileHeight)];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [[image resizedImageWithMaximumSize:CGSizeMake(exportHQWidth, exportHQWidth)] setShaderWatermarkText:_shader];
}

- (void) addHQTileToArray:(int)frameNumber time:(float)time complete:(void (^)(UIImage *image))complete {
    __weak typeof (self) weakSelf = self;
    
    float scale = 1.f/(float)exportHQTiles;
    float x = (float)((int)(frameNumber/exportHQTiles)) * exportTileWidth;
    float y = (float)((int)(frameNumber%exportHQTiles)) * exportTileHeight;
    
    [_imageShaderViewController setFragCoordScale:scale andXOffset:x andYOffset:y];
    
    [_imageShaderViewController renderOneFrame:time success:^(UIImage *image) {
        [self->_exportImageArray insertObject:image atIndex:frameNumber];
        
        [self->_progressView setProgress:(float)(frameNumber+1)/(float)(exportHQTiles*exportHQTiles) animated:NO];
        
        if( frameNumber < (exportHQTiles*exportHQTiles)-1 ) {
            [weakSelf addHQTileToArray:(frameNumber+1) time:time complete:complete];
        } else {
            complete([self composeHQImage]);
        }
    }];
}

#pragma mark - Export image

- (void)exportImage:(BOOL) asGif {
    // set render frame size
    float width = ((int)([[UIScreen mainScreen] bounds].size.width/16/ImageExportHQWidthTiles))*16*ImageExportHQWidthTiles;
    _imageShaderView.frame = CGRectMake( _imageShaderView.frame.origin.x, _imageShaderView.frame.origin.y, width, width*9.f/16.f);
    
    NSString *text = [[[[@"Check out this \"" stringByAppendingString:_shader.shaderName] stringByAppendingString:@"\" shader by "] stringByAppendingString:_shader.username] stringByAppendingString:@" on @Shadertoy"];
    NSURL *url = [_shader getShaderUrl];
    ShaderCanvasViewController *shaderCanvasViewController = _imageShaderViewController;
    
    __weak typeof (self) weakSelf = self;
    
    _exportImageArray = [[NSMutableArray alloc] initWithCapacity:kFrameCount];
    
    if( asGif ) {
        // gif export
        UIAlertController* alert =[self createProgressAlert:@"Exporting animated GIF"];
        [self presentViewController:alert animated:YES completion:nil];
        
        [_imageShaderViewController setCanvasScaleFactor: 2.f*ImageExportGIFWidth / _imageShaderView.frame.size.width ];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self addAnimationFrameToArray:0 time:[self->_imageShaderViewController getIGlobalTime]complete:^(NSURL *fileURL) {
                [alert dismissViewControllerAnimated:YES completion:nil];
                
                [weakSelf shareText:text andImage:[NSData dataWithContentsOfURL:fileURL] andUrl:url];
                [shaderCanvasViewController setDefaultCanvasScaleFactor];
            }];
        });
    } else {
        // normal export
        UIAlertController* alert =[self createProgressAlert:@"Exporting HQ image"];
        [self presentViewController:alert animated:YES completion:nil];
        
        [_imageShaderViewController setCanvasScaleFactor: exportTileWidth / _imageShaderView.frame.size.width ];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self addHQTileToArray:0 time:[self->_imageShaderViewController getIGlobalTime]complete:^(UIImage *image) {
                [alert dismissViewControllerAnimated:YES completion:nil];
                
                [weakSelf shareText:text andImage:(NSData *)image andUrl:url];
                [shaderCanvasViewController setDefaultCanvasScaleFactor];
            }];
        });
    }
    
    if( asGif ) {
        trackEvent(@"ExportImage", @"GIF", _shader.shaderId);
    } else {
        trackEvent(@"ExportImage", @"HQ", _shader.shaderId);
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

#pragma mark - Keyboard input

- (void)initButtonEvents {
    [self.keyboardDownButton setTag:1];
    [self.keyboardDownButton addTarget:self action:@selector(keydown:) forControlEvents:UIControlEventTouchDown];
    [self.keyboardDownButton addTarget:self action:@selector(keyup:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    [self.keyboardUpButton setTag:2];
    [self.keyboardUpButton addTarget:self action:@selector(keydown:) forControlEvents:UIControlEventTouchDown];
    [self.keyboardUpButton addTarget:self action:@selector(keyup:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    [self.keyboardLeftButton setTag:3];
    [self.keyboardLeftButton addTarget:self action:@selector(keydown:) forControlEvents:UIControlEventTouchDown];
    [self.keyboardLeftButton addTarget:self action:@selector(keyup:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    [self.keyboardRightButton setTag:4];
    [self.keyboardRightButton addTarget:self action:@selector(keydown:) forControlEvents:UIControlEventTouchDown];
    [self.keyboardRightButton addTarget:self action:@selector(keyup:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    
    [self.keyboardSpaceButton setTag:5];
    [self.keyboardSpaceButton addTarget:self action:@selector(keydown:) forControlEvents:UIControlEventTouchDown];
    [self.keyboardSpaceButton addTarget:self action:@selector(keyup:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
}

- (void)keydown:(id) button {
    /*
     const float KEY_W		= 87.5/256.0;
     const float KEY_A		= 65.5/256.0;
     const float KEY_S		= 83.5/256.0;
     const float KEY_D		= 68.5/256.0;
     const float KEY_LEFT  = 37.5/256.0;
     const float KEY_UP    = 38.5/256.0;
     const float KEY_RIGHT = 39.5/256.0;
     const float KEY_DOWN  = 40.5/256.0;
     const float KEY_SPACE	= 32.5/256.0;
     const float KEY_ENTER = 13.5/256.0;
     */
    if( [button tag] == 1 ) [_imageShaderViewController updateKeyboardBufferDown: 83 ];
    if( [button tag] == 1 ) [_imageShaderViewController updateKeyboardBufferDown: 40 ];
    if( [button tag] == 2 ) [_imageShaderViewController updateKeyboardBufferDown: 87 ];
    if( [button tag] == 2 ) [_imageShaderViewController updateKeyboardBufferDown: 38 ];
    if( [button tag] == 3 ) [_imageShaderViewController updateKeyboardBufferDown: 65 ];
    if( [button tag] == 3 ) [_imageShaderViewController updateKeyboardBufferDown: 37 ];
    if( [button tag] == 4 ) [_imageShaderViewController updateKeyboardBufferDown: 68 ];
    if( [button tag] == 4 ) [_imageShaderViewController updateKeyboardBufferDown: 39 ];
    if( [button tag] == 5 ) [_imageShaderViewController updateKeyboardBufferDown: 32 ];
    if( [button tag] == 5 ) [_imageShaderViewController updateKeyboardBufferDown: 13 ];
}

- (void)keyup:(id) button {
    if( [button tag] == 1 ) [_imageShaderViewController updateKeyboardBufferUp: 83 ];
    if( [button tag] == 1 ) [_imageShaderViewController updateKeyboardBufferUp: 40 ];
    if( [button tag] == 2 ) [_imageShaderViewController updateKeyboardBufferUp: 87 ];
    if( [button tag] == 2 ) [_imageShaderViewController updateKeyboardBufferUp: 38 ];
    if( [button tag] == 3 ) [_imageShaderViewController updateKeyboardBufferUp: 65 ];
    if( [button tag] == 3 ) [_imageShaderViewController updateKeyboardBufferUp: 37 ];
    if( [button tag] == 4 ) [_imageShaderViewController updateKeyboardBufferUp: 68 ];
    if( [button tag] == 4 ) [_imageShaderViewController updateKeyboardBufferUp: 39 ];
    if( [button tag] == 5 ) [_imageShaderViewController updateKeyboardBufferUp: 32 ];
    if( [button tag] == 5 ) [_imageShaderViewController updateKeyboardBufferUp: 13 ];
}

@end
