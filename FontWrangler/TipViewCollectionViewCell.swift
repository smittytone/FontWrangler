
//  TipViewCollectionViewCell.swift
//  FontWrangler
//
//  Created by Tony Smith on 11/04/2022.
//  Copyright © 2023 Tony Smith. All rights reserved.


import UIKit
import StoreKit


class TipViewCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI Outlets
    
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

    // MARK: Public Properties

    var product: SKProduct? = nil
    var isClicked: Bool = false


    // MARK: - Graphics Functions

    override func draw(_ dirtyRect: CGRect) {

        super.draw(dirtyRect)

        // Set the colours we'll be using - just use fill so we
        // get colour coming through the image
        if self.isClicked {
            UIColor.label.withAlphaComponent(0.5).setFill()
        } else {
            UIColor.clear.setFill()
        }
        
        // Highlight the cell
        let highlightCircle: UIBezierPath = UIBezierPath.init(roundedRect: dirtyRect,
                                                              cornerRadius: 8.0)
        highlightCircle.fill()
    }
}
