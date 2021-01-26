#version 420 compatibility

layout(triangles) in;
layout(points, max_vertices = 1) out;

#extension GL_ARB_geometry_shader4 : enable
const int maxVerticesOut = 1;

in VertexOut {
    vec4 vertex_color;
    vec3 vertex_world_pos;
    int block_id;
    vec3 vertex_normal;
    int fluid;
    vec2 uv;
    vec2 lmcoord;
} vertex_in[3];

out GeoOut {
    flat vec4 vertex_color;
    flat vec2 uv;
    flat int block_id;
    flat int fluid;
    flat vec2 lmcoord;
};

uniform vec3 cameraPosition;

#include "voxelize.glslinc"

void main()
{
    if (vertex_in[0].block_id == 0) return;

    // vec4 average_color = (
    //     vertex_in[0].vertex_color
    //   + vertex_in[1].vertex_color
    //   + vertex_in[2].vertex_color
    // ) * 0.333333f;

    vec4 average_color = vertex_in[0].vertex_color;

    vec3 triangle_bbox_min = min(
      min(vertex_in[0].vertex_world_pos.xyz, vertex_in[1].vertex_world_pos.xyz),
      vertex_in[2].vertex_world_pos.xyz
    );

    vec3 triangle_bbox_max = max(
      max(vertex_in[0].vertex_world_pos.xyz, vertex_in[1].vertex_world_pos.xyz),
      vertex_in[2].vertex_world_pos.xyz
    );

    vec3 average_world_pos = (triangle_bbox_min + triangle_bbox_max) * 0.5f;

    // vec2 average_uv = (
    //     vertex_in[0].uv.xy
    //   + vertex_in[1].uv.xy
    //   + vertex_in[2].uv.xy
    // ) * 0.333333f;

    vec2 average_uv = vertex_in[0].uv.xy;

    vec3 actual_normal = normalize(cross(vertex_in[0].vertex_world_pos.xyz - vertex_in[1].vertex_world_pos.xyz, vertex_in[0].vertex_world_pos.xyz - vertex_in[2].vertex_world_pos.xyz));
    
    average_world_pos -= normalize(actual_normal) * 0.05;

    ivec3 block_pos = getVolumePos(average_world_pos, cameraPosition);
    ivec2 planar_pos = volume2planar(block_pos);

    vec2 projed_dot = (vec2(planar_pos) * (1.0 / float(shadowMapResolution))) * 2.0 - 1.0;

    float z_priority = 0.0f;

    if (vertex_in[0].block_id > 9199 || vertex_in[0].lmcoord.x > 0.95) z_priority = 0.1;
    if (vertex_in[0].block_id > 28 && vertex_in[0].block_id < 33) z_priority = 0.2;

    gl_Position = vec4(projed_dot, z_priority, 1.0);
    vertex_color = average_color;
    uv = average_uv;
    block_id = vertex_in[0].block_id;
    fluid = vertex_in[0].fluid;
    lmcoord = vertex_in[0].lmcoord;
    EmitVertex();
    
    // gl_Position = vec4(projed_dot + vec2(3.0 / 1024.0, 0.0), 0.5, 1.0);
    // vertex_color = vertex_in[0].vertex_color;
    // EmitVertex();
    
    // gl_Position = vec4(projed_dot + vec2(0.0, 3.0 / 1024.0), 0.5, 1.0);
    // vertex_color = vertex_in[0].vertex_color;
    // EmitVertex();
    
    EndPrimitive();
}