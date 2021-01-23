#include "/libs/compat.glsl"

#include "/color.glslinc"

uniform vec2 invWidthHeight;

void main() {
    ivec2 iuv = ivec2(gl_FragCoord.st);

    vec3 color;

    vec2 uv = ((vec2(iuv) + vec2(PIXEL_OFFSET)) * invWidthHeight - BASE) * SCALE;

/* DRAWBUFFERS:3 */

    if (uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0)
    {
        #ifdef BRIGHT_PASS
        color = vec3(0.0);
        #else
        color = texelFetch(ORIGIN, iuv, 0).rgb;
        #endif
    }
    else
    {
        color = texture(ORIGIN, uv * PREV_SCALE + PREV_BASE).rgb;

        #ifdef IS_GAMMA
        color = fromGamma(color);
        #endif

        #ifdef BRIGHT_PASS
        color = color * smoothstep(3.0, 10.0, max(max(luma(color), color.r), max(color.g, color.b)));
        #endif
    }

    gl_FragData[0] = vec4(color, 1.0);
}