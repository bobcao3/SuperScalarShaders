#version 420 compatibility

#pragma optimize(on)

/* DRAWBUFFERS: 45 */

const bool gaux1Clear = false;
const bool gaux2Clear = false;
const bool gaux3Clear = false;

#define FINAL_PROP

#include "floodfill.glslinc"