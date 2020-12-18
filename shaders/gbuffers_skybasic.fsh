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

// uniform sampler2D gaux3;

void main()
{
    vec4 color = vec4(0.0);

    if (color.r > 0.5)
        color = vertex_color;

    vec3 world_dir = normalize(world_position.xyz);

    color.rgb += pow(texture(gaux3, project_skybox2uv(world_dir)).rgb, vec3(1.0 / 2.2));

    gl_FragData[0] = color;
}