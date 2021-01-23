#version 420 compatibility

/* DRAWBUFFERS: 02 */

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

const float sunPathRotation = -33.0f;

*/

const bool colortex2Clear = false;
const bool gaux3Clear = false;

uniform sampler2D colortex2;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;

#include "color.glslinc"

#define FASTER_PROPOGATION
#ifdef FASTER_PROPOGATION
// Do nothing because stupid optifine
#endif

uniform vec2 invWidthHeight;

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);
    vec2 uv = gl_FragCoord.st * invWidthHeight;

    vec3 color = textureLod(colortex2, uv, 0).rgb;

    color = ACESFitted(color) * 1.1;

    // if (iuv.x < 1024 && iuv.y < 1024) color = texelFetch(gaux4, iuv, 0).rgb;

    gl_FragColor = vec4(color, 1.0);
}