import CoreImage

let task5: Effect = { originalImage, depthMap in
    /*
     This function is already setup to utilize the `task5` metal kernel.
     1. Go to the Kernels.metal file to complete the task.
     */

    // We utilize the outputs from tasks 1 and 2 as foreground and background.
    let foreground = task1(originalImage, depthMap)
    let background = task2(originalImage, depthMap)
    // Load the Metal library
    let metalLibraryUrl = Bundle.main.url(forResource: "default", withExtension: "metallib")!
    let metalLibraryData = try! Data(contentsOf: metalLibraryUrl)
    // Find the kernel of interest.
    let filter = try! CIColorKernel(functionName: "task5", fromMetalLibraryData: metalLibraryData)
    // Use the kernel to process the images
    return filter.apply(
        extent: originalImage.extent,
        arguments: [foreground as Any, background as Any, depthMap]
    )
}
