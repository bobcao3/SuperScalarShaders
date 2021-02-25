#version 430 compatibility

#pragma optimize(on)

layout (local_size_x = 16, local_size_y = 16) in;

layout (r11f_g11f_b10f) uniform image2D colorimg4;

const vec2 workGroupsRender = vec2(0.13f, 0.063f);

uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;

shared vec3 colors[16][16];

void main()
{
    ivec2 iuv = ivec2(gl_GlobalInvocationID.xy);

    if (frameCounter % 5 != 0) {
        return;
    }

    vec4 skybox = vec4(0.0);

    int h_offset = int(viewWidth) >> 1;

    vec3 s = imageLoad(colorimg4, iuv * 2).rgb;
    s += imageLoad(colorimg4, iuv * 2 + ivec2(0, 1)).rgb;
    s += imageLoad(colorimg4, iuv * 2 + ivec2(1, 1)).rgb;
    s += imageLoad(colorimg4, iuv * 2 + ivec2(1, 0)).rgb;

    s *= 0.25;

    imageStore(colorimg4, ivec2(h_offset, 0) + iuv, vec4(s, 0.0));

    colors[gl_LocalInvocationID.x][gl_LocalInvocationID.y] = s;

    for (int lod = 1; lod <= 4; lod++)
    {
        h_offset += int(viewWidth) >> (lod + 1);

        int stride = 1 << lod;
        int substride = 1 << (lod - 1);

        memoryBarrierShared();

        if (gl_LocalInvocationID.x % stride != 0 || gl_LocalInvocationID.y % stride != 0) return;

        s += colors[gl_LocalInvocationID.x            ][gl_LocalInvocationID.y + substride];
        s += colors[gl_LocalInvocationID.x + substride][gl_LocalInvocationID.y            ];
        s += colors[gl_LocalInvocationID.x + substride][gl_LocalInvocationID.y + substride];

        s *= 0.25;

        colors[gl_LocalInvocationID.x][gl_LocalInvocationID.y] = s;

        imageStore(colorimg4, (iuv >> lod) + ivec2(h_offset, 0), vec4(s, 0.0));
    }
}