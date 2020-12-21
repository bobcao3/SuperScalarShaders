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
#include "/libs/noise.glsl"

// uniform sampler2D gaux3;

void main()
{
    vec4 color = vec4(0.0);

    if (max(abs(vertex_color.r - vertex_color.g), abs(vertex_color.r - vertex_color.b)) < 0.01)
        color = vertex_color;

    vec3 world_dir = normalize(world_position.xyz);

    color.rgb += pow(texture(gaux3, project_skybox2uv(world_dir)).rgb, vec3(1.0 / 2.2)) + bayer2(gl_FragCoord.st) * 0.02;

    gl_FragData[0] = color;
}