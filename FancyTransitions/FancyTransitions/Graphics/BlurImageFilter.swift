//
//  BlurImageFilter.swift
//  FancyTransitions
//
//  Created by Leonardo  on 3/05/23.
//

import CoreImage
import class UIKit.UIImageView
import class UIKit.UIImage
import class UIKit.UIScreen

protocol ImageFilter {
    associatedtype T: AnyObject

    static var shared: T { get }
    var filter: CIFilter? { get }

    @discardableResult
    func apply(with image: inout UIImage?,
               inputCIImage: CIImage,
               additionalValues: [FilterValues],
               updateImage: Bool) -> CIImage?
}

extension ImageFilter {
    func addParams(params: [FilterValues]) {
        for param in params {
            filter?.setValue(param.ciValue.value, forKey: param.ciValue.key)
        }
    }
}

enum FilterValues {
    case radius(_ value: CGFloat)

    typealias CIKeyValue = (key: String, value: Any)
    var ciValue: CIKeyValue {
        switch self {
            case .radius(let value):
                return (key: kCIInputRadiusKey, value: value)
        }
    }
}

final class BlurImageFilter: ImageFilter {
    // MARK: State
    private let ciContext = MetalWrapper.shared.ciContext
    let filter = CIFilter(name: FilterName.cIGaussianBlur.value)
    let clampFilter = ClampImageFilter.shared

    static let shared = BlurImageFilter()

    // MARK: Initializers
    private init() {}

    // MARK: Methods
    func apply(with image: inout UIImage?, inputCIImage: CIImage, additionalValues: [FilterValues], updateImage: Bool) -> CIImage? {
        let clampCIImage = clampFilter.apply(with: &image,
                                             inputCIImage: inputCIImage,
                                             additionalValues: [],
                                             updateImage: false)

        filter?.setValue(clampCIImage, forKey: kCIInputImageKey)

        addParams(params: additionalValues)

        // Update image.
        guard let outputCIImage = filter?.value(forKey: kCIOutputImageKey) as? CIImage,
              let outputCGImage = ciContext.createCGImage(outputCIImage,
                                                          from: inputCIImage.extent) else { return nil }

        if updateImage {
            let scale = image?.scale ?? 1.0
            image = UIImage(cgImage: outputCGImage, scale: scale, orientation: .up)
        }

        return outputCIImage
    }
}

extension UIImageView {
    /// Applies a specified filter to a UIImageView's image with certain parameters if needed.
    /// - Parameter key: A KeyPath which subscribes to the FilterSource.
    /// - Parameter params: Optional additional params for the filter.
    ///
    /// - Warning: This **must** be run **after** the **UIImageView's image** has been set
    /// or there will be no effect whatsoever.
    func applyFilter(_ key: KeyPath<FilterSource, Filter>, params additionalValues: [FilterValues] = []) {
        // Map and get the desired filter
        let filter = FilterSource.shared[key].filter

        // Apply the filter using params.
        Task(priority: .userInitiated) {
            guard let cgImage = image?.cgImage else { return }

            let ciImage = CIImage(cgImage: cgImage)
            filter.apply(with: &image,
                         inputCIImage: ciImage,
                         additionalValues: additionalValues,
                         updateImage: true)
        }
    }
}
