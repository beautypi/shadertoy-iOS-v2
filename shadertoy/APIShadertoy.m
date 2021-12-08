//
//  APIShadertoy.m
//  shadertoy
//
//  Created by Reinder Nijhoff on 19/08/15.
//  Copyright (c) 2015 Reinder Nijhoff. All rights reserved.
//

#import "APIShadertoy.h"
#import "NSString+URLEncode.h"

@interface APIShadertoy () {
    AFHTTPSessionManager* _manager;
    AFJSONRequestSerializer* _jsonRequestSerializer;
    AFHTTPRequestSerializer* _httpRequestSerializer;
}
@end

@implementation APIShadertoy

- (id)init {
    self = [super init];
    if(self){
        // https://www.shadertoy.com/api/v1/shaders/
        // https://www.shadertoy.com/shadertoy
        _manager = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:APIShadertoyBaseUrl]];
    
        _jsonRequestSerializer = [AFJSONRequestSerializer serializer];
        NSString *language = [[NSLocale preferredLanguages] firstObject];
        [_jsonRequestSerializer setValue:language forHTTPHeaderField:@"Accept-Language"];
        
        _httpRequestSerializer = [AFHTTPRequestSerializer serializer];
        [_httpRequestSerializer setQueryStringSerializationWithStyle:AFHTTPRequestQueryStringDefaultStyle];
        
        _manager.requestSerializer = _jsonRequestSerializer;
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html",@"application/json", @"text/json" ,@"text/javascript", nil];
        // 作者：CISay
        // https://juejin.cn/post/6844903764546027528
        _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    }
    return self;
}

-(NSURLSessionDataTask*) getShaderKeys:(NSString*)sortBy success:(void(^)(NSArray*results))success {
    NSDictionary *params = @{
                             @"key": APIShadertoyKey,
                             @"sort": sortBy
                             };
    return [self getShaderKeys:@"query" params:params success:success];
}
//https://www.shadertoy.com/api/v1/shaders/query/multipass?key=NtHKWH&sort=popular
-(NSURLSessionDataTask*) getShaderKeys:(NSString*)sortBy query:(NSString*)query success:(void(^)(NSArray *results))success {
    NSDictionary *params = @{
                             @"key": APIShadertoyKey,
                             @"sort": sortBy
                             };
    NSString *url = [NSString stringWithFormat:@"query/%@", [query URLEncode]];
    return [self getShaderKeys:url params:params success:success];
}
//https://www.shadertoy.com/api/v1/shaders/query?key=NtHKWH&sort=popular
- (NSURLSessionDataTask *) getShaderKeys:(NSString *)url params:(NSDictionary *)params success:(void (^)(NSArray *results))success {
    _manager.requestSerializer = _jsonRequestSerializer;
    return [_manager GET:[NSString stringWithFormat:@"%@%@", APIShadertoyAPIV1, url] parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask *operation, id responseObject) {
        if(![responseObject isKindOfClass:[NSDictionary class]]){
            return;
        }
        NSArray* results = [responseObject objectForKey:@"Results"];
//        NSLog(@"getShaderKeys success: %@", results);
        success(results);
    } failure:^(NSURLSessionDataTask *operation, NSError *error) {
        NSLog(@"getShaderKeys failed: %@", error);
    }];
}
// https://www.shadertoy.com/api/v1/shaders/7scGWn?key=NtHKWH
// https://www.shadertoy.com/shadertoy s=$URLEncode("{ "shaders" : ["XtlSD7"] }")&nt=1&nl=1&np=1
- (NSURLSessionDataTask *) getShader:(NSString *)shaderId success:(void (^)(NSDictionary *shaderDict))success failure:(void (^)(void))failure {
    [_httpRequestSerializer setValue:[NSString stringWithFormat:@"https://www.shadertoy.com/view/%@", shaderId] forHTTPHeaderField:@"Referer"];
    _manager.requestSerializer = _httpRequestSerializer;
    NSDictionary* params = @{
//                             @"key": APIShadertoyKey
        @"nt": @"1",
        @"nl": @"1",
        @"np": @"1",
        @"s": [NSString stringWithFormat:@"{ \"shaders\" : [\"%@\"] }", shaderId],
    };
    return [_manager POST:@"shadertoy" parameters:params headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (![responseObject isKindOfClass:[NSArray class]])
        {
            failure();
            return;
        }
        NSDictionary* shaderDict = responseObject[0];
        success(shaderDict);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure();
    }];
//    return [_manager POST:@"shadertoy" parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
////        [formData appendPartWithHeaders:nil body:[@"s=%7B%20%22shaders%22%20%3A%20%5B%22XtlSD7%22%5D%20%7D&nt=1&nl=1&np=1" dataUsingEncoding:NSUTF8StringEncoding]];
//    } progress:^(NSProgress * _Nonnull uploadProgress) {
//
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//
//    }];
//    return [_manager GET:shaderId parameters:params progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
//        if(![responseObject isKindOfClass:[NSDictionary class]]){
//            return;
//        }
//        NSDictionary *shaderDict = [responseObject objectForKey:@"Shader"];
//        if( shaderDict != nil) {
//            success(shaderDict);
//        }
//    } failure:^(NSURLSessionTask *operation, NSError *error) {
//        failure();
//    }];
}

