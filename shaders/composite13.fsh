#version 420 compatibility
#pragma optimize(on)

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D colortex3;
uniform sampler2D gaux4;

uniform vec2 invWidthHeight;
uniform float aspectRatio;

uniform float near;
uniform float far;

uniform float centerDepthSmooth;

float linearizeDepth(in float d) {
    return (2 * near) / (far + near - (d * 2.0 - 1.0) * (far - near));
}

#define DOF

#ifdef DOF
void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);
    vec2 uv = gl_FragCoord.st * invWidthHeight;

    vec3 color = texelFetch(colortex0, iuv, 0).rgb;

    float depth = textureLod(depthtex0, uv, 1).r;

    if (depth > 0.7)
    {
        float depth_linear = linearizeDepth(depth);
        float center_depth_linear = linearizeDepth(centerDepthSmooth);

        vec2 CoC_center = texture(gaux4, uv * 0.5).rg;

        vec4 dof_image = texture(colortex3, uv * 0.5);

        float blend_weight = clamp(max(CoC_center.r, CoC_center.g) * 200.0, 0.0, 1.0);
        // float blend_weight = clamp(dof_image.a * 300.0, 0.0, 1.0);
        color = mix(color, dof_image.rgb, blend_weight);

        // color = vec3(blend_weight);
    }

/* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(pow(color, vec3(1.0 / 2.2)), 1.0);
}
#endif