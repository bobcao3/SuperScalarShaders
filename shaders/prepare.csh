#version 430 compatibility

#pragma optimize(on)

layout (local_size_x = 32, local_size_y = 32) in;

layout (r11f_g11f_b10f) uniform image2D colorimg4;

const vec2 workGroupsRender = vec2(0.25f, 0.5f);

#include "libs/compat.glsl"

#include "/libs/atmosphere.glsl"

uniform int frameCounter;

void main()
{
    ivec2 iuv = ivec2(gl_GlobalInvocationID.xy);

    if (iuv.x <= (int(viewWidth) >> 2) && iuv.y <= (int(viewHeight) >> 1) && frameCounter % 2 == 0)
    {
        vec4 skybox = vec4(0.0);
    
        vec2 uv = (vec2(iuv) * invWidthHeight) * 4.0;
        skybox.rg = clamp(vec2(densitiesMap(uv)), vec2(0.0), vec2(200.0));
        skybox.ba = vec2(0.0);
    
        imageStore(colorimg4, iuv + ivec2(0, int(viewHeight) >> 1), skybox);
    }
}