
//  Created by Tony Smith on 01/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit


class FontVariantsTableViewController: UITableViewController {
    
    // This table View Controller manages the font variants menu if it is
    // enabled by the detail view controller - ie. if the selected font
    // has variants, eg. Regular, Bold, Italic, etc.
    // The user can select a variant to demo that specific font
    
    
    // MARK: - Object properties
    
    var fonts: [UserFont]? = nil
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
        return self.fonts == nil ? 0 : self.fonts!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: FontVariantsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "variant.cell", for: indexPath) as! FontVariantsTableViewCell
        
        if let fonts: [UserFont] = self.fonts {
            let font: UserFont = fonts[indexPath.row]
            
            if font.tag == "bungee" {
                // Set Quirk for Bungee, which has non-variant fonts under the same tag
                let name: NSString = font.name as NSString
                let index = name.range(of: "-")
                let variantType = name.substring(from: index.location + 1)
                let range: NSRange = NSRange(location: 6, length: index.location - 6)
                let fontName = name.substring(with: range)
                cell.name.text = (fontName != "" ? fontName : variantType)
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
        if let fonts: [UserFont] = self.fonts {
            let font: UserFont = fonts[indexPath.row]
            self.dvc!.detailItem = font
        }
        
        self.dismiss(animated: true, completion: nil)
    }

}
