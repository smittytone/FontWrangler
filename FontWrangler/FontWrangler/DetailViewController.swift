
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit


class DetailViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    // MARK: - UI properties
    
    @IBOutlet weak var fontStatusLabel: UILabel!
    
    @IBOutlet weak var dynamicSampleHeadLabel: UILabel!
    @IBOutlet weak var dynamicSampleTextView: UITextView!
    @IBOutlet weak var dynamicSampleParentView: UserTestSampleView!
    
    @IBOutlet weak var userSampleHeadLabel: UILabel!
    @IBOutlet weak var userSampleTextView: UITextView!
    
    @IBOutlet weak var fontSizeLabel: UILabel!
    @IBOutlet weak var fontSizeSlider: UISlider!
    

    // MARK: - Object properties
    
    private var substituteFont: UIFont? = nil
    private var variantsButton: UIBarButtonItem? = nil
    private var fontSize: CGFloat = kBaseDynamicSampleFontSize
    private var hasFlipped: Bool = false
    private var dynamicFlipBoundary: CGFloat = 0.0

    var mvc: MasterViewController? = nil
    var currentFamily: FontFamily? = nil
    var currentFontIndex: Int = 0
    
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
        self.dynamicSampleParentView.alpha = 0.3
        self.userSampleTextView.isEditable = false
        self.userSampleTextView.alpha = 0.3

        // Check for on-screen taps to end user sample editing
        let gr: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.doTap))
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
        guard let dynamicHead = self.dynamicSampleHeadLabel else { return }
        guard let sampleNote = self.userSampleTextView else { return }
        guard let sizeLabel = self.fontSizeLabel else { return }
        guard let sizeSlider = self.fontSizeSlider else { return }
        guard let parent = self.dynamicSampleParentView else { return }

        // Generic cases
        sizeSlider.isEnabled = false
        
        if let detail = self.detailItem {
            // We have an item to display, so load the font and register
            // it for this process only
            
            // Set the view title and show the detail
            if self.mvc != nil {
                if self.currentFamily != nil {
                    if detail.tag == "bungee" {
                        // Use Bungee Quirk
                        self.title = self.getBungeeTitle(detail.name)
                    } else {
                        self.title = self.currentFamily!.name + self.getVariantName(detail.name)
                    }
                } else {
                    self.title = self.mvc!.getPrinteableName(detail.name, "-")
                }
            } else {
                self.title = detail.name
            }

            // Prepare the status label
            let ext = (detail.path as NSString).pathExtension.lowercased()
            var labelText: String
            
            if detail.isInstalled {
                sampleNote.isEditable = true
                sampleNote.alpha = 1.0
                parent.alpha = 1.0
                
                // Set the samples' fonts
                dynamicLabel.alpha = 1.0
                dynamicHead.alpha = 1.0
                if let font = UIFont.init(name: detail.name, size: CGFloat(self.fontSize)) {
                    dynamicLabel.font = font
                }
                
                if let font = UIFont.init(name: detail.name, size: KBaseUserSampleFontSize) {
                    sampleNote.font = font
                }
                
                // Set the font size slider control and label
                sizeSlider.isEnabled = true
                sizeLabel.text = "\(Int(self.fontSize))pt"
            } else {
                dynamicLabel.font = self.substituteFont
                dynamicLabel.alpha = 0.3
                dynamicHead.alpha = 0.3
                
                sampleNote.font = substituteFont
                sampleNote.isEditable = false
                sampleNote.alpha = 0.3
                parent.alpha = 0.3
            }
            
            // Set the font status
            labelText = "This " + (ext == "otf" ? "OpenType" : "TrueType" ) + " font is "
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
        } else {
            // Hide the labels; disable the slider
            self.title = "Font Info"
            statusLabel.text = "No font selected"
            sizeLabel.text = ""
            sizeSlider.value = Float(self.fontSize)
            self.variantsButton?.isEnabled = false
        }
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        super.viewWillTransition(to: size, with: coordinator)
        self.dynamicSampleParentView.setNeedsDisplay()
    }

    
    // MARK: - Action Functions
    
    @IBAction func setFontSize(_ sender: Any) {

        // Respond to the user adjusting the font size slider

        // Update the current font size based on the slider value and update the UI
        self.fontSize = CGFloat(Int(self.fontSizeSlider.value))
        //self.fontSizeLabel.text = "\(Int(self.fontSize))pt"

        // Check whether we need to flip between the pre-broken line and unbroken line
        // text strings applied to the view
        if !self.hasFlipped {
            // Not yet flipped, so check for flip condition, ie. number of lines is greater than expected
            // Get the number of displayed lines
            let numLines = Int(self.dynamicSampleTextView.contentSize.height / self.dynamicSampleTextView.font!.lineHeight)

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

        // Update the view
        self.configureView()
    }
    

    @objc func doTap() {

        // End editing of the user sample text view on a tap

        self.userSampleTextView.endEditing(true)
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



}

