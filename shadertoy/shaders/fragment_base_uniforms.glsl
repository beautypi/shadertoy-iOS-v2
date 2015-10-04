precision highp float;
precision highp int;
precision mediump sampler2D;

uniform vec3      iResolution;                  // viewport resolution (in pixels)
uniform float     iGlobalTime;                  // shader playback time (in seconds)
uniform vec4      iMouse;                       // mouse pixel coords
uniform vec4      iDate;                        // (year, month, day, time in seconds)
uniform float     iSampleRate;                  // sound sample rate (i.e., 44100)
uniform vec3      iChannelResolution[4];        // channel resolution (in pixels)
uniform float     iChannelTime[4];              // channel playback time (in sec)

uniform vec2      ifFragCoordOffsetUniform;     // used for tiled based hq rendering

float fwidth(float p){return 0.;}  vec2 fwidth(vec2 p){return vec2(0.);}  vec3 fwidth(vec3 p){return vec3(0.);}
float dFdx(float p){return 0.;}  vec2 dFdx(vec2 p){return vec2(0.);}  vec3 dFdx(vec3 p){return vec3(0.);}
float dFdy(float p){return 0.;}  vec2 dFdy(vec2 p){return vec2(0.);}  vec3 dFdy(vec3 p){return vec3(0.);}
