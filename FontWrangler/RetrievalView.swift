
//  RetrievalView.swift
//  Fontismo
//
//  Created by Tony Smith on 30/10/2024.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit


final class RetrievalView: UIView {
    
    // Translucent view containing font family download progress updates.
    // Displayed only on the Detail View Controller
    
    
    // MARK: - Outlet Properties
    
    @IBOutlet weak var downloadProgress: UIActivityIndicatorView!
    @IBOutlet weak var backgroundView: UIVisualEffectView!
    
    
    // MARK: - Control Functions
    
    func doShow() {
        
        // Preset the view and start animating the indicator
        self.downloadProgress.startAnimating()
        self.isHidden = false
    }
    
    
    func doHide() {
        
        // Stop the indicator and hide the view
        
        self.downloadProgress.stopAnimating()
        self.isHidden = true
    }
}
