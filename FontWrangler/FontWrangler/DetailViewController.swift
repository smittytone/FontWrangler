
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var isInstalledLabel: UILabel!
    @IBOutlet weak var fontSizeSlider: UISlider!
    @IBOutlet weak var helpImage: UIImageView!

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

        // Set the font sample text
        self.detailDescriptionLabel.text = kFontSampleText_1

        // Configure the detail view
        self.configureView()
    }
    

    // MARK: - Presentation Functions
    
    func configureView() {
        
        // Update the user interface for the detail item.

        // Make sure we can access the UI items -- they may not have been
        // instantiated, if 'self.detailItem' is set before the view loads
        guard let detailLabel = self.detailDescriptionLabel else { return }
        guard let installedLabel = self.isInstalledLabel else { return }
        guard let sizeLabel = self.fontSizeLabel else { return }
        guard let sizeSlider = self.fontSizeSlider else { return }
        guard let helpImage = self.helpImage else { return }

        if let detail = self.detailItem {
            // We have an item to display, so load the font and register
            // it for this process only
            
            if detail.isInstalled {
                // Set the detail label's font to match the loaded one
                if let font = UIFont.init(name: detail.name, size: CGFloat(self.fontSize)) {
                    detailLabel.font = font
                    detailLabel.text = kFontSampleText_1
                }
                
                // Set the font installation state label
                let ext = (detail.path as NSString).pathExtension.lowercased()
                var labelText = "This is " + (ext == "otf" ? "an OpenType" : "a TrueType" ) + " font and is "
                labelText += (detail.isInstalled ? "installed" : "not installed") + " on this iPad"
                installedLabel.text = labelText

                // Set the font size slider control and label
                sizeSlider.isEnabled = true
                sizeLabel.text = "\(Int(self.fontSize))pt"

            } else {
                detailLabel.font = UIFont.init(name: "Arial", size: 38.0)
                detailLabel.text = "This font is not installed"
                
                let ext = (detail.path as NSString).pathExtension.lowercased()
                let labelText = "This is " + (ext == "otf" ? "an OpenType" : "a TrueType" ) + " font"
                installedLabel.text = labelText
                
                sizeSlider.isEnabled = false
            }

            // Set the view title and show the detail
            self.title = detail.name
            helpImage.isHidden = true
            detailLabel.isHidden = false
            installedLabel.isHidden = false
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

        // Respond to the user adjusting the font size slider
        
        self.fontSize = self.fontSizeSlider.value
        self.fontSizeLabel.text = "\(Int(self.fontSize))pt"
        self.configureView()
    }

}

