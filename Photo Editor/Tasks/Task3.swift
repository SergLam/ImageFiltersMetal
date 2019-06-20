import CoreImage

let task3: Effect = { originalImage, depthMap in
    // We utilize the outputs from tasks 1 and 2 as foreground and background.
    let foreground = task1(originalImage, depthMap)
    let background = task2(originalImage, depthMap)

    /*
     1. Look at the filter category "CICategoryCompositeOperation" on https://CIFilter.io.
        and try out different filters.
     2. Input the foreground and background using the keys "inputImage" and "inputBackgroundImage".
        Use the `setValue` method on `filter`.
     */

//    let filter = CIFilter(name: <#filtername#>)
//    <#code for step 2#>
//    return filter?.outputImage

    return originalImage // Remove this line
}
