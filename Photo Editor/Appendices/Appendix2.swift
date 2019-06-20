import CoreImage

let appendix2: Effect = { originalImage, depthMap in
    /*
     This function is already setup to utilize the `appendix2` metal kernel.
     1. Go to the Kernels.metal file to complete the task.
     */

    // Load the Metal library
    let metalLibraryUrl = Bundle.main.url(forResource: "default", withExtension: "metallib")!
    let metalLibraryData = try! Data(contentsOf: metalLibraryUrl)
    // Find the kernel of interest.
    let filter = try? CIKernel(functionName: "appendix2", fromMetalLibraryData: metalLibraryData)
    // Use the kernel to process the images
    return filter?.apply(
        extent: originalImage.extent,
        roiCallback: { _,_ in originalImage.extent },
        arguments: [originalImage as Any, depthMap as Any]
    )
}
