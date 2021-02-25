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

    // vec3 world_dir = normalize(world_position.xyz);

    // color *= max(0.0, world_dir.y);

    // color.rgb += pow(texture(colortex4, project_skybox2uv(world_dir)).rgb, vec3(1.0 / 2.2)) + bayer2(gl_FragCoord.st) * 0.02;

    // color.a = 1.0;

    gl_FragData[0] = color;
}