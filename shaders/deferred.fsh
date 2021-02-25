#version 430 compatibility

#pragma optimize(on)

#include "libs/compat.glsl"

/* RENDERTARGETS: 0 */

uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;

// uniform sampler2D colortex5;

#include "voxelize.glslinc"

// uniform vec3 previousCameraPosition;
// uniform vec3 cameraPosition;

#include "/libs/atmosphere.glsl"
#include "/libs/transform.glsl"

#include "color.glslinc"

in vec3 world_sun_dir;
in vec3 ambient;

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);

    float depth = texelFetch(depthtex0, iuv, 0).r;

    vec4 proj_pos = vec4(vec2(iuv) * invWidthHeight * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 view_pos = gbufferProjectionInverse * proj_pos;
    view_pos.xyz /= view_pos.w;
    vec3 world_pos = mat3(gbufferModelViewInverse) * (view_pos.xyz);
    vec3 world_dir = normalize(world_pos);

    vec3 color = texelFetch(colortex0, iuv, 0).rgb;

    if (depth >= 1.0)
    {
        color *= 3.0 * smoothstep(max(0.0, world_dir.y), 0.0, 0.03);
        color += texture(colortex4, project_skybox2uv(world_dir)).rgb;

        color += cloud2d(world_pos, cameraPosition) * ambient;
    }

    gl_FragData[0] = vec4(color, 1.0);
}