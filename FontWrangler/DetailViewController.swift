
//  DetailViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit


class DetailViewController: UIViewController,
                            UIPopoverPresentationControllerDelegate,
                            UITextViewDelegate {

    // MARK: - UI properties
    
    @IBOutlet weak var fontStatusLabel: UILabel!
    
    @IBOutlet weak var dynamicSampleHeadLabel: UILabel!
    @IBOutlet weak var dynamicSampleTextView: UITextView!
    @IBOutlet weak var uninstalledPreviewImage: UIImageView!

    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var fontSizeSlider: UISlider!

    @IBOutlet weak var downloadProgress: UIActivityIndicatorView!
    
    @IBOutlet weak var downloadView: RetrievalView!

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
    // FROM 2.0.0
    var shouldAutoInstallFonts: Bool = false

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
        self.dynamicSampleTextView.textContainer.lineBreakMode = .byCharWrapping
        
        self.downloadView.layer.cornerRadius = 16
        
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
        
        // Set the preview image tint as we're now using template images
        self.uninstalledPreviewImage.tintColor = .label

        // Show the master view
        self.splitViewController?.toggleMasterView()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        // FROM 2.0.0
        if let detail: UserFont = self.detailItem {
            if !detail.isInstalled {
                // Font not installed, so offer to install it
                if self.shouldAutoInstallFonts {
                    // Don't ask: perform the install automatically
                    self.installCurrentFamily()
                } else {
                    // Ask: dffer the installation as a choice
                    self.doInstall()
                }
            }
        }
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
        guard let unImage = self.uninstalledPreviewImage else { return }
        guard let dloadView = self.downloadView else { return }
        
        // REMOVED IN 1.1.0
        // guard let sampleNote = self.userSampleTextView else { return }
        // guard let parent = self.dynamicSampleParentView else { return }

        // FROM 2.0.0
        // Turn off the indicator and hide
        // dloadProgress.stopAnimating()
        dloadView.doHide()
        
        if let detail = self.detailItem {
            // We have an item to display, so load the font and register
            // it for this process only
            
            // Set the view title and show the detail
            if self.mvc != nil {
                if self.currentFamily != nil {
                    if detail.tag == "bungee" {
                        // Use Bungee quirk
                        self.title = self.getBungeeTitle(detail.name)
                    } else if detail.tag == "hanalei" {
                        // Use Hanalei quirk
                        self.title = self.getHanaleiTitle(detail.name)
                    } else if detail.tag == "fira_code_nfm" {
                        // Use Fira Code quirk
                        self.title = self.getFiraCodeTitle(detail.name)
                    } else if detail.tag == "roboto_mono_nfm" {
                        self.title = self.getRobotoMonoTitle(detail.name)
                    } else if detail.tag.contains("_nfm") {
                        // Use quirk for other Nerd Fonts
                        self.title = self.getNerdFontTitle(detail.name, self.currentFamily!.name)
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
                // Set the sample's font
                if let font: UIFont = UIFont.init(name: detail.psname, size: self.fontSize) {
                    sampleText.font = font
                }
                
                sampleText.alpha = 1.0
                sampleText.isHidden = false
                
                // Set the font size slider control and label
                sizeLabel.text = "\(Int(self.fontSize))pt"
                sizeSlider.setValue(Float(self.fontSize), animated: true)
                sizeSlider.tintColor = .systemBlue
                sizeSlider.isEnabled = true
                
                // FROM 2.0.0
                unImage.isHidden = true
            } else {
                // sampleText.font = self.substituteFont
                // sampleText.alpha = 0.3
                sampleText.isHidden = true
                
                sizeLabel.text = ""
                sizeSlider.isEnabled = false
                sizeSlider.tintColor = .gray
                
                // FROM 2.0.0
                // Use graphic preview for uninstalled fonts
                if let cf: FontFamily = self.currentFamily {
                    if let image: UIImage = UIImage.init(named: "preview_" + cf.tag) {
                        unImage.image = image
                    }
                }
                
                unImage.alpha = 0.5
                unImage.isHidden = false
            }
            
            // Set the font status label
            // FROM 2.0.0 Remove typeface type
            // let ext = (detail.path as NSString).pathExtension.lowercased()
            // var labelText = "This " + (ext == "otf" ? "OpenType" : "TrueType" ) + " font is "
            var labelText: String = "This typeface is "
            labelText += (detail.isInstalled ? "installed" : "not installed")
            statusLabel.text = labelText
            
            // Enable or disable the Variants button according to whether there are any
            var count = 0
            if let cf: FontFamily = self.currentFamily {
                if let familyFonts: [Int] = cf.fontIndices {
                    count = familyFonts.count
                }
                
                // Set the creator
                sampleHead.text = "Created by \(cf.creator)"
            }

            self.variantsButton?.isEnabled = count > 1 ? true : false

            // REMOVED 2.0.0
            // Font not installed, so offer to install it
            // if !detail.isInstalled { doInstall() }
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


    private func doInstall() {

        // FROM 1.1.0
        // Offer to install the font if it has not yet been installed

        // Create and present an alert with two buttons
        if let cf: FontFamily = self.currentFamily {
            let alert = UIAlertController.init(title: "",
                                               message: "This font family is not installed. Dynamic previews are not enabled for uninstalled fonts. Would you like to install \(cf.name) now?",
                                               preferredStyle: .alert)

            var alertButton = UIAlertAction.init(title: "Yes",
                                                 style: .default) { (action) in
                // Install the font
                self.installCurrentFamily()
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
    
    
    private func installCurrentFamily() {
        
        // If a single family has been tapped in the master view, we set the value
        // of `currentFamily`. If it has been set, run the install process for it.
        
        if let cf: FontFamily = self.currentFamily {
            // Install the font family
            // self.downloadProgress.startAnimating()
            self.downloadView.doShow()
            self.mvc!.getOneFontFamily(cf)
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
    
    @IBAction private func setFontSize(_ sender: Any) {

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
                let numLines: Int = self.dynamicSampleTextView.layoutManager.lines

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
        if let font: UIFont = UIFont.init(name: self.detailItem!.psname, size: self.fontSize) {
            self.dynamicSampleTextView.font = font
        }
    }
    

    @objc private func doTap() {

        // End editing of the user sample text view on a tap

        if let dstv = self.dynamicSampleTextView {
            dstv.endEditing(true)
        }
    }


    @objc private func doSwipe(_ pgr: UIPinchGestureRecognizer) {

        // FROM 1.1.0
        // Triggered by the pinch gesture on the main view
        guard pgr.view != nil else { return }
        
        // FROM 2.0.0
        // Don't accept gestures on non-dynamic previews
        if self.detailItem == nil || !self.detailItem!.isInstalled {
            return
        }

        // Store the current size: we will scale from this value
        if pgr.state == .began {
            self.storeSliderValue = self.fontSizeSlider.value
        }

        // Apply the scale if the pinch distance changes
        if pgr.state == .began || pgr.state == .changed {
            // Set the slider and then trigger the action function
            self.fontSizeSlider.value = self.storeSliderValue * Float(pgr.scale)
            setFontSize(self)
        }
    }
    
    
    func doCancelInstall() {
        
        // Stop the download process if the user has cancelled it
        // self.downloadProgress.stopAnimating()
        self.downloadView.doHide()
    }


    @objc private func showVariantsMenu() {
        
        // Load and configure the font variants menu view controller

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let fvtvc: FontVariantsTableViewController = storyboard.instantiateViewController(withIdentifier: "font.variants.controller") as! FontVariantsTableViewController
        fvtvc.dvc = self
        
        // Set the popover's data
        if let fontIndices: [Int] = self.currentFamily!.fontIndices {
            fvtvc.fontIndices = fontIndices
            fvtvc.currentFont = currentFontIndex
        }
        
        // Use the popover presentation style for your view controller.
        fvtvc.modalPresentationStyle = .popover

        // Specify the anchor point for the popover.
        fvtvc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        fvtvc.popoverPresentationController?.delegate = self
                   
        // Present the view controller (in a popover).
        self.present(fvtvc, animated: true, completion: nil)
    }
    
    
    private func getVariantName(_ fontName: String) -> String {
        
        // Extract the font variant from the font name
        
        let name: NSString = fontName as NSString
        let index: NSRange = name.range(of: "-")
        return index.location != NSNotFound ? (" " + name.substring(from: index.location + 1).capitalized) : " Regular"
    }


    // MARK: - Font Quirks
    
    /*
     These are routines called for handling individual fonts with non-standard naming.
     */

    private func getBungeeTitle(_ fontName: String) -> String {

        // Set Quirk for Bungee, which has non-variant fonts under the same tag

        let name: NSString = fontName as NSString
        let index: NSRange = name.range(of: "-")
        let variantType: String = name.substring(from: index.location + 1)
        let range: NSRange = NSRange(location: 6, length: index.location - 6)
        let bungeeName: String = name.substring(with: range)
        return "Bungee " + (bungeeName != "" ? bungeeName : variantType)
    }
    
    
    private func getHanaleiTitle(_ fontName: String) -> String {

        // FROM 1.1.2
        // Set Quirk for Hanalei, which has non-variant fonts under the same tag
        
        var hanaleiName: String = " ";
        if (fontName as NSString).contains("Fill") {
            hanaleiName = " Fill"
        }
        
        return "Hanalei" + hanaleiName + " Regular"
    }
    
    
    private func getFiraCodeTitle(_ fontName: String) -> String {

        // FROM 2.0.0
        // Set Quirk for FiraCode, which has non-variant fonts under the same tag
        
        let name: NSString = fontName as NSString
        let index: NSRange = name.range(of: "-")
        let variantType: String = self.getFiraCodeVariant(name.substring(from: index.location + 1))
        return "FiraCode " + variantType
    }
    
    
    func getFiraCodeVariant(_ initial: String) -> String {
        
        // FROM 2.0.0
        // Set Quirk for FiraCode, which has mis-named font variants
        
        if initial == "Reg" { return "Regular" }
        if initial == "Med" { return "Medium" }
        if initial == "SemBd" { return "SemiBold" }
        return initial
    }
    
    
    private func getRobotoMonoTitle(_ fontName: String) -> String {
        
        // FROM 2.0.0
        // Set Quirk for Roboto Mono NFM, which has mis-named font variants
        
        let fvtvc: FontVariantsTableViewController = FontVariantsTableViewController.init()
        return "Roboto Mono NF " + fvtvc.getRobotoMonoVarName(fontName)
    }
    
    
    private func getNerdFontTitle(_ fontName: String, _ familyName: String) -> String {

        // FROM 2.0.0
        // Set Quirk for Iosevka, which has non-variant fonts under the same tag
        
        let name: NSString = fontName as NSString
        let newName: String = "\(familyName) NF"
        let index: NSRange = name.range(of: "-")
        var variantType: String
        if index.location == NSNotFound {
            variantType = "Regular"
        } else {
            variantType = name.substring(from: index.location + 1)
        }
        
        return newName + " " + variantType
    }


    // MARK: - UITextViewDelegate Functions

    func textViewDidChange(_ textView: UITextView) {

        // FROM 1.1.1
        // If the sample text has changed, record the fact
        self.hasCustomText = true
    }

}
