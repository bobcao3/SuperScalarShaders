#version 430 compatibility
#pragma optimize(on)

#include "/libs/compat.glsl"

const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex4Clear = false;

#define VECTORS
#define TRANSFORMATIONS_RESIDUAL

#include "/libs/transform.glsl"
#include "/libs/noise.glsl"
#include "/libs/atmosphere.glsl"

// #define TAA_NO_CLIP

#include "voxelize.glslinc"

uniform int frameCounter;

uniform vec3 fogColor;

uniform int biomeCategory;

#include "/libs/taa.glsl"

#include "color.glslinc"

uniform int isEyeInWater;

void main() {
    ivec2 iuv = ivec2(gl_FragCoord.st);
    
    // bloom compositing

    vec3 color = texelFetch(colortex0, iuv, 0).rgb;

    #define BLOOM

    #ifdef BLOOM
    vec2 uv = vec2(iuv) * invWidthHeight;

    color = color + (
        texture(colortex8, uv * 0.5).rgb * 0.3
      + texture(colortex8, uv * 0.125 + vec2(0.0, 0.75)).rgb * 0.3
      + texture(colortex8, uv * 0.03125 + vec2(0.5, 0.75)).rgb * 0.5
    ) * 0.7;

    // color = texture(colortex8, uv).rgb;
    #endif

    vec3 vl = vec3(0.0);
    iuv *= 2;

    if (iuv.x < viewWidth && iuv.y < viewHeight)
    {
        float depth = getDepth(iuv);
        vec3 proj_pos = getProjPos(iuv, depth);
        vec3 view_pos = proj2view(proj_pos);
        vec3 world_pos = view2world(view_pos);

        // vl = texelFetch(colortex1, iuv, 0).rgb;

        float view_distance = length(view_pos);

        // VL
        float dither = fract(bayer16(gl_FragCoord.st) + texelFetch(colortex1, ivec2(frameCounter & 0xFF), 0).r);
        float total_length = min(volume_width / 2, view_distance);
        float step_length = total_length * (1.0 / 16.0);
        vec3 step_dir = normalize(world_pos);

        for (int i = 0; i < 16; i++)
        {
            float L = step_length * (float(i) + dither);
            vec3 wpos = step_dir * L;

            vec3 spos = wpos + (vec3(volume_width, volume_depth, volume_height) * 0.5) + mod(cameraPosition, 1.0);

            vec2 uv0 = volume2planarUV(vec3(spos.x, floor(spos.y), spos.z));
            vec2 uv1 = volume2planarUV(vec3(spos.x, ceil(spos.y), spos.z));

            vec3 voxel_sample0 = texture(colortex5, uv0 * invWidthHeight).rgb;
            vec3 voxel_sample1 = texture(colortex5, uv1 * invWidthHeight).rgb;

            vec3 voxel_sample = mix(voxel_sample0, voxel_sample1, fract(spos.y));

            vl += voxel_sample * step_length * exp(-L * 0.02);
        }
    }

/* RENDERTARGETS:0,8 */
    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(vl, 1.0);
}