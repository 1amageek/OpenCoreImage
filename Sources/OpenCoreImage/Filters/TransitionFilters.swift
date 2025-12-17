//
//  TransitionFilters.swift
//  OpenCoreImage
//
//  Transition filter protocols for Core Image.
//

import Foundation

// MARK: - CITransitionFilter

/// The properties you use to configure a transition filter.
public protocol CITransitionFilter: CIFilterProtocol {
    /// The image to use as an input image.
    var inputImage: CIImage? { get set }
    /// The target image for a transition.
    var targetImage: CIImage? { get set }
    /// The parametric time of the transition.
    var time: Float { get set }
}

// MARK: - CIAccordionFoldTransition

/// The properties you use to configure an accordion fold transition filter.
public protocol CIAccordionFoldTransition: CITransitionFilter {
    /// The height of the bottom fold.
    var bottomHeight: Float { get set }
    /// The number of folds.
    var numberOfFolds: Float { get set }
    /// The amount of shadow on the folds.
    var foldShadowAmount: Float { get set }
}

// MARK: - CIBarsSwipeTransition

/// The properties you use to configure a bars swipe transition filter.
public protocol CIBarsSwipeTransition: CITransitionFilter {
    /// The angle of the bars.
    var angle: Float { get set }
    /// The width of the bars.
    var width: Float { get set }
    /// The offset of the bars.
    var barOffset: Float { get set }
}

// MARK: - CICopyMachineTransition

/// The properties you use to configure a copy machine transition filter.
public protocol CICopyMachineTransition: CITransitionFilter {
    /// The extent of the effect.
    var extent: CGRect { get set }
    /// The color of the light.
    var color: CIColor { get set }
    /// The angle of the effect.
    var angle: Float { get set }
    /// The width of the light.
    var width: Float { get set }
    /// The opacity of the effect.
    var opacity: Float { get set }
}

// MARK: - CIDisintegrateWithMaskTransition

/// The properties you use to configure a disintegrate-with-mask transition filter.
public protocol CIDisintegrateWithMaskTransition: CITransitionFilter {
    /// The mask image.
    var maskImage: CIImage? { get set }
    /// The radius of the shadow.
    var shadowRadius: Float { get set }
    /// The density of the shadow.
    var shadowDensity: Float { get set }
    /// The offset of the shadow.
    var shadowOffset: CGPoint { get set }
}

// MARK: - CIDissolveTransition

/// The properties you use to configure a dissolve transition filter.
public protocol CIDissolveTransition: CITransitionFilter {
}

// MARK: - CIFlashTransition

/// The properties you use to configure a flash transition filter.
public protocol CIFlashTransition: CITransitionFilter {
    /// The center of the flash.
    var center: CGPoint { get set }
    /// The extent of the effect.
    var extent: CGRect { get set }
    /// The color of the flash.
    var color: CIColor { get set }
    /// The maximum striation radius.
    var maxStriationRadius: Float { get set }
    /// The strength of the striations.
    var striationStrength: Float { get set }
    /// The contrast of the striations.
    var striationContrast: Float { get set }
    /// The fade threshold.
    var fadeThreshold: Float { get set }
}

// MARK: - CIModTransition

/// The properties you use to configure a mod transition filter.
public protocol CIModTransition: CITransitionFilter {
    /// The center of the effect.
    var center: CGPoint { get set }
    /// The angle of the effect.
    var angle: Float { get set }
    /// The radius of the holes.
    var radius: Float { get set }
    /// The compression of the holes.
    var compression: Float { get set }
}

// MARK: - CIPageCurlTransition

/// The properties you use to configure a page curl transition filter.
public protocol CIPageCurlTransition: CITransitionFilter {
    /// The backside image.
    var backsideImage: CIImage? { get set }
    /// The shading image.
    var shadingImage: CIImage? { get set }
    /// The extent of the effect.
    var extent: CGRect { get set }
    /// The angle of the curl.
    var angle: Float { get set }
    /// The radius of the curl.
    var radius: Float { get set }
}

// MARK: - CIPageCurlWithShadowTransition

/// The properties you use to configure a page-curl-with-shadow transition filter.
public protocol CIPageCurlWithShadowTransition: CITransitionFilter {
    /// The backside image.
    var backsideImage: CIImage? { get set }
    /// The extent of the effect.
    var extent: CGRect { get set }
    /// The angle of the curl.
    var angle: Float { get set }
    /// The radius of the curl.
    var radius: Float { get set }
    /// The size of the shadow.
    var shadowSize: Float { get set }
    /// The amount of shadow.
    var shadowAmount: Float { get set }
    /// The extent of the shadow.
    var shadowExtent: CGRect { get set }
}

// MARK: - CIRippleTransition

/// The properties you use to configure a ripple transition filter.
public protocol CIRippleTransition: CITransitionFilter {
    /// The shading image.
    var shadingImage: CIImage? { get set }
    /// The center of the ripple.
    var center: CGPoint { get set }
    /// The extent of the effect.
    var extent: CGRect { get set }
    /// The width of the ripples.
    var width: Float { get set }
    /// The scale of the ripples.
    var scale: Float { get set }
}

// MARK: - CISwipeTransition

/// The properties you use to configure a swipe transition filter.
public protocol CISwipeTransition: CITransitionFilter {
    /// The extent of the effect.
    var extent: CGRect { get set }
    /// The color of the swipe.
    var color: CIColor { get set }
    /// The angle of the swipe.
    var angle: Float { get set }
    /// The width of the swipe.
    var width: Float { get set }
    /// The opacity of the swipe.
    var opacity: Float { get set }
}
