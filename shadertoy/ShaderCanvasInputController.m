//
//  ShaderCanvasInputController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 06/12/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import "ShaderCanvasInputController.h"

#import <GLKit/GLKit.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#import <AVFoundation/AVAudioPlayer.h>
#import <StreamingKit/STKAudioPlayer.h>

#include <Accelerate/Accelerate.h>

#import "Utils.h"


@interface ShaderCanvasInputController () {
    GLKTextureInfo *_textureInfo;
    STKAudioPlayer* _audioPlayer;
    
    ShaderInputFilterMode _filterMode;
    ShaderInputWrapMode _wrapMode;
    
    float _iChannelTime;
    float _iChannelResolutionWidth;
    float _iChannelResolutionHeight;
    
    int _channelSlot;
    
    
    float* window;
    float* obtainedReal;
    float* originalReal;
    unsigned char* buffer;
    int fftStride;
    
    FFTSetup setupReal;
    DSPSplitComplex fftInput;
    
    GLuint texId;
}
@end



@implementation ShaderCanvasInputController

- (void) initWithShaderPassInput:(APIShaderPassInput *)input {
    texId = 99;
    
    // video, music, webcam and keyboard is not implemented, so deliver dummy textures instead
    if( [input.ctype isEqualToString:@"video"] ) {
        input.src = [input.src stringByReplacingOccurrencesOfString:@".webm" withString:@".png"];
        input.src = [input.src stringByReplacingOccurrencesOfString:@".ogv" withString:@".png"];
        input.ctype = @"texture";
    }
    if( [input.ctype isEqualToString:@"music"] || [input.ctype isEqualToString:@"webcam"] || [input.ctype isEqualToString:@"keyboard"] ) {
        
        if( [input.ctype isEqualToString:@"music"] ) {
            _audioPlayer = [[STKAudioPlayer alloc] init];
            [self setupFFT];
            
            NSString *url = [@"https://www.shadertoy.com" stringByAppendingString:input.src];
            
            NSString *trackID = @"230240104";
            NSString *clientID = @"64a52bb31abd2ec73f8adda86358cfbf";
         //   url = [NSString stringWithFormat:@"https://api.soundcloud.com/tracks/%@/stream?client_id=%@", trackID, clientID];
            
            [_audioPlayer play:url];
            
            
            
            [_audioPlayer appendFrameFilterWithName:@"STKSpectrumAnalyzerFilter" block:^(UInt32 channelsPerFrame, UInt32 bytesPerFrame, UInt32 frameCount, void* frames) {
                
                
                 int log2n = log2f(frameCount);
                frameCount = 1 << log2n;
//                 int nOver2 = frameCount / 2;
                
           //     NSLog(@"frame count:%d, %d, %d\n", (unsigned int)frameCount, log2n, n);
                
                
                SInt16* samples16 = (SInt16*)frames;
                 SInt32* samples32 = (SInt32*)frames;
                 
                 if (bytesPerFrame / channelsPerFrame == 2)
                 {
                     for (int i = 0, j = 0; i < frameCount * channelsPerFrame; i+= channelsPerFrame, j++)
                     {
                         originalReal[j] = samples16[i] / 32768.0;
                     }
                 }
                 else if (bytesPerFrame / channelsPerFrame == 4)
                 {
                     for (int i = 0, j = 0; i < frameCount * channelsPerFrame; i+= channelsPerFrame, j++)
                     {
                         originalReal[j] = samples32[i] / 32768.0;
                     }
                 }
                 
                 vDSP_ctoz((COMPLEX*)originalReal, 2, &fftInput, 1, frameCount);
                
                
                const float one = 1;
                const Float32 kAdjust0DB = 1.5849e-13;
                
                float scale = (float)1.0 / (2 * frameCount);
                
                
                //Take the fft and scale appropriately
                 vDSP_fft_zrip(setupReal, &fftInput, 1, log2n, FFT_FORWARD);
                 vDSP_vsmul(fftInput.realp, 1, &scale, fftInput.realp, 1, frameCount/2);
                vDSP_vsmul(fftInput.imagp, 1, &scale, fftInput.imagp, 1, frameCount/2);
                
                //Zero out the nyquist value
                fftInput.imagp[0] = 0.0;
                
                //Convert the fft data to dB
                vDSP_zvmags(&fftInput, 1, obtainedReal, 1, frameCount/2);
                
                
                //In order to avoid taking log10 of zero, an adjusting factor is added in to make the minimum value equal -128dB
          //      vDSP_vsadd(obtainedReal, 1, &kAdjust0DB, obtainedReal, 1, frameCount/2);
                vDSP_vdbcon(obtainedReal, 1, &one, obtainedReal, 1, frameCount/2, 0);
                
                // min decibels is set to -100
                // max decibels is set to -30
                // calculated range is -128 to 0, so adjust:
                const float addvalue = 70;
                vDSP_vsadd(obtainedReal, 1, &addvalue, obtainedReal, 1, frameCount/2);
                scale = 5.f; //256.f / frameCount;
                vDSP_vsmul(obtainedReal, 1, &scale, obtainedReal, 1, frameCount/2);
                
                float vmin = 0;
                float vmax = 255;
                
                vDSP_vclip(obtainedReal, 1, &vmin, &vmax, obtainedReal, 1, frameCount/2);
                vDSP_vfixu8(obtainedReal, 1, buffer, 1, frameCount/2);
             }];
        }
        
   //     input.src = [[@"/presets/" stringByAppendingString:input.ctype] stringByAppendingString:@".png"];
   //     input.ctype = @"texture";
    }
    
    _channelSlot = MAX( MIN( (int)[input.channel integerValue], 3 ), 0);
    
    ShaderInputFilterMode filterMode = MIPMAP;
    ShaderInputWrapMode wrapMode = REPEAT;
    BOOL srgb = NO;
    BOOL vflip = NO;
    
    if( input.sampler ) {
        if( [input.sampler.filter isEqualToString:@"nearest"] ) {
            filterMode = NEAREST;
        } else if( [input.sampler.filter isEqualToString:@"linear"] ) {
            filterMode = LINEAR;
        } else {
            filterMode = MIPMAP;
        }
        
        if( [input.sampler.wrap isEqualToString:@"clamp"] ) {
            wrapMode = CLAMP;
        } else {
            wrapMode = REPEAT;
        }
        
        srgb = [input.sampler.srgb isEqualToString:@"true"];
        vflip = [input.sampler.vflip isEqualToString:@"true"];
    }
    
    _filterMode = filterMode;
    _wrapMode = wrapMode;
    
    
    if( [input.ctype isEqualToString:@"texture"] ) {
        // load texture to channel
        NSError *theError;
        
        NSString* file = [[@"." stringByAppendingString:input.src] stringByReplacingOccurrencesOfString:@".jpg" withString:@".png"];
        file = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:file];
        glGetError();
        
        GLKTextureInfo *spriteTexture = [GLKTextureLoader textureWithContentsOfFile:file options:@{GLKTextureLoaderGenerateMipmaps: [NSNumber numberWithBool:(filterMode == MIPMAP)],
                                                                                                   GLKTextureLoaderOriginBottomLeft: [NSNumber numberWithBool:vflip],
                                                                                                   GLKTextureLoaderSRGB: [NSNumber numberWithBool:srgb]
                                                                                                   } error:&theError];
        
        _textureInfo = spriteTexture;
        _iChannelResolutionWidth = [spriteTexture width];
        _iChannelResolutionHeight = [spriteTexture height];
    }
    if( [input.ctype isEqualToString:@"cubemap"] ) {
        // load texture to channel
        NSError *theError;
        
        NSString* file = [@"." stringByAppendingString:input.src];
        file = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:file];
        glGetError();
        
        GLKTextureInfo *spriteTexture = [GLKTextureLoader cubeMapWithContentsOfFile:file options:@{GLKTextureLoaderGenerateMipmaps: [NSNumber numberWithBool:(filterMode == MIPMAP)],
                                                                                                   GLKTextureLoaderOriginBottomLeft: [NSNumber numberWithBool:vflip],
                                                                                                   GLKTextureLoaderSRGB: [NSNumber numberWithBool:srgb]
                                                                                                   } error:&theError];
        
        _textureInfo = spriteTexture;
        _iChannelResolutionWidth = [spriteTexture width];
        _iChannelResolutionHeight = [spriteTexture height];
    }
}

