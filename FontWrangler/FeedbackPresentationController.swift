
//  FeedbackPresentationController.swift
//  FontWrangler
//
//  Created by Tony Smith on 06/02/2021.
//  Copyright © 2024 Tony Smith. All rights reserved.


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
        
        // Set up the background blur
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
        
        // The Presentation Controller is about to show the FeedbackViewController
        
        // Add and configure the background blue
        self.blurEffectView.alpha = 0.0
        self.containerView?.addSubview(blurEffectView)
        
        // Trigger the view display animation
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: {
            (UIViewControllerTransitionCoordinatorContext) in
                // Turn off the background blur
                self.blurEffectView.alpha = 0.7
            }, completion: nil)
    }
    
    
    override func dismissalTransitionWillBegin() {
        
        // The Presentation Controller is about to remove the FeedbackViewController
        
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: {
            (UIViewControllerTransitionCoordinatorContext) in
                // Turn off the background blur
                self.blurEffectView.alpha = 0.0
            }, completion: { (UIViewControllerTransitionCoordinatorContext) in
                // When the animation's done, remove the background blur
                self.blurEffectView.removeFromSuperview()
            })
    }
    
    
    override func containerViewWillLayoutSubviews() {
        
        // The presented view is about to be laid out,
        // so configure the layout
        
        // Make sure we call the parent class' function
        super.containerViewWillLayoutSubviews()
        
        // Set the layout mask info
        presentedView!.layer.masksToBounds = true
        presentedView!.layer.cornerRadius = 20
    }
    
    
    override func containerViewDidLayoutSubviews() {
        
        // The presented view was laid out, so now set up the frame
        // and the extent of the background blur
        
        // Make sure we call the parent class' function
        super.containerViewDidLayoutSubviews()
        
        // Set the view frames
        self.presentedView?.frame = frameOfPresentedViewInContainerView
        blurEffectView.frame = containerView!.bounds
    }
    
}
