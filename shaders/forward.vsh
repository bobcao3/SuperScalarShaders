attribute vec3 mc_Entity;
attribute vec4 mc_midTexCoord;

#if defined(NORMAL_MAPPING) || defined(WATER)
attribute vec4 at_tangent;
#endif

// #define WIREFRAME

out VertexOut {
    vec4 vertex_color;
    vec4 world_position;
    vec3 vertex_normal;
    flat int block_id;
    vec2 uv;
    vec2 lmcoord;
#if defined(NORMAL_MAPPING) || defined(WATER)
    vec3 tangent;
    vec3 bitangent;
#endif
#ifdef POM
    vec3 tangentpos;
#endif

    vec2 miduv;
    flat vec2 bound_uv;

#ifdef WIREFRAME
    vec4 bary;
#endif
};

uniform mat4 gbufferModelViewInverse;

uniform int biomeCategory;

#include "/libs/taa.glsl"

uniform vec2 invWidthHeight;
uniform int frameCounter;
uniform float rainStrength2;
uniform float frameTimeCounter;

#include "/libs/noise.glsl"

#ifdef WATER
#include "/libs/water.glsl"

uniform vec3 cameraPosition;
#endif

void main()
{
    vec4 vertex = gl_Vertex;

    block_id = int(round(mc_Entity.x));

#ifdef NON_BLOCK
    vec3 world_normal = normalize(mat3(gbufferModelViewInverse) * (mat3(gl_NormalMatrix) * gl_Normal.xyz));
#else

    vec3 world_normal = normalize(gl_Normal.xyz);

    #if defined(WAVING_FOILAGE)
    if (block_id == 30 || block_id == 29)
    {
        float maxStrength = 0.5 + rainStrength2;
        float time = frameTimeCounter * 3.0;

        if (block_id == 30) {
            if (gl_MultiTexCoord0.t < mc_midTexCoord.t) {
                float rand_ang = hash(vertex.xz);
                float reset = cos(rand_ang * 10.0 + time * 0.1);
                reset = max( reset * reset, max(rainStrength2 * 0.5, 0.1));
                vertex.x += (sin(rand_ang * 10.0 + time + vertex.y) * 0.2) * (reset * maxStrength);
            }
        } else if (block_id == 29) {
            float rand_ang = hash(vertex.xz);
            float reset = cos(rand_ang * 10.0 + time * 0.1);
            reset = max( reset * reset, max(rainStrength2 * 0.5, 0.1));
            vertex.x += (sin(rand_ang * 5.0 + time + vertex.x) * 0.035 + 0.035) * (reset * maxStrength);
            vertex.y += (cos(rand_ang * 5.0 + time + vertex.y) * 0.01 + 0.01) * (reset * maxStrength);
            vertex.z += (sin(rand_ang * 5.0 + time + vertex.z) * 0.035 + 0.035) * (reset * maxStrength);
        }
    }
    #endif
#endif

#ifdef WIREFRAME
    if (gl_VertexID % 4 == 0)
        bary = vec4(1.0, 0.0, 0.0, 0.0);
    else if (gl_VertexID % 4 == 1)
        bary = vec4(0.0, 1.0, 0.0, 0.0);
    else if (gl_VertexID % 4 == 2)
        bary = vec4(0.0, 0.0, 1.0, 0.0);
    else
        bary = vec4(0.0, 1.0, 0.0, 0.0);
#endif

    vec4 view_pos = gl_ModelViewMatrix * vertex;
    vec4 proj_pos = gl_ProjectionMatrix * view_pos;

    world_position = gbufferModelViewInverse * view_pos;

#ifdef WATER
    if (mc_Entity.x == 32.0)
    {
        float wave = getwave(world_position.xyz + cameraPosition, 1.0, WATER_ITERATIONS);
        vertex.y = vertex.y + wave;

        view_pos = gl_ModelViewMatrix * vertex;
        proj_pos = gl_ProjectionMatrix * view_pos;
        world_position = gbufferModelViewInverse * view_pos;
    }
#endif

    uv = gl_MultiTexCoord0.st;

#if defined(NORMAL_MAPPING) || defined(WATER)
    tangent = normalize(at_tangent.xyz * at_tangent.w);
    bitangent = cross(tangent, world_normal);
#endif

#ifdef POM
	mat3 TBN = mat3(tangent, bitangent, world_normal);
	tangentpos = normalize(world_position.xyz * TBN);
#endif

    miduv = mc_midTexCoord.st;
    bound_uv = uv;

    vertex_color = gl_Color;
    vertex_normal = world_normal;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    if (biomeCategory == 16)
    {
        lmcoord.y = 1.0;
    }

    if (mc_Entity.x > 9199) lmcoord.x = 0.95;

    gl_Position = proj_pos;

#ifdef SPECTRAL
    gl_Position.z = gl_Position.z * 0.002;
#endif

#ifndef NO_TAA
    gl_Position.st += JitterSampleOffset(frameCounter) * invWidthHeight * gl_Position.w;
#endif
}