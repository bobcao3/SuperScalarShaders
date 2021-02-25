#version 430 compatibility

#pragma optimize(on)

/* RENDERTARGETS: 3,5 */

#define FINAL_PROP

const bool colortex3Clear = false;
const bool colortex5Clear = false;
const bool colortex4Clear = false;

#include "floodfill.glslinc"