
//  RetrievalView.swift
//  Fontismo
//
//
//  Created by Tony Smith on 30/10/2024.
//  Copyright © 2025 Tony Smith. All rights reserved.


import UIKit


final class RetrievalView: UIView {
    
    // Translucent view containing font family download progress updates.
    // Displayed only on the Detail View Controller


    // MARK: - Outlet Properties
    
    @IBOutlet weak var downloadProgress: UIActivityIndicatorView!
    @IBOutlet weak var backgroundView: UIVisualEffectView!


    // MARK: - Control Functions


    /**
     Present the view and start animating the indicator
     */
    func doShow() {
        
        self.downloadProgress.startAnimating()
        self.isHidden = false
    }


    /**
     Stop the indicator and hide the vie
     */
    func doHide() {
        
        self.downloadProgress.stopAnimating()
        self.isHidden = true
    }
}
