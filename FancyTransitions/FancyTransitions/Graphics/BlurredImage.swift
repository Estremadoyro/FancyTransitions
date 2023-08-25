//
//  BlurImage.swift
//  FancyTransitions
//
//  Created by Leonardo  on 2/05/23.
//

import UIKit
import MetalKit
import Foundation

class XDController: NSObject, MetallicBuildableOwo {
    let libraryOwO: MTLLibrary
    let commandQueue: MTLCommandQueue

    init(library: MTLLibrary,
         commandQueue: MTLCommandQueue) {
        self.libraryOwO = library
        self.commandQueue = commandQueue
    }
}

final class BlurredImage: XDController {
    // MARK: State
    private let image: UIImage
    private let radius: CGFloat
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private let filter = CIFilter(name: FilterName.cIGaussianBlur.value)

    private var inputTexture: MTLTexture?
    private var mtkView: MTKView?
    private var needsRefresh: Bool = true

    // MARK: Initializers
    init(image: UIImage, radius: CGFloat) {
        self.image = image
        self.radius = radius

        super.init(library: try! Self.makeLibrary(device: Self.device),
                   commandQueue: Self.makeCommandQueue(device: Self.device))

        configure()
    }

    func getView() -> UIView {
        return mtkView ?? MTKView()
    }
}

extension BlurredImage: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    func draw(in view: MTKView) {
        guard needsRefresh else { return }
        guard let currentDrawable = view.currentDrawable else { return }
        guard let inputTexture else { return }

        // Create CI image with Metal.
        let inputImage = CIImage(mtlTexture: inputTexture)?.oriented(.down)
        // Resize image
        let scale = (UIScreen.main.bounds.size.area / self.image.size.area)
        let resizedImage = inputImage!.applyingFilter(
            FilterName.scaleTransform.value,
            parameters: [kCIInputScaleKey: scale,
                         kCIInputAspectRatioKey: 1,
                         kCIInputCenterKey: CIVector(x: UIScreen.main.bounds.width / 2,
                                                     y: UIScreen.main.bounds.height / 2)])

        // Apply blur
        let bluredImage = resizedImage
            .clampedToExtent()
            .applyingFilter(
                FilterName.cIGaussianBlur.value,
                parameters: [kCIInputRadiusKey: radius])
            .cropped(to: resizedImage.extent)

//        filter?.setValue(inputImage, forKey: kCIInputImageKey)
//        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        // Resize filter
//        filter?.setValue(scale, forKey: kCIInputScaleKey)

        // Render the CI output-image using Metal.
//        guard let outputImage = filter?.outputImage else { return }
        let outputImage = bluredImage
        guard let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer() else { return }
        let outputTexture: MTLTexture = currentDrawable.texture
        Self.ciContext.render(outputImage,
                              to: outputTexture,
                              commandBuffer: commandBuffer,
                              bounds: CGRect(x: 0, y: 0, width: 375, height: 800), // mtkView!.bounds,
                              colorSpace: colorSpace)

        // Present & run.
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
        needsRefresh = false
    }
}

private extension BlurredImage {
    func configure() {
        // MTKView
        mtkView = MTKView()
        mtkView?.delegate = self
        mtkView?.device = Self.device
        mtkView?.framebufferOnly = false

        // Texture
        let loader = MTKTextureLoader(device: Self.device)
        inputTexture = try? loader.newTexture(cgImage: image.cgImage!)
    }
}

// final class BluredView: MTKView {}
