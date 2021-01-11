#version 420 compatibility

uniform mat4 shadowModelViewInverse;

attribute vec3 mc_Entity;
attribute vec4 at_tangent;
attribute vec2 mc_midTexCoord;

out VertexOut {
    vec4 vertex_color;
    vec3 vertex_world_pos;
    int block_id;
    vec3 vertex_normal;
    int fluid;
    vec2 uv;
    vec2 lmcoord;
};

void main()
{
    vec4 vertex = gl_Vertex;
    vec4 view_pos = gl_ModelViewMatrix * vertex;
    vec4 world_pos = shadowModelViewInverse * view_pos;
    // vec4 proj_pos = gl_ProjectionMatrix * view_pos;

#if MC_VERSION < 113000
    // world_pos.y -= 1.61;
#endif

    vec3 world_normal = gl_Normal.xyz;
    uv = mc_midTexCoord; //mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.st;

    vertex_color = gl_Color;
    vertex_world_pos = world_pos.xyz;
    vertex_normal = world_normal * at_tangent.w;

    block_id = int(mc_Entity.x);
    fluid = int(mc_Entity.y);
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    // gl_Position = vec4(0.0);
}