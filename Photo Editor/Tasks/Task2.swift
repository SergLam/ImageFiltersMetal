import CoreImage

let task2: Effect = { originalImage, depthMap in
    /*
     1. Go to https://cifilter.io and find a distortion or blur type
        filter that you would like to use for the background.
        Look in the "CICategoryStylize", "CICategoryDistortionEffect" or "CICategoryBlur" categories.
     2. Change an attribute on it
     3. Return a cropped version since some filters bleed outside the image frame (extent).
     */

//    let filter = CIFilter(name: <#filtername#>)
//    filter?.setValue(originalImage, forKey: "inputImage")
//    filter?.setValue(<#value#>, forKey: <#attributeKey#>)
//    return filter?.outputImage?.cropped(to: originalImage.extent)

    return originalImage // Remove this line
}
