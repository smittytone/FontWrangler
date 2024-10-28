
//  IntroViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 10/04/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit


final class IntroViewController: UIViewController {
    
    // A sub-class of UIViewController used to add a close button
    // to the presented view
    
    
    // MARK: - UI Outlet Properties
    
    @IBOutlet weak var ownTextView: UITextView!
    
    
    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // FROM 2.0.0
        // Process the text we'll display
        self.makeDisplayString()
    }
    
    
    // MARK: - Action Functions
    
    @IBAction func doClose(_ sender: Any) {
        
        // Close the Help panel
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    internal func makeDisplayString() {
        
        // Add images to the intro text string
        // NOTE The string uses `#` as an image placeholder
        
        // FROM 2.0.0
        
        var mas: NSMutableAttributedString = NSMutableAttributedString(attributedString: self.ownTextView.attributedText)
        if let image = UIImage.init(systemName: "square.and.arrow.down") {
            mas = self.addImage(mas, 0, image.withTintColor(.label))
        }
        
        if let image = UIImage.init(systemName: "trash") {
            mas = self.addImage(mas, 1, image.withTintColor(.label))
        }
        
        if let image = UIImage.init(systemName: "ellipsis.circle") {
            mas = self.addImage(mas, 2, image.withTintColor(.label))
        }
        
        let range = NSRange(location: 0, length: mas.length)
        mas.addAttribute(NSAttributedString.Key.foregroundColor,
                         value: UIColor.label,
                         range: range)
        
        // Apply the processed text
        self.ownTextView.attributedText = mas
    }
    
    
    internal func addImage(_ text: NSMutableAttributedString, _ imageIndex: Int, _ image: UIImage) -> NSMutableAttributedString {
        
        // Insert the supplied image into the text, replacing the placeholder `#`
    
        // FROM 2.0.0
        
        let nText: NSString = text.string as NSString
        var count: Int = 0
        var range: NSRange = nText.range(of: "#")
        while count <= imageIndex && range.location != NSNotFound {
            if count == imageIndex {
                // We're at the correct placeholder, so remove the placeholder and replace it
                // with an image insertion (the image is the one supplied)
                let leftRange: NSRange = NSMakeRange(0, range.location)
                let left: NSMutableAttributedString = NSMutableAttributedString.init(attributedString: text.attributedSubstring(from: leftRange))
    
                let rightRange = NSMakeRange(range.location + range.length, nText.length - range.location + range.length - 2)
                let right: NSMutableAttributedString = NSMutableAttributedString.init(attributedString: text.attributedSubstring(from: rightRange))
                
                let imageAttachment = NSTextAttachment.init()
                imageAttachment.image = image
                let middle = NSMutableAttributedString(attachment: imageAttachment)

                left.append(middle)
                left.append(right)
                return left
            }
            
            // Move to the next placeholder
            count += 1
            range = nText.range(of: "#")
        }
        
        // If we exit here, the placeholder wasn't found, or the index supplied
        // was incorrect. Just return the source text
        return text
    }
}
