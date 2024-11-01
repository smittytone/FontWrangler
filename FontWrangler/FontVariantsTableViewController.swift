
//  FontVariantsTableViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 01/04/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit


final class FontVariantsTableViewController: UITableViewController {
    
    // This UITableViewController manages the font variants menu if it is
    // enabled by the detail view controller - ie. if the selected font
    // has variants, eg. Regular, Bold, Italic, etc.
    //
    // The user can select a variant to demo that specific font
    
    
    // MARK: - Public Properties
    
    var fontIndices: [Int]? = nil
    var currentFont: Int = -1
    var dvc: DetailViewController? = nil

    
    // MARK: - Lifecycle Functions
    
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
            let font: UserFont = self.dvc!.mvc!.fonts[fontIndexes[indexPath.row]]
            
            if font.tag == "bungee" {
                // Set Quirk for Bungee, which has non-variant fonts under the same tag
                cell = self.processBungee(cell, font)
            } else if font.tag == "hanalei" {
                // Set Quirk for Hanalei, which has non-variant fonts under the same tag
                cell = self.processHanalei(cell, font)
            } else if font.tag.hasPrefix("iosevka_") {
                // Set Quirk for Iosevka Term and Iosevka Term Slab: its regular font has no `_Regular`
                cell = self.processIosevka(cell, font)
            } else if font.tag == "roboto_mono_nfm" {
                cell.name.text = getRobotoMonoVarName(font.name)
            } else {
                // Display the font variant type, extracted from the name:
                // eg. 'Audio-Regular' -> 'Regular'
                let name: NSString = font.name as NSString
                let index = name.range(of: "-")
                cell.name.text = name.substring(from: index.location + 1)
                
                // FROMM 2.0.0
                // Apply variant quirks
                cell.name.text = self.dvc!.getFiraCodeVariant(cell.name.text!)
                
                // Back-up, just in case...
                if cell.name.text?.count == 0 {
                    cell.name.text = font.name
                }
                
                // FROM 2.0.0
                // Don't allow variant selection if the font is not installed
                cell.name.isEnabled = font.isInstalled
                cell.tintColor = font.isInstalled ? .systemBlue : .lightGray
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

    private func processBungee(_ cell: FontVariantsTableViewCell, _ font: UserFont) -> FontVariantsTableViewCell {

        let name: NSString = font.name as NSString
        let index: NSRange = name.range(of: "-")
        let variantType: String = name.substring(from: index.location + 1)
        let range: NSRange = NSRange(location: 6, length: index.location - 6)
        let fontName: String = name.substring(with: range)
        cell.name.text = (fontName != "" ? fontName : variantType)
        return cell
    }
    
    
    private func processHanalei(_ cell: FontVariantsTableViewCell, _ font: UserFont) -> FontVariantsTableViewCell {

        // FROM 1.1.2
        
        var hanaleiName: String = "";
        if (font.name as NSString).contains("Fill") {
            hanaleiName = "Fill "
        }
        
        cell.name.text = hanaleiName + "Regular"
        return cell
    }
    
    
    private func processIosevka(_ cell: FontVariantsTableViewCell, _ font: UserFont) -> FontVariantsTableViewCell {
        
        // FROM 2.0.0
        // Deal with the fact that Ioskeva Term and Iosevka Term Slab Regular have no `-regular` in its PostScript name
        
        let name: NSString = font.name as NSString
        let index: NSRange = name.range(of: "-")
        if index.location == NSNotFound {
            cell.name.text = "Regular"
        } else {
            cell.name.text = name.substring(from: index.location + 1)
        }
        
        return cell
    }
    
    
    func getRobotoMonoVarName(_ name: String) -> String {
        
        // FROM 2.0.0
        // Deal with the fact that Roboto Mono has non-standard style PostScript name suffixes
        
        var varName: String
        let nsName: NSString = name as NSString
        let index: NSRange = nsName.range(of: "-")
        if index.location != NSNotFound {
            varName = nsName.substring(from: index.location + 1)
            varName = varName.replacingOccurrences(of: "Bd", with: "Bold")
            varName = varName.replacingOccurrences(of: "It", with: "Italic")
            varName = varName.replacingOccurrences(of: "Sm", with: "Semi")
            varName = varName.replacingOccurrences(of: "Lt", with: "Light")
            varName = varName.replacingOccurrences(of: "Rg", with: "Regular")
            varName = varName.replacingOccurrences(of: "Th", with: "Thin")
            varName = varName.replacingOccurrences(of: "Md", with: "Medium")
        } else {
            varName = "Regular"
        }
        
        return varName
    }
}
