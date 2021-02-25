#version 430 compatibility
#pragma optimize(on)

uniform sampler2D colortex8;

#define PIXEL_OFFSET 1.5

#define ORIGIN colortex8
#define SCALE 8.0
#define BASE vec2(0.0, 0.75)

#define PREV_SCALE 0.5
#define PREV_BASE vec2(0.0)

#include "/libs/bloom_bright_pass.glsl"