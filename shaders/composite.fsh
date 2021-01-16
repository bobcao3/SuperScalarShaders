#version 420 compatibility
#pragma optimize(on)

/*

const float shadowDistance = 70.0f;
const float shadowDistanceRenderMul = 1.0f;
const float shadowIntervalSize = 1.0f;

const int colortex0Format = R11F_G11F_B10F;
const int colortex2Format = R11F_G11F_B10F;
const int colortex3Format = R11F_G11F_B10F;

const int gaux1Format = R11F_G11F_B10F;
const int gaux2Format = RGBA16F;
const int gaux3Format = R11F_G11F_B10F;
const int gaux4Format = R11F_G11F_B10F;

const float sunPathRotation = -43.0f;

*/

#include "/libs/compat.glsl"

const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool gaux3Clear = false;

#define VECTORS
#define TRANSFORMATIONS_RESIDUAL

#include "/libs/transform.glsl"
#include "/libs/noise.glsl"
#include "/libs/atmosphere.glsl"

// #define TAA_NO_CLIP

#include "voxelize.glslinc"

vec3 sampleHistory(ivec2 iuv, vec3 min_bound, vec3 max_bound)
{
#ifdef TAA_NO_CLIP
    return texelFetch(colortex2, iuv, 0).rgb;
#else
    return clamp(texelFetch(colortex2, iuv, 0).rgb, min_bound, max_bound);
#endif
}

uniform int frameCounter;

uniform vec3 fogColor;

uniform int biomeCategory;

#include "/libs/taa.glsl"

uniform int isEyeInWater;

void main() {
    ivec2 iuv = ivec2(gl_FragCoord.st) * 2;

    if (iuv.x > viewWidth || iuv.y > viewHeight) return;

    float depth = getDepth(iuv);
    vec3 proj_pos = getProjPos(iuv, depth);
    vec3 view_pos = proj2view(proj_pos);
    vec3 world_pos = view2world(view_pos);

    vec3 color = texelFetch(colortex1, iuv, 0).rgb;

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

        vec3 voxel_sample0 = texture(gaux2, uv0 * invWidthHeight).rgb;
        vec3 voxel_sample1 = texture(gaux2, uv1 * invWidthHeight).rgb;

        vec3 voxel_sample = mix(voxel_sample0, voxel_sample1, fract(spos.y));

        color += voxel_sample * step_length * exp(-L * 0.02);
    }

/* DRAWBUFFERS:3 */
    gl_FragData[0] = vec4(color, 1.0);
}