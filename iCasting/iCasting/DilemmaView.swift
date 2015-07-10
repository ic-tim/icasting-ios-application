//
//  DilemmaView.swift
//  iCasting
//
//  Created by Tim van Steenoven on 01/06/15.
//  Copyright (c) 2015 T. van Steenoven. All rights reserved.
//

import UIKit


class DilemmaView: UIView {

    let nibName: String = "DilemmaView"
    
    let ANIMATION_DURATION: NSTimeInterval = 0.7

    var extendedButtonModeLeft: Bool = false
    var extendedButtonModeRight: Bool = false
    
    
    var leftButtonColor: UIColor?
    var rightButtonColor: UIColor?
    
    var leftView: UIView!
    var rightView: UIView!
    var buttonView: UIView!
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftViewLabel: UILabel! /// This is a label
    @IBOutlet weak var rightViewButton: UIButton! //!!! This is a button
    
    var titleLeftButton: String? {
        get {
            return leftButton.titleForState(UIControlState.Normal)
        }
        set {
            leftButton.setTitle(newValue, forState: UIControlState.Normal)
        }
    }

    var titleRightButton: String? {
        get {
            return rightButton.titleForState(UIControlState.Normal)
        }
        set {
            rightButton.setTitle(newValue, forState: UIControlState.Normal)
        }
    }

    var titleLeftView: String? {
        get {
            return leftViewLabel.text
        }
        set {
            leftViewLabel.text = newValue
        }
    }
    
    var titleRightView: String? {
        get {
            return rightViewButton.titleForState(UIControlState.Normal)
        }
        set {
            rightViewButton.setTitle(newValue, forState: UIControlState.Normal)
        }
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        
        clipsToBounds = true
        
        let views: [UIView] = loadViewsFromNib()
        
        buttonView = views[0]
        rightView = views[1]
        leftView = views[2]
        
        configureView(buttonView)
        configureView(rightView)
        configureView(leftView)
        
        addSubview(buttonView)
        addSubview(rightView)
        addSubview(leftView)
        
        startSettingsRightView(rightView)
        startSettingsLeftView(leftView)

        leftButtonColor = leftButton.backgroundColor
        rightButtonColor = rightButton.backgroundColor
    }
    
    func reinitialize() {
        
        startSettingsMiddleView(buttonView)
        startSettingsLeftView(leftView)
        startSettingsRightView(rightView)
    }
    
    
    func startRightAnimation() {
        
        startSettingsRightView(rightView)
        UIView.animateWithDuration(
            ANIMATION_DURATION,
            delay: 0,
            options: UIViewAnimationOptions.CurveEaseOut,
            animations: { () -> Void in

            self.setRightView()
            }, completion: nil)
    }
    
    func startLeftAnimation() {
        
        startSettingsLeftView(leftView)
        UIView.animateWithDuration(
            ANIMATION_DURATION,
            delay: 0,
            options: UIViewAnimationOptions.CurveEaseOut,
            animations: { () -> Void in
            
            self.setLeftView()
            }, completion: nil)
    }
    
    
    func setLeftView() {
        
        if self.extendedButtonModeLeft == true
        {
            self.finalSettingsViewButtonMode(self.leftView)
        } else {
            self.finalSettingsView(self.leftView)
        }
        
        self.finalSettingsMiddleViewForLeft(self.buttonView)
    }
    
    func setRightView() {
        
        if self.extendedButtonModeRight == true
        {
            self.finalSettingsViewButtonMode(self.rightView)
        } else {
            self.finalSettingsView(self.rightView)
        }
        
        self.finalSettingsMiddleViewForRight(self.buttonView)
    }
    
    func disableButtons() {
        self.leftButton.enabled = false
        self.rightButton.enabled = false
        self.grayOutButtonsForInactiveState()
    }

    func enableButtons() {
        self.leftButton.enabled = true
        self.rightButton.enabled = true
        self.colorButtonsForActiveState()
    }
    
    private func grayOutButtonsForInactiveState() {

        let grayColor: UIColor = UIColor(white: 0.65, alpha: 1)
        let alpha: CGFloat = 0.60
        
        self.leftButton.alpha = alpha
        self.rightButton.alpha = alpha
        
        self.leftButton.backgroundColor = grayColor
        self.rightButton.backgroundColor = grayColor
    }
    
    private func colorButtonsForActiveState() {
        
        self.leftButton.alpha = 1
        self.rightButton.alpha = 1
        
        self.leftButton.backgroundColor = self.leftButtonColor
        self.rightButton.backgroundColor = self.rightButtonColor
    }
    
    private func startSettingsLeftView(view: UIView) {
        view.alpha = 0
        view.transform = CGAffineTransformMakeTranslation(-view.bounds.size.width / 2, 0)
    }
    
    private func startSettingsRightView(view: UIView) {
        view.alpha = 0
        view.transform = CGAffineTransformMakeTranslation(view.bounds.size.width / 2, 0)
    }

    private func startSettingsMiddleView(view: UIView) {
        view.alpha = 1
        view.transform = CGAffineTransformMakeTranslation(0, 0)
    }
    
    private func finalSettingsView(view: UIView) {
        view.alpha = 0.60
        view.backgroundColor = UIColor(white: 0.65, alpha: 1)
        view.transform = CGAffineTransformMakeTranslation(0, 0)
    }
    
    private func finalSettingsViewButtonMode(view: UIView) {
        view.alpha = 1
        view.transform = CGAffineTransformMakeTranslation(0, 0)
    }
    
    private func finalSettingsMiddleViewForLeft(view: UIView) {
        view.alpha = 0
        view.transform = CGAffineTransformMakeTranslation(view.bounds.size.width * 2, 0)
    }
    
    private func finalSettingsMiddleViewForRight(view: UIView) {
        view.alpha = 0
        view.transform = CGAffineTransformMakeTranslation(-view.bounds.size.width * 2, 0)
    }
    
    
    private func configureView(view: UIView) {
        view.frame = bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
    }
    
    
    private func loadViewFromNib() -> UIView {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    private func loadViewsFromNib() -> [UIView] {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiateWithOwner(self, options: nil).map { $0 as! UIView }
    }


}
