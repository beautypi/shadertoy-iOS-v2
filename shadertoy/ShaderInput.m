//
//  ShaderCanvasInputController.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 06/12/15.
//  Copyright © 2015 Reinder Nijhoff. All rights reserved.
//

#import "ShaderInput.h"

#import <GLKit/GLKit.h>
#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>

#import <AVFoundation/AVFoundation.h>
#import <StreamingKit/STKAudioPlayer.h>

#include <Accelerate/Accelerate.h>

#import "Utils.h"
#import "APISoundCloud.h"

#import "ShaderPassRenderer.h"



@interface ShaderInput () {
    GLKTextureInfo *_textureInfo;
    STKAudioPlayer *_audioPlayer;
    APIShaderPassInput *_shaderPassInput;
    
    ShaderInputFilterMode _filterMode;
    ShaderInputWrapMode _wrapMode;
    bool vflip;
    bool srgb;
    
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
    
    STKAudioPlayerOptions options;
    
    bool _isBuffer;
}
@end


@implementation ShaderInput

- (void) initWithShaderPassInput:(APIShaderPassInput *)input {
    _shaderPassInput = input;
    texId = 99;
    buffer = NULL;
    _isBuffer = [input.ctype isEqualToString:@"buffer"];
    
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
                     @"/media/a/cbcbb5a6cfb55c36f8f021fbb0e3f69ac96339a39fa85cd96f2017a2192821b5.png": @"tex14.jpg",
                     @"/media/a/0a40562379b63dfb89227e6d172f39fdce9022cba76623f1054a2c83d6c0ba5d.png": @"tex10.jpg",
                     @"/media/a/3083c722c0c738cad0f468383167a0d246f91af2bfa373e9c5c094fb8c8413e0.png": @"tex11.jpg",
                     @"/media/a/0c7bf5fe9462d5bffbd11126e82908e39be3ce56220d900f633d58fb432e56f5.png": @"tex12.jpg",
                     @"/media/a/85a6d68622b36995ccb98a89bbb119edf167c914660e4450d313de049320005c.png": @"tex15.jpg",
                     @"/media/a/f735bee5b64ef98879dc618b016ecf7939a5756040c2cde21ccb15e69a6e1cfb.png": @"tex16.jpg",
                     @"/media/a/3871e838723dd6b166e490664eead8ec60aedd6b8d95bc8e2fe3f882f0fd90f0.jpg": @"tex17.jpg",
                     @"/media/a/79520a3d3a0f4d3caa440802ef4362e99d54e12b1392973e4ea321840970a88a.jpg": @"tex18.jpg",
                     @"/media/a/ad56fba948dfba9ae698198c109e71f118a54d209c0ea50d77ea546abad89c57.png": @"tex19.jpg",
                     @"/media/a/8979352a182bde7c3c651ba2b2f4e0615de819585cc37b7175bcefbca15a6683.jpg": @"tex20.jpg",
                     @"/media/a/08b42b43ae9d3c0605da11d0eac86618ea888e62cdd9518ee8b9097488b31560.png": @"tex21.jpg",
                     
                     @"/media/a/585f9546c092f53ded45332b343144396c0b2d70d9965f585ebc172080d8aa58.jpg": @"cube00_0.jpg",
                     @"/media/a/793a105653fbdadabdc1325ca08675e1ce48ae5f12e37973829c87bea4be3232.png": @"cube00_1.jpg",
                     @"/media/a/488bd40303a2e2b9a71987e48c66ef41f5e937174bf316d3ed0e86410784b919.jpg": @"cube00_2.jpg",
                     @"/media/a/550a8cce1bf403869fde66dddf6028dd171f1852f4a704a465e1b80d23955663.png": @"cube00_3.jpg",
                     @"/media/a/94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0.png": @"cube00_4.jpg",
                     @"/media/a/0681c014f6c88c356cf9c0394ffe015acc94ec1474924855f45d22c3e70b5785.png": @"cube00_5.jpg",
                     
                     @"/media/a/c3a071ecf273428bc72fc72b2dd972671de8da420a2d4f917b75d20e1c24b34c.ogv": @"vid00.png",
                     @"/media/a/e81e818ac76a8983d746784b423178ee9f6cdcdf7f8e8d719341a6fe2d2ab303.webm": @"vid01.png",
                     @"/media/a/3405e48f74815c7baa49133bdc835142948381fbe003ad2f12f5087715731153.ogv": @"vid02.png",
                     @"/media/a/35c87bcb8d7af24c54d41122dadb619dd920646a0bd0e477e7bdc6d12876df17.webm": @"vid03.png"
       
    };
    
    if( [mapping objectForKey:input.src] ) {
        input.src = mapping[input.src];
    } else {
        NSLog(@"%@", input.src);
    }
    
    // video, music, webcam and keyboard is not implemented, so deliver dummy textures instead
    if( [input.ctype isEqualToString:@"keyboard"] ) {
        glGenTextures(1, &texId);
        glBindTexture(GL_TEXTURE_2D, texId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    }
    
    if( [input.ctype isEqualToString:@"video"] ) {
        input.src = [input.src stringByReplacingOccurrencesOfString:@".webm" withString:@".png"];
        input.src = [input.src stringByReplacingOccurrencesOfString:@".ogv" withString:@".png"];
        input.ctype = @"texture";
    }
    
    if( [input.ctype isEqualToString:@"music"] || [input.ctype isEqualToString:@"musicstream"] || [input.ctype isEqualToString:@"webcam"] ) {
        
        if( [input.ctype isEqualToString:@"music"] || [input.ctype isEqualToString:@"musicstream"]) {
            options.enableVolumeMixer = false;
            memset(options.equalizerBandFrequencies,0,4);
            options.flushQueueOnSeek = false;
            options.gracePeriodAfterSeekInSeconds = 0.25f;
            options.readBufferSize = 2048;
            options.secondsRequiredToStartPlaying = 0.25f;
            options.secondsRequiredToStartPlayingAfterBufferUnderun = 0;
            
            _audioPlayer = [[STKAudioPlayer alloc] initWithOptions:options];
            
            [self setupFFT];
            [_audioPlayer appendFrameFilterWithName:@"STKSpectrumAnalyzerFilter" block:^(UInt32 channelsPerFrame, UInt32 bytesPerFrame, UInt32 frameCount, void* frames) {
                
                int log2n = log2f(frameCount);
                frameCount = 1 << log2n;
                
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
                float addvalue = 70;
                vDSP_vsadd(obtainedReal, 1, &addvalue, obtainedReal, 1, frameCount/2);
                scale = 5.f; //256.f / frameCount;
                vDSP_vsmul(obtainedReal, 1, &scale, obtainedReal, 1, frameCount/2);
                
                float vmin = 0;
                float vmax = 255;
                
                vDSP_vclip(obtainedReal, 1, &vmin, &vmax, obtainedReal, 1, frameCount/2);
                vDSP_vfixu8(obtainedReal, 1, buffer, 1, MIN(256,frameCount/2));
                
                addvalue = 1.;
                vDSP_vsadd(originalReal, 1, &addvalue, originalReal, 1, MIN(256,frameCount/2));
                scale = 128.f;
                vDSP_vsmul(originalReal, 1, &scale, originalReal, 1, MIN(256,frameCount/2));
                vDSP_vclip(originalReal, 1, &vmin, &vmax, originalReal, 1,  MIN(256,frameCount/2));
                vDSP_vfixu8(originalReal, 1, &buffer[256], 1, MIN(256,frameCount/2));
            }];
            
            if( [input.ctype isEqualToString:@"musicstream"] ) {
                APISoundCloud* soundCloud = [[APISoundCloud alloc] init];
                [soundCloud resolve:input.src success:^(NSDictionary *resultDict) {
                    NSString* url = [resultDict objectForKey:@"stream_url"];
                    url = [url stringByAppendingString:@"?client_id=64a52bb31abd2ec73f8adda86358cfbf"];
                    
                    [_audioPlayer play:url];
                    for( int i=0; i<100; i++ ) {
                        [_audioPlayer queue:url];
                    }
                }];
            } else {
                NSString *url = [@"https://www.shadertoy.com" stringByAppendingString:input.src];
                [_audioPlayer play:url];
            }
            
        } else {
            input.src = [[@"/presets/" stringByAppendingString:input.ctype] stringByAppendingString:@".png"];
            input.ctype = @"texture";
        }
    }
    
    _channelSlot = MAX( MIN( (int)[input.channel integerValue], 3 ), 0);
    
    ShaderInputFilterMode filterMode = MIPMAP;
    ShaderInputWrapMode wrapMode = REPEAT;
    srgb = NO;
    vflip = NO;
    
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
        
        NSString* file = [[@"./presets/" stringByAppendingString:input.src] stringByReplacingOccurrencesOfString:@".jpg" withString:@".png"];
        file = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:file];
        glGetError();
        
        GLKTextureInfo *spriteTexture = [GLKTextureLoader textureWithContentsOfFile:file options:@{GLKTextureLoaderGenerateMipmaps: [NSNumber numberWithBool:(_filterMode == MIPMAP)],
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
        
        NSString* file = [@"./presets/" stringByAppendingString:input.src];
        file = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:file];
        glGetError();
        
        GLKTextureInfo *spriteTexture = [GLKTextureLoader cubeMapWithContentsOfFile:file options:@{GLKTextureLoaderGenerateMipmaps: [NSNumber numberWithBool:(_filterMode == MIPMAP)],
                                                                                                   GLKTextureLoaderOriginBottomLeft: [NSNumber numberWithBool:vflip],
                                                                                                   GLKTextureLoaderSRGB: [NSNumber numberWithBool:srgb]
                                                                                                   } error:&theError];
        
        _textureInfo = spriteTexture;
        _iChannelResolutionWidth = [spriteTexture width];
        _iChannelResolutionHeight = [spriteTexture height];
    }
}


- (void) bindTexture:(NSMutableArray *)shaderPasses keyboardBuffer:(unsigned char*)keyboardBuffer {
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
        
        _iChannelResolutionWidth = _textureInfo.width;
        _iChannelResolutionHeight = _textureInfo.height;
    }
    else if( texId < 99  ) {
        glActiveTexture(GL_TEXTURE0 + _channelSlot);
        glBindTexture(GL_TEXTURE_2D, texId);
        
        if( buffer != NULL ) {
            glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, 256, 2, 0, GL_RED, GL_UNSIGNED_BYTE, buffer);
        } else {
            glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, 256, 2, 0, GL_RED, GL_UNSIGNED_BYTE, keyboardBuffer);
        }
        
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
    else if(_isBuffer) {
        glActiveTexture(GL_TEXTURE0 + _channelSlot);
        
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
}

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

- (void) stop {
    if( _audioPlayer ) {
        [_audioPlayer removeFrameFilterWithName:@"STKSpectrumAnalyzerFilter"];
        [_audioPlayer stop];
        [_audioPlayer dispose];
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
