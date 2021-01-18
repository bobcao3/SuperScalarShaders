#version 420 compatibility

#pragma optimize(on)

#include "/libs/compat.glsl"

in VertexOut {
    vec4 vertex_color;
};

/* DRAWBUFFERS: 0 */

#include "voxelize.glslinc"
#include "color.glslinc"
#include "/libs/transform.glsl"

uniform vec3 fogColor;

void main()
{
    vec4 color = vertex_color;

    gl_FragData[0] = color;
}