#version 420 compatibility

#define VOXEL_RAYTRACED_AO

#pragma optimize(on)

#define USE_AF
#define NORMAL_MAPPING
#define POM

#include "/libs/compat.glsl"
#include "forward.fsh"
