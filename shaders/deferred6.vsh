#version 420 compatibility

out vec3 world_sun_dir;

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;

void main()
{
    gl_Position = ftransform();

    world_sun_dir = mat3(gbufferModelViewInverse) * (sunPosition * 0.01);
}