#version 430 compatibility
#pragma optimize(on)

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D colortex7;

const vec2 poisson64[64] = vec2[64] (
    vec2(0.0f, 0.0f),
    vec2(-0.7236182164035513f, 0.6829634656197917f),
    vec2(0.9515475251044628f, 0.3002932175678878f),
    vec2(-0.2544437621928544f, -0.9577730378547232f),
    vec2(0.23373122888134532f, 0.9316681370337644f),
    vec2(-0.8979746309444359f, -0.22259739995934072f),
    vec2(0.6564436615986121f, -0.6518168336579888f),
    vec2(-0.3563971432205133f, -0.4109610421936284f),
    vec2(-0.15338834881418406f, 0.5531741390951747f),
    vec2(-0.5809441366089148f, 0.19388431060760924f),
    vec2(0.633739714269675f, -0.08318820593919773f),
    vec2(0.32357511303488756f, 0.38604903775097243f),
    vec2(0.21320199140156984f, -0.9340534558205579f),
    vec2(0.1329940663424604f, -0.4548931460881974f),
    vec2(-0.6101393610545307f, -0.7205375198987232f),
    vec2(-0.16712294518619952f, 0.9198475941982326f),
    vec2(0.9286803750867708f, -0.340851423983577f),
    vec2(-0.896606674881588f, 0.33667387622439376f),
    vec2(0.639555308832954f, 0.759678491309135f),
    vec2(-0.5146188358237146f, -0.11004624479435388f),
    vec2(0.648957319317446f, 0.4471030391854517f),
    vec2(0.31298729162008976f, -0.012867709387180072f),
    vec2(-0.043033164286831356f, -0.7369992728269796f),
    vec2(-0.10719779753706238f, -0.281965026142244f),
    vec2(-0.2638986900714708f, 0.17156113757698024f),
    vec2(-0.3265328674911739f, -0.6973724678539756f),
    vec2(0.4580374186412187f, -0.3543295716183586f),
    vec2(0.36172062880426936f, 0.6762836735878323f),
    vec2(0.35294349977085826f, -0.6643967012734129f),
    vec2(-0.4058814213432594f, 0.7185226552205375f),
    vec2(-0.9151930535324115f, 0.045477636102362974f),
    vec2(-0.6629439078612167f, -0.41816165633041913f),
    vec2(0.07723110503325169f, 0.6711627044437033f),
    vec2(0.9949263854142011f, 0.007415110780208049f),
    vec2(0.510360864990442f, 0.20256478340459683f),
    vec2(0.15424040040569112f, -0.18807716916297434f),
    vec2(0.0588756168610071f, 0.3900224926040219f),
    vec2(-0.48518914797561913f, 0.4700481601922435f),
    vec2(-0.23851928763338356f, -0.0914074016412064f),
    vec2(0.765723737720001f, 0.16334720927793317f),
    vec2(-0.7069439588847086f, 0.0021310831356228335f),
    vec2(-0.8685964360397008f, -0.4639944784625944f),
    vec2(-0.5060613909104994f, -0.5515905527080651f),
    vec2(0.4960260705956402f, -0.8550803092576144f),
    vec2(0.6349159618961655f, -0.44949193786104275f),
    vec2(-0.1776215254034605f, -0.5174197265263771f),
    vec2(0.43682069595516815f, 0.8865299683334967f),
    vec2(0.16630531509296456f, 0.11682025861153836f),
    vec2(-0.7024665311049444f, 0.4223691069289203f),
    vec2(0.03037826057732065f, 0.8852932564457552f),
    vec2(0.7632091452070453f, 0.6140952664633548f),
    vec2(0.8588315427971827f, -0.14734196748116166f),
    vec2(-0.41936205935785836f, -0.882429197258433f),
    vec2(-0.39580221267114474f, 0.034287494098190124f),
    vec2(-0.009606496730329733f, -0.9939057041925079f),
    vec2(-0.16610307572468158f, 0.3332417807374101f),
    vec2(-0.5761566970662527f, 0.7975646997545476f),
    vec2(0.16153950057742292f, -0.7566103627635472f),
    vec2(-0.38867469485973155f, 0.9167036152262722f),
    vec2(-0.6933459448355513f, -0.20618283860748163f),
    vec2(0.4381242322047682f, -0.15968213359520492f),
    vec2(-0.018902074572386927f, 0.2274572975501825f),
    vec2(0.8506598863389525f, -0.5012708075506751f),
    vec2(0.8375246143913322f, 0.4443575222644228f)
);

uniform vec2 invWidthHeight;
uniform float aspectRatio;

uniform float near;
uniform float far;

uniform float centerDepthSmooth;

float linearizeDepth(in float d) {
    return (2 * near) / (far + near - (d * 2.0 - 1.0) * (far - near));
}

void main()
{
    ivec2 iuv = ivec2(gl_FragCoord.st);
    vec2 uv = gl_FragCoord.st * invWidthHeight;

    vec3 color = vec3(0.0);

    if (uv.x > 0.5 || uv.y > 0.5) return;

    uv *= 2.0;

    float depth = textureLod(depthtex0, uv, 1).r;
    float depth_linear = linearizeDepth(depth);
    float center_depth_linear = linearizeDepth(centerDepthSmooth);

    float far_cut_linear = center_depth_linear * 1.1;

    vec2 CoC_center = texelFetch(colortex7, iuv, 0).rg;

    float radius = max(CoC_center.r, CoC_center.g);

    float weight = 0.0;
    float max_coc = 0.0;

    for (int i = 0; i < 64; i++)
    {
        vec2 offset = poisson64[i] * radius;
        vec2 uv_test = uv + offset * vec2(1.0, aspectRatio) * 0.5;
        vec2 uv_test_half = uv_test * 0.5;

        vec2 CoC = textureLod(colortex7, uv_test_half, 0).rg;

        float test_offset_length = length(offset);

        // float depth_test = linearizeDepth(textureLod(depthtex0, uv_test, 1).r);

        if ((CoC_center.r > 0.0003 && CoC.r > 0.0003 && CoC.r >= test_offset_length) || (CoC_center.r <= 0.0003))
        {
            float sample_weight = 1.0;// - test_offset_length * 100.0;

            color += textureLod(colortex0, uv_test, 1).rgb * sample_weight;
            weight += sample_weight;

            max_coc = max(max_coc, max(CoC.r, CoC.g));
        }
    }

    color /= weight;

    // if (depth_linear >= far_cut_linear) color = vec3(0.0);

/* RENDERTARGETS:8 */
    gl_FragData[0] = vec4(color, max_coc);
}