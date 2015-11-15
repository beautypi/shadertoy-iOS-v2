vec4 iLeftEyeRect = vec4( 0., 0., 1., 1.);
vec4 iLeftEyeDegrees = vec4( -45., 45.*9./16., 45., -45.*9./16.);
vec3 iLeftEyeTranslation = vec3( -0.063, 0., 0. );
vec3 iLeftEyeRotation = vec3( 0., 0., 0. );

vec4 iRightEyeRect = vec4( 0., 0., 1., 1.);
vec4 iRightEyeDegrees = vec4( -45., 45.*9./16., 45., -45.*9./16.);
vec3 iRightEyeTranslation = vec3( 0.063, 0., 0. );
vec3 iRightEyeRotation = vec3( 0., 0., 0. );

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
    float eyeID = mod(fragCoord.x + mod(fragCoord.y,2.0),2.0);
    leftEye = eyeID > 0.;
    
    vec4 eyeRect        = leftEye ? iLeftEyeRect : iRightEyeRect;
    vec3 eyeRotation    = leftEye ? iLeftEyeRotation : iRightEyeRotation;
    vec4 eyeDegrees     = (leftEye ? iLeftEyeDegrees : iRightEyeDegrees) * (2. * 3.1415925 / 360. );
    vec3 eyeTranslation = leftEye ? iLeftEyeTranslation : iRightEyeTranslation;
    
    vec2 uv = (fragCoordScaled-eyeRect.xy)/(eyeRect.zw-eyeRect.xy);

//    eyeDegrees.xz *= .5;
    
    vec3 rd = normalize( vec3( mix( tan( eyeDegrees.x ), tan( eyeDegrees.z ), uv.x ),
                               -mix( tan( eyeDegrees.y ), tan( eyeDegrees.w ), uv.y ),
                               -1. ) );
    vec3 ro = eyeTranslation;
    
    eyeRotation.yx = .5*mix( vec2(-3.1415926), vec2(3.1415926), abs(iMouse.xy) / iResolution.xy ) * vec2(1.,-1.);
    
    mat3 rotation = iVrMatRotate( eyeRotation );
    rd = rotation * rd;
    ro = rotation * ro;
    
    mainVR( gl_FragColor, uv * iResolution.xy, ro, rd );
    
    gl_FragColor.xyz *= vec3( eyeID, 1.0-eyeID, 1.0-eyeID );
    
    gl_FragColor.w = 1.;
}