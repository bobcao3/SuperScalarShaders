#version 420 compatibility

#pragma optimize(on)

#include "/libs/compat.glsl"

in VertexOut {
    vec4 vertex_color;
    vec4 world_position;
    vec2 uv;
};

/* DRAWBUFFERS: 0 */

#include "voxelize.glslinc"
#include "color.glslinc"
#include "/libs/transform.glsl"

uniform sampler2D tex;

uniform vec3 fogColor;

void main()
{
    vec4 color = vertex_color;
    color.a *= texture(tex, uv).a;

    if (color.a > 0.1)
    {
        vec4 lighting = texelFetch(gaux2, volume2planar(getVolumePos(world_position.xyz, cameraPosition)), 0);
        
        color.rgb = fromGamma(color.rgb);
        color.rgb *= max(fogColor, lighting.rgb * 10.0);
        color.rgb = toGamma(color.rgb);

        color.a *= 0.3;
    }

    gl_FragData[0] = color;
}