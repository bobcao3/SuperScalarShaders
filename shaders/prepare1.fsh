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

uniform int frameCounter;

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);

    if (iuv.y <= (int(viewHeight) >> 3) + 8 && iuv.x <= (int(viewWidth) >> 2) + 8 && frameCounter % 2 == 0) {
        vec4 skybox = vec4(0.0);
    
        if (biomeCategory != 16) {
            vec3 dir = project_uv2skybox(vec2(iuv) * invWidthHeight);
            vec3 world_sun_dir = mat3(gbufferModelViewInverse) * (sunPosition * 0.01);

            skybox = scatter(vec3(0.0, cameraPosition.y, 0.0), dir, world_sun_dir, Ra, 0.1) * 2.0 * (1.0 - rainStrength2 * 0.95);

            skybox.rgb += vec3(dot(skybox.rgb, vec3(1.0)) * rainStrength2);
        } else {
            skybox = vec4(fromGamma(fogColor), 0.0);
        }

        gl_FragData[0] = skybox;
    } else {
        gl_FragData[0] = texelFetch(colortex4, iuv, 0);
    }
}