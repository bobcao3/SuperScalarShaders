#version 430 compatibility

#pragma optimize(on)

#include "libs/compat.glsl"

/* RENDERTARGETS: 4 */

// #define DISABLE_MIE

#include "/color.glslinc"
#include "/libs/atmosphere.glsl"

const bool colortex4Clear = false;

uniform int biomeCategory;

uniform vec3 fogColor;

// uniform sampler2D colortex4;

uniform int frameCounter;

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);

    if (frameCounter % 5 != 0) {
        discard;
    }

    vec4 skybox = vec4(0.0);

    if (iuv.y <= (int(viewHeight) >> 3) + 8 && iuv.x <= (int(viewWidth) >> 2) * 2 + 16 && iuv.x > (int(viewWidth) >> 2) + 8) {    
        ivec2 iuv_mapped = iuv - ivec2((int(viewWidth) >> 2) + 8, 0);

        for (int i = -2; i <= 2; i++)
        {
            for (int j = -2; j <= 2; j++)
            {
                ivec2 iuv_offset = clamp(iuv + ivec2(i, j) * 32, ivec2((int(viewWidth) >> 2) + 8, 0), ivec2((int(viewWidth) >> 2) * 2 + 16, (int(viewHeight) >> 3) + 8));

                skybox.rgb += texelFetch(colortex4, iuv_offset, 0).rgb;
            }
        }

        skybox.rgb *= 1.0 / 25.0;
    } else {
        skybox = texelFetch(colortex4, iuv, 0);
    }

    gl_FragData[0] = skybox;
}