
//  FontWranglerFontListTableViewCell.swift
//  Fontismo
//
//
//  Created by Tony Smith on 31/03/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit


class FontWranglerFontListTableViewCell: UITableViewCell {

    // Simple custom UITableViewCell with its own properties but no
    // custom or overridden functions. It is used in the app master
    // view to display each font family
    
    
    // MARK: - UI properties
    
    @IBOutlet weak var downloadProgressView: UIActivityIndicatorView!       // UNUSED FROM 2.0.0
    @IBOutlet weak var fontNameLabel: UILabel!
    @IBOutlet weak var fontCountLabel: UILabel!
    @IBOutlet weak var fontPreviewImageView: UIImageView!

}
