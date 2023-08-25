//
//  MetalWrapper.swift
//  FancyTransitions
//
//  Created by Leonardo  on 30/04/23.
//

import MetalKit

enum MetalFilterKey {
    static let drawWithInvertedColor = "drawWithInvertedColor"
}

enum FilterName: String {
    case cIGaussianBlur = "CIGaussianBlur"
    case scaleTransform = "CILanczosScaleTransform"
    case clamp = "CIAffineClamp"
    
    var value: String { self.rawValue }
}

typealias Filter = (name: FilterName, filter: any ImageFilter)
final class FilterSource {
    
    // "CIGaussianBlur"
    private(set) lazy var cIGaussianBlur: Filter = (name: .cIGaussianBlur, BlurImageFilter.shared)
    
    subscript(value: KeyPath<FilterSource, Filter>) -> Filter {
        get { return self[keyPath: value] }
    }
    
    static let shared = FilterSource()
    
    private init() {}
}

/*
 MTLCommandBuffers: Storage objs. for commands.
 Adding commands buffers doesn't execute them yet.
 
 Command (Shaders, aka MSL kernel code)Types:
 - Render (MTLRenderCommandEncoder): Triangles, lines, points, etc. (Mostly used in video games)
 - Blit (MTLBitCommmandEncoder): For coping, from texture to another.
 - Compute (MTLComputeCommandEncoder): General puropse stuff. (GeneralPurpose GPU)
 
 To fill commands an encoder is needed. Give the encoders stuff and tell them to "bake-sth-out-of-them".
 Key pieces of commands:
 - PipeLineState (The GPU state that is need to be set for the current command)
 Usually being created ONCE in the app's life-cycle. Cache and reuse.
 
 waitUntilCompleted is a BAD practice. Instead, add a completion handler (addComponetionHandler)
 
 Example:
 1. Declare class named after the filter/shader, a GP GPU task.
 2. Inject MTLContext/MTLLibrary in the class (Allows re-using and caching).
  */
class MetalWrapper: NSObject {
    // MARK: State
    // Singleton
    static let shared = MetalWrapper()
    
    /// The device's GPU interface
    let device: MTLDevice
    /// CoreImage context.
    let ciContext: CIContext
    
    /// # Filters
    private lazy var invertFilter = InvertColorsFilter(device: device)
    
    // MARK: Initializers
    override private init() {
        device = MTLCreateSystemDefaultDevice()!
        ciContext = CIContext(mtlDevice: device)
    }
    
    // MARK: - Methods
    typealias FilterResult = ((_ result: Result<UIImage, Error>) -> Void)
    func invertColors(of image: UIImage, result: @escaping FilterResult) {
        invertFilter?.imageInvertColors(of: image, completion: result)
    }
}

// MARK: - Extensions
protocol MetallicBuildableOwo: AnyObject {
    var libraryOwO: MTLLibrary { get }
    var commandQueue: MTLCommandQueue { get }
    
//    init(library: MTLLibrary, commandQueue: MTLCommandQueue)
}

extension MetallicBuildableOwo {
    private static var metalsito: MetalWrapper { MetalWrapper.shared }
    static var device: MTLDevice { metalsito.device }
    static var ciContext: CIContext { metalsito.ciContext }
}

// MARK: Initializer - MetallicBuildable
extension MetallicBuildableOwo {
    static func makeLibrary(device: MTLDevice) throws -> MTLLibrary {
        let bundle = Bundle(for: Self.self)
        do {
            return try device.makeDefaultLibrary(bundle: bundle)
        } catch { throw error }
    }
    
    static func makePipeline(device: MTLDevice, library: MTLLibrary) throws -> MTLComputePipelineState {
        /// # Reading shaders (This is currenlty done Sync. so it should probably run once only in the app's life-time.
        let function = library.makeFunction(name: MetalFilterKey.drawWithInvertedColor)!
        do {
            // Create a new pipeline from a .metal function (shader) (1-1 relation)
            return try device.makeComputePipelineState(function: function)
        } catch { throw error }
    }
    
    static func makeCommandQueue(device: MTLDevice) -> MTLCommandQueue {
        return device.makeCommandQueue()!
    }

//    init() {
//        // Get the bundle of the current class.
//        let library = try! Self.makeLibrary(device: Self.device)
//        let commandQueue = Self.makeCommandQueue(device: Self.device)
//            
//        self.init(library: library, commandQueue: commandQueue)
//    }
}
