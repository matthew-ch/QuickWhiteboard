//
//  BridgingHeader.h
//  QuickWhiteboard
//
//  Created by Matthew.J on 2025/1/14.
//

#ifndef BridgingHeader_h
#define BridgingHeader_h

typedef enum BufferIndices {
    BufferIndexViewport,
    BufferIndexOffset,
    BufferIndexVertexArray,
    BufferIndexUVArray,
    BufferIndexDepth,
    BufferIndexColor,
} BufferIndices;

typedef enum TextureIndices {
    TextureIndexDefault,
} TextureIndices;

#endif /* BridgingHeader_h */
