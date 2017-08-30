//
//  ShaderCanvasInputController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 06/12/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import "ShaderInput.h"

#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>

#import <AVFoundation/AVFoundation.h>
#include <Accelerate/Accelerate.h>

#import "Utils.h"
#import "APISoundCloud.h"

#import "ShaderPassRenderer.h"
#include "TextureHelper.h"

#pragma mark - TapContext

typedef struct TapContext {
    void *audioTap;
    Float64 sampleRate;
    UInt32 numSamples;
    FFTSetup fftSetup;
    COMPLEX_SPLIT split;
    float *window;
    float *inReal;
    
    float * tempBuffer;
    unsigned char * output;    
} TapContext;


#pragma mark - AudioTap Callbacks

static void TapInit(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut)
{
    TapContext *context = calloc(1, sizeof(TapContext));
    context->audioTap = clientInfo;
    context->sampleRate = NAN;
    context->numSamples = 4096;
    
    vDSP_Length log2n = log2f((float)context->numSamples);
    
    int nOver2 = context->numSamples/2;
    
    context->inReal = (float *) malloc(context->numSamples * sizeof(float));
    context->split.realp = (float *) malloc(nOver2*sizeof(float));
    context->split.imagp = (float *) malloc(nOver2*sizeof(float));
    
    context->tempBuffer =(float *) malloc(context->numSamples * sizeof(float));
    context->output = (unsigned char *) malloc(512 * sizeof(unsigned char));
    
    context->fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    
    context->window = (float *) malloc(context->numSamples * sizeof(float));
    vDSP_hann_window(context->window, context->numSamples, vDSP_HANN_DENORM);
    
    *tapStorageOut = context;
}

static void TapPrepare(MTAudioProcessingTapRef tap, CMItemCount numberFrames, const AudioStreamBasicDescription *format)
{
    TapContext *context = (TapContext *)MTAudioProcessingTapGetStorage(tap);
    context->sampleRate = format->mSampleRate;
    
    if (format->mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
        NSLog(@"is Non Interleaved");
    }
    
    if (format->mFormatFlags & kAudioFormatFlagIsSignedInteger) {
        NSLog(@"dealing with integers");
    }
}


