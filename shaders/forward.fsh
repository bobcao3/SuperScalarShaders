in VertexOut {
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

#ifdef NORMAL_MAPPING
uniform sampler2D normals;
#endif

uniform sampler2D tex;
uniform sampler2D gaux1;
// uniform sampler2D gaux2;
// uniform sampler2D gaux3;
// uniform sampler2D lightmap;

/* DRAWBUFFERS: 0 */

#include "voxelize.glslinc"
#include "color.glslinc"
#include "/libs/transform.glsl"

// uniform vec3 cameraPosition;
// uniform vec3 previousCameraPosition;

// uniform vec3 skyColor;


#ifdef POM
#define tileResolution 128 // [16 32 64 128 256 512 1024]

uniform ivec2 atlasSize;

vec2 tileResolutionF = vec2(tileResolution) / atlasSize;

vec2 minCoord = vec2(uv.x - mod(uv.x, tileResolutionF.x), uv.y - mod(uv.y, tileResolutionF.y));
vec2 maxCoord = minCoord + tileResolutionF;

vec2 atlas_offset(in vec2 coord, in vec2 offset) {
	vec2 offsetCoord = coord + mod(offset.xy, tileResolutionF);

	offsetCoord.x -= float(offsetCoord.x > maxCoord.x) * tileResolutionF.x;
	offsetCoord.x += float(offsetCoord.x < minCoord.x) * tileResolutionF.x;

	offsetCoord.y -= float(offsetCoord.y > maxCoord.y) * tileResolutionF.y;
	offsetCoord.y += float(offsetCoord.y < minCoord.y) * tileResolutionF.y;

	return offsetCoord;
}

ivec2 atlas_offset(in ivec2 coord, in ivec2 offset, int lodi) {
    int tileResLod = (tileResolution >> lodi);

	ivec2 offsetCoord = coord + offset.xy % tileResLod;

    ivec2 minCoordi = coord - coord % tileResLod;
    ivec2 maxCoordi = minCoordi + tileResLod;

	offsetCoord.x -= int(offsetCoord.x >= maxCoordi.x) * tileResLod;
	offsetCoord.x += int(offsetCoord.x < minCoordi.x) * tileResLod;

	offsetCoord.y -= int(offsetCoord.y >= maxCoordi.y) * tileResLod;
	offsetCoord.y += int(offsetCoord.y < minCoordi.y) * tileResLod;

	return offsetCoord;
}

vec2 ParallaxMapping(in vec2 coord) {
	vec2 adjusted = coord.st;
	#define POM_STEPS 4 // [4 8 16]
	#define scale 0.01 // [0.005 0.01 0.02 0.04]

	float heightmap = texture(normals, coord.st).a - 1.0f;

	vec3 offset = vec3(0.0f, 0.0f, 0.0f);
	vec3 s = normalize(tangentpos);
	s = s / s.z * scale / POM_STEPS;

	float lazyx = 0.5;
	const float lazyinc = 0.5 / POM_STEPS;

	if (heightmap < 0.0f) {
		for (int i = 0; i < POM_STEPS; i++) {
			float prev = offset.z;

			offset += (heightmap - prev) * lazyx * s;
			lazyx += lazyinc;

			adjusted = atlas_offset(coord.st, offset.st);
			heightmap = texture(normals, adjusted).a - 1.0f;
			if (max(0.0, offset.z - heightmap) < 0.05) break;
		}
	}

	return adjusted;
}
#endif


#define SMOOTH_LIGHTING

vec3 sample_lighting_bilinear(sampler2D tex, vec3 world_pos, ivec3 ioffset)
{
    vec3 spos = world_pos - 0.5;

    vec3 interp = fract(spos);

    ivec3 base_pos = ivec3(floor(spos)) + ioffset;

    const ivec3 volume_offset = ivec3(volume_width, volume_depth, volume_height) / 2;

    vec4 center = texelFetch(tex, volume2planar(ivec3(floor(world_pos)) + volume_offset), 0);

#ifndef SMOOTH_LIGHTING
    return center.rgb;
#endif

    vec4 c000 = texelFetch(tex, volume2planar(base_pos + ivec3(0, 0, 0) + volume_offset), 0); c000.rgb = mix(c000.rgb, center.rgb, c000.a);
    vec4 c001 = texelFetch(tex, volume2planar(base_pos + ivec3(0, 0, 1) + volume_offset), 0); c001.rgb = mix(c001.rgb, center.rgb, c001.a);
    vec4 c010 = texelFetch(tex, volume2planar(base_pos + ivec3(0, 1, 0) + volume_offset), 0); c010.rgb = mix(c010.rgb, center.rgb, c010.a);
    vec4 c011 = texelFetch(tex, volume2planar(base_pos + ivec3(0, 1, 1) + volume_offset), 0); c011.rgb = mix(c011.rgb, center.rgb, c011.a);
    vec4 c100 = texelFetch(tex, volume2planar(base_pos + ivec3(1, 0, 0) + volume_offset), 0); c100.rgb = mix(c100.rgb, center.rgb, c100.a);
    vec4 c101 = texelFetch(tex, volume2planar(base_pos + ivec3(1, 0, 1) + volume_offset), 0); c101.rgb = mix(c101.rgb, center.rgb, c101.a);
    vec4 c110 = texelFetch(tex, volume2planar(base_pos + ivec3(1, 1, 0) + volume_offset), 0); c110.rgb = mix(c110.rgb, center.rgb, c110.a);
    vec4 c111 = texelFetch(tex, volume2planar(base_pos + ivec3(1, 1, 1) + volume_offset), 0); c111.rgb = mix(c111.rgb, center.rgb, c111.a);

    return 
        mix( mix( mix(c000.rgb, c001.rgb, interp.z),
                  mix(c100.rgb, c101.rgb, interp.z), interp.x),
             mix( mix(c010.rgb, c011.rgb, interp.z),
                  mix(c110.rgb, c111.rgb, interp.z), interp.x), interp.y);
}

#define VOXEL_RAYTRACED_AO

#include "/libs/noise.glsl"
#include "/libs/taa.glsl"

uniform int frameCounter;

#ifdef VOXEL_RAYTRACED_AO
uniform sampler2D shadowcolor0;

mat3 make_coord_space(vec3 n) {
    vec3 h = n;
    if (abs(h.x) <= abs(h.y) && abs(h.x) <= abs(h.z))
        h.x = 1.0;
    else if (abs(h.y) <= abs(h.x) && abs(h.y) <= abs(h.z))
        h.y = 1.0;
    else
        h.z = 1.0;

    vec3 y = normalize(cross(h, n));
    vec3 x = normalize(cross(n, y));

    return mat3(x, y, n);
}

// vec3 ImportanceSampleGGX(vec2 rand, vec3 N, vec3 wo, float roughness, out float pdf)
// {
// 	rand = clamp(rand, vec2(0.0001), vec2(0.9999));

// 	roughness = clamp(roughness, 0.00001, 0.999999);

// 	float tanTheta = roughness * sqrt(rand.x / (1.0 - rand.x));
// 	float theta = clamp(atan(tanTheta), 0.0, 3.1415926 * 0.5 - 0.2);
// 	float phi = 2.0 * 3.1415926 * rand.y;

// 	vec3 h = vec3(
// 		sin(theta) * cos(phi),
// 		sin(theta) * sin(phi),
// 		cos(theta)
// 	);

// 	h = make_coord_space(N) * h;

// 	float sin_h = abs(sin(theta));
// 	float cos_h = abs(cos(theta));

// 	vec3 wi = reflect(wo, h);

// 	pdf = (2.0 * roughness * roughness * cos_h * sin_h) / pow2((roughness * roughness - 1.0) * cos_h * cos_h + 1.0) / (4.0 * abs(dot(wo, h)));

// 	return wi;
// }

#endif

vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness)
{
    float a = roughness*roughness;
	
    float phi = 2.0 * PI * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
	
    // from spherical coordinates to cartesian coordinates
    vec3 H;
    H.x = cos(phi) * sinTheta;
    H.y = sin(phi) * sinTheta;
    H.z = cosTheta;
	
    // from tangent-space vector to world-space sample vector
    vec3 up        = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent   = normalize(cross(up, N));
    vec3 bitangent = cross(N, tangent);
	
    vec3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
    return normalize(sampleVec);
}

vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow5(max(1.0 - cosTheta, 0.001));
}

bool match(float a, float b)
{
	return (a > b - 0.002 && a < b + 0.002);
}

vec3 getF(float metalic, float cosTheta)
{
	if (metalic < 229.5 / 255.0)
		return vec3(1.0);

	#include "materials.glsl"

	cosTheta = max(0.01, abs(cosTheta));

	vec3 NcosTheta = 2.0 * N * cosTheta;
	float cosTheta2 = cosTheta * cosTheta;
	vec3 N2K2 = N * N + K * K;

	vec3 Rs = (N2K2 - NcosTheta + cosTheta2) / (N2K2 + NcosTheta + cosTheta2);
	vec3 Rp = (N2K2 * cosTheta2 - NcosTheta + 1.0) / (N2K2 * cosTheta2 + NcosTheta + 1.0);

	return (Rs + Rp) * 0.5;
}

uniform sampler2D specular;

uniform vec3 fogColor;

void main()
{
    vec3 normal = vertex_normal;

#ifdef POM
    vec2 adj_uv = ParallaxMapping(uv);
    #define uv adj_uv
#endif

#ifdef NORMAL_MAPPING
    vec3 normal_map;
    normal_map.xy = texture(normals, uv).rg * 2.0 - 1.0;
    normal_map.z = sqrt(max(0.0001, 1.0 - dot(normal_map.xy, normal_map.xy)));
    normal_map = mat3(tangent, bitangent, normal) * normal_map;
    if (normal_map.xy != vec2(0.0))
        normal = normal_map;
#endif

    vec3 sample_pos_smooth = world_position.xyz + normal * 0.51 + mod(cameraPosition, 1.0);

#ifdef WATER
    ivec3 ioffset = ivec3(0);
#else
    ivec3 ioffset = -ivec3(previousCameraPosition) + ivec3(cameraPosition);
#endif

    vec3 fade_distances = smoothstep(vec3(volume_width, volume_depth, volume_height) * 0.4f, vec3(volume_width, volume_depth, volume_height) * 0.5f, abs(world_position.xyz));
    float fade_distance = max(max(fade_distances.x, fade_distances.y), fade_distances.z);

    vec3 lighting = vec3(0.0);
    vec3 lighting_additive = vec3(0.0);
 
#ifdef UNLIT
    lighting = vec3(1.0);
#else
    if (fade_distance < 1.0)
    {
        lighting = sample_lighting_bilinear(gaux2, sample_pos_smooth, ioffset) * 10.0;
    }
#endif

    vec3 fade_lighting = pow(lmcoord.x, 4.0) * vec3(1.0, 0.8, 0.5) * 2.0;

    lighting = mix(lighting, fade_lighting, fade_distance);

    if (lmcoord.x >= 0.95)
    {
        lighting = vec3(1.0);
    }

    vec3 image_based_lighting = vec3(0.0);

    vec3 world_dir = normalize(world_position.xyz);
    vec3 reflection_dir = reflect(world_dir, normal);

    vec4 color = texture(tex, uv) * vertex_color;
    
    color.rgb = fromGamma(color.rgb);

    vec3 world_sun_dir = mat3(gbufferModelViewInverse) * sunPosition * 0.01;

    float NdotL = max(0.0, dot(normal, world_sun_dir));
    float NdotV = max(0.0, dot(normal, -world_dir));

    vec4 materials = texture(specular, uv);

    float roughness = 1.0 - materials.r;

    #define LIGHTING_SAMPLES 4 // [4 8 16]

    float hash1d = texelFetch(gaux4, ivec2(gl_FragCoord.st + WeylNth(frameCounter & 0xFF) * 16) & 0xFF, 0).r;    
    float rand1d = hash1d * 65536.0;// + float(frameCounter & 0xFF);

    vec3 F = getF(materials.g, NdotV); //fresnelSchlickRoughness(NdotV, getF(materials.g, NdotV), roughness);

    for (int i = 0; i < LIGHTING_SAMPLES; i++)
    {
        vec2 rand2d = WeylNth(int(rand1d) * LIGHTING_SAMPLES + i);

        vec3 H = ImportanceSampleGGX(rand2d, normal, roughness);
        vec3 sample_dir = normalize(2.0 * dot(-world_dir, H) * H + world_dir);

        #ifdef VOXEL_RAYTRACED_AO
        bool hit = false;
        vec3 hitcolor = vec3(0.0);

        if ((fade_distance < 1.0) && (dot(sample_dir, vertex_normal) > 0.0))
        {
            for (int j = 0; j < 4; j++)
            {
                vec3 sample_pos = world_position.xyz + vertex_normal * 0.2 + sample_dir * (float(j) + hash1d);
                ivec3 volume_pos = getVolumePos(sample_pos, cameraPosition);// + ioffset;
                ivec2 planar_pos = volume2planar(volume_pos);

                if (planar_pos == ivec2(-1)) break;

                if (texelFetch(shadowcolor0, planar_pos, 0).a < 1.0)
                {
                    hit = true;
                    
                    ivec3 volume_pos_prev = getVolumePos(sample_pos, cameraPosition) + ioffset;
                    ivec2 planar_pos_prev = volume2planar(volume_pos_prev);
                    
                    hitcolor = texelFetch(shadowcolor0, planar_pos, 0).rgb * max(fogColor * lmcoord.y * 0.3, texelFetch(gaux2, planar_pos_prev, 0).rgb * 10.0);
                    break;
                }

            }
        }
        
        if (!hit) {
            image_based_lighting += pow(lmcoord.y, 2.0) * texture(gaux3, project_skybox2uv(sample_dir), 3).rgb * 3.0;
        } else {
            image_based_lighting += hitcolor;
        }
        #else
        image_based_lighting += pow(lmcoord.y, 3.0) * texture(gaux3, project_skybox2uv(sample_dir), 3).rgb * vertex_color.a * 3.0;
        #endif
    }

    lighting += image_based_lighting * F;

    #ifdef WATER
    lighting /= color.a;
    #endif

    if (block_id < 200)
    {
        color.rgb *= lighting;
    }
    else
    {
        color.rgb += color.rgb * lighting;
    }

    color.rgb += lighting_additive;

    color.rgb = toGamma(color.rgb);

    // color.rgb = lighting * 0.3;

    gl_FragData[0] = color;
}