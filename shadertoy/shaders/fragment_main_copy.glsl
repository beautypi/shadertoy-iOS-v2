#version 300 es

precision highp float;
precision highp int;

uniform highp sampler2D sourceTexture;
uniform vec2 sourceResolution;
uniform vec2 targetResolution;

out vec4 glFragColor;

void main()  {
    vec2 fragCoordScaled = gl_FragCoord.xy / targetResolution;
    fragCoordScaled *= targetResolution / sourceResolution;
    
    if( fragCoordScaled.x >= 1. || fragCoordScaled.y >= 1. ) discard;
    
    // gl_FragColor = vec4( fragCoordScaled, 0,1); //
    glFragColor = texture( sourceTexture, fragCoordScaled );
}
