#version 430 compatibility
#pragma optimize(on)

#define BASE vec2(0.0, 0.0)
#define BOUND vec2(0.5, 0.5)

#define PREV_BASE vec2(0.0, 0.0)
#define PREV_BOUND vec2(0.5, 0.5)

#define DIR(x) vec2(0, x)

#include "/libs/bloom_blur.glsl"