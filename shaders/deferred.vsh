#version 430 compatibility

#pragma optimize(on)

out vec3 world_sun_dir;
out vec3 ambient;

#include "libs/compat.glsl"

#include "/libs/atmosphere.glsl"
#include "/libs/transform.glsl"

#include "color.glslinc"

void main()
{
    gl_Position = ftransform();

    world_sun_dir = mat3(gbufferModelViewInverse) * (sunPosition * 0.01);
    ambient = sampleLODmanual(colortex4, project_skybox2uv(world_sun_dir), 3).rgb;
    ambient = ambient * 0.5 + dot(ambient, vec3(0.333)) * 0.5;
}