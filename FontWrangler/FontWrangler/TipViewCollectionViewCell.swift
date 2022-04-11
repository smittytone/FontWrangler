
//  TipViewCollectionViewCell.swift
//  FontWrangler
//
//  Created by Tony Smith on 11/04/2022.


import UIKit


class TipViewCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!


    // MARK: - Graphics Functions

    override func draw(_ dirtyRect: CGRect) {

        super.draw(dirtyRect)

        // Set the colours we'll be using - just use fill so we
        // get colour coming through the image
        if self.isSelected {
            UIColor.red.setFill()
        } else {
            UIColor.clear.setFill()
        }

        // Make the circle
        let highlightCircle: UIBezierPath = UIBezierPath.init(roundedRect: dirtyRect, cornerRadius: 8.0)
        highlightCircle.lineWidth = 2.0
        highlightCircle.fill()

    }
}
