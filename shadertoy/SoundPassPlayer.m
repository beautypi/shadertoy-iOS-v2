//
//  SoudPassPlayer.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 31/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "SoundPassPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

const int bufferBlockSize = 256*256*4;
const int bufferNumBlocks = 10;
const float frameRate = 11025.;

OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData) {
    
    SoundPassPlayer *spp = (__bridge SoundPassPlayer *)inRefCon;
    unsigned char *_buffer = spp->buffer;
    
    for( int channel=0; channel<2; channel++ ) {
        Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
        
        UInt32 frameOffset = spp->startFrame + channel * 2;
        
        for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
            if( frameOffset < bufferBlockSize*bufferNumBlocks ) {
                float v = _buffer[ frameOffset + 0 ] + 256.*_buffer[ frameOffset + 1 ];
                buffer[ frame ] = v * (1. / (256. * 128.) ) - 1. ;
            } else {
                buffer[ frame ] = 0.f;
            }
            frameOffset += 4;
        }
    }
    spp->startFrame += inNumberFrames*4;
    
    return noErr;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState) {
//    SoundPassPlayer *SoundPassPlayer = (__bridge SoundPassPlayer *)inClientData;
}

@interface SoundPassPlayer () {
    AudioComponentInstance toneUnit;
}
@end

@implementation SoundPassPlayer

- (id)init {
    self = [super init];
    buffer = malloc( sizeof(unsigned char)*bufferBlockSize*bufferNumBlocks );
    startFrame = 0;
    return self;
}

- (void)dealloc {
    [self stop];
    AudioComponentInstanceDispose(toneUnit);
    toneUnit = nil;
    free( buffer );
}

- (void) fillSoundBufferFromImage:(UIImage *)image block:(NSInteger)block {
    long int size = bufferBlockSize;
    CFDataRef cgdata = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    memcpy( &buffer[ size*block ], CFDataGetBytePtr(cgdata), size );
    CFRelease(cgdata);
}

- (void) prepareToPlay {
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    AudioComponentInstanceNew(defaultOutput, &toneUnit);
    
    AURenderCallbackStruct input;
    input.inputProc = RenderTone;
    input.inputProcRefCon = (__bridge void *)(self);
    AudioUnitSetProperty(toneUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         0,
                         &input,
                         sizeof(input));
    
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = frameRate;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamFormat.mBytesPerPacket = 4;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = 4;
    streamFormat.mChannelsPerFrame = 2;
    streamFormat.mBitsPerChannel = 4 * 8;
    AudioUnitSetProperty (toneUnit,
                          kAudioUnitProperty_StreamFormat,
                          kAudioUnitScope_Input,
                          0,
                          &streamFormat,
                          sizeof(AudioStreamBasicDescription));
    
    return;
}

- (void) play {
    AudioUnitInitialize(toneUnit);
    AudioOutputUnitStart(toneUnit);
}

- (void) stop {
    AudioOutputUnitStop(toneUnit);
    AudioUnitUninitialize(toneUnit);
}

- (void) setTime:(float)time {
    startFrame = 4*(UInt32)(frameRate*time);
}

@end
