void main()  {
    mainImage(gl_FragColor, gl_FragCoord.xy + ifFragCoordOffsetUniform );
    gl_FragColor.w = 1.;
}