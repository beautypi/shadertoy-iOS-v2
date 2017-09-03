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
            [self loadData:&data[i*x*x*n] width:x height:x channels:n cubemapLayer:i];
        }
    } else {
        [self loadData:data width:x height:y channels:n];
    }
    
    free(data);
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
                        _fileURL = fileURL;
                        _newDataLoaded = true;
                    }
                }] resume];
}

- (void) loadData:(unsigned char *)data width:(int)width height:(int)height channels:(int)channels {
    [self loadData:data width:width height:height channels:channels cubemapLayer:0];
}

- (void) loadData:(unsigned char *)data width:(int)width height:(int)height channels:(int)channels cubemapLayer:(int)layer {
    GLenum format=GL_RGBA;
    GLenum sourceFormat=GL_RGBA;
    
    if (channels == 3) {
        format=GL_RGB;
        sourceFormat=GL_RGB;
    }
    if (channels == 1) {
        format=GL_R8;
        sourceFormat=GL_RED;
    }
    
    if( _type == TEXTURECUBE ) {
        glBindTexture(GL_TEXTURE_CUBE_MAP, _texId);
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + layer, 0, format, width, height, 0, sourceFormat, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_CUBE_MAP);
    } else {
        glBindTexture(GL_TEXTURE_2D, _texId);
        glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, sourceFormat, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    
    _iChannelWidth = (float)width;
    _iChannelHeight = (float)height;
    
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

- (void) bindToChannel:(int)channel{
    if( _newDataLoaded ) {
        [self loadFromFile:[_fileURL path] ];
        _newDataLoaded = NO;
    }
    
    GLuint target = (_type == TEXTURECUBE) ? GL_TEXTURE_CUBE_MAP : GL_TEXTURE_2D;
    glActiveTexture(GL_TEXTURE0 + channel);
    glBindTexture( target, _texId);
    
    if( _wrapMode == REPEAT ) {
        glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_REPEAT);
        if(_type == TEXTURECUBE) glTexParameteri(target, GL_TEXTURE_WRAP_R, GL_REPEAT);
    } else {
        glTexParameteri(target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        if(_type == TEXTURECUBE) glTexParameteri(target, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    }
    
    if( _filterMode == NEAREST ) {
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    } else if( _filterMode == MIPMAP ) {
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    } else {
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
}

- (void)dealloc {
    glDeleteTextures(1, &_texId);
}

@end
