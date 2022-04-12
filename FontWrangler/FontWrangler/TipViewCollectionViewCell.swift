
//  TipViewCollectionViewCell.swift
//  FontWrangler
//
//  Created by Tony Smith on 11/04/2022.


import UIKit
import StoreKit


class TipViewCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI Outlets
    
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    var product: SKProduct? = nil


    // MARK: - Graphics Functions

    override func draw(_ dirtyRect: CGRect) {

        super.draw(dirtyRect)

        // Set the colours we'll be using - just use fill so we
        // get colour coming through the image
        if self.isSelected {
            UIColor.init(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0).setFill()
        } else {
            UIColor.clear.setFill()
        }

        // Highlight the cell
        let highlightCircle: UIBezierPath = UIBezierPath.init(roundedRect: dirtyRect, cornerRadius: 8.0)
        highlightCircle.lineWidth = 2.0
        highlightCircle.fill()

    }
}