static  void TapProcess(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags,
                        AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut)
{
    OSStatus status;
    
    status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);
    if (status != noErr) {
        NSLog(@"MTAudioProcessingTapGetSourceAudio: %d", (int)status);
        return;
    }
    
    //UInt32 bufferCount = bufferListInOut->mNumberBuffers;
    
    AudioBuffer *firstBuffer = &bufferListInOut->mBuffers[1];
    
    float *bufferData = firstBuffer->mData;
    //UInt32 dataSize = firstBuffer->mDataByteSize;
    //printf(": %li", dataSize);
    
    
    TapContext *context = (TapContext *)MTAudioProcessingTapGetStorage(tap);
    
    vDSP_vmul(bufferData, 1, context->window, 1, context->inReal, 1, context->numSamples);
    
    vDSP_ctoz((COMPLEX *)context->inReal, 2, &context->split, 1, context->numSamples/2);
    
    
    vDSP_Length log2n = log2f((float)context->numSamples);
    vDSP_fft_zrip(context->fftSetup, &context->split, 1, log2n, FFT_FORWARD);
    context->split.imagp[0] = 0.0;
    
    const float one = 1;
    float scale = (float)1.0 / (2 * context->numSamples);
    
    
    vDSP_vsmul(context->split.realp, 1, &scale, context->split.realp, 1, context->numSamples/2);
    vDSP_vsmul(context->split.imagp, 1, &scale, context->split.imagp, 1, context->numSamples/2);
    
    //Zero out the nyquist value
    context->split.imagp[0] = 0.0;
    
    //Convert the fft data to dB
    vDSP_zvmags(&context->split, 1, context->tempBuffer, 1, context->numSamples/2);
    
    
    //In order to avoid taking log10 of zero, an adjusting factor is added in to make the minimum value equal -128dB
    //      vDSP_vsadd(obtainedReal, 1, &kAdjust0DB, obtainedReal, 1, frameCount/2);
    vDSP_vdbcon(context->tempBuffer, 1, &one, context->tempBuffer, 1, context->numSamples/2, 0);
    
    // min decibels is set to -100
    // max decibels is set to -30
    // calculated range is -128 to 0, so adjust:
    float addvalue = 74;
    vDSP_vsadd(context->tempBuffer, 1, &addvalue, context->tempBuffer, 1, context->numSamples/2);
    scale = 5.f; //256.f / frameCount;
    vDSP_vsmul(context->tempBuffer, 1, &scale, context->tempBuffer, 1, context->numSamples/2);
    
    float vmin = 0;
    float vmax = 255;
    
    vDSP_vclip(context->tempBuffer, 1, &vmin, &vmax, context->tempBuffer, 1, context->numSamples/2);
    vDSP_vfixu8(context->tempBuffer, 1, context->output, 1, MIN(256,context->numSamples/2));
    
    memcpy(context->tempBuffer, bufferData, context->numSamples * sizeof(float));

    addvalue = 1.;
    vDSP_vsadd(context->tempBuffer, 1, &addvalue, context->tempBuffer, 1, MIN(256,context->numSamples/2));
    scale = 128.f;
    vDSP_vsmul(context->tempBuffer, 1, &scale, context->tempBuffer, 1, MIN(256,context->numSamples/2));
    vDSP_vclip(context->tempBuffer, 1, &vmin, &vmax, context->tempBuffer, 1,  MIN(256,context->numSamples/2));
    vDSP_vfixu8(context->tempBuffer, 1, &context->output[256], 1, MIN(256,context->numSamples/2));
    
    ShaderInput *audioTap = (__bridge ShaderInput *)context->audioTap;
    [audioTap updateSpectrum:context->output];
}

static void TapUnprepare(MTAudioProcessingTapRef tap)
{
    
}

static void TapFinalize(MTAudioProcessingTapRef tap)
{
    TapContext *context = (TapContext *)MTAudioProcessingTapGetStorage(tap);
    
    free(context->split.realp);
    free(context->split.imagp);
    free(context->inReal);
    free(context->window);
    
    free(context->tempBuffer);
    free(context->output);
    
    context->fftSetup = nil;
    context->audioTap = nil;
    free(context);
}

@interface ShaderInput () {
    APIShaderPassInput *_shaderPassInput;
    
    ShaderInputType _type;
    ShaderInputFilterMode _filterMode;
    ShaderInputWrapMode _wrapMode;
    
    TextureHelper *_textureHelper;
    
    float _iChannelTime;
    float _iChannelResolutionWidth;
    float _iChannelResolutionHeight;
    int _channelSlot;
    
    unsigned char *_buffer;
    AVPlayer* _avplayer;
}
@end


@implementation ShaderInput

