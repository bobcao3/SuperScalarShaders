#version 430 compatibility
#pragma optimize(on)

#define BASE vec2(0.0, 0.75)
#define BOUND vec2(0.25, 1.0)

#define PREV_BASE vec2(0.0, 0.75)
#define PREV_BOUND vec2(0.25, 1.0)

#define DIR(x) vec2(x, 0)

#include "/libs/bloom_blur.glsl"