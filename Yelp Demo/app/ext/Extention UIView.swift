//
//  Extention UIView.swift
//  Yelp Demo
//
//  Created by Bambang on 11/05/23.
//

import UIKit
import Alamofire

extension UIView{
    func addErrorView(toview: UIView, errortext: String, showimage: Bool = true, showreload: Bool = false, onReload: (() -> Void)? = nil){
        
        //Image View
        let imageView = UIImageView()
        //            imageView.backgroundColor = UIColor.blue
        imageView.heightAnchor.constraint(equalToConstant: 120.0).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 120.0).isActive = true
        imageView.image = UIImage(named: "icon_tidak_ada_koneksi")
        
        //Text Label
        let textLabel = UILabel()
        //            textLabel.backgroundColor = UIColor.yellow
        textLabel.widthAnchor.constraint(equalToConstant: toview.frame.width).isActive = true
        textLabel.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        textLabel.text  = errortext//"No Internet Connection"
        textLabel.textAlignment = .center
        var reloadTapView: UIButton!
        if(showreload) {
            //Reload View
            reloadTapView = UIButton()
            reloadTapView.frame = CGRect(x: 0, y: 0, width: 120, height: 30)
            reloadTapView.layer.borderWidth = 0
            reloadTapView.layer.masksToBounds = true
            reloadTapView.setTitleColor(UIColor.black, for: .normal)
            reloadTapView.setTitle("Tap to reload", for: .normal)
            
            reloadTapView.widthAnchor.constraint(equalToConstant: toview.frame.width).isActive = true
            reloadTapView.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
            
            reloadTapView.addTargetClosure { (uiButton) in
                self.removeBluerLoader()
                onReload!()
            }
            
        }
        //Stack View
        let stackView   = UIStackView()
        stackView.axis  = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.alignment = UIStackView.Alignment.center
        stackView.spacing   = 16.0
        
        if(showimage) {
            stackView.addArrangedSubview(imageView)
        }
        stackView.addArrangedSubview(textLabel)
        if(showreload && reloadTapView != nil) {
            stackView.addArrangedSubview(reloadTapView!)
        }
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        toview.addSubview(stackView)
//        stackView.layoutMargins.top = 100
        
        //Constraints
        stackView.centerYAnchor.constraint(greaterThanOrEqualTo: toview.topAnchor, constant: 100).isActive = true
        stackView.centerXAnchor.constraint(equalTo: toview.centerXAnchor).isActive = true
//        stackView.centerYAnchor.constraint(equalTo: toview.centerYAnchor).isActive = true
    }
    
    func showBlurErrorView(errortext: String, showimage: Bool? = true, showreload: Bool? = false, onReload: (() -> Void)? = nil){
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if(showreload!) {
            addErrorView(toview: blurEffectView.contentView, errortext: errortext, showimage: showimage!, showreload: showreload!) {
                onReload!()
            }
        } else {
            addErrorView(toview: blurEffectView.contentView, errortext: errortext, showimage: showimage!) {
                
            }
        }
        self.addSubview(blurEffectView)
    }
    
    func showBlurLoader(onReload: (() -> Void)? = nil) {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if(isConnectedToInternet()) {
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.color = UIColor.cyan//UIColor(red: 20, green: 202, blue: 255, alpha: 1.0)
//            activityIndicator.tintColor = UIColor(red: 20, green: 202, blue: 255, alpha: 1.0)
            
            blurEffectView.contentView.addSubview(activityIndicator)
            self.addSubview(blurEffectView)
            activityIndicator.center = CGPoint(x: blurEffectView.contentView.center.x, y: 100)//blurEffectView.contentView.center
            activityIndicator.startAnimating()
        } else {
            if(onReload != nil) {
                addErrorView(toview: blurEffectView.contentView, errortext: "No Internet Connection", showreload: true) {
                    onReload!()
                }
                self.addSubview(blurEffectView)
            } else {
                self.removeBluerLoader()
            }
        }
        
    }
    
    func removeBluerLoader(){
        self.subviews.compactMap {  $0 as? UIVisualEffectView }.forEach {
            $0.removeFromSuperview()
        }
    }
    
    func isConnectedToInternet() -> Bool {
        return NetworkReachabilityManager()!.isReachable
    }
}

typealias UIButtonTargetClosure = (UIControl) -> ()

class ClosureWrapper: NSObject {
    let closure: UIButtonTargetClosure
    init(_ closure: @escaping UIButtonTargetClosure) {
        self.closure = closure
    }
}

extension UIControl {
    
    private struct AssociatedKeys {
        static var targetClosure = "targetClosure"
    }
    
    private var targetClosure: UIButtonTargetClosure? {
        get {
            guard let closureWrapper = objc_getAssociatedObject(self, &AssociatedKeys.targetClosure) as? ClosureWrapper else { return nil }
            return closureWrapper.closure
        }
        set(newValue) {
            guard let newValue = newValue else { return }
            objc_setAssociatedObject(self, &AssociatedKeys.targetClosure, ClosureWrapper(newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func addTargetClosure(closure: @escaping UIButtonTargetClosure) {
        targetClosure = closure
        addTarget(self, action: #selector(UIControl.closureAction), for: .touchUpInside)
    }
    
    @objc func closureAction() {
        guard let targetClosure = targetClosure else { return }
        targetClosure(self)
    }
}
