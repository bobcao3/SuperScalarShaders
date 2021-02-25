#version 430 compatibility

#pragma optimize(on)

#include "/libs/compat.glsl"

in VertexOut {
    vec4 vertex_color;
    vec4 world_position;
    vec2 uv;
};

/* DRAWBUFFERS: 0 */

#include "voxelize.glslinc"
#include "color.glslinc"
#include "/libs/transform.glsl"
#include "/libs/noise.glsl"

// uniform sampler2D colortex4;

void main()
{
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

    if (max(abs(vertex_color.r - vertex_color.g), abs(vertex_color.r - vertex_color.b)) < 0.01)
        color = vec4(vertex_color.rgb, 1.0);

    gl_FragData[0] = color;
}