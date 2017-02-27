out vec4 glFragColor;

void main()  {
    mainImage(glFragColor, gl_FragCoord.xy + ifFragCoordOffsetUniform );
}
