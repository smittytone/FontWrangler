
//  IntroViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 10/04/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit


class IntroViewController: UIViewController {

    // Subclass UIViewController in order to add the close button

    @IBOutlet weak var ownTextView: UITextView!


    override func viewDidLoad() {

        super.viewDidLoad()

        // Update the embedded Attributed String with the correct colour,
        // unobtainable via InterfaceBuilder
        let mas: NSMutableAttributedString = NSMutableAttributedString(attributedString: self.ownTextView.attributedText)
        let range = NSRange(location: 0,
                            length: mas.length)
        mas.addAttribute(NSAttributedString.Key.foregroundColor,
                         value: UIColor.label,
                         range: range)
        self.ownTextView.attributedText = mas
    }


    @IBAction func doClose(_ sender: Any) {

        // Close the Help panel
        
        self.dismiss(animated: true, completion: nil)
    }

}
