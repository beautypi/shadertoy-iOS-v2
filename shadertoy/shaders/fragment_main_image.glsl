// empty line

out vec4 glFragColor;

void main()  {
    glFragColor.w = 1.;

    mainImage(glFragColor, (gl_FragCoord.xy+ifFragCoordOffsetUniform) );
}
