//
//  RangeSlider.swift
//  CustomSliderExample
//
//  Created by William Archimede on 04/09/2014.
//  Copyright (c) 2014 HoodBrains. All rights reserved.
//

import UIKit
import QuartzCore

class RangeSliderTrackLayer: CALayer {
    weak var rangeSlider: RangeSlider?

    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else { return }

        // Clip
        let cornerRadius = bounds.height * slider.curvaceousness / 2.0
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        ctx.addPath(path.cgPath)

        // Fill the track
        ctx.setFillColor(slider.trackTintColor.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        // Fill the highlighted range
        ctx.setFillColor(slider.trackHighlightTintColor.cgColor)
        let lowerValuePosition = CGFloat(slider.lowerThumbCenterX)
        let upperValuePosition = CGFloat(slider.upperThumbCenterX)
        let rect = CGRect(x: lowerValuePosition, y: 0.0, width: upperValuePosition - lowerValuePosition, height: bounds.height)
        ctx.fill(rect)
    }
}

class RangeSliderThumbLayer: CALayer {

    var highlighted: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    weak var rangeSlider: RangeSlider?

    var strokeColor: UIColor = UIColor.gray {
        didSet {
            setNeedsDisplay()
        }
    }
    var lineWidth: CGFloat = 0.5 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(in ctx: CGContext) {
        guard let slider = rangeSlider else { return }

        let thumbFrame = bounds.insetBy(dx: 2.0, dy: 2.0)
        let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
        let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)

        // Fill
        ctx.setFillColor(slider.thumbTintColor.cgColor)
        ctx.addPath(thumbPath.cgPath)
        ctx.fillPath()

        // Outline
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.addPath(thumbPath.cgPath)
        ctx.strokePath()

        if highlighted && slider.highlightThumbs {
            ctx.setFillColor(UIColor(white: 0.0, alpha: 0.1).cgColor)
            ctx.addPath(thumbPath.cgPath)
            ctx.fillPath()
        }
    }
}

@IBDesignable
public class RangeSlider: UIControl {

    /// RangeSlider's minimum possible value.
    /// Default value: 0.0.
    @IBInspectable public var minimumValue: Double = 0.0 {
//        willSet(newValue) {
//            assert(newValue < maximumValue, "RangeSlider: minimumValue should be lower than maximumValue")
//        }
        didSet {
            updateLayerFrames()
        }
    }

    /// RangeSlider's maximum possible value.
    /// Default value: 1.0.
    @IBInspectable public var maximumValue: Double = 1.0 {
//        willSet(newValue) {
//            assert(newValue > minimumValue, "RangeSlider: maximumValue should be greater than minimumValue")
//        }
        didSet {
            updateLayerFrames()
        }
    }

    /// RangeSlider's current lower value.
    /// Default value: 0.0.
    @IBInspectable public var lowerValue: Double = 0.0 {
        didSet {
            if lowerValue < minimumValue {
                lowerValue = minimumValue
            }

            lowerThumbCenterX = positionForValue(lowerValue)
            updateLayerFrames()
        }
    }

    /// RangeSlider's current maximum value.
    /// Default value: 1.0.
    @IBInspectable public var upperValue: Double = 1.0 {
        didSet {
            if upperValue > maximumValue {
                upperValue = maximumValue
            }

            upperThumbCenterX = positionForValue(upperValue)
            updateLayerFrames()
        }
    }

    @IBInspectable public var interval: Double = 1.0 {
        didSet {
            updateLayerFrames()
        }
    }

