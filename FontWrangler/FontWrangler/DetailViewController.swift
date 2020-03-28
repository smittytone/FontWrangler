
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var fontFilenameLabel: UILabel!
    @IBOutlet weak var isInstalledLabel: UILabel!


    var detailItem: UserFont? {
        
        didSet {
            // When set, display immediately
            configureView()
        }
    }
    
    
    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Hide the labels initially
        self.detailDescriptionLabel.isHidden = true
        self.fontFilenameLabel.isHidden = true
        self.isInstalledLabel.isHidden = true
        configureView()
    }
    

    // MARK: - Presentation Functions
    
    func configureView() {
        
        // Update the user interface for the detail item.

        guard let detailLabel = self.detailDescriptionLabel else { return }
        guard let fileLabel = self.fontFilenameLabel else { return }
        guard let installedLabel = self.isInstalledLabel else { return }

        if let detail = self.detailItem {
            
            let _ = CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: detail.path) as CFURL,
                                                           .process,
                                                           nil)

            if let font = UIFont.init(name: detail.name, size: 48.0) {
                detailLabel.font = font
            }

            detailLabel.text = "ABCDEFGHI\nJKLMNOPQ\nRSTUVWXYZ\n\n0123456789\n\nabcdefghi\njklmnopq\nrstuvwxyz\n\n!@£$%^&~*()[]{}"
            detailLabel.isHidden = false

            let ext = (detail.path as NSString).pathExtension.lowercased()
            fileLabel.text = (ext == "ttf" ? "A TrueType (.ttf) font" : "An OpenType (.otf) font")
            fileLabel.isHidden = false

            installedLabel.text = (detail.isInstalled ? "Installed" : "Not installed") + " on this iPad"
            installedLabel.isHidden = false

            self.title = detail.name
        }
    }

}