- (void) initWithShaderPassInput:(APIShaderPassInput *)input {
    _shaderPassInput = input;
    _buffer = NULL;
    _channelSlot = MAX( MIN( (int)[input.channel integerValue], 3 ), 0);
    
    bool vflip = NO;
    bool srgb = NO;
    
    if( input.sampler ) {
        if( [input.sampler.filter isEqualToString:@"nearest"] ) {
            _filterMode = NEAREST;
        } else if( [input.sampler.filter isEqualToString:@"linear"] ) {
            _filterMode = LINEAR;
        } else {
            _filterMode = MIPMAP;
        }
        
        if( [input.sampler.wrap isEqualToString:@"clamp"] ) {
            _wrapMode = CLAMP;
        } else {
            _wrapMode = REPEAT;
        }
        
        srgb = [input.sampler.srgb isEqualToString:@"true"];
        vflip = [input.sampler.vflip isEqualToString:@"true"];
    }
    
    NSDictionary *mapping = @{
                              @"/media/a/10eb4fe0ac8a7dc348a2cc282ca5df1759ab8bf680117e4047728100969e7b43.jpg": @"tex00.jpg",
                              @"/media/a/cd4c518bc6ef165c39d4405b347b51ba40f8d7a065ab0e8d2e4f422cbc1e8a43.jpg": @"tex01.jpg",
                              @"/media/a/95b90082f799f48677b4f206d856ad572f1d178c676269eac6347631d4447258.jpg": @"tex02.jpg",
                              @"/media/a/e6e5631ce1237ae4c05b3563eda686400a401df4548d0f9fad40ecac1659c46c.jpg": @"tex03.jpg",
                              @"/media/a/8de3a3924cb95bd0e95a443fff0326c869f9d4979cd1d5b6e94e2a01f5be53e9.jpg": @"tex04.jpg",
                              @"/media/a/1f7dca9c22f324751f2a5a59c9b181dfe3b5564a04b724c657732d0bf09c99db.jpg": @"tex05.jpg",
                              @"/media/a/fb918796edc3d2221218db0811e240e72e340350008338b0c07a52bd353666a6.jpg": @"tex06.jpg",
                              @"/media/a/52d2a8f514c4fd2d9866587f4d7b2a5bfa1a11a0e772077d7682deb8b3b517e5.jpg": @"tex07.jpg",
                              @"/media/a/bd6464771e47eed832c5eb2cd85cdc0bfc697786b903bfd30f890f9d4fc36657.jpg": @"tex08.jpg",
                              @"/media/a/92d7758c402f0927011ca8d0a7e40251439fba3a1dac26f5b8b62026323501aa.jpg": @"tex09.jpg",
                              @"/media/a/0a40562379b63dfb89227e6d172f39fdce9022cba76623f1054a2c83d6c0ba5d.png": @"tex10.png",
                              @"/media/a/3083c722c0c738cad0f468383167a0d246f91af2bfa373e9c5c094fb8c8413e0.png": @"tex11.png",
                              @"/media/a/0c7bf5fe9462d5bffbd11126e82908e39be3ce56220d900f633d58fb432e56f5.png": @"tex12.png",
                              @"/media/a/cbcbb5a6cfb55c36f8f021fbb0e3f69ac96339a39fa85cd96f2017a2192821b5.png": @"tex14.png",
                              @"/media/a/85a6d68622b36995ccb98a89bbb119edf167c914660e4450d313de049320005c.png": @"tex15.png",
                              @"/media/a/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png": @"tex16.png",
                              @"/media/a/3871e838723dd6b166e490664eead8ec60aedd6b8d95bc8e2fe3f882f0fd90f0.jpg": @"tex17.jpg",
                              @"/media/a/79520a3d3a0f4d3caa440802ef4362e99d54e12b1392973e4ea321840970a88a.jpg": @"tex18.jpg",
                              @"/media/a/ad56fba948dfba9ae698198c109e71f118a54d209c0ea50d77ea546abad89c57.png": @"tex19.png",
                              @"/media/a/8979352a182bde7c3c651ba2b2f4e0615de819585cc37b7175bcefbca15a6683.jpg": @"tex20.jpg",
                              @"/media/a/08b42b43ae9d3c0605da11d0eac86618ea888e62cdd9518ee8b9097488b31560.png": @"tex21.png",
                              
                              @"/media/a/585f9546c092f53ded45332b343144396c0b2d70d9965f585ebc172080d8aa58.jpg": @"cube00_0.jpg",
                              @"/media/a/793a105653fbdadabdc1325ca08675e1ce48ae5f12e37973829c87bea4be3232.png": @"cube01_0.png",
                              @"/media/a/488bd40303a2e2b9a71987e48c66ef41f5e937174bf316d3ed0e86410784b919.jpg": @"cube02_0.jpg",
                              @"/media/a/550a8cce1bf403869fde66dddf6028dd171f1852f4a704a465e1b80d23955663.png": @"cube03_0.png",
                              @"/media/a/94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0.png": @"cube04_0.png",
                              @"/media/a/0681c014f6c88c356cf9c0394ffe015acc94ec1474924855f45d22c3e70b5785.png": @"cube05_0.png",
                              
                              @"/media/a/c3a071ecf273428bc72fc72b2dd972671de8da420a2d4f917b75d20e1c24b34c.ogv": @"vid00.png",
                              @"/media/a/e81e818ac76a8983d746784b423178ee9f6cdcdf7f8e8d719341a6fe2d2ab303.webm": @"vid01.png",
                              @"/media/a/3405e48f74815c7baa49133bdc835142948381fbe003ad2f12f5087715731153.ogv": @"vid02.png",
                              @"/media/a/35c87bcb8d7af24c54d41122dadb619dd920646a0bd0e477e7bdc6d12876df17.webm": @"vid03.png",
                              
                              @"webcam": @"webcam.png",
                              @"music": @"music.png"
                              };
    
    if( [input.ctype isEqualToString:@"buffer"] ) {
        _type = BUFFER;
    }
    
    // video, music, webcam and keyboard is not implemented, so deliver dummy textures instead
    if( [input.ctype isEqualToString:@"keyboard"] ) {
        _textureHelper = [[TextureHelper alloc] initWithType:KEYBOARD vFlip:vflip sRGB:srgb wrapMode:_wrapMode filterMode:_filterMode];
        _type = KEYBOARD;
    }
    
    if( [input.ctype isEqualToString:@"video"] ) {
        _type = TEXTURE2D;
    }
    
    if( [input.ctype isEqualToString:@"music"] || [input.ctype isEqualToString:@"musicstream"] || [input.ctype isEqualToString:@"webcam"] ) {
        if( [input.ctype isEqualToString:@"music"] || [input.ctype isEqualToString:@"musicstream"]) {
            if( [input.ctype isEqualToString:@"musicstream"] ) {
                _type = SOUNDCLOUD;
                APISoundCloud* soundCloud = [[APISoundCloud alloc] init];
                [soundCloud resolve:input.src success:^(NSDictionary *resultDict) {
                    NSString* url = [resultDict objectForKey:@"stream_url"];
                    url = [url stringByAppendingString:@"?client_id=64a52bb31abd2ec73f8adda86358cfbf"];
                    [self playUrl:url];
                }];
            } else {
                _type = MUSIC;
                NSString *url = [@"https://www.shadertoy.com" stringByAppendingString:input.src];
                [self playUrl:url];
            }
            _textureHelper = [[TextureHelper alloc] initWithType:MUSIC vFlip:vflip sRGB:srgb wrapMode:_wrapMode filterMode:_filterMode];
        } else {
            _type = TEXTURE2D;
        }
    }
    
    if( _type == TEXTURE2D || [input.ctype isEqualToString:@"texture"] || [input.ctype isEqualToString:@"cubemap"] ) {
        _type = [input.ctype isEqualToString:@"cubemap"] ? TEXTURECUBE : TEXTURE2D;
        
        if( [mapping objectForKey:input.src] ) {
            NSString* file = [@"./presets/" stringByAppendingString:mapping[input.src]];
            file = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:file];
            
            _textureHelper = [[TextureHelper alloc] initWithType:_type vFlip:vflip sRGB:srgb wrapMode:_wrapMode filterMode:_filterMode];
            [_textureHelper loadFromFile:file];
        } else {
            NSString* file = [@"http://www.shadertoy.com/" stringByAppendingString:input.src];
            
            _textureHelper = [[TextureHelper alloc] initWithType:_type vFlip:vflip sRGB:srgb wrapMode:_wrapMode filterMode:_filterMode];
            [_textureHelper loadFromURL:file];
        }
    }
}

