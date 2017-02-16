#version 300 es

precision highp float;
precision highp int;

in vec3 position;

void main() {
    gl_Position.xyz = position;
    gl_Position.w = 1.0;
}
