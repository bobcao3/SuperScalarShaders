#version 420 compatibility

#pragma optimize(on)

#include "libs/compat.glsl"

/* DRAWBUFFERS: 6 */

// #define DISABLE_MIE

#include "/color.glslinc"
#include "/libs/atmosphere.glsl"

const bool gaux3Clear = false;

uniform int biomeCategory;

uniform vec3 fogColor;

// uniform sampler2D gaux3;

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);

    vec4 skybox = vec4(0.0);

    if (iuv.y <= (int(viewHeight) >> 3) + 8 && iuv.x <= (int(viewWidth) >> 2) * 2 + 16 && iuv.x > (int(viewWidth) >> 2) + 8) {    

        for (int i = -2; i <= 2; i++)
        {
            for (int j = -2; j <= 2; j++)
            {
                ivec2 iuv_offset = clamp(iuv + ivec2(i, j) * 2, ivec2((int(viewWidth) >> 2) + 8, 0), ivec2((int(viewWidth) >> 2) * 2 + 16, (int(viewHeight) >> 3) + 8));
                
                skybox.rgb += texelFetch(gaux3, iuv_offset, 0).rgb;
            }
        }

        skybox.rgb *= 1.0 / 25.0;
    } else {
        skybox = texelFetch(gaux3, iuv, 0);
    }

    gl_FragData[0] = skybox;
}