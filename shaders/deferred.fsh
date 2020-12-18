#version 420 compatibility

#pragma optimize(on)

#include "libs/compat.glsl"

/* DRAWBUFFERS: 4 */

uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;

uniform sampler2D gaux1;
// uniform sampler2D gaux2;

#include "voxelize.glslinc"

// uniform vec3 previousCameraPosition;
// uniform vec3 cameraPosition;

#include "/libs/atmosphere.glsl"

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);

    if (iuv.x < volume_width * volume_depth_grid_width && iuv.y < volume_height * volume_depth_grid_height)
    {
        vec4 voxel_color = texelFetch(shadowcolor0, iuv, 0).rgba;
        vec4 voxel_attribute = texelFetch(shadowcolor1, iuv, 0).rgba;

        if (voxel_color.a > 0.9 && voxel_attribute.r > 0.9)
        {
            voxel_color = vec4(0.0);

            ivec3 volume_pos = planar2volume(iuv);
            ivec3 prev_volume_pos = volume_pos - ivec3(previousCameraPosition) + ivec3(cameraPosition);
            ivec2 prev_planar_pos = volume2planar(prev_volume_pos);

            vec4 prev_color = texelFetch(gaux1, prev_planar_pos, 0);
            float prev_solid = texelFetch(gaux2, prev_planar_pos, 0).a;
            
            if (prev_planar_pos != ivec2(-1) && prev_solid < 1.0)
            {
                voxel_color.rgb = prev_color.rgb * 0.9;
            }
        }
        else
        {
            voxel_color.a = float(voxel_color.a < 0.9);

            if (voxel_attribute.r < 1.0 && voxel_attribute.r > 0.0)
            {
                voxel_color.rgb = pow(voxel_color.rgb, vec3(2.2)) * 10.0;
            }
            else
            {
                voxel_color.rgb = vec3(0.0);
            }
        }

        gl_FragData[0] = voxel_color;
    }
}