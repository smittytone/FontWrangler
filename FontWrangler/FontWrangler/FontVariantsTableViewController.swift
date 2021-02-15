
//  FontVariantsTableViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 01/04/2020.
//  Copyright © 2021 Tony Smith. All rights reserved.


import UIKit


class FontVariantsTableViewController: UITableViewController {
    
    // This table View Controller manages the font variants menu if it is
    // enabled by the detail view controller - ie. if the selected font
    // has variants, eg. Regular, Bold, Italic, etc.
    // The user can select a variant to demo that specific font
    
    
    // MARK: - Object properties
    
    var fontIndices: [Int]? = nil
    var currentFont: Int = -1
    var dvc: DetailViewController? = nil

    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
    }

    
    // MARK: - Table View Data Source Functions

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        // Return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Return the number of rows
        return self.fontIndices == nil ? 0 : self.fontIndices!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: FontVariantsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "variant.cell", for: indexPath) as! FontVariantsTableViewCell
        
        if let fontIndexes: [Int] = self.fontIndices {
            let font: UserFont = dvc!.mvc!.fonts[fontIndexes[indexPath.row]]
            
            if font.tag == "bungee" {
                // Set Quirk for Bungee, which has non-variant fonts under the same tag
                cell = self.doBungee(cell, font)
            } else if font.tag == "hanalei" {
                // Set Quirk for Hanalei, which has non-variant fonts under the same tag
                cell = self.doHanalei(cell, font)
            } else {
                // Display the font variant type, extracted from the name:
                // eg. 'Audio-Regular' -> 'Regular'
                let name: NSString = font.name as NSString
                let index = name.range(of: "-")
                cell.name.text = name.substring(from: index.location + 1)
                
                // Back-up, just in case...
                if cell.name.text?.count == 0 {
                    cell.name.text = font.name
                }
            }
            
            // Tick the current variant
            cell.accessoryType = self.currentFont == indexPath.row ? .checkmark : .none
        }

        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Update the (underlying) detail view with the newly selected variant
        if let fontIndexes: [Int] = self.fontIndices {
            if let advc = self.dvc {
                if let amvc = advc.mvc {
                    let font: UserFont = amvc.fonts[fontIndexes[indexPath.row]]
                    advc.detailItem = font
                    advc.currentFontIndex = indexPath.row
                    self.currentFont = indexPath.row
                    //advc.configureView()
                    
                    #if DEBUG
                        print("Font selected '\(font.name)' at row \(indexPath.row)")
                    #endif
                }
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }


    // MARK: - Font Quirks

    func doBungee(_ cell: FontVariantsTableViewCell, _ font: UserFont) -> FontVariantsTableViewCell {

        let name: NSString = font.name as NSString
        let index = name.range(of: "-")
        let variantType = name.substring(from: index.location + 1)
        let range: NSRange = NSRange(location: 6, length: index.location - 6)
        let fontName = name.substring(with: range)
        cell.name.text = (fontName != "" ? fontName : variantType)
        return cell
    }
    
    
    func doHanalei(_ cell: FontVariantsTableViewCell, _ font: UserFont) -> FontVariantsTableViewCell {

        // FROM 1.1.2
        
        var hanaleiName: String = "";
        if (font.name as NSString).contains("Fill") {
            hanaleiName = "Fill "
        }
        
        cell.name.text = hanaleiName + "Regular"
        return cell
    }
}
