#version 300 es

precision highp float;
precision highp int;

layout(location = 0) in vec3 uPosition;
layout(location = 1) in vec2 uUV;

uniform int uOrientation;

out vec2 vUV;

void main() {
    gl_Position.xyz = uPosition;
    gl_Position.w = 1.0;
    
    vUV = uPosition.xy * .5 + .5;
    
    if( uOrientation == 1 ) { // UIInterfaceOrientationPortrait
        vUV = vec2( 1.-vUV.y, 1.-vUV.x );
        vUV.x = (vUV.x-.5) * 9./16. * 9./16. + .5;
    } if( uOrientation == 2 ) { // UIInterfaceOrientationLandscapeLeft
        vUV = vec2( 1.-vUV.x, vUV.y );
    } else if( uOrientation == 3 ) { // UIInterfaceOrientationLandscapeRight
        vUV = vec2( vUV.x, 1.-vUV.y );
    } else {
        
    }
}

