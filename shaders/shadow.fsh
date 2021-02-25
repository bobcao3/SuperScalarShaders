#version 430 compatibility

in GeoOut {
    flat vec4 vertex_color;
    flat vec2 uv;
    flat int block_id;
    flat int fluid;
    flat vec2 lmcoord;
};

uniform sampler2D tex;

void main()
{
    float transparency = 0.5;
    float emmisive = 1.0;

    if (fluid == 1 || (block_id > 28 && block_id < 33) || block_id >= 9230) transparency = 1.0;

    if (block_id > 9199) emmisive = 0.9;

    vec4 texcolor = texture(tex, uv, 3);
    vec3 color = mix(vec3(0.5), texcolor.rgb * vertex_color.rgb, texcolor.a);

    if (transparency == 1.0) color.rgb = color.rgb * 0.5 + 0.5;

    if (block_id == 30)
        color = color * 0.4 + 0.6;
    else if (block_id == 9201)
        color = vec3(255.0, 176.0, 94.0) / 255.0;
    else if (block_id == 9231)
        color = vec3(255.0, 147.0, 41.0) / 255.0;
    else if (block_id == 9232)
        color = vec3(132.0, 194.0, 188.0) / 255.0;
    else if (block_id == 9233)
        color = vec3(154.0, 43.0, 35.0) / 255.0;
    else if (block_id == 9234)
        color = vec3(254.0, 227.0, 255.0) / 255.0;
    else if (lmcoord.x > 0.9685)
        emmisive = 0.9;
    else if (block_id == 32)
        color = vec3(1.0);

    gl_FragColor = vec4(color, transparency);
}