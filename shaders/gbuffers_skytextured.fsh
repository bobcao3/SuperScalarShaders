#version 420 compatibility

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

uniform sampler2D tex;

uniform vec3 fogColor;

void main()
{
    vec4 color = vertex_color * texture(tex, uv);

    gl_FragData[0] = color;
}