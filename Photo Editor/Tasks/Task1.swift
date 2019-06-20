import CoreImage

let task1: Effect = { originalImage, depthMap in
    /*
     1. Go to https://cifilter.io and find a filter that you would like
     to apply to the image. Choose from the "CICategoryColorEffect" category.
     2. Replace "CIPhotoEffectNoir" in CIFilter(name:) with your chosen filter name.
     */
    
    let filter = CIFilter(name: "CIPhotoEffectNoir")
    filter?.setValue(originalImage, forKey: "inputImage")
    return filter?.outputImage
}
