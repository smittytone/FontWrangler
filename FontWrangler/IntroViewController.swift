
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

        // Update the embedded attributed string with the correct colour,
        // unobtainable via InterfaceBuilder
        let mas: NSMutableAttributedString = NSMutableAttributedString(attributedString: self.ownTextView.attributedText)
        let range = NSRange(location: 0,
                            length: mas.length)
        mas.addAttribute(NSAttributedString.Key.foregroundColor,
                         value: UIColor.label,
                         range: range)
        self.ownTextView.attributedText = mas
    }


    // MARK: - Action Functions
    
    @IBAction func doClose(_ sender: Any) {

        // Close the Help panel
        
        self.dismiss(animated: true, completion: nil)
    }

}
