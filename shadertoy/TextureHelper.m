//
//  TextureHelper.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 25/05/2017.
//  Copyright © 2017 Reinder Nijhoff. All rights reserved.
//

#import "TextureHelper.h"
#import "LocalCache.h"

#import <GLKit/GLKit.h>
#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

@interface TextureHelper () {
    ShaderInputType _type;
    ShaderInputFilterMode _filterMode;
    ShaderInputWrapMode _wrapMode;
    
    bool _vFlip;
    bool _sRGB;
    
    float _iChannelTime;
    float _iChannelWidth;
    float _iChannelHeight;
    float _iChannelDepth;
    
    int _channelSlot;
    
    GLuint _texId;
    
    bool _isInitialised;
    bool _newDataLoaded;
    NSURL *_fileURL;
}
@end

@implementation TextureHelper

- (id) initWithType:(ShaderInputType)type vFlip:(bool)vFlip sRGB:(bool)sRGB wrapMode:(ShaderInputWrapMode)wrapMode filterMode:(ShaderInputFilterMode)filterMode {
    self = [super init];
    if(self){
        _type = type;
        _filterMode = filterMode;
        _wrapMode = wrapMode;
        _vFlip = vFlip;
        _sRGB = sRGB;
        _iChannelDepth = 1.f;
        
        // create opengl es texture
        glGenTextures(1, &_texId);
        
        _isInitialised = NO;
    }
    return self;
}

- (void) loadFromFile:(NSString *)file {
    if( _type == TEXTURE3D ) {
        [self loadBinVolumeFile:file];
    } else {
        stbi_convert_iphone_png_to_rgb(0);
        stbi_set_flip_vertically_on_load(_vFlip);
        
        int x,y,n;
        
        unsigned char *data=stbi_load([file cStringUsingEncoding:NSASCIIStringEncoding],&x,&y,&n,0);
        if (data==NULL)
        {
            NSLog(@"Data loaded incorrectly %s", [file cStringUsingEncoding:NSASCIIStringEncoding]);
            NSLog(@"Failure reason: %s",stbi_failure_reason());
        }
        
        if( _type == TEXTURECUBE ) {
            for(int i=0; i<6; i++) {
                [self loadData:&data[i*x*x*n] width:x height:x depth:1 channels:n isFloat:NO cubemapLayer:i];
            }
        } else {
            [self loadData:data width:x height:y depth:1 channels:n isFloat:NO];
        }
        
        free(data);
    }
}

- (void) loadBinVolumeFile:(NSString *)filePath {
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:filePath];
    
    if (file == nil) {
        NSLog(@"%@%@",@"Failed to open file at path:", filePath);
    } else {
        // int signature = [self readInt32:file offset:0];
        _iChannelWidth = [self readInt32:file offset:4];
        _iChannelHeight = [self readInt32:file offset:8];
        _iChannelDepth = [self readInt32:file offset:12];
        
        unsigned char binNumChannels = [self readUInt8:file offset:16];
        // unsigned char binLayout = [self readUInt8:file offset:17];
        uint16_t binFormat = [self readUInt16:file offset:18];
        
        int n = 1;
        bool isFloat = NO;
        
        if( binNumChannels==1 && binFormat==0 ) {n=1; isFloat=NO; } // format = renderer.TEXFMT.C1I8;
        else if( binNumChannels==2 && binFormat==0 ) {n=2; isFloat=NO; }  // format = renderer.TEXFMT.C2I8;
        else if( binNumChannels==3 && binFormat==0 ) {n=3; isFloat=NO; }  // format = renderer.TEXFMT.C3I8;
        else if( binNumChannels==4 && binFormat==0 ) {n=4; isFloat=NO; }  // format = renderer.TEXFMT.C4I8;
        else if( binNumChannels==1 && binFormat==10 ) {n=1; isFloat=YES; }  // format = renderer.TEXFMT.C1F32;
        else if( binNumChannels==2 && binFormat==10 ) {n=2; isFloat=YES; }// format = renderer.TEXFMT.C2F32;
        else if( binNumChannels==3 && binFormat==10 ) {n=3; isFloat=YES; } // format = renderer.TEXFMT.C3F32;
        else if( binNumChannels==4 && binFormat==10 ) {n=4; isFloat=YES; } // format = renderer.TEXFMT.C4F32;
        else return;
        
        unsigned char *data = [self readRestOfFile:file offset:20];

        [self loadData:data width:_iChannelWidth height:_iChannelHeight depth:_iChannelDepth channels:n isFloat:isFloat];
        
        // free(data);
        [file closeFile];
    }
}

- (int32_t)readInt32:(NSFileHandle *)file offset:(int)offset {
    [file seekToFileOffset:offset];
    NSData *databuffer = [file readDataOfLength:4];
    return *((int32_t *)[databuffer bytes]);
}

- (uint16_t)readUInt16:(NSFileHandle *)file offset:(int)offset {
    [file seekToFileOffset:offset];
    NSData *databuffer = [file readDataOfLength:2];
    return *((uint16_t *)[databuffer bytes]);
}

- (unsigned char)readUInt8:(NSFileHandle *)file offset:(int)offset {
    [file seekToFileOffset:offset];
    NSData *databuffer = [file readDataOfLength:1];
    return *((unsigned char *)[databuffer bytes]);
}

- (unsigned char *)readRestOfFile:(NSFileHandle *)file offset:(int)offset {
    [file seekToFileOffset:offset];
    NSData *databuffer = [file readDataToEndOfFile];
    return (unsigned char *)[databuffer bytes];
}

