# CoreImage in Color and Depth Workshop

The workshop has been created for a local meetup in Copenhagen [Peer Lab](https://www.meetup.com/CopenhagenCocoa/events/260892812/) and the Swift conference [Swift Aveiro 2019](http://swiftaveiro.xyz) in Portugal.

The authors are [Kalle](https://twitter.com/kkabell) and [Tobias](https://twitter.com/tobiasdm) from [Kabell & Munk](https://twitter.com/kabellmunk).

This project contains workshop material that besides this document includes a sample project with tasks as well as sample photos containing depth maps.

This file includes:

- A theoretical introduction to Core Image,
- an introduction guide for tasks to complete in the sample project, and
- a list of references.

## Prerequisites

- Basic knowledge in Swift
- Some experience using Xcode

## Technical Requirements

The project requires:

- A Mac running Mac OS Mojave 10.15+
- Xcode 10.0+
- Swift 5.0+
- An iOS device running iOS 12+

The sample project includes sample photos as an alternative to using images from one's own photo library. This way, the project can be used even when running on iOS devices that doesn't support capturing depth maps as part of the Portrait Effects Mode.

## Theory

[Core Image](https://developer.apple.com/documentation/coreimage) is a powerful framework for image processing and analysis. It is available on iOS, macOS, and tvOS and works both on still and video images.

Core Image has many built-in filters (`CIFilter`s) that can be chained together to create complex processing graphs. Examples of filters include gaussian blur, sepia tone, overlay blending, glass distortion, QR code generator, radial gradient, convolution, and even a page curl transition.

### Recipe based

Core Image produces `CIImage`s which are not images in the same sense as a `CGImage`. The latter has an image buffer in memory that contains a color value for each pixel. `CIImage` is more like a recipe for how the image should be constructed and processed. This means that setting up filters and chaining them is in itself very light weight, while rendering the result to an image buffer (like a `UIImage` in `UIImageView`) might require a lot of processing power.

When applying multiple effects or manipulations to an image, this delayed processing allows Core Image to optimize the recipe to make rendering as efficient as possible. For instance, in some situations it's possible for different effects to be concatened into a single job to be performed on the GPU. This would not be possible, if rendering was performed immediately after applying each individual effect.

### Extensible

The framework is also highly extensible by enabling integration of custom filters. This allows the processing graphs to stay highly performant by utilizing advanced software and hardware optimizations built in to Core Image.

The closest integration of custom logic into Core Image can be accomplished using [`CIKernel`](https://developer.apple.com/documentation/coreimage/writing_custom_kernels)s. The custom logic is written in a subset of the [Metal Shading Language](https://developer.apple.com/metal/MetalCIKLReference6.pdf) specifically for Core Image Kernels.

Core Image can also be extended using [`CIImageProcessorKernel`](https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel)s that enables the integration of custom image processors into the Core Image filter chain. This includes using other image processing technologies available on Apple's platform like [Metal Performance Shaders](https://developer.apple.com/documentation/metalperformanceshaders), [Core Graphics](https://developer.apple.com/documentation/coregraphics), [Accelerate vImage](https://developer.apple.com/documentation/accelerate/vimage). One can also create completely custom CPU-based processing logic in Swift or Objective-C.

# Tasks

There are 4 tasks in this workshop. The tasks build on top of each other, so it's preferred to complete them in order.

All tasks are setup in separate files `Task1.swift`, `Task2.swift` and so on. Each file contains a single (anonymous) function. It receives two arguments: The original image and the depth map. To complete a task, make the function return a processed image that is an image with image effects applied.

Read the instructions below before diving into each task's corresponding code file.

## Task 1

CoreImage is centered around filters, so let's start out by creating a filter, passing an image to it, and seeing the filter's resulting output.

To create a filter, use:

```swift
let filter = CIFilter(name: "CIPhotoEffectNoir")
```

where the filter name is provided as a string, here `"CIPhotoEffectNoir"`.

All built-in filters can be looked up at [CIFilter.io](https://cifilter.io) by [Noah Gilmore](https://twitter.com/noahsark769). Apple's own documentation ([Core Image Filter Reference](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html)) is outdated, so it lacks filters introduced in the recent years.

Some simple filters just take an input image and no other arguments. Set the input image using the designated string key `"inputImage"` like this:

```swift
filter.setValue(originalImage, forKey: "inputImage")
```

At this point, the filter is set up and the resulting image can be read from the `outputImage` property on the filter as follows:

```swift
let result = filter.outputImage
```

Now, complete the subtasks in `Task1.swift` and run the app to check the result.

## Task 2

A `CIFilter` can have multiple input images and arguments that change the behavior of the filter. Arguments are set just like the input image – as seen in the previous task.

```swift
filter.setValue(10, forKey: "inputRadius")
```

Here the radius is set for a filter named `"CIBoxBlur"` that also takes a `"inputImage"`. For this filter, each pixel in the `outputImage` is computed by taking the average of a square with a side length of 2 times `10` pixels, centered at the pixel. The documentation for the keys for the built-in filters (including this one) can be found at [CIFilter.io](https://cifilter.io).

The subtasks are ready for you in `Task2.swift`.

## Task 3

In task 1 and 2 we have created a foreground and background, and the objective now is to combine the two.

Each pixel in an image consists of 4 components that represents the color channels _red, green_, and _blue_ and the opacity channel _alpha_. Often shorted as RGBA. Each channel has a value between `0` and `1`.

For example, a solid red pixel has a value `1` in the `R`, and `A` channels and `0` for all other channels. A purple pixel would also have a value of `1` in its blue channel.

Let's say we are combining two images, and for a particular position we have a dark red and dark purple pixel respectively. The `"CIMultiplyCompositing"` filter multiplies the pixel values. This is done separately in each RGBA-channel, so the resulting in output pixel will be calculated like this:

```
[0.5 0 0 1] x [0.5 0 0.5 1] = [0.25 0 0 1]
```

The result will be an even darker red pixel.

In Core Image, we would use blending and compositing filters like this, where foreground and background are two `CIImage`s:

```swift
let filter = CIFilter("CIMultiplyCompositing")
filter.setValue(background, "inputBackgroundImage")
filter.setValue(foreground, "inputImage")
let blendedImage = filter.outputImage
```

Head to the `Task3.swift` file now to find your favorite blending filter.

## Task 4

In task 3 we used the blending filters that come built-in to Core Image. Your job now is to recreate the blending filter that you have chosen, by writing the logic yourself.

To create a custom image processing logic, Core Image has kernels that can be used in place of `CIFilter`s. The kernels are defined using pure functions written in Metal.

One kind of kernel is the `CIBlendKernel` whose Metal function is called once for each pixel, with the corresponding color values from a foreground image and a background image. It must return a single color value which will be used in the final image:

```c++
float4 aBlendKernel(sample_t foregroundImage, sample_t backgroundImage) {
    return float4( /* color components */ );
}
```

A color value is of type `float4`. `sample_t` is also a `float4`. The color channels are accessed as the properties `r`, `g`, `b` and `a`.

A full blend kernel function could look like this:

```c++
float4 subtract(sample_t foregroundImage, sample_t backgroundImage) {
    // Blend the images by subtracting the color components of the
    // foreground from the corresponding components in the background
    float red = backgroundImage.r - foregroundImage.r;
    float green = backgroundImage.g - foregroundImage.g;
    float blue = backgroundImage.b - foregroundImage.b;
    float alpha = input.a;

    // Return a new float4
    return float4(red, green, blue, alpha);
}
```

With a kernel function, you have full control of how two images should be blended together. You are free to do any math on the color values to achieve the desired effect.

Go on to `Task4.swift` now and follow the steps.

## Task 5

Let's try to build our own blending filter, using the image's depth map. We will selectively decide which areas of the output image should be sampled from the two images created in task 1 and 2.

To achieve this, we will use a color kernel. The `CIColorKernel` is a Metal function which is called once for each pixel, with the corresponding color value(s) from the input image(s) and it must return a single color value which will be used in the final image:

A full color kernel function could look like this:

```c++
float4 darken(sample_t input) {
    // Darken the image by 10% by multiplying
    // the red, green and blue values with 0.9
    float red = input.r * 0.9;
    float green = input.g * 0.9;
    float blue = input.b * 0.9;
    float alpha = input.a;

    // Return a new float4
    return float4(red, green, blue, alpha);
}
```

In this task, alongside samples from the background and foreground images, we receive a sample from the depth map. Depth maps are greyscale images which means that for any particular pixel, the red, green and blue channels all have the same value. In depth maps, a black pixel (r, g, b values of 0) represents something that is very close to the camera, while a white pixel (r, g, b values of 1) is as far in the background as possible.

Using this information, our image kernel can return color values that are calculated from both the color value and the depth of each pixel. For example, to split an image into blue colors for "close" pixels and red colors for "far away" pixels, we could do the following:

```c++
float4 redAndBlue(sample_t input, sample_t depthMap) {
    float depthValue = depthMap.r; // r, g, b has the same value
    if (depthValue < 0.5) {
        // The pixel is 'close', return blue
        return float4(0.0, 0.0, 1.0, 1.0);
    } else {
        // The pixel is 'far away', return red
        return float4(1.0, 0.0, 0.0, 1.0);
    }
}
```

Take your new knowledge about Metal Shading Language and depth maps with you to `Task5.swift` and follow the instructions to play around with your own image kernels.

# References

- [Core Image](https://developer.apple.com/documentation/coreimage) by Apple
- [CIFilter.io](https://cifilter.io) by [Noah Gilmore](https://twitter.com/noahsark769)
- [Processing an Image Using Built-in Filters](https://developer.apple.com/documentation/coreimage/processing_an_image_using_built-in_filters) by Apple.
- [Core Image Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html#//apple_ref/doc/uid/TP30001185) by Apple.
- [How to set up an Xcode project for Core Image Metal kernels](https://developer.apple.com/documentation/coreimage/cikernel/2880194-init) by Apple.
- [Metal Shading Language for Core Image Kernels](https://developer.apple.com/metal/MetalCIKLReference6.pdf) by Apple.
- [Metal Shading Language Specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf) by Apple.
- [Writing Custom Kernels](https://developer.apple.com/documentation/coreimage/writing_custom_kernels) by Apple.
- [Kabell & Munk](https://kabellmunk.dk)
