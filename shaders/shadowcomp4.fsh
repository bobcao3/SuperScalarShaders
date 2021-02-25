#version 430 compatibility

#pragma optimize(on)

/* RENDERTARGETS: 1 */

#define FINAL_PROP

const bool shadowcolor1Clear = false;
const bool colortex5Clear = false;
const bool colortex4Clear = false;

#include "floodfill.glslinc"