#version 300 es

precision highp float;
precision highp int;

layout(location = 0) in vec3 uPosition;
layout(location = 1) in vec2 uUV;

void main() {
    gl_Position.xyz = uPosition;
    gl_Position.w = 1.0;
}
