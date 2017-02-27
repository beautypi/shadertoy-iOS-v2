out vec4 glFragColor;

void main()  {
    float t = ifFragCoordOffsetUniform.x + (((iResolution.x-0.5+gl_FragCoord.x)/11025.) + (iResolution.y-.5-gl_FragCoord.y)*(iResolution.x/11025.));
    vec2 y = mainSound( t );
    vec2 v  = floor((0.5+0.5*y)*65536.0);
    vec2 vl = mod(v,256.0)/255.0;
    vec2 vh = floor(v/256.0)/255.0;
    glFragColor = vec4(vl.x,vh.x,vl.y,vh.y);
}
