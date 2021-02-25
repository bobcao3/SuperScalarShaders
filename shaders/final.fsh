#version 430 compatibility

/* DRAWBUFFERS: 02 */

/*

const float shadowDistance = 70.0f;
const float shadowDistanceRenderMul = 1.0f;
const float shadowIntervalSize = 1.0f;

// 0: composite
const int colortex0Format = R11F_G11F_B10F;
// 1: noise
// 2: TAA temporal
const int colortex2Format = R11F_G11F_B10F;
// 3: Lighting temporal
const int colortex3Format = R11F_G11F_B10F;
// 4: Skybox temporal
const int colortex4Format = R11F_G11F_B10F;
// 5:
const int colortex5Format = RGBA16F;
// 6: 
const int colortex6Format = R11F_G11F_B10F;
// 7: 
const int colortex7Format = R11F_G11F_B10F;
// 8: Post processing
const int colortex8Format = R11F_G11F_B10F;

const float sunPathRotation = -33.0f;

*/

const bool colortex2Clear = false;
const bool colortex4Clear = false;

// uniform sampler2D colortex2;
// uniform sampler2D colortex3;
// uniform sampler2D colortex5;
// uniform sampler2D colortex4;
// uniform sampler2D colortex7;
// uniform sampler2D shadowcolor0;
// uniform sampler2D shadowtex0;

#include "color.glslinc"

#define FASTER_PROPOGATION
#ifdef FASTER_PROPOGATION
// Do nothing because stupid optifine
#endif

// uniform vec2 invWidthHeight;

uniform float valHurt;

#include "/libs/transform.glsl"

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);
    vec2 uv = gl_FragCoord.st * invWidthHeight;

    vec3 color = textureLod(colortex2, uv, 0).rgb;

    float blend_weight = clamp(length(uv - 0.5), 0.0, 1.0);

    color = mix(color, color * vec3(1.0, 1.0 - valHurt * 0.8, 1.0 - valHurt), blend_weight);

    color = ACESFitted(toGamma(color)) * 1.1;

    // if (iuv.x < 1024 && iuv.y < 1024) color = texelFetch(colortex7, iuv, 0).rgb;
    // color = texelFetch(colortex4, iuv, 0).rgb;
    // color = sampleLODmanual(colortex4, uv, 5).rgb;

    gl_FragColor = vec4(color, 1.0);
}