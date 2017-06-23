//
//  FBLoader.swift
//  FBAnimatedView
//
//  Created by Samhan on 08/01/16.
//  Copyright © 2016 Samhan. All rights reserved.
//

import UIKit

public extension UITableView {
    public func ld_visibleContentViews() -> [UIView] {

        return (visibleCells as NSArray).valueForKey("contentView") as! [UIView]
    }
}

public extension UICollectionView {
    public func ld_visibleContentViews() -> [UIView] {

        return (visibleCells() as NSArray).valueForKey("contentView") as! [UIView]
    }
}

extension UIColor {

    static func backgroundFadedGrey() -> UIColor {
        return UIColor(red: (246.0 / 255.0), green: (247.0 / 255.0), blue: (248.0 / 255.0), alpha: 1)
    }

    static func gradientFirstStop() -> UIColor {
        return UIColor(red: (238.0 / 255.0), green: (238.0 / 255.0), blue: (238.0 / 255.0), alpha: 1.0)
    }

    static func gradientSecondStop() -> UIColor {
        return UIColor(red: (221.0 / 255.0), green: (221.0 / 255.0), blue: (221.0 / 255.0), alpha: 1.0)
    }
}

public class Loader {
    public static func addLoaderToViews(let views: [UIView]) {
        CATransaction.begin()
        views.forEach { $0.ld_addLoader() }
        CATransaction.commit()
    }

    public static func removeLoaderFromViews(let views: [UIView]) {
        CATransaction.begin()
        views.forEach { $0.ld_removeLoader() }
        CATransaction.commit()
    }

    public static func addLoaderToTableView(let table: UITableView) {
        addLoaderToViews(table.ld_visibleContentViews())
    }

    public static func addLoaderToCollectionView(let coll: UICollectionView) {
        addLoaderToViews(coll.ld_visibleContentViews())
    }

    public static func removeLoaderFromTableView(let table: UITableView) {
        removeLoaderFromViews(table.ld_visibleContentViews())
    }

    public static func removeLoaderFromCollectionView(let coll: UICollectionView) {
        removeLoaderFromViews(coll.ld_visibleContentViews())
    }
}

class CutoutView: UIView {

    override func drawRect(rect: CGRect) {

        super.drawRect(rect)

        let context = UIGraphicsGetCurrentContext()

        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)

        CGContextFillRect(context, bounds)

        for view in (superview?.subviews)! {

            if view != self {

                CGContextSetBlendMode(context, .Clear)
                CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
                CGContextFillRect(context, view.frame)
            }
        }
    }
}

var cutoutHandle: UInt8 = 0
var gradientHandle: UInt8 = 0

extension UIView {
    public func ld_getCutoutView() -> UIView? {
        return objc_getAssociatedObject(self, &cutoutHandle) as! UIView?
    }

    func ld_setCutoutView(aView: UIView) {
        return objc_setAssociatedObject(self, &cutoutHandle, aView, .OBJC_ASSOCIATION_RETAIN)
    }

    func ld_getGradient() -> CAGradientLayer? {
        return objc_getAssociatedObject(self, &gradientHandle) as! CAGradientLayer?
    }

    func ld_setGradient(aLayer: CAGradientLayer) {
        return objc_setAssociatedObject(self, &gradientHandle, aLayer, .OBJC_ASSOCIATION_RETAIN)
    }

    public func ld_addLoader() {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height)
        layer.insertSublayer(gradient, atIndex: 0)

        configureAndAddAnimationToGradient(gradient)
        addCutoutView()
    }

    public func ld_removeLoader() {
        ld_getCutoutView()?.removeFromSuperview()
        ld_getGradient()?.removeAllAnimations()
        ld_getGradient()?.removeFromSuperlayer()

        for view in subviews {
            view.alpha = 1
        }
    }

    func configureAndAddAnimationToGradient(let gradient: CAGradientLayer) {
        gradient.startPoint = CGPointMake(-1.25, 0)
        gradient.endPoint = CGPointMake(1.25, 0)

        gradient.colors = [
            UIColor.backgroundFadedGrey().CGColor,
            UIColor.gradientFirstStop().CGColor,
            UIColor.gradientSecondStop().CGColor,
            UIColor.gradientFirstStop().CGColor,
            UIColor.backgroundFadedGrey().CGColor,
        ]

        gradient.locations = [NSNumber(double: -1.25), NSNumber(double: -1.25), NSNumber(double: 0), NSNumber(double: 0.25), NSNumber(double: 1.25)]

        let gradientAnimation = CABasicAnimation(keyPath: "locations")
        gradientAnimation.fromValue = [NSNumber(double: 0.0), NSNumber(double: 0.0), NSNumber(double: 0.10), NSNumber(double: 0.25), NSNumber(double: 1)]

        gradientAnimation.toValue = [NSNumber(double: 0), NSNumber(double: 1), NSNumber(double: 1), NSNumber(double: 1.15), NSNumber(double: 1.25)]

        gradientAnimation.repeatCount = Float.infinity
        gradientAnimation.fillMode = kCAFillModeForwards
        gradientAnimation.removedOnCompletion = false

        gradientAnimation.duration = 1
        gradient.addAnimation(gradientAnimation, forKey: "locations")

        ld_setGradient(gradient)
    }

    func addCutoutView() {
        let cutout = CutoutView()
        cutout.frame = bounds
        cutout.backgroundColor = UIColor.clearColor()

        insertSubview(cutout, atIndex: 1)
        cutout.setNeedsDisplay()

        for view in subviews {
            if view != cutout {
                view.alpha = 0
            }
        }
        ld_setCutoutView(cutout)
    }
}
