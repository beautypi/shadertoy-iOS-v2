

uniform mat3 iDeviceRotationUniform;


#ifdef VR_SETTINGS_FULLSCREEN
vec4 iLeftEyeRect = vec4( 0., 0., 1., 1.);
vec4 iLeftEyeDegrees = vec4( -1., 0.472964775891327, 1., -0.472964775891327);
vec3 iLeftEyeTranslation = vec3( 0., 0., 0. );
vec3 iLeftEyeRotation = vec3( 0., 0., 0. );

vec4 iRightEyeRect = vec4( 0., 0., 0., 0.);
vec4 iRightEyeDegrees = vec4( -1., 0.472964775891327, 1., -0.472964775891327);
vec3 iRightEyeTranslation = vec3( 0., 0., 0. );
vec3 iRightEyeRotation = vec3( 0., 0., 0. );
#endif


#ifdef VR_SETTINGS_CARDBOARD
    vec4 iLeftEyeRect = vec4( 0., 0., .5, 1.);
    vec4 iLeftEyeDegrees = vec4( -0.946, 1.0, 0.946, -1.0); //  tan( vec4( -64., 64., 64., -64.) * (2. * 3.1415925 / 360. ) );
    vec3 iLeftEyeTranslation = vec3( -0.032, 0., 0. );
    vec3 iLeftEyeRotation = vec3( 0., 0., 0. );

    vec4 iRightEyeRect = vec4( 0.5, 0., 1., 1.);
    vec4 iRightEyeDegrees = vec4( -0.946, 1.0, 0.946, -1.0); //  tan( vec4( -64., 64., 64., -64.) * (2. * 3.1415925 / 360. ) );
    vec3 iRightEyeTranslation = vec3( 0.032, 0., 0. );
    vec3 iRightEyeRotation = vec3( 0., 0., 0. );
#endif


#ifdef VR_SETTINGS_CROSS_EYE
    vec4 iLeftEyeRect = vec4( 0.5, 0., 1., 1.);
    vec4 iLeftEyeDegrees = vec4( -1., 0.472964775891327, 1., -0.472964775891327);
    vec3 iLeftEyeTranslation = vec3( -0.063, 0., 0. );
    vec3 iLeftEyeRotation = vec3( 0., 0., 0. );

    vec4 iRightEyeRect = vec4( 0., 0., .5, 1.);
    vec4 iRightEyeDegrees = vec4( -1., 0.472964775891327, 1., -0.472964775891327);
    vec3 iRightEyeTranslation = vec3( 0.063, 0., 0. );
    vec3 iRightEyeRotation = vec3( 0., 0., 0. );
#endif


#ifdef VR_SETTINGS_RED_CYAN
    vec4 iLeftEyeRect = vec4( 0., 0., 1., 1.);
    vec4 iLeftEyeDegrees = vec4( -1., 0.472964775891327, 1., -0.472964775891327);
    vec3 iLeftEyeTranslation = vec3( -0.063, 0., 0. );
    vec3 iLeftEyeRotation = vec3( 0., 0., 0. );

    vec4 iRightEyeRect = vec4( 0., 0., 1., 1.);
    vec4 iRightEyeDegrees = vec4( -1., 0.472964775891327, 1., -0.472964775891327);
    vec3 iRightEyeTranslation = vec3( 0.063, 0., 0. );
    vec3 iRightEyeRotation = vec3( 0., 0., 0. );
#endif

mat3 iVrMatRotate( in vec3 xyz ) {
    vec3 si = sin(xyz);
    vec3 co = cos(xyz);
    
    return mat3(    co.y*co.z,                co.y*si.z,               -si.y,
                    si.x*si.y*co.z-co.x*si.z, si.x*si.y*si.z+co.x*co.z, si.x*co.y,
                    co.x*si.y*co.z+si.x*si.z, co.x*si.y*si.z-si.x*co.z, co.x*co.y );
}

void main()  {
    vec2 fragCoordScaled = (gl_FragCoord.xy + ifFragCoordOffsetUniform.xy) / iResolution.xy;
    
    bool leftEye  = all( greaterThanEqual( fragCoordScaled.xy, iLeftEyeRect.xy ) ) && all( lessThanEqual( fragCoordScaled.xy, iLeftEyeRect.zw ) );
    
    vec2 fragCoord = (gl_FragCoord.xy + ifFragCoordOffsetUniform.xy);
    
#ifdef VR_SETTINGS_RED_CYAN
    float eyeID = mod(fragCoord.x + mod(fragCoord.y,2.0),2.0);
    leftEye = eyeID > 0.;
#endif
    
    vec4 eyeRect        = leftEye ? iLeftEyeRect : iRightEyeRect;
    vec3 eyeRotation    = leftEye ? iLeftEyeRotation : iRightEyeRotation;
    vec4 eyeDegrees     = (leftEye ? iLeftEyeDegrees : iRightEyeDegrees);
    vec3 eyeTranslation = leftEye ? iLeftEyeTranslation : iRightEyeTranslation;
    
    vec2 uv = (fragCoordScaled-eyeRect.xy)/(eyeRect.zw-eyeRect.xy);

#ifdef VR_SETTINGS_CARDBOARD
    float r = dot( uv - .5, uv - .5 );
    uv = uv * ( 1. + 0.33582564 * r + 0.55348791
               
 * r * r);
#endif
    
    
    vec3 rd = normalize( vec3( mix( eyeDegrees.x, eyeDegrees.z, uv.x ),
                               -mix( eyeDegrees.y, eyeDegrees.w, uv.y ),
                               -1. ) );
    vec3 ro = eyeTranslation;
    
    eyeRotation.yx = .5*mix( vec2(-3.1415926), vec2(3.1415926), abs(iMouse.xy) / iResolution.xy ) * vec2(1.,-1.);
    
 //   eyeRotation = vec3(-1.5707963267949-iDeviceRotationUniform.z, iDeviceRotationUniform.y, -iDeviceRotationUniform.x);
    
    mat3 rotation = iVrMatRotate( eyeRotation );
    
    rotation = iDeviceRotationUniform;
    
    rd = rotation * vec3(rd.y, -rd.x, rd.z);
    ro = rotation * vec3(ro.y, -ro.x, ro.z);
    
    mainVR( gl_FragColor, uv * iResolution.xy, vec3(-ro.x, ro.yz), vec3(-rd.x, rd.yz) );

#ifdef VR_SETTINGS_RED_CYAN
    gl_FragColor.xyz *= vec3( eyeID, 1.0-eyeID, 1.0-eyeID );
#endif
    
    gl_FragColor.w = 1.;
}
