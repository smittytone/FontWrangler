//
//  UserTestSampleView.swift
//  FontWrangler
//
//  Created by Tony Smith on 10/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.
//

import UIKit

class UserTestSampleView: UIView {

    private var path: UIBezierPath?

    override func draw(_ rect: CGRect) {

        let newRect = rect.insetBy(dx: 2.0, dy: 2.0)
        // Drawing code
        if self.path == nil {
            path = UIBezierPath(roundedRect: newRect, cornerRadius: 12.0)
            path!.lineWidth = 2.0
        }

        if let c = UIGraphicsGetCurrentContext() {
            c.setStrokeColor(UIColor.label.cgColor)
        }

        path!.stroke(with: .normal, alpha: 0.7)
    }

}
