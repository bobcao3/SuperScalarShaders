#version 420 compatibility
#pragma optimize(on)

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform vec2 invWidthHeight;
uniform float aspectRatio;

uniform float near;
uniform float far;

uniform mat4 gbufferProjection;

uniform float centerDepthSmooth;

float linearizeDepth(in float d) {
    return (2 * near) / (far + near - (d * 2.0 - 1.0) * (far - near));
}

const float sensorHeight = 0.024f; // full-frame (24mm)
const float sensorWidth = 0.036f; // full-frame (24mm)

float getCoC(float depth, float A, float f, float S1, float maxCoC)
{
    float S2 = depth * far;
    S1 = S1 * far;

    float c = A * (abs(S2 - S1) / S2 * (f / (S1 - f)));

    float percentOfSensor = c / sensorHeight;

    return clamp(percentOfSensor, 0.0, maxCoC);
}

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);
    vec2 uv = gl_FragCoord.st * invWidthHeight;

    vec3 color = vec3(0.0);

    if (uv.x > 0.5 || uv.y > 0.5) return;

    uv *= 2.0;

    float depth = textureLod(depthtex0, uv, 1).r;
    float depth_linear = linearizeDepth(depth);
    float center_depth_linear = linearizeDepth(centerDepthSmooth);

    float focalLength = gbufferProjection[0][0] * sensorWidth * 0.5;

#define APERATURE 2.0 // [0.95 1.2 1.4 1.8 2.0 2.2 2.4 2.8 3.2 3.6 4.8 5.6 6.4 8.0]

    float CoC = getCoC(depth_linear, focalLength / 2.8, focalLength, center_depth_linear, 0.01);

    vec2 CoC_near_far;

    if (depth >= centerDepthSmooth)
        CoC_near_far = vec2(CoC, 0.0);
    else
        CoC_near_far = vec2(0.0, CoC);

    if (depth < 0.7) CoC_near_far = vec2(0.0);

/* DRAWBUFFERS:7 */
    gl_FragData[0] = vec4(CoC_near_far, 0.0, 1.0);
}