
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var isInstalledLabel: UILabel!
    @IBOutlet weak var fontSizeSlider: UISlider!

    var fontSize: Float = 48.0

    var detailItem: UserFont? {
        
        didSet {
            // When set, display immediately
            self.configureView()
        }
    }
    
    
    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.configureView()
    }
    

    // MARK: - Presentation Functions
    
    func configureView() {
        
        // Update the user interface for the detail item.

        guard let detailLabel = self.detailDescriptionLabel else { return }
        guard let installedLabel = self.isInstalledLabel else { return }
        guard let sizeLabel = self.fontSizeLabel else { return }
        guard let sizeSlider = self.fontSizeSlider else { return }

        if let detail = self.detailItem {
            
            let _ = CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: detail.path) as CFURL,
                                                           .process,
                                                           nil)

            if let font = UIFont.init(name: detail.name, size: CGFloat(self.fontSize)) {
                detailLabel.font = font
            }

            detailLabel.text = "ABCDEFGHI\nJKLMNOPQ\nRSTUVWXYZ\n\n0123456789\n\nabcdefghi\njklmnopq\nrstuvwxyz\n\n!@£$%^&~*()[]{}"
            detailLabel.isHidden = false

            let ext = (detail.path as NSString).pathExtension.lowercased()
            var labelText = "This is " + (ext == "otf" ? "an OpenType" : "a TrueType" ) + " font and is "
            labelText += (detail.isInstalled ? "installed" : "not installed") + " on this iPad"
            installedLabel.text = labelText
            installedLabel.isHidden = false

            sizeSlider.isEnabled = true
            sizeLabel.text = "Size: \(Int(self.fontSize))pt"

            self.title = detail.name
        } else {
            // Hide the labels; disable the slider
            detailLabel.isHidden = true
            installedLabel.isHidden = true
            sizeLabel.text = ""
            sizeSlider.value = self.fontSize
            sizeSlider.isEnabled = false
            self.title = "Font Info"
        }
    }


    @IBAction func setFontSize(_ sender: Any) {

        self.fontSize = self.fontSizeSlider.value
        self.fontSizeLabel.text = "Size: \(Int(self.fontSize))pt"
        self.configureView()
    }

}