- (void) bindTexture:(NSMutableArray *)shaderPasses keyboardBuffer:(unsigned char*)keyboardBuffer {
    // NSLog(@"Bind input %s to %d", [_shaderPassInput.src cStringUsingEncoding:NSUTF8StringEncoding], _channelSlot );
    
    glActiveTexture(GL_TEXTURE0 + _channelSlot);
    
    if( _type == BUFFER ) {
        NSNumber *inputId = _shaderPassInput.inputId;
        
        for( ShaderPassRenderer *shaderPass in shaderPasses ) {
            if( [inputId integerValue] == [[shaderPass getOutputId] integerValue] ) {
                glBindTexture(GL_TEXTURE_2D, [shaderPass getCurrentTexId]);
                if( _filterMode == NEAREST ) {
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
                } else {
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                }
                _iChannelResolutionWidth = [shaderPass getWidth];
                _iChannelResolutionHeight = [shaderPass getHeight];
                
            }
        }
    }
    else if( _textureHelper ) {
        if( [_textureHelper getType] == KEYBOARD ) {
            [_textureHelper loadData:keyboardBuffer width:256 height:2 channels:1];
        }
        else if( [_textureHelper getType] == MUSIC ) {
            [_textureHelper loadData:_buffer width:256 height:2 channels:1];
        }
        
        [_textureHelper bindToChannel:_channelSlot];
        
        _iChannelResolutionWidth = [_textureHelper getWidth];
        _iChannelResolutionHeight = [_textureHelper getHeight];
    }
}

