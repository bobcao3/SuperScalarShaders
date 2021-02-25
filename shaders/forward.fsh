// #define WIREFRAME
// #define WIREFRAME_ONLY

in VertexOut {
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

    float fade_distance;

#ifdef WIREFRAME
    vec4 bary;
#endif
};

#ifdef ENTITY
uniform vec4 entityColor;
#endif

#ifdef NORMAL_MAPPING
uniform sampler2D normals;
#endif

uniform sampler2D tex;
// uniform sampler2D colortex5;
// uniform sampler2D colortex4;

/* DRAWBUFFERS: 0 */

#include "voxelize.glslinc"
#include "color.glslinc"
#include "/libs/transform.glsl"

// uniform vec3 cameraPosition;
// uniform vec3 previousCameraPosition;

#ifdef POM

vec2 ParallaxMapping(in vec2 coord) {
	vec2 adjusted = coord.st;
	#define POM_STEPS 4 // [4 8 16]
	#define scale 0.01 // [0.005 0.01 0.02 0.04]

	float heightmap = texture(normals, coord.st).a - 1.0f;

    vec3 uv_dir = (tangentpos);
    vec2 rect_size = abs(bound_uv - miduv);

	vec3 offset = vec3(0.0f, 0.0f, 0.0f);
	vec3 s = uv_dir / uv_dir.z * (0.5 * scale / POM_STEPS);

	float lazyx = 0.5;
	const float lazyinc = 0.5 / POM_STEPS;

	if (heightmap < 0.0f) {
		for (int i = 0; i < POM_STEPS; i++) {
			float prev = offset.z;

			offset += (heightmap - prev) * lazyx * s;
			lazyx += lazyinc;

			vec2 offset_from_mid = coord + offset.st - miduv;
            adjusted = miduv + clamp(offset_from_mid, -rect_size, rect_size);// * sign(offset_from_mid);
		
        	heightmap = texture(normals, adjusted).a - 1.0f;
			if (max(0.0, offset.z - heightmap) < 0.01) break;
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

#include "/libs/noise.glsl"
#include "/libs/taa.glsl"

uniform int frameCounter;

#ifdef WATER
uniform float frameTimeCounter;

#include "/libs/water.glsl"
#endif

#ifdef VOXEL_RAYTRACED_AO
uniform sampler2D shadowcolor0;

#define RAYTRACE_DISTANCE 4 // [2 4 8 16 32 64]

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
    float a = roughness;
	
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

vec3 getF(float metalic, float roughness, float cosTheta)
{
	if (metalic < (229.5 / 255.0))
    {
        float metalic_generated = 1.0 - metalic * (229.0 / 255.0);
        metalic_generated = pow(metalic_generated, 2.0);
		return fresnelSchlickRoughness(cosTheta, vec3(metalic_generated), roughness);
    }

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

uniform sampler2D shadowtex0;

uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

void main()
{
    vec3 normal = vertex_normal;

#ifdef POM
    vec2 adj_uv = ParallaxMapping(uv);
    #define uv adj_uv
#endif

    vec2 atlas_size = textureSize(tex, 0);

    vec2 ddx = dFdx(uv);
    vec2 ddy = dFdy(uv);

    float dL = min(length(ddx * atlas_size), length(ddy * atlas_size));
    float lod = clamp(round(log2(dL) - 1.0), 0, 3);

    vec4 color = vec4(0.0);
    
    #define AF_TAPS 8 // [2 4 8 16]

#ifdef USE_AF
    vec2 rect_size = abs(bound_uv - miduv);
    
    for (int i = 0; i < AF_TAPS; i++)
    {
        vec2 offset = WeylNth(i);

        vec2 offset_from_mid = uv + (offset - 0.5) * max(ddx, ddy) - miduv;
        vec2 uv_offset = miduv + clamp(offset_from_mid, -rect_size, rect_size);// * sign(offset_from_mid);

        color.rgb += textureLod(tex, uv_offset, lod).rgb;
    }

    color.rgb /= float(AF_TAPS);
    color.a = textureLod(tex, uv, lod).a;
#else
    color = texture(tex, uv);
#endif

    color *= vertex_color;
    
    if (color.a < 0.1)
    {
        gl_FragData[0] = vec4(0.0);
        return;
    }

    color.rgb = fromGamma(color.rgb);

#ifdef NORMAL_MAPPING
    vec3 normal_map;
#ifdef LABPBR_STRICT_NORMAL_ENCODING
    normal_map.xy = texture(normals, uv).rg * 2.0 - 1.0;
    normal_map.z = sqrt(max(0.0001, 1.0 - dot(normal_map.xy, normal_map.xy)));
#else
    normal_map.xyz = texture(normals, uv).rgb * 2.0 - 1.0;
#endif
    normal_map = mat3(tangent, bitangent, normal) * normal_map;
    if (normal_map.xy != vec2(0.0))
        normal = normal_map;
#endif

#ifdef WATER
    if (block_id == 32) normal = get_water_normal(world_position.xyz + cameraPosition, 1.0, vertex_normal, tangent, bitangent);
#endif

    vec3 sample_pos_smooth = world_position.xyz + normal * 0.51 + mod(cameraPosition, 1.0);

// #ifdef WATER
    ivec3 ioffset = ivec3(0);
// #else
//     ivec3 ioffset = ivec3(floor(cameraPosition) - floor(previousCameraPosition));
// #endif

    vec3 fade_distances = smoothstep(vec3(volume_width, volume_depth, volume_height) * 0.4f, vec3(volume_width, volume_depth, volume_height) * 0.5f, abs(world_position.xyz));
    float fade_distance = max(max(fade_distances.x, fade_distances.y), fade_distances.z);

    vec3 lighting = vec3(0.0);
 
#ifdef UNLIT
    lighting = vec3(1.0);
#else
    if (fade_distance < 1.0)
    {
        lighting = sample_lighting_bilinear(colortex5, sample_pos_smooth, ioffset);

        int handLightLevel = max(heldBlockLightValue, heldBlockLightValue2);
        float handLightLevel_f = float(handLightLevel) * (1.0 / 240.0);
        float world_distance = length(world_position.xyz);
        float attenuation = 1.0 / ((1.0 + world_distance) * (1.0 + world_distance));
        lighting = max(lighting, attenuation * handLightLevel_f * vec3(1.0, 0.8, 0.5) * 30.0);
    }
#endif

    vec3 fade_lighting = pow(lmcoord.x, 4.0) * vec3(1.0, 0.8, 0.5) * 2.0;

    lighting = mix(lighting, fade_lighting, fade_distance);

    if (lmcoord.x >= 0.9685)
    {
        lighting = vec3(1.0);
    }

    vec3 image_based_lighting = vec3(0.0);

#if MC_VERSION > 11300
    vec3 world_dir = normalize(world_position.xyz);
#else
    vec3 world_dir = normalize(world_position.xyz - vec3(0.0, 1.61, 0.0));
#endif

    vec3 reflection_dir = reflect(world_dir, normal);

    vec3 world_sun_dir = mat3(gbufferModelViewInverse) * sunPosition * 0.01;

    float NdotL = max(0.0, dot(normal, world_sun_dir));
    float NdotV = max(0.0, dot(normal, -world_dir));

    vec4 materials = texture(specular, uv);

    float roughness = pow(1.0 - materials.r, 2.0);

    #ifdef WATER
    float foam = getpeaks(world_position.xyz + cameraPosition, 1.0, 2, 4) * (getpeaks(world_position.xyz + cameraPosition, 1.0, 0, 2) * 0.7 + 0.3);

    if (block_id == 32)
    {
        roughness = 0.02;
        materials.g = 0.89;
    
        color.rgb = vertex_color.rgb;// * 0.5 + 0.5;

        color.rgb = mix(color.rgb, vec3(1.0), foam);
    }

    vec3 sun_color = sampleLODmanual(colortex4, project_skybox2uv(world_sun_dir), 3).rgb;
    #endif

    #define LIGHTING_SAMPLES 4 // [4 8 16]

    float hash1d = texelFetch(colortex7, ivec2(gl_FragCoord.st + WeylNth(frameCounter & 0xFFFF) * 256) & 0xFF, 0).r;    
    float rand1d = hash1d * 65536.0;// + float(frameCounter & 0xFF);

    vec3 F = getF(materials.g, roughness, NdotV);

    lighting *= F;

    #ifdef WATER
    for (int i = 0; i < 1; i++)    
    #else
    for (int i = 0; i < LIGHTING_SAMPLES; i++)
    #endif
    {
        vec2 rand2d = WeylNth(int(rand1d) * LIGHTING_SAMPLES + i);

        vec3 H = ImportanceSampleGGX(rand2d, normal, roughness);
        vec3 sample_dir = normalize(2.0 * dot(-world_dir, H) * H + world_dir);

        if (dot(sample_dir, vertex_normal) <= 0.0)
        {
            sample_dir = reflect(sample_dir, vertex_normal);
        }

        vec2 skybox_uv = project_skybox2uv(sample_dir);
        
        // if (roughness > 0.3)
        // {
        //     skybox_uv.x += 0.25 + 8.0 * invWidthHeight.x;
        // }

        int skybox_lod = int(ceil(pow(roughness, 0.25) * 6.0));

        #ifdef VOXEL_RAYTRACED_AO
        bool hit = false;
        vec3 hitcolor = vec3(1.0);

        vec3 skybox_color = sampleLODmanual(colortex4, skybox_uv, skybox_lod).rgb;

        if ((fade_distance < 1.0) && (dot(sample_dir, vertex_normal) > 0.0))
        {
            #ifdef WATER
            for (int j = 0; j < RAYTRACE_DISTANCE * 4; j++)
            #else
            for (int j = 0; j < RAYTRACE_DISTANCE; j++)
            #endif
            {
                #ifdef WATER
                vec3 sample_pos = world_position.xyz + vertex_normal * 0.5 + sample_dir * (float(j) + hash1d);
                #else
                vec3 sample_pos = world_position.xyz + vertex_normal * 0.1 + sample_dir * (float(j) + hash1d);
                #endif
                ivec3 volume_pos = getVolumePos(sample_pos, cameraPosition);
                ivec2 planar_pos = volume2planar(volume_pos);

                if (planar_pos == ivec2(-1)) break;

                vec4 voxel_color = texelFetch(shadowcolor0, planar_pos, 0);
                float voxel_attribute = texelFetch(shadowtex0, planar_pos, 0).r;

                hitcolor *= (voxel_color.rgb);

                bool is_lightsource = (voxel_attribute > 0.54 && voxel_attribute < 0.56);

                if (voxel_color.a < 1.0 || is_lightsource)
                {
                    hit = true;
                    
                    ivec3 volume_pos_prev = getVolumePos(sample_pos - sample_dir * 0.5, cameraPosition) + ioffset;
                    ivec2 planar_pos_prev = volume2planar(volume_pos_prev);

                    if (!is_lightsource) hitcolor *= max(skybox_color * pow2(lmcoord.y) * 0.7, texelFetch(colortex5, planar_pos_prev, 0).rgb);
                    break;
                }
            }
        } else {
            hitcolor *= vertex_color.a;
        }

        vec3 approxSkylight = pow2(lmcoord.y) * skybox_color;

        #ifndef WATER
        // if (dot(sample_dir, vertex_normal) <= 0.0)
        // {
        //     hit = true;
        //     hitcolor = approxSkylight;
        // }
        #endif

        if (!hit) {
            image_based_lighting += hitcolor * approxSkylight;
        } else {
            image_based_lighting += hitcolor;
        }
        #else
        image_based_lighting += pow3(lmcoord.y) * sampleLODmanual(colortex4, skybox_uv, skybox_lod).rgb * vertex_color.a;
        #endif
    }

    image_based_lighting *= 4.0 / float(LIGHTING_SAMPLES);

    if (block_id < 9200)
    {
        lighting += image_based_lighting;
        color.rgb *= lighting;
    }
    else
    {
        // color.rgb += color.rgb * lighting * 2.0;
        color.rgb *= 5.0;
    }

    // color.rgb = image_based_lighting;

    #ifdef WATER
    if (block_id == 32)
    {
        color.rgb += foam * sun_color;
    }
    #endif

    #ifdef WATER
    if (block_id == 32)
    {
        color.a = clamp(F.g * 1.7 + 0.3, 0.0, 1.0);
    }
    #endif

    #ifdef WATER
    lighting /= color.a;
    #endif

#ifdef SPECTRAL
    color.rgb = mix(vec3(0.7), color.rgb, 1.0 - min(1.0, length(world_position) / 16.0));
#endif

#ifdef WIREFRAME
    float outlineWidth = 0.05;

    #ifndef WIREFRAME_ONLY
    if (bary.x < outlineWidth || bary.y < outlineWidth || bary.z < outlineWidth) {
        color.rgb = vec3(0.0, 0.4, 1.0);
        color.a = 1.0;
    }
    #else
    if (bary.x < outlineWidth || bary.y < outlineWidth || bary.z < outlineWidth) {
        if (color.a < 0.1)
        {
            color.rgb = vec3(1.0, 0.0, 1.0);
        }
        color.a = 1.0;
    } else {
        discard;
    }
    #endif
#endif

    // color.rgb = toGamma(color.rgb);

    // color.rgb = lighting;

#ifdef ENTITY
    color.rgb += entityColor.rgb;
#endif

    // color.rgb = vec3(roughness);
    // color.rgb = normal * 0.5 + 0.5;

    gl_FragData[0] = color;
}