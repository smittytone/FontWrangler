
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var fontStatusLabel: UILabel!
    
    @IBOutlet weak var dynamicSampleHeadLabel: UILabel!
    @IBOutlet weak var dynamicSampleTextView: UITextView!
    
    @IBOutlet weak var userSampleHeadLabel: UILabel!
    @IBOutlet weak var userSampleTextView: UITextView!
    
    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var fontSizeSlider: UISlider!
    

    var fontSize: CGFloat = kBaseDynamicSampleFontSize
    var substituteFont: UIFont? = nil
    var mvc: MasterViewController? = nil

    
    var detailItem: UserFont? {
        
        didSet {
            // When set, display immediately
            self.configureView()
        }
    }
    
    
    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set the base size
        self.substituteFont = UIFont.init(name: "Arial", size: KBaseUserSampleFontSize)
        self.fontSize = kBaseDynamicSampleFontSize
        self.fontSizeSlider.value = Float(self.fontSize)
        self.fontSizeLabel.text = "\(Int(self.fontSize))pt"
        
        // Set the font sample text
        self.dynamicSampleTextView.text = kFontSampleText_1
        self.dynamicSampleTextView.isEditable = false
        
        // Block access to the user-entered sample
        self.userSampleTextView.isEditable = false
        
        // Configure the detail view
        self.configureView()
    }
    

    // MARK: - Presentation Functions
    
    func configureView() {
        
        // Update the user interface for the detail item.

        // Make sure we can access the UI items -- they may not have been
        // instantiated, if 'self.detailItem' is set before the view loads
        guard let statusLabel = self.fontStatusLabel else { return }
        guard let dynamicLabel = self.dynamicSampleTextView else { return }
        guard let sampleNote = self.userSampleTextView else { return }
        guard let sizeLabel = self.fontSizeLabel else { return }
        guard let sizeSlider = self.fontSizeSlider else { return }
        
        // Generic cases
        sizeSlider.isEnabled = false
        
        if let detail = self.detailItem {
            // We have an item to display, so load the font and register
            // it for this process only
            
            // Set the view title and show the detail
            if self.mvc != nil {
                self.title = self.mvc!.getPrinteableName(detail.name, "-")
            } else {
                self.title = detail.name
            }
            
            // Prepare the status label
            let ext = (detail.path as NSString).pathExtension.lowercased()
            var labelText: String
            
            if detail.isInstalled {
                sampleNote.isEditable = true
                
                // Set the samples' fonts
                if let font = UIFont.init(name: detail.name, size: CGFloat(self.fontSize)) {
                    dynamicLabel.font = font
                }
                
                if let font = UIFont.init(name: detail.name, size: KBaseUserSampleFontSize) {
                    sampleNote.font = font
                }
                
                // Set the font state label
                labelText = "This is " + (ext == "otf" ? "an OpenType" : "a TrueType" ) + " font and is "
                labelText += (detail.isInstalled ? "installed" : "not installed") + " on this iPad"

                // Set the font size slider control and label
                sizeSlider.isEnabled = true
                sizeLabel.text = "\(Int(self.fontSize))pt"

            } else {
                dynamicLabel.font = self.substituteFont

                sampleNote.font = substituteFont
                sampleNote.isEditable = false
                
                labelText = "This is " + (ext == "otf" ? "an OpenType" : "a TrueType" ) + " font"
            }
            
            // Set the font status
            statusLabel.text = labelText
        } else {
            // Hide the labels; disable the slider
            self.title = "Font Info"
            statusLabel.text = "No font selected"
            sizeLabel.text = ""
            sizeSlider.value = Float(self.fontSize)
        }
    }


    @IBAction func setFontSize(_ sender: Any) {

        // Respond to the user adjusting the font size slider
        
        self.fontSize = CGFloat(self.fontSizeSlider.value)
        self.fontSizeLabel.text = "\(Int(self.fontSize))pt"
        self.configureView()
    }

}

