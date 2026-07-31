#version 460
#extension GL_EXT_samplerless_texture_functions : require

struct _4
{
    uint _m0;
};

layout(set = 0, binding = 3, std140) uniform _24_23
{
    _4 _m0;
} _23;

layout(set = 0, binding = 0) uniform texture2D _15[5];
layout(set = 0, binding = 1) uniform sampler _18[5];
layout(set = 0, binding = 2) uniform texture2D _21;

layout(location = 0) out vec4 _50;

vec4 _33(texture2D _27, sampler _30, vec2 _32)
{
    return textureLod(sampler2D(_27, _30), _32, 0.0);
}

vec4 _43(texture2D _41)
{
    return texelFetch(_41, ivec2(0), 0);
}

void main()
{
    vec4 _61 = vec4(0.0);
    _61 += _33(_15[0u], _18[0u], vec2(0.5));
    _61 += _43(_15[1u]);
    _61 += _33(_15[_23._m0._m0], _18[_23._m0._m0], vec2(0.5));
    _61 += _43(_15[_23._m0._m0]);
    _61 += textureLod(sampler2D(_15[0u], _18[0u]), vec2(0.5), 0.0);
    _61 += _33(_21, _18[0u], vec2(0.5));
    _50 = _61;
}

