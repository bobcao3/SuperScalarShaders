#version 430 compatibility
#pragma optimize(on)

#include "/libs/compat.glsl"

const bool colortex2Clear = false;
const bool colortex4Clear = false;
const bool colortex7Clear = false;

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
#define DOF

void main() {
    ivec2 iuv = ivec2(gl_FragCoord.st);
    vec2 uv = gl_FragCoord.st * invWidthHeight;

    float depth = getDepth(iuv);
    vec3 proj_pos = getProjPos(iuv, depth);
    vec3 view_pos = proj2view(proj_pos);
    vec3 world_pos = view2world(view_pos);

    vec3 current = texelFetch(colortex0, iuv, 0).rgb;

    float view_distance = length(view_pos);

    vec3 world_sun_dir = mat3(gbufferModelViewInverse) * (sunPosition * 0.01);

    if (isEyeInWater == 1)
    {
        vec3 ambient = texture(colortex4, project_skybox2uv(world_sun_dir), 3).rgb;
        ambient = ambient * 0.5 + dot(ambient, vec3(0.333)) * 0.5;
        float strength = exp(-view_distance * 0.05);
        current = mix(vec3(0.1, 0.6, 1.0) * ambient * 0.1, current * vec3(0.8, 0.9, 1.0), sin(clamp(strength, 0.0, 1.0)));
    }
    else if (depth <= 0.999999f && biomeCategory != 16)
    {
        current = pow(current, vec3(2.2));

        vec4 fog = scatter(vec3(0.0, cameraPosition.y, 0.0), normalize(world_pos), world_sun_dir, view_distance * 50.0, 0.1) * (1.0 - rainStrength2 * 0.9);
        current = mix(fog.rgb, current, fog.a);
        current = pow(current, vec3(1.0 / 2.2));
    }
    else if (biomeCategory == 16)
    {
        current = mix(current, pow(fogColor, vec3(2.2)) * 10.0, smoothstep(0.0, 256.0, view_distance));
    }

    vec3 vl = vec3(0.0);

#ifdef VOLUMETRIC_LIGHTING
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vl += texelFetch(colortex8, iuv / 2 + ivec2(i, j), 0).rgb;
        }        
    }

    if (isEyeInWater == 1)
        vl *= vec3(0.002, 0.006, 0.01);
    else
        vl *= 0.002;

    current += vl;
#endif

#ifdef DOF
    current = pow(current, vec3(2.2));
#endif

/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(current, 1.0);
}