- (void) bindTexture {
    if( _textureInfo ) {
        glActiveTexture(GL_TEXTURE0 + _channelSlot);
        glBindTexture(_textureInfo.target, _textureInfo.name );
        
        if( _textureInfo.target == GL_TEXTURE_2D ) {
            if( _wrapMode == REPEAT ) {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
            } else {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
            
            if( _filterMode == NEAREST ) {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            } else if( _filterMode == MIPMAP ) {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            } else {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            }
        }
    }
    if( texId < 99 ) {
        glActiveTexture(GL_TEXTURE0 + _channelSlot);
        glBindTexture(GL_TEXTURE_2D, texId);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, 256, 1, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, buffer);
        if( _wrapMode == REPEAT ) {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        } else {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
        
        if( _filterMode == NEAREST ) {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        } else if( _filterMode == MIPMAP ) {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        } else {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        }
    }
}
/*
glGenTextures(1, &n_tex_surface);
glBindTexture(GL_TEXTURE_2D, n_tex_surface);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

glBindTexture(GL_TEXTURE_2D, n_tex_surface);
glTexImage2D(GL_TEXTURE_2D, 0, GL_R32F, datawidth, dataheight, 0, GL_RED, GL_FLOAT, checkImage);
*/


- (void) mute {
    
}

- (void) pause {
    if( _audioPlayer ) {
        [_audioPlayer pause];
    }
}

- (void) play {
    if( _audioPlayer ) {
        [_audioPlayer resume];
    }
}

- (void) rewindTo:(double)time {
    if( _audioPlayer ) {
        [_audioPlayer seekToTime:time];
    }
}




- (void) dealloc {
    if( _textureInfo ) {
        GLuint name = _textureInfo.name;
        glDeleteTextures(1, &name);
        _textureInfo = nil;
    }
    if( _audioPlayer ) {
        [_audioPlayer stop];
        [_audioPlayer dispose];
        _audioPlayer = nil;
    }
    
}



- (void) setupFFT {
    int maxSamples = 4096;
    int log2n = log2f(maxSamples);
    int n = 1 << log2n;

    NSLog(@"N = %d\n",n);
    
    fftStride = 1;
    int nOver2 = maxSamples / 2;

    fftInput.realp = (float*)calloc(nOver2, sizeof(float));
    fftInput.imagp =(float*)calloc(nOver2, sizeof(float));

    obtainedReal = (float*)calloc(n, sizeof(float));
    originalReal = (float*)calloc(n, sizeof(float));
    window = (float*)calloc(maxSamples, sizeof(float));
    buffer = (unsigned char*)calloc(n, sizeof(unsigned char));

    vDSP_blkman_window(window, maxSamples, 0);

    setupReal = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    
    glGenTextures(1, &texId);
    glBindTexture(GL_TEXTURE_2D, texId);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
}

@end
