#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

uniform sampler2D SamplerY;
uniform sampler2D SamplerUV;

out vec4 color;

in vec2 vUV;

void main()
{
    vec3 yuv;
    vec3 rgb;
    
    yuv.x = texture(SamplerY, vUV).r - (16.0 / 255.0);
    yuv.yz = texture(SamplerUV, vUV).ra - vec2(0.5, 0.5);

    rgb = mat3(      1,       1,      1,
               0, -.18732, 1.8556,
               1.57481, -.46813,      0) * yuv;
  
    color = vec4(rgb, 1);
//    color = vec4(vUV, 0, 1);
}
