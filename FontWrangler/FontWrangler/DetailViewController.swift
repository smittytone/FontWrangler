
//  DetailViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2022 Tony Smith. All rights reserved.


import UIKit


class DetailViewController: UIViewController,
                            UIPopoverPresentationControllerDelegate,
                            UITextViewDelegate {

    // MARK: - UI properties
    
    @IBOutlet weak var fontStatusLabel: UILabel!
    
    @IBOutlet weak var dynamicSampleHeadLabel: UILabel!
    @IBOutlet weak var dynamicSampleTextView: UITextView!

    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var fontSizeSlider: UISlider!

    @IBOutlet weak var downloadProgress: UIActivityIndicatorView!

    // REMOVED IN 1.1.0
    //@IBOutlet weak var dynamicSampleParentView: UserTestSampleView!
    //@IBOutlet weak var userSampleHeadLabel: UILabel!
    //@IBOutlet weak var userSampleTextView: UITextView!


    // MARK: - Object properties
    
    private var substituteFont: UIFont? = nil
    private var variantsButton: UIBarButtonItem? = nil
    private var fontSize: CGFloat = kBaseDynamicSampleFontSize
    private var hasFlipped: Bool = false
    private var dynamicFlipBoundary: CGFloat = 0.0
    private var storeSliderValue: Float = Float(kBaseDynamicSampleFontSize)
    
    var mvc: MasterViewController? = nil
    var currentFamily: FontFamily? = nil
    var currentFontIndex: Int = 0
    var hasCustomText: Bool = false

    var detailItem: UserFont? {
        
        didSet {
            // When set, update the view immediately
            self.configureView()
        }
    }


    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let rightButton = UIBarButtonItem(title: "Variations",
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
        self.dynamicSampleTextView.isEditable = true
        self.dynamicSampleTextView.alpha = 0.3
        
        // REMOVED IN 1.1.0
        // Block access to the user-entered sample
        //self.dynamicSampleParentView.alpha = 0.3
        //self.userSampleTextView.isEditable = false
        //self.userSampleTextView.alpha = 0.3

        // Check for on-screen taps to end user sample editing
        let tapRec: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self,
                                                                         action: #selector(self.doTap))
        self.view?.addGestureRecognizer(tapRec)

        // FROM 1.1.0
        // Add pinch-to-zoom for font scaling
        let pinchRec: UIPinchGestureRecognizer = UIPinchGestureRecognizer.init(target: self,
                                                                               action: #selector(self.doSwipe))
        self.view?.addGestureRecognizer(pinchRec)
        
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
        guard let sampleText = self.dynamicSampleTextView else { return }
        guard let sampleHead = self.dynamicSampleHeadLabel else { return }
        guard let sizeLabel = self.fontSizeLabel else { return }
        guard let sizeSlider = self.fontSizeSlider else { return }

        // REMOVED IN 1.1.0
        // guard let sampleNote = self.userSampleTextView else { return }
        // guard let parent = self.dynamicSampleParentView else { return }

        // Generic cases
        //sizeSlider.isEnabled = false

        // FROM 1.1.1
        // Turn of the indicator and hide
        if let dp = self.downloadProgress {
            dp.stopAnimating()
        }
        
        if let detail = self.detailItem {
            // We have an item to display, so load the font and register
            // it for this process only
            
            // Set the view title and show the detail
            if self.mvc != nil {
                if self.currentFamily != nil {
                    if detail.tag == "bungee" {
                        // Use Bungee Quirk
                        self.title = self.getBungeeTitle(detail.name)
                    } else if detail.tag == "hanalei" {
                        self.title = self.getHanaleiTitle(detail.name)
                    } else {
                        self.title = self.currentFamily!.name + self.getVariantName(detail.name)
                    }
                } else {
                    self.title = self.mvc!.getPrinteableName(detail.name, "-")
                }
            } else {
                self.title = detail.name
            }

            if detail.isInstalled {
                // Set the samples' fonts
                sampleText.alpha = 1.0
                sampleHead.alpha = 1.0

                if let font = UIFont.init(name: detail.psname, size: self.fontSize) {
                    sampleText.font = font
                }
                
                // Set the font size slider control and label
                sizeLabel.text = "\(Int(self.fontSize))pt"
                sizeSlider.isEnabled = true
                sizeSlider.setValue(Float(self.fontSize), animated: true);
                
                // REMOVED IN 1.1.0
                //sampleNote.isEditable = true
                //sampleNote.alpha = 1.0
                //parent.alpha = 1.0
                // if let font = UIFont.init(name: detail.psname, size: KBaseUserSampleFontSize) { sampleNote.font = font }
            } else {
                sampleText.font = self.substituteFont
                sampleText.alpha = 0.3
                sampleHead.alpha = 0.3
                sizeLabel.text = ""
                sizeSlider.isEnabled = false
                
                // REMOVED IN 1.1.0
                //sampleNote.font = substituteFont
                //sampleNote.isEditable = false
                //sampleNote.alpha = 0.3
                //parent.alpha = 0.3
            }
            
            // Set the font status label
            let ext = (detail.path as NSString).pathExtension.lowercased()
            var labelText = "This " + (ext == "otf" ? "OpenType" : "TrueType" ) + " font is "
            labelText += (detail.isInstalled ? "installed" : "not installed")
            statusLabel.text = labelText
            
            // Enable or disable the Variants button according to whether there are any
            var count = 0
            if let family = self.currentFamily {
                if let familyFonts = family.fontIndices {
                    count = familyFonts.count
                }
            }

            self.variantsButton?.isEnabled = count > 1 ? true : false

            // FROM 1.1.0
            // Font not installed, so offer to install it
            if !detail.isInstalled {
                doInstall()
            }
        } else {
            // Hide the labels; disable the slider
            self.title = "Font Info"
            statusLabel.text = "No font selected"
            sizeLabel.text = ""
            sizeSlider.value = Float(self.fontSize)
            sizeSlider.isEnabled = false
            self.variantsButton?.isEnabled = false
        }
    }


    func doInstall() {

        // FROM 1.1.0
        // Offer to install the font if it has not yet been installed

        // Create and present an alert with two buttons
        if let cf = self.currentFamily {
            let alert = UIAlertController.init(title: "\(cf.name)",
                                               message: "This font family is not installed. Would you like to install it now?",
                                               preferredStyle: .alert)

            var alertButton = UIAlertAction.init(title: "Yes",
                                                 style: .default) { (action) in
                // Install the font
                self.downloadProgress.isHidden = false
                self.downloadProgress.startAnimating()
                self.mvc!.getOneFontFamily(cf)
            }

            alert.addAction(alertButton)

            alertButton = UIAlertAction.init(title: "No",
                                             style: .cancel,
                                             handler: nil)

            alert.addAction(alertButton)

            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }

    // REMOVED IN 1.1.0
    /*
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        super.viewWillTransition(to: size, with: coordinator)

        // Make sure dynamicSampleParentView not nil
        if let pv = self.dynamicSampleParentView {
            pv.setNeedsDisplay()
        }
    }
    */

    
    // MARK: - Action Functions
    
    @IBAction func setFontSize(_ sender: Any) {

        // Respond to the user adjusting the font size slider

        // Update the current font size based on the slider value and update the UI
        self.fontSize = CGFloat(Int(self.fontSizeSlider.value))

        // FROM 1.1.1
        // End editing on scale
        self.dynamicSampleTextView.endEditing(true)

        // FROM 1.1.1
        // Wrap the following section in a check for custom text, so that we do not
        // change the displayed string back to the alphabet list
        if !self.hasCustomText {
            // Check whether we need to flip between the pre-broken line and unbroken line
            // text strings applied to the view
            if !self.hasFlipped {
                // Not yet flipped, so check for flip condition, ie. number of lines is greater than expected
                // Get the number of displayed lines
                //let numLines = Int(self.dynamicSampleTextView.contentSize.height / self.dynamicSampleTextView.font!.lineHeight)
                let numLines = self.dynamicSampleTextView.layoutManager.lines

                if numLines > kFontSampleText_1_Lines && self.fontSize > CGFloat(kFontSampleText_1_Limit) {
                    // At least one line has wrapped, so trigger a flip:
                    // Use the un-broken text so it wraps right: no orphans
                    self.dynamicSampleTextView.text = kFontSampleText_2
                    self.hasFlipped = true

                    // First time, record the font size at which the flip occurred
                    if self.dynamicFlipBoundary == 0.0 {
                        self.dynamicFlipBoundary = self.fontSize
                    }
                }
            } else {
                // We are flipped - do we need to flip back? Only if the displayed
                // font size is less than the size at which we flipped
                if self.fontSize < self.dynamicFlipBoundary {
                    self.dynamicSampleTextView.text = kFontSampleText_1
                    self.hasFlipped = false
                }
            }
        }

        // Update the view
        // self.configureView()
        self.fontSizeLabel.text = "\(Int(self.fontSize))pt"
        if let font = UIFont.init(name: self.detailItem!.psname, size: self.fontSize) {
            self.dynamicSampleTextView.font = font
        }
    }
    

    @objc func doTap() {

        // End editing of the user sample text view on a tap

        if let stv = self.dynamicSampleTextView {
            stv.endEditing(true)
        }
    }


    @objc func doSwipe(_ pgr: UIPinchGestureRecognizer) {

        // FROM 1.1.0
        // Triggered by the pinch gesture on the main view
        guard pgr.view != nil else { return }

        // Store the current size: we will scale from this value
        if pgr.state == .began {
            storeSliderValue = self.fontSizeSlider.value
        }

        // Apply the scale if the pinch distance changes
        if pgr.state == .began || pgr.state == .changed {
            // Set the slider and then trigger the action function
            self.fontSizeSlider.value = storeSliderValue * Float(pgr.scale)
            setFontSize(self)
        }
    }


    @objc func showVariantsMenu() {
        
        // Load and configure the font variants menu view controller

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let fvc: FontVariantsTableViewController = storyboard.instantiateViewController(withIdentifier: "font.variants.controller") as! FontVariantsTableViewController
        fvc.dvc = self
        
        // Set the popover's data
        if let fontIndices = self.currentFamily!.fontIndices {
            fvc.fontIndices = fontIndices
            fvc.currentFont = currentFontIndex
        }
        
        // Use the popover presentation style for your view controller.
        fvc.modalPresentationStyle = .popover

        // Specify the anchor point for the popover.
        fvc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        fvc.popoverPresentationController?.delegate = self
                   
        // Present the view controller (in a popover).
        self.present(fvc, animated: true, completion: nil)
    }
    
    
    func getVariantName(_ fontName: String) -> String {
        
        // Extract the font variant from the font name
        
        let name: NSString = fontName as NSString
        let index = name.range(of: "-")
        return index.location != NSNotFound ? (" " + name.substring(from: index.location + 1).capitalized) : " Regular"
    }


    // MARK: - Font Quirks

    func getBungeeTitle(_ fontName: String) -> String {

        // Set Quirk for Bungee, which has non-variant fonts under the same tag

        let name: NSString = fontName as NSString
        let index = name.range(of: "-")
        let variantType = name.substring(from: index.location + 1)
        let range: NSRange = NSRange(location: 6, length: index.location - 6)
        let bungeeName = name.substring(with: range)
        return "Bungee " + (bungeeName != "" ? bungeeName : variantType)
    }
    
    
    func getHanaleiTitle(_ fontName: String) -> String {

        // FROM 1.1.2
        // Set Quirk for Hanalei, which has non-variant fonts under the same tag
        
        var hanaleiName: String = " ";
        if (fontName as NSString).contains("Fill") {
            hanaleiName = " Fill"
        }
        
        return "Hanalei" + hanaleiName + " Regular"
    }


    // MARK: - UITextViewDelegate Functions

    func textViewDidChange(_ textView: UITextView) {

        // FROM 1.1.1
        // If the sample text has changed, record the fact
        self.hasCustomText = true
    }

}


// FROM 1.1.1
// Add alternative (and better) sample text line counter
// Adapted from https://stackoverflow.com/a/49528540
extension NSLayoutManager {
    var lines: Int {
        guard let _ = textStorage else { return 0 }

        var lineCount = 0
        let range = NSMakeRange(0, numberOfGlyphs)
        enumerateLineFragments(forGlyphRange: range) { _, _, _, _, _ in
            lineCount += 1
        }

        return lineCount
    }
}
