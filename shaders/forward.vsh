attribute vec3 mc_Entity;
attribute vec4 mc_midTexCoord;

#ifdef NORMAL_MAPPING
attribute vec4 at_tangent;
#endif

out VertexOut {
    vec4 vertex_color;
    vec4 world_position;
    vec3 vertex_normal;
    flat int block_id;
    vec2 uv;
    vec2 lmcoord;
#ifdef NORMAL_MAPPING
    vec3 tangent;
    vec3 bitangent;
#endif
#ifdef POM
    vec3 tangentpos;
#endif
};

uniform mat4 gbufferModelViewInverse;

uniform int biomeCategory;

#include "/libs/taa.glsl"

uniform vec2 invWidthHeight;
uniform int frameCounter;
uniform float rainStrength;
uniform float frameTimeCounter;

float hash(float n) { return fract(sin(n) * 43758.5453123); }

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.2031);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

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
        float maxStrength = 0.5 + rainStrength;
        float time = frameTimeCounter * 3.0;

        if (block_id == 30) {
            if (gl_MultiTexCoord0.t < mc_midTexCoord.t) {
                float rand_ang = hash(vertex.xz);
                float reset = cos(rand_ang * 10.0 + time * 0.1);
                reset = max( reset * reset, max(rainStrength * 0.5, 0.1));
                vertex.x += (sin(rand_ang * 10.0 + time + vertex.y) * 0.2) * (reset * maxStrength);
            }
        } else if (block_id == 29) {
            float rand_ang = hash(vertex.xz);
            float reset = cos(rand_ang * 10.0 + time * 0.1);
            reset = max( reset * reset, max(rainStrength * 0.5, 0.1));
            vertex.x += (sin(rand_ang * 5.0 + time + vertex.x) * 0.035 + 0.035) * (reset * maxStrength);
            vertex.y += (cos(rand_ang * 5.0 + time + vertex.y) * 0.01 + 0.01) * (reset * maxStrength);
            vertex.z += (sin(rand_ang * 5.0 + time + vertex.z) * 0.035 + 0.035) * (reset * maxStrength);
        }
    }
    #endif
#endif

#ifdef WATER
    if (mc_Entity.x == 32.0)
    {
        float wave = cos(hash(vertex.xz) + frameTimeCounter * 3.0);
        vertex.y = vertex.y - 0.2 + wave * 0.1;
    }
#endif

    vec4 view_pos = gl_ModelViewMatrix * vertex;
    vec4 proj_pos = gl_ProjectionMatrix * view_pos;

    uv = gl_MultiTexCoord0.st;

#ifdef NORMAL_MAPPING
    tangent = normalize(at_tangent.xyz * at_tangent.w);
    bitangent = normalize(cross(tangent, world_normal));
#endif

    world_position = gbufferModelViewInverse * view_pos;

#ifdef POM
	mat3 TBN = mat3(tangent, bitangent, world_normal);
	tangentpos = normalize(world_position.xyz * TBN);
#endif

    vertex_color = gl_Color;
    vertex_normal = world_normal;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

    if (biomeCategory == 16)
    {
        lmcoord.y = 1.0;
    }

    gl_Position = proj_pos;

#ifndef NO_TAA
    gl_Position.st += JitterSampleOffset(frameCounter) * invWidthHeight * gl_Position.w;
#endif
}