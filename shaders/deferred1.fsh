#version 420 compatibility

#pragma optimize(on)

/* DRAWBUFFERS: 4 */

const bool colortex0Clear = false;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = false;

const bool gaux1Clear = false;
const bool gaux2Clear = false;
const bool gaux3Clear = false;
const bool gaux4Clear = false;

#include "floodfill.glslinc"