#version 420 compatibility
#pragma optimize(on)


/*

const float shadowDistance = 70.0f;
const float shadowDistanceRenderMul = 1.0f;
const float shadowIntervalSize = 1.0f;

const int colortex0Format = R11F_G11F_B10F;
const int colortex2Format = R11F_G11F_B10F;

const int gaux1Format = R11F_G11F_B10F;
const int gaux2Format = RGBA16F;
const int gaux3Format = R11F_G11F_B10F;

const float sunPathRotation = -43.0f;

*/

#include "/libs/compat.glsl"

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

void main() {
    ivec2 iuv = ivec2(gl_FragCoord.st);

    float depth = getDepth(iuv);
    vec3 proj_pos = getProjPos(iuv, depth);
    vec3 view_pos = proj2view(proj_pos);
    vec3 world_pos = view2world(view_pos);

    vec4 world_pos_prev = vec4(world_pos - previousCameraPosition + cameraPosition, 1.0);
    vec4 proj_pos_prev = gbufferPreviousProjection * (gbufferPreviousModelView * world_pos_prev);
    proj_pos_prev.xy /= proj_pos_prev.w;

    vec3 current = texelFetch(colortex0, iuv, 0).rgb;

    if (depth <= 0.999999f && biomeCategory != 16)
    {
        current = pow(current, vec3(2.2));
        float view_distance = length(view_pos);

        vec3 world_sun_dir = mat3(gbufferModelViewInverse) * (sunPosition * 0.01);

        vec4 fog = scatter(vec3(0.0, cameraPosition.y, 0.0), normalize(world_pos), world_sun_dir, view_distance * 50.0, 0.1);
        current = mix(fog.rgb, current, fog.a);
        current = pow(current, vec3(1.0 / 2.2));
    }

    if (isnan(current.r) || isnan(current.g) || isnan(current.b)) current = vec3(0.0);

    // VL
    float dither = fract(texelFetch(colortex1, iuv & 0xFF, 0).r + texelFetch(colortex1, ivec2(frameCounter & 0xF), 0).r);
    float world_length = length(world_pos);
    float total_length = min(volume_width, world_length);
    float step_length = total_length * 0.1;
    vec3 step_dir = normalize(world_pos);

    if (biomeCategory == 16)
    {
        current = mix(current, pow(fogColor, vec3(2.2)) * 10.0, smoothstep(0.0, 256.0, world_length));

        for (int i = 0; i < 10; i++)
        {
            float L = step_length * (float(i) + dither + 0.05);
            vec3 wpos = step_dir * L;

            vec3 rand_offset = vec3(hash(vec2(i * 3, dither * 10.0)), hash(vec2(i * 3 + 1, dither * 10.0)), hash(vec2(i * 3 + 2, dither * 10.0)));
            vec3 spos = wpos + (vec3(volume_width, volume_depth, volume_height) * 0.5) + mod(cameraPosition, 1.0) + rand_offset - 0.5;

            vec3 voxel_sample = texelFetch(gaux2, volume2planar(ivec3(spos)), 0).rgb;
            // sample_lighting_bilinear(gaux2, wpos + mod(cameraPosition, 1.0), ivec3(0));

            current += voxel_sample * step_length * exp(-L * 0.001) * 0.1;
        }
    }
    
    vec3 min_neighbor0 = current;
    vec3 max_neighbor0 = current;

    for (int i = -1; i <= 1; i++)
    {
        for (int j = -1; j <= 1; j++) if (i != 0 || j != 0)
        {
            vec3 s = texelFetch(colortex0, iuv + ivec2(i, j), 0).rgb;
            min_neighbor0 = min(min_neighbor0, s);
            max_neighbor0 = max(max_neighbor0, s);
        }
    }

    vec2 prev_uv = (proj_pos_prev.xy * 0.5 + 0.5);
    vec2 prev_uv_texels = prev_uv * vec2(viewWidth, viewHeight);
    vec2 iprev_uv = floor(prev_uv_texels);
    prev_uv += 0.5 * invWidthHeight;


    vec3 s00 = sampleHistory(ivec2(iprev_uv), min_neighbor0, max_neighbor0);
    vec3 s01 = sampleHistory(ivec2(iprev_uv) + ivec2(0, 1), min_neighbor0, max_neighbor0);
    vec3 s10 = sampleHistory(ivec2(iprev_uv) + ivec2(1, 0), min_neighbor0, max_neighbor0);
    vec3 s11 = sampleHistory(ivec2(iprev_uv) + ivec2(1, 1), min_neighbor0, max_neighbor0);

    vec3 history = mix(
        mix(s00, s10, prev_uv_texels.x - iprev_uv.x),
        mix(s01, s11, prev_uv_texels.x - iprev_uv.x),
        prev_uv_texels.y - iprev_uv.y
    );

    if (prev_uv.x < 0.0 || prev_uv.x > 1.0 || prev_uv.y < 0.0 || prev_uv.y > 1.0) history = current.rgb;

    vec3 color = mix(history, current.rgb, 0.15);

    if (depth <= 0.7) {
        color = current.rgb;
    }

/* DRAWBUFFERS:2 */
    gl_FragData[0] = vec4(color, 1.0);
}