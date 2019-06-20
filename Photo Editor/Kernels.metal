#include <metal_stdlib>
using namespace metal;
#include <CoreImage/CoreImage.h> // includes CIKernelMetalLib.h

extern "C" {
    namespace coreimage {
        // Blend kernel
        float4 task4(sample_t foreground, sample_t background) {
            /*
             1. Replicate the math of the blend filter chosen in task 3.
             */

            // Note: You can work with `sample_t` and `float4` as vector.
//            return <#foreground + background#>;

            return foreground; // Remove this line
        }

        // Color kernel
        float4 task5(sample_t foreground, sample_t background, sample_t depthMap) {
            /*
             1. Define a constant for a threshold. Its value is the approximate distance from the camera in meters
             2. Read out the value of the red color channel from the depth map (the `r` property on `depthMap`).
             3. Compare the depth value to your threshold.
             4. Return `foreground` if closer than threshold, else return `background`.
             */

//            float threshold = <#value#>;
//            float depthValue = depthMap.<#colorchannel#>;
//            if (<#compare#>) {
//                return <#    #>;
//            } else {
//                return <#    #>;
//            }

            return foreground; // Remove this line
        }

        // Warp kernel
        // Receives as argument the position of the pixel in the output image.
        // Its job is to return a coordinate indicating where in the source image
        // there should be sampled from.
        float2 appendix1(destination dest) {
            float2 c = dest.coord();

            float columnWidth = 150.0;
            float columnIndex = floor(c.x / columnWidth);

            float2 sampleCoord;

            if (int(columnIndex) % 2 == 0) {
                sampleCoord = float2(c.x, c.y + 30.0);
            } else {
                sampleCoord = float2(c.x, c.y - 30.0);
            }

            return sampleCoord;
        }

        // A general kernel
        float4 appendix2(sampler originalImage, sampler depthMap, destination dest) {
            float2 c = dest.coord();
            float depth = depthMap.sample(depthMap.coord()).r;
            float distortAmount = (1.0 - min(depth, 1.0)) * 100.0;

            float columnWidth = 150.0;
            float columnIndex = floor(c.x / columnWidth);

            float2 sampleCoord;
            if (int(columnIndex) % 2 == 0) {
                sampleCoord = float2(c.x, c.y + distortAmount);
            } else {
                sampleCoord = float2(c.x, c.y - distortAmount);
            }

            return originalImage.sample(originalImage.transform(sampleCoord));
        }

        // Warp kernel
        // In this example, we create a tiling effect. This is achieved by returning
        // the same sampling coordinate for pixels that lie within the same tile.
        float2 appendix3(destination dest) {
            // Get the coordinate of the pixel in the output image
            float2 c = dest.coord();
            // Define the width and height of a tile
            const float2 tileSize = float2(200.0, 300.0);
            // Make coordinates within the same tile sample from the same coordinate
            // Ex. if tileSize.x == 5.0:
            //  0.0 <= c.x <  5.0  -->  sampleCoord.x ==  0.0
            //  5.0 <= c.x < 10.0  -->  sampleCoord.x ==  5.0
            // 10.0 <= c.x < 15.0  -->  sampleCoord.x == 10.0
            float2 sampleCoord = float2(
                                        floor(c.x / tileSize.x) * tileSize.x,
                                        floor(c.y / tileSize.y) * tileSize.y
                                        );
            return sampleCoord;
        }

        // Color kernel
        float4 appendix4(sample_t originalImage) {
            float value = (originalImage.r + originalImage.g + originalImage.b) / 3.0;
            return float4(float3(value), originalImage.a);
        }

        // General kernel
        float4 appendix5(sampler originalImage, sampler depthMap, destination d) {
            float4 originalColor = originalImage.sample(originalImage.coord());
            float4 tintColor = appendix4(originalColor);

            float tintAmount = d.coord().x / originalImage.size().x;
            return float4(
                originalColor.r * (1.0 - tintAmount) + tintColor.r * tintAmount,
                originalColor.g * (1.0 - tintAmount) + tintColor.g * tintAmount,
                originalColor.b * (1.0 - tintAmount) + tintColor.b * tintAmount,
                1.0
            );
        }

        float4 appendix6(sample_t originalImage, sample_t depthMap) {
            float depth = depthMap.r;

            float4 tintColor = appendix4(originalImage);
            float tintAmount = max(min((depth - 0.5) / (1.0 - 0.5), 1.0), 0.0);
            return float4(
                originalImage.r * (1.0 - tintAmount) + tintColor.r * tintAmount,
                originalImage.g * (1.0 - tintAmount) + tintColor.g * tintAmount,
                originalImage.b * (1.0 - tintAmount) + tintColor.b * tintAmount,
                1.0
            );
        }

        // A general kernel
        // The destination parameter is optional for general kernel. Must be last.
        float4 appendix7(sampler originalImage, sampler depthMap, destination d) {
            // Take sample from samplers at coordinate that matches output/destination space
            float4 colorSample = originalImage.sample(originalImage.coord());
            float4 depthSample = depthMap.sample(depthMap.coord());

            // Change color of foreground
            float4 foreground = float4(// Blue channel directly from color sampler
                                       colorSample.b,
                                       // Green channel as gradient from top to bottom using size() of color sampler
                                       d.coord().y / originalImage.size().y,
                                       // Green channel from on depth sampler
                                       depthSample.r,
                                       1);

            // Distort background by tiling
            // Tile width is determined based on the depth value in each pixel
            float depth = depthSample.r;
            float tileWidth = depth * 20.0;
            float2 sampleCoord = float2(
                                        floor(d.coord().x / tileWidth) * tileWidth,
                                        floor(d.coord().y / tileWidth) * tileWidth
                                        );
            // Sample background from the new coordinate.
            // We need to use the .transform method to translate destination
            // space (absolute pixel values) to input/color space (normalized pixel values)
            float4 background = originalImage.sample(originalImage.transform(sampleCoord));

            // Use the `task5` kernel function directly to combine foreground and background based on depth map.
            return task5(foreground, background, depthSample);
        }
    }
}
