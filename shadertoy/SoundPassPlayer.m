//
//  SoudPassPlayer.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 31/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "SoundPassPlayer.h"
#import <AVFoundation/AVAudioPlayer.h>

@interface SoundPassPlayer () {
    AVAudioPlayer *avap1;
    unsigned char *_buffer;
}
@end

const int bufferBlockSize = 256*256*4;
const int bufferNumBlocks = 10;

@implementation SoundPassPlayer

- (id)init {
    self = [super init];
    _buffer = malloc( sizeof(unsigned char)*bufferBlockSize*bufferNumBlocks );
    return self;
}

- (void)dealloc {
    free(_buffer);
}

- (void) fillSoundBufferFromImage:(UIImage *)image block:(NSInteger)block {    
    long int size =bufferBlockSize;
    memcpy( &_buffer[ size*block ], CFDataGetBytePtr(CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage))), size );
}

- (void) prepareToPlay {
    NSData* data = [NSData dataWithBytes:_buffer length:bufferBlockSize*bufferNumBlocks];
    
    unsigned long totalAudioLen=[data length];
    unsigned long totalDataLen = totalAudioLen + 44;
    unsigned long longSampleRate = 11025.;
    unsigned int channels = 2;
    unsigned long byteRate = (16 * longSampleRate * channels)/8;
    
    Byte *header = (Byte*)malloc(44);
    header[0] = 'R';  // RIFF/WAVE header
    header[1] = 'I';
    header[2] = 'F';
    header[3] = 'F';
    header[4] = (Byte) ((totalDataLen+36) & 0xff);
    header[5] = (Byte) (((totalDataLen+36) >> 8) & 0xff);
    header[6] = (Byte) (((totalDataLen+36) >> 16) & 0xff);
    header[7] = (Byte) (((totalDataLen+36) >> 24) & 0xff);
    header[8] = 'W';
    header[9] = 'A';
    header[10] = 'V';
    header[11] = 'E';
    header[12] = 'f';  // 'fmt ' chunk
    header[13] = 'm';
    header[14] = 't';
    header[15] = ' ';
    header[16] = 16;  // 4 bytes: size of 'fmt ' chunk
    header[17] = 0;
    header[18] = 0;
    header[19] = 0;
    header[20] = 1;  // format = 1 for pcm and 2 for byte integer
    header[21] = 0;
    header[22] = (Byte) channels;
    header[23] = 0;
    header[24] = (Byte) (longSampleRate & 0xff);
    header[25] = (Byte) ((longSampleRate >> 8) & 0xff);
    header[26] = (Byte) ((longSampleRate >> 16) & 0xff);
    header[27] = (Byte) ((longSampleRate >> 24) & 0xff);
    header[28] = (Byte) (byteRate & 0xff);
    header[29] = (Byte) ((byteRate >> 8) & 0xff);
    header[30] = (Byte) ((byteRate >> 16) & 0xff);
    header[31] = (Byte) ((byteRate >> 24) & 0xff);
    header[32] = (Byte) (16*channels)/8;  // block align
    header[33] = 0;
    header[34] = 16;  // bits per sample
    header[35] = 0;
    header[36] = 'd';
    header[37] = 'a';
    header[38] = 't';
    header[39] = 'a';
    header[40] = (Byte) (totalAudioLen & 0xff);
    header[41] = (Byte) ((totalAudioLen >> 8) & 0xff);
    header[42] = (Byte) ((totalAudioLen >> 16) & 0xff);
    header[43] = (Byte) ((totalAudioLen >> 24) & 0xff);
    
    NSData *headerData = [NSData dataWithBytes:header length:44];
    NSMutableData * soundFileData1 = [NSMutableData alloc];
    [soundFileData1 appendData:headerData];
    [soundFileData1 appendData:data];
    
    NSError *error;
    avap1 = [[AVAudioPlayer alloc] initWithData:soundFileData1 fileTypeHint:@"wav" error:&error];
    [avap1 setVolume:0.25f];
    [avap1 prepareToPlay];
}

- (void) play {
    [avap1 play];
    [avap1 setVolume:0.25f];
}

@end
