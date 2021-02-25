#version 430 compatibility

#pragma optimize(on)

layout (local_size_x = 8, local_size_y = 8) in;

layout (r11f_g11f_b10f) uniform image2D colorimg4;

const vec2 workGroupsRender = vec2(0.0078125f, 0.00390625f);

uniform int frameCounter;

// uniform float viewWidth;
// uniform float viewHeight;

#include "/libs/transform.glsl"

void main()
{
    ivec2 iuv = ivec2(gl_GlobalInvocationID.xy);

    if (frameCounter % 5 != 0) {
        return;
    }

    int iViewWidth = int(viewWidth);

    int h_offset = (iViewWidth >> 1) + (iViewWidth >> 2) + (iViewWidth >> 3) + (iViewWidth >> 4) + (iViewWidth >> 5) + (iViewWidth >> 6);

    vec3 skybox = vec3(0.0);

    for (int i = -2; i <= 2; i++)
    {
        for (int j = -2; j <= 2; j++)
        {
            vec2 uv = vec2(iuv * 64 + ivec2(i, j)) * invWidthHeight;
            skybox += sampleLODmanual(colortex4, clamp(uv, vec2(0.0), vec2(0.25, 0.125)), 5).rgb;
        }
    }

    skybox *= (1.0 / 25.0);

    imageStore(colorimg4, iuv + ivec2(h_offset, 0), vec4(skybox, 0.0));
}