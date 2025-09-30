//
//  Shader.metal
//  QuickWhiteboard
//
//  Created by Matthew.J on 2024/4/25.
//

#include <metal_stdlib>
#include "BridgingHeader.h"
using namespace metal;

struct Vertex {
    float4 position [[ position ]];
};

struct VertexWithUV {
    float4 position [[ position ]];
    float2 uv;
};

vertex Vertex simpleVertex(const constant float4 &frameRect [[ buffer(BufferIndexViewport) ]],
                           const constant float2 &offset [[ buffer(BufferIndexOffset) ]],
                           const device float2* vertexArray [[ buffer(BufferIndexVertexArray) ]],
                           const constant float &depth [[ buffer(BufferIndexDepth) ]],
                           unsigned int vid [[ vertex_id ]]) {
    return Vertex {
        .position = float4((vertexArray[vid] + offset - frameRect.xy) / frameRect.zw * 2.0 - 1.0, depth, 1.0),
    };
}

fragment float4 simpleFragment(const constant float4& color [[ buffer(BufferIndexColor) ]]) {
    float4 output = color;
    output.xyz *= output.w;
    return output;
}

vertex VertexWithUV textureVertex(const constant float4 &frameRect [[ buffer(BufferIndexViewport) ]],
                                  const constant float2 &offset [[ buffer(BufferIndexOffset) ]],
                                  const device float2* vertexArray [[ buffer(BufferIndexVertexArray) ]],
                                  const constant float &depth [[ buffer(BufferIndexDepth) ]],
                                  const device float2* uv_array [[ buffer(BufferIndexUVArray) ]],
                                  unsigned int vid [[ vertex_id ]]) {
    return VertexWithUV {
        .position = float4((vertexArray[vid] + offset - frameRect.xy) / frameRect.zw * 2.0 - 1.0, depth, 1.0),
        .uv = uv_array[vid]
    };
}

fragment float4 textureFragment(VertexWithUV in [[ stage_in]],
                                texture2d<float, access::sample> tex [[ texture(TextureIndexDefault) ]]) {
    constexpr sampler samp(mag_filter::linear, min_filter::linear, address::clamp_to_edge);
    return tex.sample(samp, in.uv);
}