    // Minimum space (value) between thumbs
    @IBInspectable public var minSpaceBetween: Double = 1.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    /// RangeSlider's track color when value are not in range.
    /// Default value: UIColor(white: 0.9, alpha: 1.0).
    @IBInspectable public var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }

    /// RangeSlider's track color when value are in range.
    /// /// Default value: UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0).
    @IBInspectable public var trackHighlightTintColor: UIColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }

    @IBInspectable public var trackHeight: CGFloat = 2.0

    /// RangleSlider's thumb "button" color.
    /// Default value: .white.
    @IBInspectable public var thumbTintColor: UIColor = .white {
        didSet {
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }

    /// RangleSlider's thumb "button" boder color.
    /// Default value: .gray.
    @IBInspectable public var thumbBorderColor: UIColor = .gray {
        didSet {
            lowerThumbLayer.strokeColor = thumbBorderColor
            upperThumbLayer.strokeColor = thumbBorderColor
        }
    }

    /// RangeSlider's thumb "button" border width.
    /// Default value: 0.5
    @IBInspectable public var thumbBorderWidth: CGFloat = 0.5 {
        didSet {
            lowerThumbLayer.lineWidth = thumbBorderWidth
            upperThumbLayer.lineWidth = thumbBorderWidth
        }
    }

    @IBInspectable public var thumbHeight: CGFloat = 5.0

    // Should highlight thumbs during drag?
    @IBInspectable public var highlightThumbs: Bool = false {
        didSet {
            updateLayerFrames()
        }
    }
    
    /// Thumb's "button" curvaceousness.
    /// Should be between 0.0 and 1.0.
    /// Default value: 1.0
    @IBInspectable public var curvaceousness: CGFloat = 1.0 {
        didSet {
            // Force curvaceousness to be between 0 and 1
            curvaceousness = max(0.0, min(1.0, curvaceousness))

            trackLayer.setNeedsDisplay()
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }

    fileprivate var lowerThumbCenterX: CGFloat = 0.0

    fileprivate var upperThumbCenterX: CGFloat = 0.0

    fileprivate var range: Double {
        return maximumValue - minimumValue
    }


    fileprivate var step: Double {
        return (Double(bounds.width) * interval) / range
    }

    fileprivate var previousX: CGFloat = 0.0
    fileprivate var initialX: CGFloat = 0.0
    fileprivate var currentDistance: CGFloat = 0.0
    fileprivate var previouslocation = CGPoint()

    fileprivate let trackLayer = RangeSliderTrackLayer()
    fileprivate let lowerThumbLayer = RangeSliderThumbLayer()
    fileprivate let upperThumbLayer = RangeSliderThumbLayer()

    fileprivate var thumbWidth: CGFloat {
        return CGFloat(bounds.height)
    }

    fileprivate var thumbOffset: CGFloat {
        return thumbWidth / 2.0
    }

    override public var frame: CGRect {
        didSet {
            lowerThumbCenterX = CGFloat(positionForValue(lowerValue))
            upperThumbCenterX = CGFloat(positionForValue(upperValue))
            updateLayerFrames()
            setNeedsDisplay()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initializeLayers()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeLayers()
    }

    override public func layoutSublayers(of: CALayer) {
        super.layoutSublayers(of: layer)
        updateLayerFrames()
    }

    public override func setNeedsDisplay() {
        super.setNeedsDisplay()
        lowerThumbCenterX = CGFloat(positionForValue(lowerValue))
        upperThumbCenterX = CGFloat(positionForValue(upperValue))
        updateLayerFrames()
    }

    fileprivate func initializeLayers() {
        layer.backgroundColor = UIColor.clear.cgColor

        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)

        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(lowerThumbLayer)

        upperThumbLayer.rangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(upperThumbLayer)
    }

    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        trackLayer.frame =  CGRect(x: thumbOffset, y: (bounds.size.height - trackHeight) / 2.0, width: (bounds.size.width - thumbWidth), height: trackHeight)
        trackLayer.setNeedsDisplay()

        lowerThumbLayer.frame = CGRect(x: lowerThumbCenterX, y: 0.0, width: thumbWidth, height: thumbWidth)
        lowerThumbLayer.setNeedsDisplay()

        upperThumbLayer.frame = CGRect(x: upperThumbCenterX, y: 0.0, width: thumbWidth, height: thumbWidth)
        upperThumbLayer.setNeedsDisplay()

        CATransaction.commit()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        lowerThumbCenterX = CGFloat(positionForValue(lowerValue))
        upperThumbCenterX = CGFloat(positionForValue(upperValue))
        updateLayerFrames()
    }

    // MARK: - Utils
    func positionForValue(_ value: Double) -> CGFloat {
        return trackLayer.frame.size.width * CGFloat(value / range)
    }

    func valueForPosition(_ position: CGFloat) -> Double {
        return round(Double(position) / step) * interval
    }

    func boundValue<T: Comparable>(_ value: T, lowerValue: T, upperValue: T) -> T {
        return min(max(value, lowerValue), upperValue)
    }

    // MARK: - Touches

    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let currentLocation = touch.location(in: self)


        // Hit test the thumb layers
        if upperThumbLayer.frame.contains(currentLocation) {
            upperThumbLayer.highlighted = true
            initialX = upperThumbCenterX + thumbWidth
        } else if lowerThumbLayer.frame.contains(currentLocation) {
            lowerThumbLayer.highlighted = true
            initialX = lowerThumbCenterX
        }

        previousX = currentLocation.x
        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
    }

    override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)

        // Determine by how much the user has dragged

        if lowerThumbLayer.highlighted {
            lowerValue = boundValue(valueForPosition(initialX), lowerValue: minimumValue, upperValue: upperValue - minSpaceBetween)
        } else if upperThumbLayer.highlighted {
            upperValue = boundValue(valueForPosition(initialX), lowerValue: lowerValue + minSpaceBetween, upperValue: maximumValue)
        }

        let deltaLocation = location.x - previousX

        initialX += deltaLocation

        previousX = location.x

        sendActions(for: .valueChanged)

        return true
    }

    override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        lowerThumbLayer.highlighted = false
        upperThumbLayer.highlighted = false
        currentDistance = 0.0
        
        sendActions(for: .editingDidEnd)
    }
}
