
//  FeedbackPresentationController.swift
//  FontWrangler
//
//  Created by Tony Smith on 06/02/2021.
//  Copyright © 2021 Tony Smith. All rights reserved.


import UIKit


class FeedbackPresentationController: UIPresentationController {
    
    // This is the custom UIPresentationController for the feedback view controller
    // when it is displayed on an iPad. We use this in order to control the size
    // of the presented view controller's view frame
    
    
    // MARK: - Private Properties
    
    private let blurEffectView: UIVisualEffectView!
    private var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    
    // MARK: - Other Properties
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        // Set the size of the presented view controller's view
        // NOTE This is only called on iPads
        
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        let isLandscape: Bool = (screenWidth > screenHeight)
        
        var frame: CGRect = .zero
        
        if isLandscape {
            // Set the frame to 3/4 width, just under 1/2 height
            frame.size = CGSize(width: self.containerView!.frame.width * 0.75, height: self.containerView!.frame.height * 0.45)
            frame.origin.x = self.containerView!.frame.width * 0.125
            frame.origin.y = 20
        } else {
            // Set the frame to 1/2 width, 2/3 height
            frame.size = CGSize(width: self.containerView!.frame.width * 0.5, height: self.containerView!.frame.height * 0.667)
            frame.origin.x = self.containerView!.frame.width * 0.25
            frame.origin.y = 40
        }
        
        return frame
    }
    
    
    // MARK: - Lifecycle Functions
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        
        // Set up the backgrojnd blur
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        self.blurEffectView = UIVisualEffectView(effect: blurEffect)
        self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.blurEffectView.isUserInteractionEnabled = true
        
        // Initialize the parent class
        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)
        
        // Set up and add the background tap register
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(self.dismiss))
        self.blurEffectView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    
    @objc func dismiss() {
        
        // Handler for background taps: dismiss the feedback view controller
        self.presentedViewController.dismiss(animated: true,
                                             completion: nil)
    }
    
    
    // MARK: - Presentation Start and End Functions
    
    override func presentationTransitionWillBegin() {
        
        self.blurEffectView.alpha = 0
        self.containerView?.addSubview(blurEffectView)
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.alpha = 0.7
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in
            // NOP
        })
    }
    
    
    override func dismissalTransitionWillBegin() {
        
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.alpha = 0
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.removeFromSuperview()
        })
    }
    
    
    override func containerViewWillLayoutSubviews() {
        
        super.containerViewWillLayoutSubviews()
        presentedView!.layer.masksToBounds = true
        presentedView!.layer.cornerRadius = 20
    }
    
    
    override func containerViewDidLayoutSubviews() {
        
        super.containerViewDidLayoutSubviews()
        self.presentedView?.frame = frameOfPresentedViewInContainerView
        blurEffectView.frame = containerView!.bounds
    }
    
}
