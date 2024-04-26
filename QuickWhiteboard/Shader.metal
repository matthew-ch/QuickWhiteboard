//
//  Shader.metal
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexWithUV {
    float4 position [[ position ]];
    float2 uv;
};

vertex float4 simpleVertex(const constant float4 &frameRect [[ buffer(0) ]],
                           const device float2* vertexArray [[ buffer(1) ]],
                           unsigned int vid [[ vertex_id ]]) {
    return float4((vertexArray[vid] - frameRect.xy) / frameRect.zw * 2.0 - 1.0, 0.0, 1.0);
}

fragment float4 simpleFragment(const constant float4& color [[ buffer(0) ]]) {
    return color;
}

vertex VertexWithUV textureVertex(const constant float4 &frameRect [[ buffer(1) ]],
                                  const device float2* vertexArray [[ buffer(0) ]],
                                  const device float2* uv_array [[ buffer(2) ]],
                                  unsigned int vid [[ vertex_id ]]) {
    return VertexWithUV {
        .position = float4((vertexArray[vid] - frameRect.xy) / frameRect.zw * 2.0 - 1.0, 0.0, 1.0),
        .uv = uv_array[vid]
    };
}

fragment float4 textureFragment(VertexWithUV in [[ stage_in]],
                                 texture2d<float, access::sample> tex [[ texture(0) ]]) {
    constexpr sampler samp(mag_filter::linear, min_filter::linear, address::clamp_to_edge);
    return tex.sample(samp, in.uv);
}
