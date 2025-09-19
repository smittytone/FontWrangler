/*
 *  DetailViewController.swift
 *  Fontismo
 *
 *  Created by Tony Smith on 27/03/2020.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

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


    // MARK: - Public Properties

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


    // MARK: - Private properties

    private var substituteFont: UIFont? = nil
    private var variantsButton: UIBarButtonItem? = nil
    private var fontSize: CGFloat = FONTISMO_CONSTANTS.FONT_DYNAMIC_SIZE
    private var hasFlipped: Bool = false
    private var dynamicFlipBoundary: CGFloat = 0.0
    private var storeSliderValue: Float = Float(FONTISMO_CONSTANTS.FONT_DYNAMIC_SIZE)


    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let rightButton = UIBarButtonItem(title: "Variations",
                                          style: .plain,
                                          target: self,
                                          action: #selector(self.showVariantsMenu))
        self.navigationItem.rightBarButtonItem = rightButton
        self.variantsButton = rightButton

        // Set the base size
        self.substituteFont = UIFont(name: "Arial", size: FONTISMO_CONSTANTS.FONT_SAMPLE_SIZE)
        self.fontSize = FONTISMO_CONSTANTS.FONT_DYNAMIC_SIZE
        self.fontSizeSlider.value = Float(self.fontSize)
        self.fontSizeLabel.text = "\(Int(self.fontSize))pt"
        
        // Set the font sample text
        self.dynamicSampleTextView.text = FONTISMO_CONSTANTS.FONT_SAMPLE[0]
        self.dynamicSampleTextView.isEditable = true
        self.dynamicSampleTextView.alpha = 0.3
        self.dynamicSampleTextView.textContainer.lineBreakMode = .byCharWrapping

        // Style the download panel
        self.downloadView.layer.cornerRadius = 16
        
        // Check for on-screen taps to end user sample editing
        let tapRec = UITapGestureRecognizer(target: self, action: #selector(self.doTap))
        self.view?.addGestureRecognizer(tapRec)

        // FROM 1.1.0
        // Add pinch-to-zoom for font scaling
        let pinchRec = UIPinchGestureRecognizer(target: self, action: #selector(self.doSwipe))
        self.view?.addGestureRecognizer(pinchRec)
        
        // Configure the detail view
        configureView()
        
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
                // Font not installed, so either install it automatically,
                // or offer to install it
                if self.shouldAutoInstallFonts {
                    // Don't ask, just perform the install
                    installCurrentFamily()
                } else {
                    // Offer the installation as a choice
                    queryInstall()
                }
            }
        }
    }


    // MARK: - Presentation Functions

    /**
     Update the user interface for the detail item.
     */
    func configureView() {

        // FROM 2.1.0
        // Make sure this UI update code runs on the main thread
        DispatchQueue.main.async(qos: .userInteractive) {
            // Make sure we can access the UI items -- they may not have been
            // instantiated, if 'self.detailItem' is set before the view loads
            guard let statusLabel = self.fontStatusLabel else { return }
            guard let sampleText = self.dynamicSampleTextView else { return }
            guard let sampleHead = self.dynamicSampleHeadLabel else { return }
            guard let sizeLabel = self.fontSizeLabel else { return }
            guard let sizeSlider = self.fontSizeSlider else { return }
            guard let unImage = self.uninstalledPreviewImage else { return }
            guard let dloadView = self.downloadView else { return }

            // FROM 2.0.0
            // Turn off the indicator and hide
            // Turn off the indicator and hide
            if !dloadView.isHidden {
                dloadView.doHide()
            }

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
                    if let font: UIFont = UIFont(name: detail.psname, size: self.fontSize) {
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
                        if let image: UIImage = UIImage(named: "preview_" + cf.tag) {
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
                // if !detail.isInstalled { queryInstall() }
            } else {
                // Hide the labels; disable the slider
                self.title = "Typeface Info"
                statusLabel.text = "No variant selected"
                sizeLabel.text = ""
                sizeSlider.value = Float(self.fontSize)
                sizeSlider.isEnabled = false
                self.variantsButton?.isEnabled = false
            }
        } /* END OF CLOSURE */
    }


    /**
     Offer to install the current family if it has not yet been installed.

     FROM 1.1.0
     */
    private func queryInstall() {

        // FROM 2.1.0
        // Make sure this UI update code runs on the main thread
        DispatchQueue.main.async(qos: .userInteractive) {
            // Create and present an alert with two buttons
            if let cf: FontFamily = self.currentFamily {
                let alert = UIAlertController(title: "",
                                              message: "This typeface family is not installed. Dynamic previews are not enabled for uninstalled typefaces. Would you like to install \(cf.name) now?",
                                              preferredStyle: .alert)

                // Add choice: YES
                var alertButton = UIAlertAction(title: "Yes", style: .default) { (action) in
                    // Install the font
                    self.installCurrentFamily()
                }
                alert.addAction(alertButton)

                // Add choice: NO
                alertButton = UIAlertAction(title: "No", style: .cancel, handler: nil)
                alert.addAction(alertButton)

                // Show the alert
                self.present(alert, animated: true, completion: nil)
            }
        }
    }


    /**
     If a single family has been tapped in the master view, we set the value
     of `currentFamily`. If it has been set, run the install process for it.
     */
    private func installCurrentFamily() {
        
        if let cf: FontFamily = self.currentFamily {
            // Show the download status panel (this view only)
            if Thread.isMainThread {
                self.downloadView.doShow()
            } else {
                DispatchQueue.main.sync {
                    self.downloadView.doShow()
                }
            }

            // Get the current family
            self.mvc!.currentInstallCount = 1
            self.mvc!.getOneFontFamily(cf)
        }
    }


    // MARK: - Action Functions

    /**
     Respond to the user adjusting the font size slider.
     */
    @IBAction
    private func setFontSize(_ sender: Any) {

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

                if numLines > FONTISMO_CONSTANTS.FONT_SAMPLE_LINES && self.fontSize > CGFloat(FONTISMO_CONSTANTS.FONT_SAMPLE_LIMIT) {
                    // At least one line has wrapped, so trigger a flip:
                    // Use the un-broken text so it wraps right: no orphans
                    self.dynamicSampleTextView.text = FONTISMO_CONSTANTS.FONT_SAMPLE[1]
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
                    self.dynamicSampleTextView.text = FONTISMO_CONSTANTS.FONT_SAMPLE[0]
                    self.hasFlipped = false
                }
            }
        }

        // Update the view
        // configureView()
        self.fontSizeLabel.text = "\(Int(self.fontSize))pt"
        if let font: UIFont = UIFont(name: self.detailItem!.psname, size: self.fontSize) {
            self.dynamicSampleTextView.font = font
        }
    }


    /**
     End editing of the user sample text view on a tap.
     */
    @objc
    private func doTap() {

        if let dstv = self.dynamicSampleTextView {
            dstv.endEditing(true)
        }
    }


    /**
     Triggered by the pinch gesture on the main view.

     FROM 1.1.0
     */
    @objc
    private func doSwipe(_ pgr: UIPinchGestureRecognizer) {

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


    /**
     Stop the download process if the user has cancelled it.
     */
    func doCancelInstall() {
        
        // FROM 2.1.0
        // Make sure this UI changing function runs on the main thread
        if Thread.isMainThread {
            self.downloadView.doHide(true)
        } else {
            DispatchQueue.main.sync {
                self.downloadView.doHide(true)
            }
        }
    }


    /**
     Load and configure the font variants menu view controller.
     */
    @objc
    private func showVariantsMenu() {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let fvtvc: FontVariantsTableViewController = storyboard.instantiateViewController(withIdentifier: "font.variants.controller") as! FontVariantsTableViewController
        fvtvc.dvc = self
        
        // Set the popover's data
        if let fontIndices: [Int] = self.currentFamily!.fontIndices {
            fvtvc.fontIndices = fontIndices
            fvtvc.currentFont = self.currentFontIndex
        }
        
        // Use the popover presentation style for your view controller.
        fvtvc.modalPresentationStyle = .popover

        // Specify the anchor point for the popover.
        fvtvc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        fvtvc.popoverPresentationController?.delegate = self
                   
        // Present the view controller (in a popover).
        self.present(fvtvc, animated: true, completion: nil)
    }


    /**
     Extract the font variant from the font name.
     */
    private func getVariantName(_ fontName: String) -> String {
        
        let name: NSString = fontName as NSString
        let index: NSRange = name.range(of: "-")
        return index.location != NSNotFound ? (" " + name.substring(from: index.location + 1).capitalized) : " Regular"
    }


    // MARK: - Font Quirks
    
    /*
     These are routines called for handling individual fonts with non-standard naming.
     */

    /**
     Set Quirk for Bungee, which has non-variant fonts under the same tag.
     */
    private func getBungeeTitle(_ fontName: String) -> String {

        let name: NSString = fontName as NSString
        let index: NSRange = name.range(of: "-")
        let variantType: String = name.substring(from: index.location + 1)
        let range: NSRange = NSRange(location: 6, length: index.location - 6)
        let bungeeName: String = name.substring(with: range)
        return "Bungee " + (bungeeName != "" ? bungeeName : variantType)
    }


    /**
     Set Quirk for Hanalei, which has non-variant fonts under the same tag.

     FROM 1.1.2
     */
    private func getHanaleiTitle(_ fontName: String) -> String {

        var hanaleiName: String = " ";
        if (fontName as NSString).contains("Fill") {
            hanaleiName = " Fill"
        }
        
        return "Hanalei" + hanaleiName + " Regular"
    }


    /**
     Set Quirk for FiraCode, which has non-variant fonts under the same tag.

     FROM 2.0.0
     */
    private func getFiraCodeTitle(_ fontName: String) -> String {

        let name: NSString = fontName as NSString
        let index: NSRange = name.range(of: "-")
        let variantType: String = self.getFiraCodeVariant(name.substring(from: index.location + 1))
        return "FiraCode " + variantType
    }


    /**
     Set Quirk for FiraCode, which has mis-named font variants.

     FROM 2.0.0
     */
    func getFiraCodeVariant(_ initial: String) -> String {
        
        if initial == "Reg" { return "Regular" }
        if initial == "Med" { return "Medium" }
        if initial == "SemBd" { return "SemiBold" }
        return initial
    }


    /**
     Set Quirk for Roboto Mono NFM, which has mis-named font variants.

     FROM 2.0.0
     */
    private func getRobotoMonoTitle(_ fontName: String) -> String {
        
        let fvtvc: FontVariantsTableViewController = FontVariantsTableViewController()
        return "Roboto Mono NF " + fvtvc.getRobotoMonoVarName(fontName)
    }


    /**
     Set Quirk for Iosevka, which has non-variant fonts under the same tag.

     FROM 2.0.0
     */
    private func getNerdFontTitle(_ fontName: String, _ familyName: String) -> String {

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

    /**
     If the sample text has changed (the user has entered something), record the fact.

     FROM 1.1.1
     */
    func textViewDidChange(_ textView: UITextView) {

        self.hasCustomText = true
    }


    /*
     LEGACY FUNCTIONS
     */

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
}
