#version 420 compatibility

#pragma optimize(on)

out VertexOut {
    vec4 vertex_color;
    vec4 world_position;
    vec2 uv;
};

uniform mat4 gbufferModelViewInverse;

void main()
{
    vec4 vertex = gl_Vertex;

    vec4 view_pos = gl_ModelViewMatrix * vertex;
    vec4 proj_pos = gl_ProjectionMatrix * view_pos;

    uv = gl_MultiTexCoord0.st;

    world_position = gbufferModelViewInverse * view_pos;
    vertex_color = gl_Color;

    gl_Position = proj_pos;
}