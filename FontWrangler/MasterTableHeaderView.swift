//
//  MasterTableHeaderView.swift
//  FontWrangler
//
//  Created by Tony Smith on 18/10/2024.
//  Copyright © 2024 Tony Smith. All rights reserved.
//

import Foundation
import UIKit


class MasterTableHeaderView: UIView {
    
    // A UIView sub-class used to provide the view set as the main table's
    // header view.
    
    
    // MARK: - UI properties

    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    
    
    // MARK: - Public Properties
    
    var parent: UITableView? = nil
    
    
    // MARK: - Draw Function
    
    override func draw(_ dirtyRect: CGRect) {
        
        // Adjust the left and right margin constrainsts
        // (left for TYPEFACE and right for ADDED) to align over columns
        if let parent = self.parent {
            self.leftConstraint.constant = parent.frame.origin.x + parent.safeAreaInsets.left + 16
            let a = (parent.safeAreaInsets.right + 12) * -1.0
            self.rightConstraint.constant = a
        }
        
        super.draw(dirtyRect)
    }
}
