import UIKit

public class TimelineView: UIView {
    public enum Decoration {
        case dot, squiggle
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
    }

    public var decoration: Decoration = .dot {
        didSet {
            guard oldValue != decoration else {
                return
            }

            switch decoration {
            case .squiggle:
                innerDotShapeLayer.removeFromSuperlayer()
                outerDotShapeLayer.removeFromSuperlayer()
                layer.addSublayer(squiggleShapeLayer)
                updateSquiggleCenterPoint()
            case .dot:
                squiggleShapeLayer.removeFromSuperlayer()
                layer.addSublayer(innerDotShapeLayer)
                layer.addSublayer(outerDotShapeLayer)
            }

            setNeedsDisplay()
        }
    }
    public var shouldAnimateDots: Bool = false
    public var minimizeUnanimatedDots: Bool = false
    public var timelineColor: UIColor? = nil {
        didSet {
            refreshColors()
        }
    }
    private var color: CGColor {
        return timelineColor?.cgColor ?? tintColor.cgColor
    }

    public var verticalLineWidth: CGFloat = 1.0 {
        didSet {
            squiggleShapeLayer.lineWidth = verticalLineWidth
            setNeedsDisplay()
        }
    }
    
    public var pauseDotsAnimation: Bool = true {
        didSet {
            displayLink?.isPaused = pauseDotsAnimation
        }
    }

    private let dotRadius:CGFloat = 9.0
    private let dotMinRadiusNormal:CGFloat = 0.4

    // At a height of less than 30, (due to rounding) the squiggle's curves don't perfectly align with the straight lines.
    private let squiggleHeight: CGFloat = 30.0
    
    public var dotsY: CGFloat = 0 {
        didSet {
            guard shouldAnimateDots == false || decoration == .squiggle else {
                return
            }

            switch decoration {
            case .dot: updateDotsRadii(to: minimizeUnanimatedDots ? 0.0 : 1.0, at: CGPoint(x: bounds.midX, y: dotsY))
            case .squiggle: updateSquiggleCenterPoint()
            }
            setNeedsDisplay()
        }
    }
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        refreshColors()
    }
    
    override public var backgroundColor: UIColor? {
        didSet {
            outerDotShapeLayer.fillColor = backgroundColor?.cgColor
            squiggleShapeLayer.fillColor = backgroundColor?.cgColor
        }
    }

    private lazy var outerDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = backgroundColor?.cgColor ?? UIColor.white.cgColor
        shape.strokeColor = color
        shape.lineWidth = 1.0
        if decoration == .dot {
            self.layer.addSublayer(shape)
        }
        return shape
    }()

    private lazy var innerDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = color
        shape.strokeColor = color
        shape.lineWidth = 1.0
        if decoration == .dot {
            self.layer.addSublayer(shape)
        }
        return shape
    }()

    private lazy var squiggleShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.updateSquiggleLocation(height: squiggleHeight, decorationMidY: dotsY, midX: bounds.midX)
        shape.strokeColor = color
        shape.fillColor = backgroundColor?.cgColor ?? UIColor.white.cgColor
        shape.lineWidth = verticalLineWidth
        if decoration == .squiggle {
            self.layer.addSublayer(shape)
        }
        return shape
    }()

