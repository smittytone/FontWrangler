
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class DetailViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var fontStatusLabel: UILabel!
    
    @IBOutlet weak var dynamicSampleHeadLabel: UILabel!
    @IBOutlet weak var dynamicSampleTextView: UITextView!
    @IBOutlet weak var dynamicSampleParentView: UIView!
    
    @IBOutlet weak var userSampleHeadLabel: UILabel!
    @IBOutlet weak var userSampleTextView: UITextView!
    
    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var fontSizeSlider: UISlider!
    

    var fontSize: CGFloat = kBaseDynamicSampleFontSize
    var substituteFont: UIFont? = nil
    var mvc: MasterViewController? = nil
    var variantsButton: UIBarButtonItem? = nil
    var currentFamily: FontFamily? = nil
    
    var detailItem: UserFont? {
        
        didSet {
            // When set, display immediately
            self.configureView()
        }
    }
    
    
    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let rightButton = UIBarButtonItem(title: "Variants",
                                          style: .plain,
                                          target: self,
                                          action: #selector(self.showVariantsMenu))
        navigationItem.rightBarButtonItem = rightButton
        self.variantsButton = rightButton
        
        // Set the base size
        self.substituteFont = UIFont.init(name: "Arial", size: KBaseUserSampleFontSize)
        self.fontSize = kBaseDynamicSampleFontSize
        self.fontSizeSlider.value = Float(self.fontSize)
        self.fontSizeLabel.text = "\(Int(self.fontSize))pt"
        
        // Set the font sample text
        self.dynamicSampleTextView.text = kFontSampleText_1
        self.dynamicSampleTextView.isEditable = false
        self.dynamicSampleTextView.alpha = 0.3
        
        // Block access to the user-entered sample
        self.userSampleTextView.isEditable = false
        self.userSampleTextView.alpha = 0.3

        // Check for on-screen taps to end user sample editing
        let gr: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.tap))
        self.view?.addGestureRecognizer(gr)
        
        // Configure the detail view
        self.configureView()

        // Show the master view
        self.splitViewController?.toggleMasterView()
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
                sampleNote.alpha = 1.0
                
                // Set the samples' fonts
                dynamicLabel.alpha = 1.0
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
                dynamicLabel.alpha = 0.3
                
                sampleNote.font = substituteFont
                sampleNote.isEditable = false
                sampleNote.alpha = 0.3
                
                labelText = "This is " + (ext == "otf" ? "an OpenType" : "a TrueType" ) + " font"
            }
            
            // Set the font status
            statusLabel.text = labelText
            
            // Enable or disable the Variants button according to whether there are any
            var count = 0
            if let family = self.currentFamily {
                if let familyFonts = family.fonts {
                    count = familyFonts.count
                }
            }
            self.variantsButton?.isEnabled = count > 1 ? true : false
        } else {
            // Hide the labels; disable the slider
            self.title = "Font Info"
            statusLabel.text = "No font selected"
            sizeLabel.text = ""
            sizeSlider.value = Float(self.fontSize)
            self.variantsButton?.isEnabled = false
        }
    }


    @IBAction func setFontSize(_ sender: Any) {

        // Respond to the user adjusting the font size slider
        
        self.fontSize = CGFloat(self.fontSizeSlider.value)
        self.fontSizeLabel.text = "\(Int(self.fontSize))pt"
        self.configureView()
    }
    

    @objc func tap() {

        // End editing of the user sample text view on a tap

        self.userSampleTextView.endEditing(true)
    }


    @objc func showVariantsMenu() {
        
        // Load and configure the menu view controller.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let fvc: FontVariantsTableViewController = storyboard.instantiateViewController(withIdentifier: "font.variants.controller") as! FontVariantsTableViewController
        fvc.dvc = self
        
        // Set the popover's data
        if let fonts = self.currentFamily!.fonts {
            fvc.fonts = fonts
            
            var index: Int = 0
            for font: UserFont in fonts {
                if font == self.detailItem {
                    fvc.currentFont = index
                    break
                }
                
                index += 1
            }
        }
        
        // Use the popover presentation style for your view controller.
        fvc.modalPresentationStyle = .popover

        // Specify the anchor point for the popover.
        fvc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        fvc.popoverPresentationController?.delegate = self
                   
        // Present the view controller (in a popover).
        self.present(fvc, animated: true, completion: nil)
    }

}

