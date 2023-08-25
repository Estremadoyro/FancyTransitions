//
//  BrightnessKernel.metal
//  FancyTransitions
//
//  Created by Leonardo  on 30/04/23.
//

#include <metal_stdlib>
using namespace metal;

/// Invert colors.
half4 invertColor(half4 color) {
    return half4((1.0 - color.rgb), color.a);
}

/// Kernel - Invert colors.
///
/// This will be instantiated and applied to each pixel of the grid specified by the gid parameter.
/// thread_position_in_grid
kernel void drawWithInvertedColor(texture2d<half, access::read> inTexture [[ texture(0) ]],
                                  texture2d<half, access::read_write> outTexture [[ texture(1) ]],
                                  uint2 gid [[ thread_position_in_grid ]]) {
    half4 color = inTexture.read(gid).rgba;
    half4 invertedColor = invertColor(color);

    outTexture.write(invertedColor, gid);
}
