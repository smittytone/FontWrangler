//
//  RetrievalView.swift
//  FontWrangler
//
//  Created by Tony Smith on 30/10/2024.
//  Copyright © 2024 Tony Smith. All rights reserved.
//

import UIKit


final class RetrievalView: UIView {
    
    @IBOutlet weak var downloadProgress: UIActivityIndicatorView!
    @IBOutlet weak var backgroundView: UIVisualEffectView!
    
    /*
    override func draw(_ rect: CGRect) {

        let path = UIBezierPath(roundedRect: self.frame, cornerRadius: 16.0)
        let backgroundColour: UIColor = UIColor.red.withAlphaComponent(1.0)
        backgroundColour.setFill()
        path.fill()
    }
    */
    
    func doShow() {
        
        self.downloadProgress.startAnimating()
        self.isHidden = false
    }
    
    
    func doHide() {
        
        self.downloadProgress.stopAnimating()
        self.isHidden = true
    }
}