//    private var newSquiggleShapeLayer: CAShapeLayer {
//        let shape = CAShapeLayer()
//        let squiggle = UIBezierPath()
//
//        if false {
//            let startY = dotsY - squiggleHeight/2 // squiggle's middle (not top) should be startY
//            let top = CGPoint(x: bounds.midX, y: startY)
//            let midPoint = CGPoint(x: bounds.midX, y: startY + (squiggleHeight*3/6))
//            let bottom = CGPoint(x: bounds.midX, y: startY + squiggleHeight)
//
//            let middleLeading1 = CGPoint(x: 0, y: startY + (squiggleHeight*1/6))
//            let middleTrailing1 = CGPoint(x: bounds.maxX, y: startY + (squiggleHeight*2/6))
//            let middleLeading2 = CGPoint(x: 0, y: startY + (squiggleHeight*4/6))
//            let middleTrailing2 = CGPoint(x: bounds.maxX, y: startY + (squiggleHeight*5/6))
//
//            squiggle.move(to: top)
//            squiggle.addCurve(to: midPoint, controlPoint1: middleLeading1, controlPoint2: middleTrailing1)
//            squiggle.addCurve(to: bottom, controlPoint1: middleLeading2, controlPoint2: middleTrailing2)
//        } else if false {
//            let startY = dotsY - squiggleHeight/2 // squiggle's middle (not top) should be startY
//            let top = CGPoint(x: bounds.midX, y: startY)
//            let midPoint = CGPoint(x: bounds.midX, y: startY + (squiggleHeight*3/6))
//            let bottom = CGPoint(x: bounds.midX, y: startY + squiggleHeight)
//
//            let quarterOnePoint = CGPoint(x: bounds.midX, y: startY + (squiggleHeight*1/4))
//            let quarterThreePoint = CGPoint(x: bounds.midX, y: startY + (squiggleHeight*3/4))
//            let controlPoint1 = CGPoint(x: 0, y: midPoint.y)
//            let controlPoint2 = CGPoint(x: bounds.maxX, y: top.y)
//            let controlPoint3 = CGPoint(x: 0, y: bottom.y)
//            let controlPoint4 = CGPoint(x: bounds.maxX, y: midPoint.y)
//
//            squiggle.move(to: top)
//            squiggle.addQuadCurve(to: quarterOnePoint, controlPoint: controlPoint1)
//            squiggle.addQuadCurve(to: midPoint, controlPoint: controlPoint2)
//            squiggle.addQuadCurve(to: quarterThreePoint, controlPoint: controlPoint3)
//            squiggle.addQuadCurve(to: bottom, controlPoint: controlPoint4)
//        } else {
//            shape.updateSquiggleLocation(height: squiggleHeight, decorationMidY: dotsY, midX: bounds.midX)
//            shape.strokeColor = color
//            shape.fillColor = backgroundColor?.cgColor ?? UIColor.white.cgColor
//            shape.lineWidth = verticalLineWidth
//            self.layer.addSublayer(shape)
//            return shape
//        }
//    }

    private lazy var displayLink: CADisplayLink? = {
        guard decoration == .dot, shouldAnimateDots == true else {
            return nil
        }
        let link = CADisplayLink(target: self, selector: #selector(maybeUpdateDotsRadii))
        link.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        return link
    }()
    
    override public func removeFromSuperview() {
        displayLink?.invalidate()
        displayLink = nil
        super.removeFromSuperview()
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        drawVerticalLine(in: context, rect: rect)
    }
    
    public var extendTimelineAboveDot: Bool = true {
        didSet {
            if oldValue != extendTimelineAboveDot {
                setNeedsDisplay()
            }
        }
    }
    
    private func drawVerticalLine(in context: CGContext, rect: CGRect){
        context.setLineWidth(verticalLineWidth)
        context.setStrokeColor(color)
        let lineTopY = extendTimelineAboveDot ? rect.minY : dotsY

        switch decoration {
        case .dot:
            context.move(to: CGPoint(x: rect.midX, y: lineTopY))
            context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        case .squiggle:
            if extendTimelineAboveDot {
                context.move(to: CGPoint(x: rect.midX, y: lineTopY))
                context.addLine(to: CGPoint(x: rect.midX, y: dotsY-squiggleHeight/2))
            }
            context.move(to: CGPoint(x: rect.midX, y: dotsY+squiggleHeight/2))
            context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }

        context.strokePath()
    }

    private func refreshColors() {
        outerDotShapeLayer.strokeColor = color
        innerDotShapeLayer.fillColor = color
        innerDotShapeLayer.strokeColor = color
        squiggleShapeLayer.strokeColor = color
        setNeedsDisplay()
    }
    
    // Returns CGFloat in range from 0.0 to 1.0. 0.0 indicates dot should be minimized.
    // 1.0 indicates dot should be maximized. Approaches 1.0 as timelineView.dotY
    // approaches vertical center. Approaches 0.0 as timelineView.dotY approaches top
    // or bottom.
    private func dotRadiusNormal(with y:CGFloat, in container:UIView) -> CGFloat {
        let yInContainer = convert(CGPoint(x:0, y:y), to: container).y
        let halfContainerHeight = container.bounds.size.height * 0.5
        return max(0.0, 1.0 - (abs(yInContainer - halfContainerHeight) / halfContainerHeight))
    }

    private var lastDotRadiusNormal: CGFloat = -1.0 // -1.0 so dots with dotAnimationNormal of "0.0" are visible initially
    
    @objc private func maybeUpdateDotsRadii() {
        guard let containerView = window else {
            return
        }

        // Shift the "full-width dot" point up a bit - otherwise it's in the vertical center of screen.
        let yOffset = containerView.bounds.size.height * 0.15

        var radiusNormal = dotRadiusNormal(with: dotsY + yOffset, in: containerView)

        // Reminder: can reduce precision to 1 (significant digit) to reduce how often dot radii are updated.
        let precision: CGFloat = 2
        let roundingNumber = pow(10, precision)
        radiusNormal = (radiusNormal * roundingNumber).rounded(.up) / roundingNumber
        
        guard radiusNormal != lastDotRadiusNormal else {
            return
        }
        
        updateDotsRadii(to: radiusNormal, at: CGPoint(x: bounds.midX, y: dotsY))
        
        // Progressively fade the inner dot when it gets tiny.
        innerDotShapeLayer.opacity = easeInOutQuart(number: Float(radiusNormal))
        
        lastDotRadiusNormal = radiusNormal
    }
    
    private func updateDotsRadii(to radiusNormal: CGFloat, at center: CGPoint){
        outerDotShapeLayer.updateDotRadius(dotRadius * max(radiusNormal, dotMinRadiusNormal), center: center)
        innerDotShapeLayer.updateDotRadius(dotRadius * max((radiusNormal - dotMinRadiusNormal), 0.0), center: center)
    }

    private func updateSquiggleCenterPoint() {
        squiggleShapeLayer.updateSquiggleLocation(height: squiggleHeight, decorationMidY: dotsY, midX: bounds.midX)
    }
    
    private func easeInOutQuart(number:Float) -> Float {
        return number < 0.5 ? 8.0 * pow(number, 4) : 1.0 - 8.0 * (number - 1.0) * pow(number, 3)
    }
}

