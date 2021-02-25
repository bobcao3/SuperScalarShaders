#version 430 compatibility

#pragma optimize(on)

// layout (local_size_x = 16, local_size_y = 16) in;

// layout (rg32f) uniform image2D colorimg4;

const vec2 workGroupsRender = vec2(0.5f, 0.5f);

#include "libs/compat.glsl"

/* RENDERTARGETS: 4 */

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