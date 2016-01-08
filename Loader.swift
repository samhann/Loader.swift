//
//  FBLoader.swift
//  FBAnimatedView
//
//  Created by Samhan on 08/01/16.
//  Copyright © 2016 Samhan. All rights reserved.
//

import UIKit

@objc public protocol ListLoadable
{
    func ld_visibleContentViews()->[UIView]
}

extension UITableView : ListLoadable
{
    public func ld_visibleContentViews()->[UIView]
    {
        
        return (self.visibleCells as NSArray).valueForKey("contentView") as! [UIView]
        
    }
}

extension UICollectionView : ListLoadable
{
    public func ld_visibleContentViews()->[UIView]
    {
        
        return (self.visibleCells() as NSArray).valueForKey("contentView") as! [UIView]
        
    }
}

extension UIColor {
    
    static func backgroundFadedGrey()->UIColor
    {
        return UIColor(red: (246.0/255.0), green: (247.0/255.0), blue: (248.0/255.0), alpha: 1)
    }
    
    static func gradientFirstStop()->UIColor
    {
        return  UIColor(red: (238.0/255.0), green: (238.0/255.0), blue: (238.0/255.0), alpha: 1.0)
    }
    
    static func gradientSecondStop()->UIColor
    {
        return UIColor(red: (221.0/255.0), green: (221.0/255.0), blue:(221.0/255.0) , alpha: 1.0);
    }
}

extension UIView{
    
    func boundInside(superView: UIView){
        
        self.translatesAutoresizingMaskIntoConstraints = false
        superView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics:nil, views:["subview":self]))
        superView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics:nil, views:["subview":self]))
        
        
    }
}

public class Loader
{
    static func addLoaderToViews(let views : [UIView])
    {
        CATransaction.begin()
        views.forEach { $0.ld_addLoader() }
        CATransaction.commit()
    }
    
    static func removeLoaderFromViews(let views: [UIView])
    {
        CATransaction.begin()
        views.forEach { $0.ld_removeLoader() }
        CATransaction.commit()
    }
    
    public static func addLoaderTo(let list : ListLoadable )
    {
        self.addLoaderToViews(list.ld_visibleContentViews())
    }
    
    
    public static func removeLoaderFrom(let list : ListLoadable )
    {
        self.removeLoaderFromViews(list.ld_visibleContentViews())
    }
    
    
}

class CutoutView : UIView
{
    
    override func drawRect(rect: CGRect) {
        
        super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextFillRect(context, self.bounds)
        
        for view in (self.superview?.subviews)! {

            if view != self {
                
                CGContextSetBlendMode(context, .Clear);
                CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
                CGContextFillRect(context, view.frame)
            }
        }
    }
    
    
    override func layoutSubviews() {
        
        self.setNeedsDisplay()
        self.superview?.ld_getGradient()?.frame = (self.superview?.bounds)!
    }
}

// TODO :- Allow caller to tweak these

var cutoutHandle: UInt8         = 0
var gradientHandle: UInt8       = 0
var loaderDuration              = 0.85
var gradientWidth               = 0.17
var gradientFirstStop           = 0.1

extension CGFloat
{
    func doubleValue()->Double
    {
        return Double(self)
    }
    
}

extension UIView
{
    public func ld_getCutoutView()->UIView?
    {
        return objc_getAssociatedObject(self, &cutoutHandle) as! UIView?
    }
    
    func ld_setCutoutView(aView : UIView)
    {
        return objc_setAssociatedObject(self, &cutoutHandle, aView, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func ld_getGradient()->CAGradientLayer?
    {
        return objc_getAssociatedObject(self, &gradientHandle) as! CAGradientLayer?
    }
    
    func ld_setGradient(aLayer : CAGradientLayer)
    {
        return objc_setAssociatedObject(self, &gradientHandle, aLayer, .OBJC_ASSOCIATION_RETAIN)
    }
    
    public func ld_addLoader()
    {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRectMake(0, 0, self.bounds.size.width , self.bounds.size.height)
        self.layer.insertSublayer(gradient, atIndex:0)
        
        self.configureAndAddAnimationToGradient(gradient)
        self.addCutoutView()
    }
    
    public func ld_removeLoader()
    {
        self.ld_getCutoutView()?.removeFromSuperview()
        self.ld_getGradient()?.removeAllAnimations()
        self.ld_getGradient()?.removeFromSuperlayer()
        
        for view in self.subviews {
            view.alpha = 1
        }
    }
    
    
    func configureAndAddAnimationToGradient(let gradient : CAGradientLayer)
    {
        gradient.startPoint = CGPointMake(-1.0 + CGFloat(gradientWidth), 0)
        gradient.endPoint = CGPointMake(1.0 + CGFloat(gradientWidth), 0)
        
        gradient.colors = [
            UIColor.backgroundFadedGrey().CGColor,
            UIColor.gradientFirstStop().CGColor,
            UIColor.gradientSecondStop().CGColor,
            UIColor.gradientFirstStop().CGColor,
            UIColor.backgroundFadedGrey().CGColor
        ]
        
        let startLocations = [NSNumber(double: gradient.startPoint.x.doubleValue()),NSNumber(double:gradient.startPoint.x.doubleValue()),NSNumber(double:0),NSNumber(double: gradientWidth),NSNumber(double: 1 + gradientWidth)]
        
        
        gradient.locations = startLocations
        let gradientAnimation = CABasicAnimation(keyPath: "locations")
        gradientAnimation.fromValue = startLocations
        gradientAnimation.toValue = [NSNumber(double: 0),NSNumber(double:1),NSNumber(double:1),NSNumber(double: 1 + (gradientWidth - gradientFirstStop)),NSNumber(double: 1 + gradientWidth)]
        
        gradientAnimation.repeatCount = Float.infinity
        gradientAnimation.fillMode = kCAFillModeForwards
        gradientAnimation.removedOnCompletion = false
        gradientAnimation.duration = loaderDuration
        gradient.addAnimation(gradientAnimation ,forKey:"locations")
        
        
        self.ld_setGradient(gradient)
        
    }
    
    func addCutoutView()
    {
        let cutout = CutoutView()
        cutout.frame = self.bounds
        cutout.backgroundColor = UIColor.clearColor()
        
        self.addSubview(cutout)
        cutout.setNeedsDisplay()
        cutout.boundInside(self)
        
        for view in self.subviews {
            if view != cutout {
                view.alpha = 0
            }
        }
        
        
        self.ld_setCutoutView(cutout)
    }
}

