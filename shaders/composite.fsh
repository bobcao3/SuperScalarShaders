#version 420 compatibility
#pragma optimize(on)

uniform sampler2D colortex0;

#define ORIGIN colortex0
#define SCALE 2.0
#define BASE vec2(0.0)

#define IS_GAMMA
#define BRIGHT_PASS

#define PIXEL_OFFSET 0.5

#define PREV_SCALE 1.0
#define PREV_BASE vec2(0.0)

#include "/libs/bloom_bright_pass.glsl"