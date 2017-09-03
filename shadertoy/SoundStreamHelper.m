//
//  SoundStreamHelper.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 03/09/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import "SoundStreamHelper.h"

#import <AVFoundation/AVFoundation.h>
#include <Accelerate/Accelerate.h>

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
    
    SoundStreamHelper *audioTap = (__bridge SoundStreamHelper *)context->audioTap;
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


@interface SoundStreamHelper () {
    AVPlayer* _avplayer;
    __weak typeof (ShaderInput *) _shaderInput;
}
@end

@implementation SoundStreamHelper


- (id) initWithShaderInput:(ShaderInput *) shaderInput {
    self = [super init];
    if(self){
        _shaderInput = shaderInput;
    }
    return self;
}

- (void) playUrl:(NSString*) url {
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    AVPlayerItem* item = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
    
    if([item.asset.tracks count] > 0 ) {
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

- (float) getTime {
    if( _avplayer ) {
        return (float)[_avplayer currentTime].value / (float)[_avplayer currentTime].timescale;
    }
    return 0.f;
}

- (void) dealloc {
    if( _avplayer ) {
        AVMutableAudioMixInputParameters *params = (AVMutableAudioMixInputParameters *) _avplayer.currentItem.audioMix.inputParameters[0];
        MTAudioProcessingTapRef tap = params.audioTapProcessor;
        _avplayer.currentItem.audioMix = nil;
        _avplayer = nil;
        CFRelease(tap);
    }
}

- (void) updateSpectrum:(unsigned char *)data {
    [_shaderInput updateSpectrum:data];
}

@end
