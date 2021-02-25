#version 430 compatibility

#pragma optimize(on)

#include "libs/compat.glsl"

layout (local_size_x = 32, local_size_y = 32) in;

const vec2 workGroupsRender = vec2(1.0f, 1.0f);

/* RENDERTARGETS: 1 */

uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex0;

const bool shadowcolor1Clear = false;

#include "voxelize.glslinc"

// uniform vec3 previousCameraPosition;
// uniform vec3 cameraPosition;

#include "/libs/atmosphere.glsl"
#include "/libs/transform.glsl"

#include "color.glslinc"

layout (rgba16f) uniform image2D shadowcolorimg1;

void main()
{
    ivec2 iuv = ivec2(gl_GlobalInvocationID.xy);

    vec4 voxel_color = texelFetch(shadowcolor0, iuv, 0).rgba;
    float voxel_attribute = texelFetch(shadowtex0, iuv, 0).r;

    ivec3 volume_pos = planar2volume(iuv);
    ivec3 prev_volume_pos = volume_pos + ivec3(floor(cameraPosition)) - ivec3(floor(previousCameraPosition));
    ivec2 prev_planar_pos = volume2planar(prev_volume_pos);

    if (voxel_color.a > 0.9 && (voxel_attribute < 0.54 || voxel_attribute > 0.56))
    {
        voxel_color = vec4(0.0);

        vec4 prev_color = texelFetch(shadowcolor1, prev_planar_pos, 0);
        float prev_solid = prev_color.a;

        if (prev_planar_pos != ivec2(-1) && (prev_solid < 0.3))
        {
            voxel_color.rgb = prev_color.rgb * 0.7;
        }
    }
    else
    {
        voxel_color.a = float(voxel_color.a < 0.9);

        if (voxel_attribute > 0.54 && voxel_attribute < 0.56)
        {
            voxel_color.rgb = voxel_color.rgb * 20.0;
        }
        else
        {
            voxel_color.rgb = vec3(0.0);
        }
    }

    // gl_FragData[0] = vec4(voxel_color);

    imageStore(shadowcolorimg1, iuv, voxel_color);
}