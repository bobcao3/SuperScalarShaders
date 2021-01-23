#include "/libs/compat.glsl"

#include "/color.glslinc"

uniform sampler2D colortex3;

uniform vec2 invWidthHeight;

uniform float viewHeight;
uniform float viewWidth;

uniform float aspectRatio;

void main() {
    ivec2 iuv = ivec2(gl_FragCoord.st);

    vec2 uv = vec2(iuv) * invWidthHeight;

    vec3 color;

    if (uv.x < BASE.x || uv.y < BASE.y || uv.x > BOUND.x || uv.y > BOUND.y)
    {
        color = texelFetch(colortex3, iuv, 0).rgb;
    }
    else
    {
        const float kernels[5] = float[] (
            0.06136, 0.24477, 0.38774, 0.24477, 0.06136
        );

        uv -= BASE;

        for (int i = -2; i <= 2; i++)
        {
            vec2 uv_offset = clamp(uv + DIR(i) * invWidthHeight + PREV_BASE, PREV_BASE, PREV_BOUND);

            color += textureLod(colortex3, uv_offset, 1).rgb * kernels[i + 2];
        }
    }


/* DRAWBUFFERS:3 */
    gl_FragData[0] = vec4(color, 1.0);
}