- (void) loadFromURL:(NSString *)url {
    // get tmp filename
    NSURL *fileURL;
    NSString *strFileURL = [[LocalCache sharedLocalCache] getObject:url];
    
    if( strFileURL ) {
        fileURL = [NSURL URLWithString:strFileURL];
        // check if file exists
        NSError *err;
        if ([fileURL checkResourceIsReachableAndReturnError:&err] ) {
            [self loadFromFile: [fileURL path] ];
            return;
        }
    }
    
    fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:[[[NSUUID new] UUIDString] stringByAppendingString:@".img"]] isDirectory:NO];
    [[LocalCache sharedLocalCache] storeObject:[fileURL absoluteString] forKey:url];
    
    NSLog(@"Download %@ to %@", url, fileURL);
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [[session dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    // do stuff
                    if (error) {
                        NSLog(@"Download Error:%@",error.description);
                    }
                    if (data) {
                        NSError *writeError = nil;
                        [data writeToURL:fileURL options:NSDataWritingAtomic error:&writeError];
                        if (writeError) {
                            NSLog(@"Download Error:%@",writeError.description);
                        } else {
                            NSLog(@"File is saved to %@",fileURL);
                        }
                        self->_fileURL = fileURL;
                        self->_newDataLoaded = true;
                    }
                }] resume];
}

- (void) loadData:(unsigned char *)data width:(int)width height:(int)height depth:(int)depth channels:(int)channels isFloat:(BOOL)isFloat {
    [self loadData:data width:width height:height depth:depth channels:channels isFloat:isFloat cubemapLayer:0];
}

- (void) loadData:(unsigned char *)data width:(int)width height:(int)height depth:(int)depth channels:(int)channels isFloat:(BOOL)isFloat cubemapLayer:(int)layer {
    GLenum format=GL_RGBA;
    GLenum sourceFormat=GL_RGBA;
    
    if (channels == 4) {
        format = isFloat?GL_RGBA16F:GL_RGBA8;
        sourceFormat=GL_RGBA;
    }
    if (channels == 3) {
        format = isFloat?GL_RGB16F:GL_RGB8;
        sourceFormat=GL_RGB;
    }
    if (channels == 2) {
        format = isFloat?GL_RG16F:GL_RG8;
        sourceFormat=GL_RG;
    }
    if (channels == 1) {
        format = isFloat?GL_R16F:GL_R8;
        sourceFormat=GL_RED;
    }
    
    if( _type == TEXTURECUBE ) {
        glBindTexture(GL_TEXTURE_CUBE_MAP, _texId);
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + layer, 0, format, width, height, 0, sourceFormat, isFloat?GL_FLOAT:GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
    } else if( _type == TEXTURE3D) {
        glBindTexture(GL_TEXTURE_3D, _texId);
        glTexImage3D(GL_TEXTURE_3D, 0, format, width, height, depth, 0, sourceFormat, isFloat?GL_FLOAT:GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_3D);
    } else {
        glBindTexture(GL_TEXTURE_2D, _texId);
        glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, sourceFormat, isFloat?GL_FLOAT:GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    
    _iChannelWidth = (float)width;
    _iChannelHeight = (float)height;
    _iChannelDepth = (float)depth;
    
    _isInitialised = YES;
}

+ (int) getMipLevels:(int)width height:(int)height {
    return 1 + floor(log2(MAX(width, height)));
}

- (void) createEmpty:(int)width height:(int)height {
    glBindTexture(GL_TEXTURE_2D, _texId);
    int levels = [TextureHelper getMipLevels:width height:height];
    glTexStorage2D(GL_TEXTURE_2D, levels, GL_RGBA8, width, height);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,  _texId, 0);
    
    _iChannelWidth = (float)width;
    _iChannelHeight = (float)height;
    _iChannelDepth = 1.0f;
    
    _isInitialised = YES;
}

- (float) getWidth {
    return _iChannelWidth;
}

- (float) getHeight {
    return _iChannelHeight;
}

- (float) getDepth {
    return _iChannelDepth;
}

- (ShaderInputType) getType {
    return _type;
}
    
- (ShaderInputFilterMode) getFilterMode {
    return _filterMode;
}

- (void) bindToChannel:(int)channel{
    if( _newDataLoaded ) {
        [self loadFromFile:[_fileURL path] ];
        _newDataLoaded = NO;
    }
    
    GLuint target = (_type == TEXTURECUBE) ? GL_TEXTURE_CUBE_MAP : (_type == TEXTURE3D) ? GL_TEXTURE_3D : GL_TEXTURE_2D;
    glActiveTexture(GL_TEXTURE0 + channel);
    glBindTexture( target, _texId);
    [TextureHelper setGLTexParameters:target type:_type wrapMode:_wrapMode filterMode:_filterMode];
}

+ (void) setGLTexParameters:(GLuint)target type:(ShaderInputType)type wrapMode:(ShaderInputWrapMode)wrapMode filterMode:(ShaderInputFilterMode)filterMode {
    if( wrapMode == REPEAT ) {
        glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_REPEAT);
        if(type == TEXTURECUBE || type == TEXTURE3D) glTexParameteri(target, GL_TEXTURE_WRAP_R, GL_REPEAT);
    } else {
        glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        if(type == TEXTURECUBE || type == TEXTURE3D) glTexParameteri(target, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    }
    
    if( filterMode == NEAREST ) {
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    } else if( filterMode == MIPMAP ) {
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    } else {
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
}

- (GLuint) getTexId {
    return _texId;
}

- (void) update {
}
    
- (void) dealloc {
    glDeleteTextures(1, &_texId);
}

@end
