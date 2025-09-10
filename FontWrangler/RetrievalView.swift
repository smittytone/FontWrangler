/*
 *  RetrievalView.swift
 *  Fontismo
 *
 *  Created by Tony Smith on 30/10/2024.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

import UIKit


final class RetrievalView: UIView {

    // Translucent view containing font family download progress updates.
    // Displayed only on the Detail View Controller


    // MARK: - Outlet Properties
    
    @IBOutlet weak var downloadProgress: UIActivityIndicatorView!
    @IBOutlet weak var backgroundView: UIVisualEffectView!
    // FROM 2.1.0
    @IBOutlet weak var actionLabel: UILabel!


    // MARK: - Control Functions

    /**
     Present the view and start animating the indicator.
     */
    func doShow(_ text: String = "Retrieving...") {

        self.downloadProgress.startAnimating()
        self.actionLabel.text = text
        self.isHidden = false
    }


    /**
     Stop the indicator and hide the view.
     */
    func doHide(_ now: Bool = false) {

        if !now {
            _  = Timer.scheduledTimer(withTimeInterval: 1.2,
                                      repeats: false,
                                      block: { (firedTimer) in
                DispatchQueue.main.async(qos: .userInteractive) {
                    self.downloadProgress.stopAnimating()
                    self.isHidden = true
                } /* END OF CLOSURE */
            } /* END OF CLOSURE */
            )
        } else {
            self.downloadProgress.stopAnimating()
            self.isHidden = true
        }
    }
}
