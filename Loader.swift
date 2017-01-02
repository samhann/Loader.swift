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
        
        return (self.visibleCells as NSArray).value(forKey: "contentView") as! [UIView]
        
    }
}

extension UICollectionView : ListLoadable
{
    public func ld_visibleContentViews()->[UIView]
    {
        
        return (self.visibleCells as NSArray).value(forKey: "contentView") as! [UIView]
        
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
    
    func boundInside(_ superView: UIView){
        
        self.translatesAutoresizingMaskIntoConstraints = false
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: NSLayoutFormatOptions(), metrics:nil, views:["subview":self]))
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: NSLayoutFormatOptions(), metrics:nil, views:["subview":self]))
        
        
    }
}

open class Loader
{
    static func addLoaderToViews(_ views : [UIView])
    {
        CATransaction.begin()
        views.forEach { $0.ld_addLoader() }
        CATransaction.commit()
    }
    
    static func removeLoaderFromViews(_ views: [UIView])
    {
        CATransaction.begin()
        views.forEach { $0.ld_removeLoader() }
        CATransaction.commit()
    }
    
    open static func addLoaderTo(_ list : ListLoadable )
    {
        self.addLoaderToViews(list.ld_visibleContentViews())
    }
    
    
    open static func removeLoaderFrom(_ list : ListLoadable )
    {
        self.removeLoaderFromViews(list.ld_visibleContentViews())
    }
    
    
}

class CutoutView : UIView
{
    
    override func draw(_ rect: CGRect) {
        
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(self.bounds)
        
        for view in (self.superview?.subviews)! {

            if view != self {
                
                context?.setBlendMode(.clear);
                context?.setFillColor(UIColor.clear.cgColor)
                context?.fill(view.frame)
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
    
    func ld_setCutoutView(_ aView : UIView)
    {
        return objc_setAssociatedObject(self, &cutoutHandle, aView, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func ld_getGradient()->CAGradientLayer?
    {
        return objc_getAssociatedObject(self, &gradientHandle) as! CAGradientLayer?
    }
    
    func ld_setGradient(_ aLayer : CAGradientLayer)
    {
        return objc_setAssociatedObject(self, &gradientHandle, aLayer, .OBJC_ASSOCIATION_RETAIN)
    }
    
    public func ld_addLoader()
    {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width , height: self.bounds.size.height)
        self.layer.insertSublayer(gradient, at:0)
        
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
    
    
    func configureAndAddAnimationToGradient(_ gradient : CAGradientLayer)
    {
        gradient.startPoint = CGPoint(x: -1.0 + CGFloat(gradientWidth), y: 0)
        gradient.endPoint = CGPoint(x: 1.0 + CGFloat(gradientWidth), y: 0)
        
        gradient.colors = [
            UIColor.backgroundFadedGrey().cgColor,
            UIColor.gradientFirstStop().cgColor,
            UIColor.gradientSecondStop().cgColor,
            UIColor.gradientFirstStop().cgColor,
            UIColor.backgroundFadedGrey().cgColor
        ]
        
        let startLocations = [NSNumber(value: gradient.startPoint.x.doubleValue() as Double),NSNumber(value: gradient.startPoint.x.doubleValue() as Double),NSNumber(value: 0 as Double),NSNumber(value: gradientWidth as Double),NSNumber(value: 1 + gradientWidth as Double)]
        
        
        gradient.locations = startLocations
        let gradientAnimation = CABasicAnimation(keyPath: "locations")
        gradientAnimation.fromValue = startLocations
        gradientAnimation.toValue = [NSNumber(value: 0 as Double),NSNumber(value: 1 as Double),NSNumber(value: 1 as Double),NSNumber(value: 1 + (gradientWidth - gradientFirstStop) as Double),NSNumber(value: 1 + gradientWidth as Double)]
        
        gradientAnimation.repeatCount = Float.infinity
        gradientAnimation.fillMode = kCAFillModeForwards
        gradientAnimation.isRemovedOnCompletion = false
        gradientAnimation.duration = loaderDuration
        gradient.add(gradientAnimation ,forKey:"locations")
        
        
        self.ld_setGradient(gradient)
        
    }
    
    func addCutoutView()
    {
        let cutout = CutoutView()
        cutout.frame = self.bounds
        cutout.backgroundColor = UIColor.clear
        
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