-(NSURLSessionDataTask*) getShaders:(NSArray<NSString* >*)shaderIDs success:(void (^)(NSArray<NSDictionary* >* shaderDicts))success failure:(void (^)(void))failure {
    if (!shaderIDs || shaderIDs.count <= 0)
    {
        return nil;
    }
    [_httpRequestSerializer setValue:[NSString stringWithFormat:@"https://www.shadertoy.com/view/%@", shaderIDs[0]] forHTTPHeaderField:@"Referer"];
    _manager.requestSerializer = _httpRequestSerializer;
    NSMutableString* s = [[NSMutableString alloc] initWithFormat:@"{ \"shaders\" : [\"%@\"", shaderIDs[0]];
    for (NSInteger i = 1; i < shaderIDs.count; i++)
    {
        [s appendFormat:@", \"%@\"", shaderIDs[i]];
    }
    [s appendString:@"] }"];
    
    NSDictionary* params = @{
//                             @"key": APIShadertoyKey
        @"nt": @"1",
        @"nl": @"1",
        @"np": @"1",
        @"s": s,
    };
    return [_manager POST:@"shadertoy" parameters:params headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {

    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (![responseObject isKindOfClass:[NSArray class]])
        {
            failure();
            return;
        }
        NSArray<NSDictionary* >* shaderDicts = responseObject;
        success(shaderDicts);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure();
    }];
//    return [_manager POST:@"shadertoy" parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
////        [formData appendPartWithHeaders:nil body:[@"s=%7B%20%22shaders%22%20%3A%20%5B%22XtlSD7%22%5D%20%7D&nt=1&nl=1&np=1" dataUsingEncoding:NSUTF8StringEncoding]];
//    } progress:^(NSProgress * _Nonnull uploadProgress) {
//
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//
//    }];
//    return [_manager GET:shaderId parameters:params progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
//        if(![responseObject isKindOfClass:[NSDictionary class]]){
//            return;
//        }
//        NSDictionary *shaderDict = [responseObject objectForKey:@"Shader"];
//        if( shaderDict != nil) {
//            success(shaderDict);
//        }
//    } failure:^(NSURLSessionTask *operation, NSError *error) {
//        failure();
//    }];
}

@end

