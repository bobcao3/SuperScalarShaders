#version 420 compatibility
#pragma optimize(on)

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

#define VOLUMETRIC_LIGHTING

void main() {
    ivec2 iuv = ivec2(gl_FragCoord.st);
    vec2 uv = gl_FragCoord.st * invWidthHeight;

    float depth = getDepth(iuv);
    vec3 proj_pos = getProjPos(iuv, depth);
    vec3 view_pos = proj2view(proj_pos);
    vec3 world_pos = view2world(view_pos);

    vec4 world_pos_prev = vec4(world_pos - previousCameraPosition + cameraPosition, 1.0);
    vec4 proj_pos_prev = gbufferPreviousProjection * (gbufferPreviousModelView * world_pos_prev);
    proj_pos_prev.xy /= proj_pos_prev.w;

    vec3 current = texelFetch(colortex0, iuv, 0).rgb;

    float view_distance = length(view_pos);

    vec3 world_sun_dir = mat3(gbufferModelViewInverse) * (sunPosition * 0.01);

    if (isEyeInWater == 1)
    {
        vec3 ambient = texture(gaux3, project_skybox2uv(world_sun_dir), 3).rgb;
        ambient = ambient * 0.5 + dot(ambient, vec3(0.333)) * 0.5;
        current = mix(current, vec3(0.1, 0.6, 1.0) * ambient * 0.1, smoothstep(view_distance, 0.0, 32.0));
    }
    else if (depth <= 0.999999f && biomeCategory != 16)
    {
        current = pow(current, vec3(2.2));

        vec4 fog = scatter(vec3(0.0, cameraPosition.y, 0.0), normalize(world_pos), world_sun_dir, view_distance * 50.0, 0.1);
        current = mix(fog.rgb, current, fog.a);
        current = pow(current, vec3(1.0 / 2.2));
    }
    else if (biomeCategory == 16)
    {
        current = mix(current, pow(fogColor, vec3(2.2)) * 10.0, smoothstep(0.0, 256.0, view_distance));
    }

    if (isnan(current.r) || isnan(current.g) || isnan(current.b)) current = vec3(0.0);

    // VL
#ifdef VOLUMETRIC_LIGHTING
    vec3 vl = vec3(0.0);
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vl += texelFetch(colortex1, iuv / 2 + ivec2(i, j), 0).rgb;
        }        
    }
    current += vl * (0.002);
#endif

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

    vec3 color = mix(history, current.rgb, 0.1);

    if (depth <= 0.7) {
        color = current.rgb;
    }

/* DRAWBUFFERS:2 */
    gl_FragData[0] = vec4(color, 1.0);
}