#version 420 compatibility
#pragma optimize(on)

/*

const float shadowDistance = 70.0f;
const float shadowDistanceRenderMul = 1.0f;
const float shadowIntervalSize = 1.0f;

const int colortex0Format = R11F_G11F_B10F;
const int colortex1Format = R11F_G11F_B10F;
const int colortex2Format = R11F_G11F_B10F;

const int gaux1Format = R11F_G11F_B10F;
const int gaux2Format = RGBA16F;
const int gaux3Format = R11F_G11F_B10F;

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
    float dither = fract(texelFetch(colortex1, iuv & 0xFF, 0).r + texelFetch(colortex1, ivec2(frameCounter & 0xFF), 0).r);
    float total_length = min(volume_width / 2, view_distance);
    float step_length = total_length * (1.0 / 16.0);
    vec3 step_dir = normalize(world_pos);

    for (int i = 0; i < 16; i++)
    {
        float L = step_length * (float(i) + dither + 0.05);
        vec3 wpos = step_dir * L;

        vec3 rand_offset = vec3(hash(vec2(i * 3, dither * 10.0)), hash(vec2(i * 3 + 1, dither * 10.0)), hash(vec2(i * 3 + 2, dither * 10.0)));
        vec3 spos = wpos + (vec3(volume_width, volume_depth, volume_height) * 0.5) + mod(cameraPosition, 1.0) + rand_offset - 0.5;

        vec3 voxel_sample = texelFetch(gaux2, volume2planar(ivec3(spos)), 0).rgb;
        // sample_lighting_bilinear(gaux2, wpos + mod(cameraPosition, 1.0), ivec3(0));

        color += voxel_sample * step_length * exp(-L * 0.001);
    }

/* DRAWBUFFERS:1 */
    gl_FragData[0] = vec4(color, 1.0);
}