extension CAShapeLayer {
    fileprivate func updateDotRadius(_ radius: CGFloat, center: CGPoint) {
        path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0.0, endAngle:CGFloat.pi * 2.0, clockwise: true).cgPath
    }

    fileprivate func updateSquiggleLocation(height: CGFloat, decorationMidY: CGFloat, midX: CGFloat) {
        let startY = decorationMidY - height/2 // squiggle's middle (not top) should be startY
        let topPoint = CGPoint(x: midX, y: startY)
        let quarterOnePoint = CGPoint(x: midX, y: startY + (height*1/4))
        let midPoint = CGPoint(x: midX, y: startY + (height*2/4))
        let quarterThreePoint = CGPoint(x: midX, y: startY + (height*3/4))
        let bottomPoint = CGPoint(x: midX, y: startY + height)

        /// Math for curves shown/explained on Phab ticket: https://phabricator.wikimedia.org/T258209#6363389
        let eighthOfHeight = height/8
        let circleDiameter = sqrt(2*(eighthOfHeight*eighthOfHeight))
        let radius = circleDiameter/2

        /// Without this adjustment, the `arcCenter`s are not the true center of circle and the squiggle has some jagged edges.
        let centerAdjustedRadius = radius - 1

        let arc1Start = CGPoint(x: midX - radius*3, y: topPoint.y + radius*3)
        let arc1Center = CGPoint(x: arc1Start.x + centerAdjustedRadius, y: arc1Start.y + centerAdjustedRadius)

        let arc2Start = CGPoint(x: midX + radius*1, y: quarterOnePoint.y - radius*1)
        let arc2Center = CGPoint(x: arc2Start.x + centerAdjustedRadius, y: arc2Start.y + centerAdjustedRadius)

        let arc3Start = CGPoint(x: midX - radius*3, y: midPoint.y + radius*3)
        let arc3Center = CGPoint(x: arc3Start.x + centerAdjustedRadius, y: arc3Start.y + centerAdjustedRadius)

        let arc4Start = CGPoint(x: midX + radius*1, y: quarterThreePoint.y - radius*1)
        let arc4Center = CGPoint(x: arc4Start.x + centerAdjustedRadius, y: arc4Start.y + centerAdjustedRadius)

        let squiggle = UIBezierPath()
        let fullCircle = 2 * CGFloat.pi // addArc's angles are in radians, let's make it easier
        squiggle.move(to: topPoint)
        squiggle.addLine(to: arc1Start)
        squiggle.addArc(withCenter: arc1Center, radius: radius, startAngle: fullCircle * 5/8, endAngle: fullCircle * 1/8, clockwise: false)
        squiggle.addLine(to: arc2Start)
        squiggle.addArc(withCenter: arc2Center, radius: radius, startAngle: fullCircle * 5/8, endAngle: fullCircle * 1/8, clockwise: true)
        squiggle.addLine(to: arc3Start)
        squiggle.addArc(withCenter: arc3Center, radius: radius, startAngle: fullCircle * 5/8, endAngle: fullCircle * 1/8, clockwise: false)
        squiggle.addLine(to: arc4Start)
        squiggle.addArc(withCenter: arc4Center, radius: radius, startAngle: fullCircle * 5/8, endAngle: fullCircle * 1/8, clockwise: true)
        squiggle.addLine(to: bottomPoint)

        path = squiggle.cgPath
    }
}