/// Sample shader dict:
// Printing description of shaderDict:
// {
//     info =     {
//         date = 1482384986;
//         description = "Another terrain, with cheap trees made of ellipsoids and noise. It computes analytic normals for the terrain and clouds. The art composed to camera as usual.";
//         flags = 32;
//         hasliked = 0;
//         id = 4ttSWf;
//         likes = 766;
//         name = Rainforest;
//         published = 3;
//         tags =         (
//             procedural,
//             3d,
//             raymarching,
//             reprojection
//         );
//         usePreview = 0;
//         username = iq;
//         viewed = 159458;
//     };
//     renderpass =     (
//                 {
//             code = "// Created by inigo quilez - iq/2016\n// I share this piece (art and code) here in Shadertoy and through its Public API, only for educational purposes. \n// You cannot use, sell, share or host this piece or modifications of it as part of your own commercial or non-commercial product, website or project.\n// You can share a link to it or an unmodified screenshot of it provided you attribute \"by Inigo Quilez, @iquilezles and iquilezles.org\". \n// If you are a teacher, lecturer, educator or similar and these conditions are too restrictive for your needs, please contact me and we'll work it out.\n\n// Normals are analytical (true derivatives) for the terrain and for the\n// clouds, including the noise, the fbm and the smoothsteps.\n//\n// See here for more info: \n//  https://iquilezles.org/www/articles/fbm/fbm.htm\n//  http://iquilezles.org/www/articles/morenoise/morenoise.htm\n//\n// Lighting and art composed for this shot/camera. The trees are really\n// cheap (ellipsoids with noise), but they kind of do the job in distance\n// and low image resolutions Also I used some cheap reprojection technique\n// to smooth out the render.\n\n\nvoid mainImage( out vec4 fragColor, in vec2 fragCoord )\n{\n    vec2 p = fragCoord/iResolution.xy;\n\n    vec3 col = texture( iChannel0, p ).xyz;\n  //vec3 col = texelFetch( iChannel0, ivec2(fragCoord-0.5), 0 ).xyz;\n\n    col *= 0.5 + 0.5*pow( 16.0*p.x*p.y*(1.0-p.x)*(1.0-p.y), 0.05 );\n         \n    fragColor = vec4( col, 1.0 );\n}\n";
//             description = "";
//             inputs =             (
//                                 {
//                     channel = 0;
//                     ctype = buffer;
//                     id = 257;
//                     published = 1;
//                     sampler =                     {
//                         filter = linear;
//                         internal = byte;
//                         srgb = false;
//                         vflip = true;
//                         wrap = clamp;
//                     };
//                     src = "/media/previz/buffer00.png";
//                 }
//             );
//             name = Image;
//             outputs =             (
//                                 {
//                     channel = 0;
//                     id = 37;
//                 }
//             );
//             type = image;
//         },
//                 {
//             code = "#define LOWQUALITY\n#define LOWQUALITY_SHADOWS\n\n//==========================================================================================\n// general utilities\n//==========================================================================================\n#define ZERO (min(iFrame,0))\n\nfloat sdEllipsoidY( in vec3 p, in vec2 r )\n{\n    float k0 = length(p/r.xyx);\n    float k1 = length(p/(r.xyx*r.xyx));\n    return k0*(k0-1.0)/k1;\n}\nfloat sdEllipsoid( in vec3 p, in vec3 r )\n{\n    float k0 = length(p/r);\n    float k1 = length(p/(r*r));\n    return k0*(k0-1.0)/k1;\n}\n\n// return smoothstep and its derivative\nvec2 smoothstepd( float a, float b, float x)\n{\n\tif( x<a ) return vec2( 0.0, 0.0 );\n\tif( x>b ) return vec2( 1.0, 0.0 );\n    float ir = 1.0/(b-a);\n    x = (x-a)*ir;\n    return vec2( x*x*(3.0-2.0*x), 6.0*x*(1.0-x)*ir );\n}\n\nmat3 setCamera( in vec3 ro, in vec3 ta, float cr )\n{\n\tvec3 cw = normalize(ta-ro);\n\tvec3 cp = vec3(sin(cr), cos(cr),0.0);\n\tvec3 cu = normalize( cross(cw,cp) );\n\tvec3 cv = normalize( cross(cu,cw) );\n    return mat3( cu, cv, cw );\n}\n\n//==========================================================================================\n// hashes (low quality, do NOT use in production)\n//==========================================================================================\n\nfloat hash1( vec2 p )\n{\n    p  = 50.0*fract( p*0.3183099 );\n    return fract( p.x*p.y*(p.x+p.y) );\n}\n\nfloat hash1( float n )\n{\n    return fract( n*17.0*fract( n*0.3183099 ) );\n}\n\nvec2 hash2( vec2 p ) \n{\n    const vec2 k = vec2( 0.3183099, 0.3678794 );\n    float n = 111.0*p.x + 113.0*p.y;\n    return fract(n*fract(k*n));\n}\n\n//==========================================================================================\n// noises\n//==========================================================================================\n\n// value noise, and its analytical derivatives\nvec4 noised( in vec3 x )\n{\n    vec3 p = floor(x);\n    vec3 w = fract(x);\n    #if 1\n    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);\n    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);\n    #else\n    vec3 u = w*w*(3.0-2.0*w);\n    vec3 du = 6.0*w*(1.0-w);\n    #endif\n\n    float n = p.x + 317.0*p.y + 157.0*p.z;\n    \n    float a = hash1(n+0.0);\n    float b = hash1(n+1.0);\n    float c = hash1(n+317.0);\n    float d = hash1(n+318.0);\n    float e = hash1(n+157.0);\n\tfloat f = hash1(n+158.0);\n    float g = hash1(n+474.0);\n    float h = hash1(n+475.0);\n\n    float k0 =   a;\n    float k1 =   b - a;\n    float k2 =   c - a;\n    float k3 =   e - a;\n    float k4 =   a - b - c + d;\n    float k5 =   a - c - e + g;\n    float k6 =   a - b - e + f;\n    float k7 = - a + b + c - d + e - f - g + h;\n\n    return vec4( -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z), \n                      2.0* du * vec3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,\n                                      k2 + k5*u.z + k4*u.x + k7*u.z*u.x,\n                                      k3 + k6*u.x + k5*u.y + k7*u.x*u.y ) );\n}\n\nfloat noise( in vec3 x )\n{\n    vec3 p = floor(x);\n    vec3 w = fract(x);\n    \n    #if 1\n    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);\n    #else\n    vec3 u = w*w*(3.0-2.0*w);\n    #endif\n    \n\n\n    float n = p.x + 317.0*p.y + 157.0*p.z;\n    \n    float a = hash1(n+0.0);\n    float b = hash1(n+1.0);\n    float c = hash1(n+317.0);\n    float d = hash1(n+318.0);\n    float e = hash1(n+157.0);\n\tfloat f = hash1(n+158.0);\n    float g = hash1(n+474.0);\n    float h = hash1(n+475.0);\n\n    float k0 =   a;\n    float k1 =   b - a;\n    float k2 =   c - a;\n    float k3 =   e - a;\n    float k4 =   a - b - c + d;\n    float k5 =   a - c - e + g;\n    float k6 =   a - b - e + f;\n    float k7 = - a + b + c - d + e - f - g + h;\n\n    return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);\n}\n\nvec3 noised( in vec2 x )\n{\n    vec2 p = floor(x);\n    vec2 w = fract(x);\n    #if 1\n    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);\n    vec2 du = 30.0*w*w*(w*(w-2.0)+1.0);\n    #else\n    vec2 u = w*w*(3.0-2.0*w);\n    vec2 du = 6.0*w*(1.0-w);\n    #endif\n    \n    float a = hash1(p+vec2(0,0));\n    float b = hash1(p+vec2(1,0));\n    float c = hash1(p+vec2(0,1));\n    float d = hash1(p+vec2(1,1));\n\n    float k0 = a;\n    float k1 = b - a;\n    float k2 = c - a;\n    float k4 = a - b - c + d;\n\n    return vec3( -1.0+2.0*(k0 + k1*u.x + k2*u.y + k4*u.x*u.y), \n                      2.0* du * vec2( k1 + k4*u.y,\n                                      k2 + k4*u.x ) );\n}\n\nfloat noise( in vec2 x )\n{\n    vec2 p = floor(x);\n    vec2 w = fract(x);\n    #if 1\n    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);\n    #else\n    vec2 u = w*w*(3.0-2.0*w);\n    #endif\n\n    float a = hash1(p+vec2(0,0));\n    float b = hash1(p+vec2(1,0));\n    float c = hash1(p+vec2(0,1));\n    float d = hash1(p+vec2(1,1));\n    \n    return -1.0+2.0*( a + (b-a)*u.x + (c-a)*u.y + (a - b - c + d)*u.x*u.y );\n}\n\n//==========================================================================================\n// fbm constructions\n//==========================================================================================\n\nconst mat3 m3  = mat3( 0.00,  0.80,  0.60,\n                      -0.80,  0.36, -0.48,\n                      -0.60, -0.48,  0.64 );\nconst mat3 m3i = mat3( 0.00, -0.80, -0.60,\n                       0.80,  0.36, -0.48,\n                       0.60, -0.48,  0.64 );\nconst mat2 m2 = mat2(  0.80,  0.60,\n                      -0.60,  0.80 );\nconst mat2 m2i = mat2( 0.80, -0.60,\n                       0.60,  0.80 );\n\n//------------------------------------------------------------------------------------------\n\nfloat fbm_4( in vec2 x )\n{\n    float f = 1.9;\n    float s = 0.55;\n    float a = 0.0;\n    float b = 0.5;\n    for( int i=ZERO; i<4; i++ )\n    {\n        float n = noise(x);\n        a += b*n;\n        b *= s;\n        x = f*m2*x;\n    }\n\treturn a;\n}\n\nfloat fbm_4( in vec3 x )\n{\n    float f = 2.0;\n    float s = 0.5;\n    float a = 0.0;\n    float b = 0.5;\n    for( int i=ZERO; i<4; i++ )\n    {\n        float n = noise(x);\n        a += b*n;\n        b *= s;\n        x = f*m3*x;\n    }\n\treturn a;\n}\n\nvec4 fbmd_7( in vec3 x )\n{\n    float f = 1.92;\n    float s = 0.5;\n    float a = 0.0;\n    float b = 0.5;\n    vec3  d = vec3(0.0);\n    mat3  m = mat3(1.0,0.0,0.0,\n                   0.0,1.0,0.0,\n                   0.0,0.0,1.0);\n    for( int i=ZERO; i<7; i++ )\n    {\n        vec4 n = noised(x);\n        a += b*n.x;          // accumulate values\t\t\n        d += b*m*n.yzw;      // accumulate derivatives\n        b *= s;\n        x = f*m3*x;\n        m = f*m3i*m;\n    }\n\treturn vec4( a, d );\n}\n\nvec4 fbmd_8( in vec3 x )\n{\n    float f = 2.0;\n    float s = 0.65;\n    float a = 0.0;\n    float b = 0.5;\n    vec3  d = vec3(0.0);\n    mat3  m = mat3(1.0,0.0,0.0,\n                   0.0,1.0,0.0,\n                   0.0,0.0,1.0);\n    for( int i=ZERO; i<8; i++ )\n    {\n        vec4 n = noised(x);\n        a += b*n.x;          // accumulate values\t\t\n        if( i<4 )\n        d += b*m*n.yzw;      // accumulate derivatives\n        b *= s;\n        x = f*m3*x;\n        m = f*m3i*m;\n    }\n\treturn vec4( a, d );\n}\n\nfloat fbm_9( in vec2 x )\n{\n    float f = 1.9;\n    float s = 0.55;\n    float a = 0.0;\n    float b = 0.5;\n    for( int i=ZERO; i<9; i++ )\n    {\n        float n = noise(x);\n        a += b*n;\n        b *= s;\n        x = f*m2*x;\n    }\n\treturn a;\n}\n\nvec3 fbmd_9( in vec2 x )\n{\n    float f = 1.9;\n    float s = 0.55;\n    float a = 0.0;\n    float b = 0.5;\n    vec2  d = vec2(0.0);\n    mat2  m = mat2(1.0,0.0,0.0,1.0);\n    for( int i=ZERO; i<9; i++ )\n    {\n        vec3 n = noised(x);\n        \n        a += b*n.x;          // accumulate values\t\t\n        d += b*m*n.yz;       // accumulate derivatives\n        b *= s;\n        x = f*m2*x;\n        m = f*m2i*m;\n    }\n\treturn vec3( a, d );\n}\n\n//==========================================================================================\n// specifics to the actual painting\n//==========================================================================================\n\n\n//------------------------------------------------------------------------------------------\n// global\n//------------------------------------------------------------------------------------------\n\nconst vec3  kSunDir = vec3(-0.624695,0.468521,-0.624695);\nconst float kMaxTreeHeight = 2.4;\nconst float kMaxHeight = 120.0;\n\nvec3 fog( in vec3 col, float t )\n{\n    vec3 ext = exp2(-t*0.0005*vec3(1,1.5,4)); \n    return col*ext + (1.0-ext)*vec3(0.55,0.55,0.58); // 0.55\n}\n\n//------------------------------------------------------------------------------------------\n// clouds\n//------------------------------------------------------------------------------------------\n\nvec4 cloudsFbm( in vec3 pos )\n{\n    return fbmd_8(pos*0.003+vec3(2.0,2.0,1.0)+0.07*vec3(iTime,0.5*iTime,-0.15*iTime));\n}\n\nvec4 cloudsMap( in vec3 pos, out float nnd )\n{\n    float d = abs(pos.y-150.0)-20.0;\n    vec3 gra = vec3(0.0,sign(pos.y-150.0),0.0);\n    \n    vec4 n = cloudsFbm(pos);\n    d += 200.0*n.x * (0.7+0.3*gra.y);\n    \n    if( d>0.0 ) return vec4(-d,0.0,0.0,0.0);\n    \n    nnd = -d;\n    d = min(-d/50.0,0.25);\n    \n    //gra += 0.1*n.yzw *  (0.7+0.3*gra.y);\n    \n    return vec4( d, gra );\n}\n\nfloat cloudsShadowFlat( in vec3 ro, in vec3 rd )\n{\n    float t = (150.0-ro.y)/rd.y;\n    if( t<0.0 ) return 1.0;\n    vec3 pos = ro + rd*t;\n    vec4 n = cloudsFbm(pos);\n    return 200.0*n.x-20.0;\n}\n\n#ifndef LOWQUALITY_SHADOWS\nfloat cloudsShadow( in vec3 ro, in vec3 rd, float tmin, float tmax )\n{\n\tfloat sum = 0.0;\n\n    // bounding volume!!\n    float tl = (  50.0-ro.y)/rd.y;\n    float th = ( 300.0-ro.y)/rd.y;\n    if( tl>0.0 ) { if(ro.y>50.0) tmin = min( tmin, tl ); else tmin = max( tmin, tl ); }\n    if( th>0.0 ) tmax = min( tmax, th );\n\n    // raymarch\n\tfloat t = tmin;\n\tfor(int i=ZERO; i<128; i++)\n    { \n        vec3  pos = ro + t*rd; \n        float kk;\n        vec4  denGra = cloudsMap( pos, kk ); \n        float den = denGra.x;\n        float dt = max(1.0,0.05*t);\n        if( den>0.01 ) \n        { \n            float alp = clamp(den*0.1*dt,0.0,1.0);\n            sum = sum + alp*(1.0-sum);\n        }\n        else \n        {\n            dt = -den+0.1;\n        }\n        t += dt;\n        if( sum>0.995 || t>tmax ) break;\n    }\n\n    return clamp( 1.0-sum, 0.0, 1.0 );\n}\n#endif\n\nfloat terrainShadow( in vec3 ro, in vec3 rd, in float mint );\n\nvec4 renderClouds( in vec3 ro, in vec3 rd, float tmin, float tmax, inout float resT, in vec2 px )\n{\n    vec4 sum = vec4(0.0);\n\n    // bounding volume!!\n    float tl = (   0.0-ro.y)/rd.y;\n    float th = ( 300.0-ro.y)/rd.y;\n    if( tl>0.0 ) tmin = max( tmin, tl ); else return sum;\n    if( th>0.0 ) tmax = min( tmax, th );\n\n    float t = tmin;\n    //t += 1.0*hash1(gl_FragCoord.xy);\n    float lastT = -1.0;\n    float thickness = 0.0;\n    #ifdef LOWQUALITY_SHADOWS\n    for(int i=ZERO; i<128; i++)\n    { \n        vec3  pos = ro + t*rd; \n        float nnd;\n        vec4  denGra = cloudsMap( pos, nnd ); \n        float den = denGra.x;\n        float dt = max(0.1,0.011*t);\n        //dt *= hash1(px+float(i));\n        if( den>0.001 ) \n        { \n            float kk;\n            cloudsMap( pos+kSunDir*35.0, kk );\n            float sha = 1.0-smoothstep(-100.0,100.0,kk); sha *= 1.5;\n            \n            vec3 nor = normalize(denGra.yzw);\n            float dif = clamp( 0.4+0.6*dot(nor,kSunDir), 0.0, 1.0 )*sha; \n            float fre = clamp( 1.0+dot(nor,rd), 0.0, 1.0 )*sha;\n            float occ = 0.2+0.7*max(1.0-kk/100.0,0.0) + 0.1*(1.0-den);\n            // lighting\n            vec3 lin  = vec3(0.0);\n                 lin += vec3(0.70,0.80,1.00)*1.0*(0.5+0.5*nor.y)*occ;\n                 lin += vec3(0.10,0.40,0.20)*1.0*(0.5-0.5*nor.y)*occ;\n                 lin += vec3(1.00,0.95,0.85)*3.0*dif*occ + 0.1;\n\n            // color\n            vec3 col = vec3(0.8,0.8,0.8)*0.45;\n\n            col *= lin;\n\n            col = fog( col, t );\n\n            // front to back blending    \n            float alp = clamp(den*0.5*0.25*dt,0.0,1.0);\n            col.rgb *= alp;\n            sum = sum + vec4(col,alp)*(1.0-sum.a);\n\n            thickness += dt*den;\n            if( lastT<0.0 ) lastT = t;            \n        }\n        else \n        {\n            dt = abs(den)+0.1;\n\n        }\n        t += dt;\n        if( sum.a>0.995 || t>tmax ) break;\n    }\n    #else\n    for(int i=ZERO; i<128; i++)\n    { \n        vec3  pos = ro + t*rd; \n        float  kk;\n        vec4  denGra = cloudsMap( pos, kk ); \n        float den = denGra.x;\n        float dt = max(0.1,0.011*t);\n        if( den>0.001 ) \n        { \n            float sha = cloudsShadow( pos, kSunDir, 0.0, 150.0 );\n            vec3 nor = normalize(denGra.yzw);\n            float dif = clamp( 0.5+0.5*dot(nor,kSunDir), 0.0, 1.0 )*sha; \n            float fre = clamp( 1.0+dot(nor,rd), 0.0, 1.0 )*sha;\n            // lighting\n            vec3 lin  = vec3(0.0);\n                 lin += vec3(0.70,0.80,1.00)*1.0*(0.5+0.5*nor.y)*(1.0-den);\n                 lin += vec3(0.20,0.30,0.20)*1.0*(0.5-0.5*nor.y)*(1.0-den);\n                 lin += vec3(1.00,0.75,0.50)*2.0*dif;\n            \t lin += vec3(0.80,0.70,0.50)*11.3*pow(fre,32.0)*(1.0-den);\n                 lin += sha*0.4*(1.0-den);\n                 lin = max(lin,0.0);\n            // color\n            vec3 col = vec3(0.8,0.8,0.8)*0.6;\n\n            col *= lin;\n            \n            col = fog( col, t );\n\n            float alp = clamp(den*0.5*0.25*dt,0.0,1.0);\n            col.rgb *= alp;\n            sum = sum + vec4(col,alp)*(1.0-sum.a);\n\n            thickness += dt*den;\n            if( lastT<0.0 ) lastT = t;           \n        }\n        else \n        {\n            dt = abs(den)+0.1;\n\n        }\n        t += dt;\n        if( sum.a>0.995 || t>tmax ) break;\n    }\n    #endif\n    \n    //resT = min(resT, (150.0-ro.y)/rd.y );\n    if( lastT>0.0 ) resT = min(resT,lastT);\n    //if( lastT>0.0 ) resT = mix( resT, lastT, sum.w );\n    \n    \n    sum.xyz += max(0.0,1.0-0.025*thickness)*vec3(1.00,0.60,0.40)*0.3*pow(clamp(dot(kSunDir,rd),0.0,1.0),32.0);\n\n    return clamp( sum, 0.0, 1.0 );\n}\n\n\n//------------------------------------------------------------------------------------------\n// terrain\n//------------------------------------------------------------------------------------------\n\nvec2 terrainMap( in vec2 p )\n{\n    const float sca = 0.0010;\n    const float amp = 300.0;\n    p *= sca;\n    float e = fbm_9( p + vec2(1.0,-2.0) );\n    float a = 1.0-smoothstep( 0.12, 0.13, abs(e+0.12) ); // flag high-slope areas (-0.25, 0.0)\n    e = e + 0.15*smoothstep( -0.08, -0.01, e );\n    e *= amp;\n    return vec2(e,a);\n}\n\nvec4 terrainMapD( in vec2 p )\n{\n\tconst float sca = 0.0010;\n    const float amp = 300.0;\n    p *= sca;\n    vec3 e = fbmd_9( p + vec2(1.0,-2.0) );\n    vec2 c = smoothstepd( -0.08, -0.01, e.x );\n\te.x = e.x + 0.15*c.x;\n\te.yz = e.yz + 0.15*c.y*e.yz;    \n    e.x *= amp;\n    e.yz *= amp*sca;\n    return vec4( e.x, normalize( vec3(-e.y,1.0,-e.z) ) );\n}\n\nvec3 terrainNormal( in vec2 pos )\n{\n#if 1\n    return terrainMapD(pos).yzw;\n#else    \n    vec2 e = vec2(0.03,0.0);\n\treturn normalize( vec3(terrainMap(pos-e.xy).x - terrainMap(pos+e.xy).x,\n                           2.0*e.x,\n                           terrainMap(pos-e.yx).x - terrainMap(pos+e.yx).x ) );\n#endif    \n}\n\nfloat terrainShadow( in vec3 ro, in vec3 rd, in float mint )\n{\n    float res = 1.0;\n    float t = mint;\n#ifdef LOWQUALITY\n    for( int i=ZERO; i<32; i++ )\n    {\n        vec3  pos = ro + t*rd;\n        vec2  env = terrainMap( pos.xz );\n        float hei = pos.y - env.x;\n        res = min( res, 32.0*hei/t );\n        if( res<0.0001 || pos.y>kMaxHeight ) break;\n        t += clamp( hei, 1.0+t*0.1, 50.0 );\n    }\n#else\n    for( int i=ZERO; i<128; i++ )\n    {\n        vec3  pos = ro + t*rd;\n        vec2  env = terrainMap( pos.xz );\n        float hei = pos.y - env.x;\n        res = min( res, 32.0*hei/t );\n        if( res<0.0001 || pos.y>kMaxHeight  ) break;\n        t += clamp( hei, 0.5+t*0.05, 25.0 );\n    }\n#endif\n    return clamp( res, 0.0, 1.0 );\n}\n\nvec2 raymarchTerrain( in vec3 ro, in vec3 rd, float tmin, float tmax )\n{\n    // bounding plane\n    float tp = (kMaxHeight+kMaxTreeHeight-ro.y)/rd.y;\n    if( tp>0.0 ) tmax = min( tmax, tp );\n    \n    // raymarch\n    float dis, th;\n    float t2 = -1.0;\n    float t = tmin; \n    float ot = t;\n    float odis = 0.0;\n    float odis2 = 0.0;\n    for( int i=ZERO; i<400; i++ )\n    {\n        th = 0.001*t;\n\n        vec3  pos = ro + t*rd;\n        vec2  env = terrainMap( pos.xz );\n        float hei = env.x;\n\n        // tree envelope\n        float dis2 = pos.y - (hei+kMaxTreeHeight*1.1);\n        if( dis2<th ) \n        {\n            if( t2<0.0 )\n            {\n                t2 = ot + (th-odis2)*(t-ot)/(dis2-odis2); // linear interpolation for better accuracy\n            }\n        }\n        odis2 = dis2;\n        \n        // terrain\n        dis = pos.y - hei;\n        if( dis<th ) break;\n        \n        ot = t;\n        odis = dis;\n        t += dis*0.8*(1.0-0.75*env.y); // slow down in step areas\n        if( t>tmax ) break;\n    }\n\n    if( t>tmax ) t = -1.0;\n    else t = ot + (th-odis)*(t-ot)/(dis-odis); // linear interpolation for better accuracy\n    \n    return vec2(t,t2);\n}\n\n//------------------------------------------------------------------------------------------\n// trees\n//------------------------------------------------------------------------------------------\n\nfloat treesMap( in vec3 p, in float rt, out float oHei, out float oMat, out float oDis )\n{\n    oHei = 1.0;\n    oDis = 0.0;\n    oMat = 0.0;\n        \n    float base = terrainMap(p.xz).x; \n    \n    float bb = fbm_4(p.xz*0.15);\n\n    float d = 10.0;\n    vec2 n = floor( p.xz );\n    vec2 f = fract( p.xz );\n    for( int j=0; j<=1; j++ )\n    for( int i=0; i<=1; i++ )\n    {\n        vec2  g = vec2( float(i), float(j) ) - step(f,vec2(0.5));\n        vec2  o = hash2( n + g );\n        vec2  v = hash2( n + g + vec2(13.1,71.7) );\n        vec2  r = g - f + o;\n\n        float height = kMaxTreeHeight * (0.4+0.8*v.x);\n        float width = 0.5 + 0.2*v.x + 0.3*v.y;\n\n        if( bb<0.0 ) width *= 0.5; else height *= 0.7;\n        \n        vec3  q = vec3(r.x,p.y-base-height*0.5,r.y);\n        \n        float k = sdEllipsoidY( q, vec2(width,0.5*height) );\n\n        if( k<d )\n        { \n            d = k;\n            oMat = 0.5*hash1(n+g+111.0);\n            if( bb>0.0 ) oMat += 0.5;\n            oHei = (p.y - base)/height;\n            oHei *= 0.5 + 0.5*length(q) / width;\n        }\n    }\n\n    // distort ellipsoids to make them look like trees (works only in the distance really)\n    if( rt<500.0 )\n    {\n        float s = fbm_4( p*6.0 );\n        s = s*s;\n        float att = 1.0-smoothstep(50.0,500.0,rt);\n        d += 2.0*s*att;\n        oDis = s*att;\n    }\n    \n    return d;\n}\n\nfloat treesShadow( in vec3 ro, in vec3 rd )\n{\n    float res = 1.0;\n    float t = 0.02;\n#ifdef LOWQUALITY\n    for( int i=ZERO; i<64; i++ )\n    {\n        float kk1, kk2, kk3;\n        vec3 pos = ro + rd*t;\n        float h = treesMap( pos, t, kk1, kk2, kk3 );\n        res = min( res, 32.0*h/t );\n        t += h;\n        if( res<0.001 || t>50.0 || pos.y>kMaxHeight+kMaxTreeHeight ) break;\n    }\n#else\n    for( int i=ZERO; i<150; i++ )\n    {\n        float kk1, kk2, kk3;\n        float h = treesMap( ro + rd*t, t, kk1, kk2, kk3 );\n        res = min( res, 32.0*h/t );\n        t += h;\n        if( res<0.001 || t>120.0 ) break;\n    }\n#endif\n    return clamp( res, 0.0, 1.0 );\n}\n\nvec3 treesNormal( in vec3 pos, in float t )\n{\n    float kk1, kk2, kk3;\n#if 0    \n    const float eps = 0.005;\n    vec2 e = vec2(1.0,-1.0)*0.5773*eps;\n    return normalize( e.xyy*treesMap( pos + e.xyy, t, kk1, kk2, kk3 ) + \n                      e.yyx*treesMap( pos + e.yyx, t, kk1, kk2, kk3 ) + \n                      e.yxy*treesMap( pos + e.yxy, t, kk1, kk2, kk3 ) + \n                      e.xxx*treesMap( pos + e.xxx, t, kk1, kk2, kk3 ) );            \n#else\n    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times\n    vec3 n = vec3(0.0);\n    for( int i=ZERO; i<4; i++ )\n    {\n        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);\n        n += e*treesMap(pos+0.005*e, t, kk1, kk2, kk3);\n    }\n    return normalize(n);\n#endif    \n}\n\n//------------------------------------------------------------------------------------------\n// sky\n//------------------------------------------------------------------------------------------\n\nvec3 renderSky( in vec3 ro, in vec3 rd )\n{\n    // background sky     \n    //vec3 col = vec3(0.45,0.6,0.85)/0.85 - rd.y*vec3(0.4,0.36,0.4);\n    //vec3 col = vec3(0.4,0.6,1.1) - rd.y*0.4;\n    vec3 col = vec3(0.42,0.62,1.1) - rd.y*0.4;\n\n    // clouds\n    float t = (1000.0-ro.y)/rd.y;\n    if( t>0.0 )\n    {\n        vec2 uv = (ro+t*rd).xz;\n        float cl = fbm_9( uv*0.002 );\n        float dl = smoothstep(-0.2,0.6,cl);\n        col = mix( col, vec3(1.0), 0.3*0.4*dl );\n    }\n    \n\t// sun glare    \n    float sun = clamp( dot(kSunDir,rd), 0.0, 1.0 );\n    col += 0.2*vec3(1.0,0.6,0.3)*pow( sun, 32.0 );\n    \n\treturn col;\n}\n\n//------------------------------------------------------------------------------------------\n// main image making function\n//------------------------------------------------------------------------------------------\n\nvoid mainImage( out vec4 fragColor, in vec2 fragCoord )\n{\n    vec2 o = hash2( vec2(iFrame,1) ) - 0.5;\n    \n    vec2 p = (2.0*(fragCoord+o)-iResolution.xy)/ iResolution.y;\n    \n    //----------------------------------\n    // setup\n    //----------------------------------\n\n    // camera\n    float time = iTime;\n    vec3 ro = vec3(0.0, -99.25, 3.0);\n    vec3 ta = vec3(0.0, -98.25, -45.0 + ro.z );\n    \n    //ro += vec3(10.0*sin(0.02*time),0.0,-10.0*sin(0.2+0.031*time))\n    \n    ro.x -= 40.0*sin(0.01*time);\n    ta.x -= 43.0*sin(0.01*time);\n\n    // ray\n    mat3 ca = setCamera( ro, ta, 0.0 );\n    vec3 rd = ca * normalize( vec3(p,1.5));\n\n\tfloat resT = 1000.0;\n\n    //----------------------------------\n    // sky\n    //----------------------------------\n\n    vec3 col = renderSky( ro, rd );\n\n\n    //----------------------------------\n    // raycast terrain and tree envelope\n    //----------------------------------\n    {\n    const float tmax = 1000.0;\n    int   obj = 0;\n    vec2 t = raymarchTerrain( ro, rd, 15.0, tmax );\n    if( t.x>0.0 )\n    {\n        resT = t.x;\n        obj = 1;\n    }\n\n    //----------------------------------\n    // raycast trees, if needed\n    //----------------------------------\n    float hei, mid, displa;\n    if( t.y>0.0 )\n    {\n        float tf = t.y;\n        float tfMax = (t.x>0.0)?t.x:tmax;\n        for(int i=ZERO; i<64; i++) \n        { \n            vec3  pos = ro + tf*rd; \n            float dis = treesMap( pos, tf, hei, mid, displa); \n            if( dis<(0.00025*tf) ) break;\n            tf += dis;\n            if( tf>tfMax ) break;\n        }\n        if( tf<tfMax )\n        {\n            resT = tf;\n            obj = 2;\n        }\n    }\n\n    //----------------------------------\n    // shade\n    //----------------------------------\n    if( obj>0 )\n    {\n        vec3 pos  = ro + resT*rd;\n        vec3 epos = pos + vec3(0.0,2.4,0.0);\n\n        float sha1  = terrainShadow( pos+vec3(0,0.01,0), kSunDir, 0.01 );;\n        sha1 *= smoothstep(-25.0,25.0,60.0+cloudsShadowFlat(epos, kSunDir));\n        \n        #ifndef LOWQUALITY\n        float sha2  = treesShadow( pos+vec3(0,0.01,0), kSunDir );\n        #endif\n\n        vec3 tnor = terrainNormal( pos.xz );\n        vec3 nor;\n        \n        vec3 speC = vec3(1.0);\n        //----------------------------------\n        // terrain\n        //----------------------------------\n        if( obj==1 )\n        {\n            // bump map\n            nor = normalize( tnor + 0.8*(1.0-abs(tnor.y))*0.8*fbmd_7( pos*0.3*vec3(1.0,0.2,1.0) ).yzw );\n\n            col = vec3(0.18,0.12,0.10)*.85;\n\n            col = 1.0*mix( col, vec3(0.1,0.1,0.0)*0.2, smoothstep(0.7,0.9,nor.y) );      \n            float dif = clamp( dot( nor, kSunDir), 0.0, 1.0 ); \n            dif *= sha1;\n            #ifndef LOWQUALITY\n            dif *= sha2;\n            #endif\n\n            float bac = clamp( dot(normalize(vec3(-kSunDir.x,0.0,-kSunDir.z)),nor), 0.0, 1.0 );\n            float foc = clamp( (pos.y+120.0)/130.0, 0.0,1.0);\n            float dom = clamp( 0.5 + 0.5*nor.y, 0.0, 1.0 );\n            vec3  lin  = 1.0*0.2*mix(0.1*vec3(0.1,0.2,0.1),vec3(0.7,0.9,1.5)*3.0,dom)*foc;\n                  lin += 1.0*8.5*vec3(1.0,0.9,0.8)*dif;        \n                  lin += 1.0*0.27*vec3(1.1,1.0,0.9)*bac*foc;\n            speC = vec3(4.0)*dif*smoothstep(20.0,0.0,abs(pos.y-10.0)-20.0);\n\n            col *= lin;\n        }\n        //----------------------------------\n        // trees\n        //----------------------------------\n        else //if( obj==2 )\n        {\n            vec3 gnor = treesNormal( pos, resT );\n            \n            nor = normalize( gnor + 2.0*tnor );\n\n            // --- lighting ---\n            vec3  ref = reflect(rd,nor);\n            float occ = clamp(hei,0.0,1.0) * pow(1.0-2.0*displa,3.0);\n            float dif = clamp( 0.1 + 0.9*dot( nor, kSunDir), 0.0, 1.0 ); \n            dif *= sha1;\n            if( dif>0.0001 )\n            {\n                float a = clamp( 0.5+0.5*dot(tnor,kSunDir), 0.0, 1.0);\n                a = a*a;\n                a *= occ;\n                a *= 0.6;\n                a *= smoothstep(30.0,100.0,resT);\n                // tree shadows with fake transmission\n                #ifdef LOWQUALITY\n                float sha2  = treesShadow( pos+kSunDir*0.05, kSunDir );\n                #endif\n                dif *= a+(1.0-a)*sha2;\n            }\n            float dom = clamp( 0.5 + 0.5*nor.y, 0.0, 1.0 );\n            float fre = clamp(1.0+dot(nor,rd),0.0,1.0);\n            //float spe = pow( clamp(dot(ref,kSunDir),0.0, 1.0), 9.0 )*dif*(0.2+0.8*pow(fre,5.0))*occ;\n\n            // --- lights ---\n            vec3 lin  = 1.1*0.5*mix(0.1*vec3(0.1,0.2,0.0),vec3(0.6,1.0,1.0),dom*occ);\n                 lin += 1.5*8.0*vec3(1.2,1.0,0.7)*dif*occ*(2.0-smoothstep(0.0,120.0,resT));\n                 lin += 1.1*vec3(0.9,1.0,0.8)*pow(fre,5.0)*occ*(1.0-smoothstep(100.0,200.0,resT));\n                 lin += 0.06*vec3(0.15,0.4,0.1)*occ;\n            speC = dif*vec3(1.0,1.1,1.5)*1.2;\n\n            // --- material ---\n            float brownAreas = fbm_4( pos.zx*0.03 );\n            col = vec3(0.08,0.08,0.02)*0.45;\n            col = mix( col, vec3(0.13,0.08,0.02)*0.45, smoothstep(0.2,0.9,fract(2.0*mid)) );\n            col *= (mid<0.5)?0.65+0.3*smoothstep(150.0,300.0,resT)*smoothstep(50.0,-50.0,pos.y):1.0;\n            col = mix( col, vec3(0.25,0.16,0.01)*0.15, 0.7*smoothstep(0.1,0.3,brownAreas)*smoothstep(0.5,0.8,tnor.y) );\n            col *= 2.0*1.64*1.3;\n            col *= 1.0-0.35*smoothstep(-100.0,50.0,pos.y);\n            col *= lin;\n\n        }\n\n        // spec\n        vec3  ref = reflect(rd,nor);            \n        float fre = clamp(1.0+dot(nor,rd),0.0,1.0);\n        float spe = 3.0*pow( clamp(dot(ref,kSunDir),0.0, 1.0), 9.0 )*(0.05+0.95*pow(fre,5.0));\n        col += spe*speC;\n\n        col = fog(col,resT);\n    }\n    }\n\n\n\n    float isCloud = 0.0;\n    //----------------------------------\n    // clouds\n    //----------------------------------\n    {\n        vec4 res = renderClouds( ro, rd, 0.0, resT, resT, fragCoord );\n        col = col*(1.0-res.w) + res.xyz;\n        isCloud = res.w;\n    }\n\n    //----------------------------------\n    // final\n    //----------------------------------\n    \n    // sun glare    \n    float sun = clamp( dot(kSunDir,rd), 0.0, 1.0 );\n    col += 0.25*vec3(0.8,0.4,0.2)*pow( sun, 4.0 );\n \n\n    // gamma\n    //col = sqrt( clamp(col,0.0,1.0) );\n    col = pow( clamp(col*1.1-0.02,0.0,1.0), vec3(0.4545) );\n\n    // contrast\n    col = col*col*(3.0-2.0*col);            \n    \n    // color grade    \n    col = pow( col, vec3(1.0,0.92,1.0) );   // soft green\n    col *= vec3(1.02,0.99,0.99);            // tint red\n    col.z = (col.z+0.1)/1.1;                // bias blue\n    \n    //------------------------------------------\n\t// reproject from previous frame and average\n    //------------------------------------------\n\n    mat4 oldCam = mat4( textureLod(iChannel0,vec2(0.5,0.5)/iResolution.xy, 0.0),\n                        textureLod(iChannel0,vec2(1.5,0.5)/iResolution.xy, 0.0),\n                        textureLod(iChannel0,vec2(2.5,0.5)/iResolution.xy, 0.0),\n                        0.0, 0.0, 0.0, 1.0 );\n    \n    // world space\n    vec4 wpos = vec4(ro + rd*resT,1.0);\n    // camera space\n    vec3 cpos = (wpos*oldCam).xyz; // note inverse multiply\n    // ndc space\n    vec2 npos = 1.5 * cpos.xy / cpos.z;\n    // screen space\n    vec2 spos = 0.5 + 0.5*npos*vec2(iResolution.y/iResolution.x,1.0);\n    // undo dither\n    spos -= o/iResolution.xy;\n\t// raster space\n    vec2 rpos = spos * iResolution.xy;\n    \n    if( rpos.y<1.0 && rpos.x<3.0 )\n    {\n    }\n\telse\n    {\n        vec3 ocol = textureLod( iChannel0, spos, 0.0 ).xyz;\n    \tif( iFrame==0 ) ocol = col;\n        col = mix( ocol, col, 0.1+0.8*isCloud );\n    }\n\n    //----------------------------------\n                           \n\tif( fragCoord.y<1.0 && fragCoord.x<3.0 )\n    {\n        if( abs(fragCoord.x-2.5)<0.5 ) fragColor = vec4( ca[2], -dot(ca[2],ro) );\n        if( abs(fragCoord.x-1.5)<0.5 ) fragColor = vec4( ca[1], -dot(ca[1],ro) );\n        if( abs(fragCoord.x-0.5)<0.5 ) fragColor = vec4( ca[0], -dot(ca[0],ro) );\n    }\n    else\n    {\n        fragColor = vec4( col, 1.0 );\n    }\n}";
//             description = "";
//             inputs =             (
//                                 {
//                     channel = 0;
//                     ctype = buffer;
//                     id = 257;
//                     published = 1;
//                     sampler =                     {
//                         filter = linear;
//                         internal = byte;
//                         srgb = false;
//                         vflip = true;
//                         wrap = clamp;
//                     };
//                     src = "/media/previz/buffer00.png";
//                 }
//             );
//             name = "Buffer A";
//             outputs =             (
//                                 {
//                     channel = 0;
//                     id = 257;
//                 }
//             );
//             type = buffer;
//         }
//     );
//     ver = "0.1";
// }
