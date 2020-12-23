#version 420 compatibility

#pragma optimize(on)

#include "libs/compat.glsl"

/* DRAWBUFFERS: 6 */

#include "/libs/atmosphere.glsl"

uniform int frameCounter;

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);

    if (iuv.x <= (int(viewWidth) >> 2) && iuv.y >= (int(viewHeight) >> 2) && frameCounter % 2 == 0)
    {
        vec4 skybox = vec4(0.0);
    
        vec2 uv = (vec2(iuv) * invWidthHeight - vec2(0.0, 0.5)) * 4.0;
        skybox.rg = clamp(vec2(densitiesMap(uv)), vec2(0.0), vec2(200.0));
        skybox.ba = vec2(0.0);
    
        gl_FragData[0] = skybox;
    } else {
        discard;
    }
}