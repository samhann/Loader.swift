//
//  FBLoader.swift
//  FBAnimatedView
//
//  Created by Samhan on 08/01/16.
//  Copyright © 2016 Samhan. All rights reserved.
//

import UIKit

@objc public protocol ListLoadable {
    var ld_visibleContentViews: [UIView] { get }
}

extension ListLoadable {
    func ld_visibleContentViews(for views: [UIView]) -> [UIView] {
        return views.flatMap { $0.value(forKey: "contentView") as? UIView }
    }
}

extension UITableView: ListLoadable {
    public var ld_visibleContentViews: [UIView] {
        return ld_visibleContentViews(for: visibleCells)
    }
}

extension UICollectionView: ListLoadable {
    public var ld_visibleContentViews: [UIView] {
        return ld_visibleContentViews(for: visibleCells)
    }
}

extension UIColor {
    
    static var backgroundFadedGrey: UIColor {
        return UIColor(red: (246.0/255.0), green: (247.0/255.0), blue: (248.0/255.0), alpha: 1)
    }
    
    static var gradientFirstStop: UIColor {
        return  UIColor(red: (238.0/255.0), green: (238.0/255.0), blue: (238.0/255.0), alpha: 1.0)
    }
    
    static var gradientSecondStop: UIColor {
        return UIColor(red: (221.0/255.0), green: (221.0/255.0), blue:(221.0/255.0) , alpha: 1.0);
    }
}

extension UIView{
    
    func boundInside(_ superView: UIView) {
        
        translatesAutoresizingMaskIntoConstraints = false
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views:["subview": self]))
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views:["subview": self]))
    }
}

public struct Config {
    let loaderDuration: Double
    let gradientWidth: Double
    let gradientFirstStop: Double

    init(loaderDuration: Double = 0.85, gradientWidth: Double = 0.17, gradientFirstStop: Double = 0.1) {
        self.loaderDuration = loaderDuration
        self.gradientWidth = gradientWidth
        self.gradientFirstStop = gradientFirstStop
    }
}

open class Loader {
    
    static let shared = Loader()
    
    var config: Config!
    
    private init() {}
    
    static func addLoaderToViews(_ views: [UIView]) {
        CATransaction.begin()
        views.forEach { $0.ld_addLoader() }
        CATransaction.commit()
    }

    static func removeLoaderFromViews(_ views: [UIView]) {
        CATransaction.begin()
        views.forEach { $0.ld_removeLoader() }
        CATransaction.commit()
    }

    open static func addLoader(to list: ListLoadable, config: Config = Config()) {
        shared.config = config
        addLoaderToViews(list.ld_visibleContentViews)
    }

    open static func removeLoader(from list: ListLoadable) {
        removeLoaderFromViews(list.ld_visibleContentViews)
    }
}

class CutoutView: UIView {

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(self.bounds)

        for view in superview!.subviews where view != self {

            context?.setBlendMode(.clear)
            context?.setFillColor(UIColor.clear.cgColor)
            context?.fill(view.frame)
        }
    }
    

    override func layoutSubviews() {
        super.layoutSubviews()

        setNeedsDisplay()
        superview?.gradient?.frame = superview!.bounds
    }
}

extension CGFloat {
    var doubleValue: Double {
        return Double(self)
    }
}

extension UIView {
    
    struct AssociatedKey {
        static var cutoutHandle: UInt8 = 0
        static var gradientHandle: UInt8 = 0
    }
    
    var cutoutView: UIView? {
        set {
            objc_setAssociatedObject(self, &AssociatedKey.cutoutHandle, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.cutoutHandle) as? UIView
        }
    }
    
    var gradient: CAGradientLayer? {
        set {
            objc_setAssociatedObject(self, &AssociatedKey.gradientHandle, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
        
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.gradientHandle) as? CAGradientLayer
        }
    }

    public func ld_addLoader() {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: bounds.width , height: bounds.height)
        layer.insertSublayer(gradient, at:0)
        
        configureAndAddAnimationToGradient(gradient)
        addCutoutView()
    }
    
    public func ld_removeLoader() {
        
        cutoutView?.removeFromSuperview()
        gradient?.removeAllAnimations()
        gradient?.removeFromSuperlayer()
        
        for view in subviews {
            view.alpha = 1
        }
    }
    
    func curry<T>(a: T, f: @escaping (_ a: T, _ b: T) -> T) -> (T) -> T {
        return { f(a, $0) }
    }

    func configureAndAddAnimationToGradient(_ gradient: CAGradientLayer) {
        let gradientWidth = Loader.shared.config.gradientWidth
        let add = curry(a: gradientWidth, f: +)
        let gradientFirstStop = Loader.shared.config.gradientFirstStop
        let loaderDuration = Loader.shared.config.loaderDuration
        
        gradient.startPoint = CGPoint(x: add(-1.0), y: 0)
        gradient.endPoint = CGPoint(x: add(1), y: 0)

        gradient.colors = [
            UIColor.backgroundFadedGrey.cgColor,
            UIColor.gradientFirstStop.cgColor,
            UIColor.gradientSecondStop.cgColor,
            UIColor.gradientFirstStop.cgColor,
            UIColor.backgroundFadedGrey.cgColor
        ]
        
        let startLocations = [
            NSNumber(value: gradient.startPoint.x.doubleValue),
            NSNumber(value: gradient.startPoint.x.doubleValue),
            NSNumber(value: 0),
            NSNumber(value: gradientWidth),
            NSNumber(value: add(1.0))
        ]
        

        gradient.locations = startLocations
        let gradientAnimation = CABasicAnimation(keyPath: "locations")
        gradientAnimation.fromValue = startLocations
        gradientAnimation.toValue = [
            NSNumber(value: 0),
            NSNumber(value: 1),
            NSNumber(value: 1),
            NSNumber(value: add(1.0) - gradientFirstStop),
            NSNumber(value: add(1.0))
        ]

        gradientAnimation.repeatCount = Float.infinity
        gradientAnimation.fillMode = kCAFillModeForwards
        gradientAnimation.isRemovedOnCompletion = false
        gradientAnimation.duration = loaderDuration
        gradient.add(gradientAnimation ,forKey:"locations")
        

        self.gradient = gradient
    }
    
    func addCutoutView() {
        let cutout = CutoutView(frame: bounds)
        cutout.backgroundColor = UIColor.clear

        addSubview(cutout)
        cutout.setNeedsDisplay()
        cutout.boundInside(self)
        
        for view in subviews where view != cutout {
            view.alpha = 0
        }
        
        cutoutView = cutout
    }
}

