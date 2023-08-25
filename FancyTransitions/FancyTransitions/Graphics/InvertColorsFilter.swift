//
//  InvertColorsFilter.swift
//  FancyTransitions
//
//  Created by Leonardo  on 1/05/23.
//

import MetalKit

// MARK: - Filters
final class InvertColorsFilter {
    // MARK: State
    private let device: MTLDevice // cached
    
    private let library: MTLLibrary
    private let pipeline: MTLComputePipelineState
    private let commandQueue: MTLCommandQueue
    
    // MARK: Initializers
    init?(device: MTLDevice) {
        self.device = device
        
        do {
            // Get the bundle of the current class.
            self.library = try Self.makeLibrary(device: device)
            self.pipeline = try Self.makePipeline(device: device, library: library)
            self.commandQueue = Self.makeCommandQueue(device: device)
            
        } catch { return nil }
    }
    
    private static func makeLibrary(device: MTLDevice) throws -> MTLLibrary {
        let bundle = Bundle(for: Self.self)
        do {
            return try device.makeDefaultLibrary(bundle: bundle)
        } catch { throw error }
    }
    
    private static func makePipeline(device: MTLDevice, library: MTLLibrary) throws -> MTLComputePipelineState {
        /// # Reading shaders (This is currenlty done Sync. so it should probably run once only in the app's life-time.
        let function = library.makeFunction(name: MetalFilterKey.drawWithInvertedColor)!
        do {
            // Create a new pipeline from a .metal function (shader) (1-1 relation)
            return try device.makeComputePipelineState(function: function)
        } catch { throw error }
    }
    
    private static func makeCommandQueue(device: MTLDevice) -> MTLCommandQueue {
        return device.makeCommandQueue()!
    }
}

// MARK: - Methods (Public)
extension InvertColorsFilter {
    func imageInvertColors(of image: UIImage, completion: @escaping (_ result: Result<UIImage, Error>) -> Void) {
        // Get the .metal function
        do {
            /// # Creating intput/output textures
            // Create textures from images.
            let textureLoader = MTKTextureLoader(device: device)
            
            // Input-Texture
            guard let cgImage = image.cgImage else { return }
            let inputTexture: MTLTexture = try textureLoader.newTexture(cgImage: cgImage)
            
            // Dimensions
            let (width, height) = (inputTexture.width, inputTexture.height)
            
            // Output-Texture: Plain writable texture of the same size as the input.
            // The MTLTextureDescriptor allows to create new plain-Texture objects that use RGBA components.
            // rgba8Uint -> 0-255 decimal of rgba
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false) // mipmapped true removes aliasing.
            // Allow write operations in the descriptor.
            textureDescriptor.usage = [.shaderRead, .shaderWrite]
            guard let outputTexture = device.makeTexture(descriptor: textureDescriptor) else { return }
            
            /// # Encoding in commandQueue
            /// The pipeline needs to be **encoded** into the into the **buffer** of a **commandQueue** so that *Metal* can send it to the *GPU* for execution.
            // 1. Create the command-queue.
            /// *Created at the initializer...*
            
            // 2. Create a command-buffer which will store commands for the SHADERS to be executed by the GPU.
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
            
            // 3. Encode & write the commands in the buffer.
            guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
            // 3.1 Set the function represented by the pipeline created as the compute-pipeline-state of the encoder.
            commandEncoder.setComputePipelineState(pipeline)
            // 3.2 Inform the data it needs to work with.
            // Declaring the inTexture and outTexture.
            commandEncoder.setTexture(inputTexture, index: 0)
            commandEncoder.setTexture(outputTexture, index: 1)
            
            // 3.3 Specifying the thread details for the compute command
            let threadsPerThreadGroup = MTLSize(width: 16, height: 16, depth: 1)
            // Size of the grid to be the same size of the original image.
            let threadGroupsPerGrid = MTLSize(width: width/16 + 1, height: height/16 + 1, depth: 1)
            commandEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
            // 3.4 Inform encoding is finished
            commandEncoder.endEncoding()
            
            // 4. Define the completion operations. Create a CIImage from the output-texure.
            let completion: MTLCommandBufferHandler = { _ in
                // The texture, thus the CIIMage is mirrored upside down after computed.
                // It's done in the CIIMage to keep the UIImage with the proper .imageOrientation property-value.
                guard let ciImage = CIImage(mtlTexture: outputTexture)?.oriented(.downMirrored) else { return }
                let invertedImage = UIImage(ciImage: ciImage)
                
                DispatchQueue.main.async {
                    completion(.success(invertedImage))
                }
            }
            // 4.1 Add completion handler (Async) or wait for completion (Sync. blocks thread).
            commandBuffer.addCompletedHandler(completion)
            
            // 5. Make the commandBuffer commit the commands for execution.
            commandBuffer.commit()

        } catch {
            print("error: \(error)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
}
