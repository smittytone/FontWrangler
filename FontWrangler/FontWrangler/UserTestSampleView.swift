
//  UserTestSampleView.swift
//  Fontismo
//
//  Created by Tony Smith on 10/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit


class UserTestSampleView: UIView {

    override func draw(_ rect: CGRect) {

        // Get the current graphics context to set the stroke colour
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.label.cgColor)
        }

        // Inset the view rect by two pixels - the path's width - and
        // create a bezier as the context's stroke path
        let newRect = rect.insetBy(dx: 2.0, dy: 2.0)

        let path = UIBezierPath(roundedRect: newRect, cornerRadius: 12.0)
        path.lineWidth = 2.0
        path.stroke(with: .normal, alpha: 0.7)
    }

}
