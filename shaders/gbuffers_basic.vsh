#version 420 compatibility

#pragma optimize(on)

out VertexOut {
    vec4 vertex_color;
};

#include "/libs/taa.glsl"

uniform int frameCounter;
uniform vec2 invWidthHeight;

void main()
{
    vec4 vertex = gl_Vertex;

    vec4 view_pos = gl_ModelViewMatrix * vertex;
    vec4 proj_pos = gl_ProjectionMatrix * view_pos;

    vertex_color = gl_Color;

    gl_Position = proj_pos;

#ifndef NO_TAA
    gl_Position.st += JitterSampleOffset(frameCounter) * invWidthHeight * gl_Position.w;
#endif
}