#version 430 compatibility

#pragma optimize(on)

#include "libs/compat.glsl"

/* RENDERTARGETS: 0,3 */

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

    if (iuv.x < volume_width * volume_depth_grid_width && iuv.y < volume_height * volume_depth_grid_height)
    {
        vec4 voxel_color = texelFetch(shadowcolor0, iuv, 0).rgba;
        float voxel_attribute = texelFetch(shadowtex0, iuv, 0).r;

        ivec3 volume_pos = planar2volume(iuv);
        ivec3 prev_volume_pos = volume_pos + ivec3(floor(cameraPosition) - floor(previousCameraPosition));
        ivec2 prev_planar_pos = volume2planar(prev_volume_pos);

        vec4 prev_color = texelFetch(colortex3, prev_planar_pos, 0);
        float prev_solid = prev_color.a;

        if (voxel_color.a > 0.9 && (voxel_attribute < 0.54 || voxel_attribute > 0.56))
        {
            voxel_color = vec4(0.0);

            if (prev_planar_pos != ivec2(-1))
            {
                voxel_color.rgb = prev_color.rgb * 0.95;
            }
        }
        else
        {
            voxel_color.a = float(voxel_color.a < 0.9);

            if (voxel_attribute > 0.54 && voxel_attribute < 0.56)
            {
                voxel_color.rgb = mix(prev_color.rgb, voxel_color.rgb * 20.0, 0.2);
            }
            else
            {
                voxel_color.rgb = vec3(0.0);
            }
        }

        gl_FragData[1] = voxel_color;
    }
}