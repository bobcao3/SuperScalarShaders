#version 430 compatibility

#pragma optimize(on)

/* RENDERTARGETS: 3 */

const bool colortex3Clear = false;
const bool colortex5Clear = false;
const bool colortex4Clear = false;

#define FINAL_PROP

#include "floodfill.glslinc"