- (void) playUrl:(NSString*) url {
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    AVPlayerItem* item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
    
    AVMutableAudioMixInputParameters *inputParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:item.asset.tracks[0]];
    
    //MTAudioProcessingTap
    MTAudioProcessingTapCallbacks callbacks;
    
    callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
    
    callbacks.init = TapInit;
    callbacks.prepare = TapPrepare;
    callbacks.process = TapProcess;
    callbacks.unprepare = TapUnprepare;
    callbacks.finalize = TapFinalize;
    callbacks.clientInfo = (__bridge void *)self;
    
    MTAudioProcessingTapRef tapRef;
    OSStatus err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks,
                                              kMTAudioProcessingTapCreationFlag_PostEffects, &tapRef);
    
    if (err || !tapRef) {
        NSLog(@"Unable to create AudioProcessingTap.");
        return;
    }
    
    
    inputParams.audioTapProcessor = tapRef;
    
    // Create a new AVAudioMix and assign it to our AVPlayerItem
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = @[inputParams];
    item.audioMix = audioMix;
    
    _avplayer = [AVPlayer playerWithPlayerItem:item];
    [_avplayer play];
}

- (void) updateSpectrum:(unsigned char *)data {
    _buffer = data;
}

- (void) mute {
    
}

- (void) pause {
    if( _avplayer ) {
        [_avplayer pause];
    }
}

- (void) play {
    if( _avplayer ) {
        [_avplayer play];
    }
}

- (void) rewindTo:(double)time {
    if( _avplayer ) {
        [_avplayer seekToTime:CMTimeMakeWithSeconds(time,120)];
    }
}

- (void) dealloc {
    if( _textureHelper ) {
        _textureHelper = nil;
    }
    if( _avplayer ) {
        AVMutableAudioMixInputParameters *params = (AVMutableAudioMixInputParameters *) _avplayer.currentItem.audioMix.inputParameters[0];
        MTAudioProcessingTapRef tap = params.audioTapProcessor;
        _avplayer.currentItem.audioMix = nil;
        _avplayer = nil;
        CFRelease(tap);
    }
}

- (float) getResolutionWidth {
    return _iChannelResolutionWidth;
}

- (float) getResolutionHeight {
    return _iChannelResolutionHeight;
}

- (int) getChannel {
    return [[_shaderPassInput channel] intValue];
}

@end
