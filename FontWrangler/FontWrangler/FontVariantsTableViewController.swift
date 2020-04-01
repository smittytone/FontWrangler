//
//  FontVariantsTableViewController.swift
//  FontWrangler
//
//  Created by Tony Smith on 01/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.
//

import UIKit

class FontVariantsTableViewController: UITableViewController {
    
    
    var fonts: [UserFont]? = nil
    var currentFont: Int = -1
    var dvc: DetailViewController? = nil
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        // Return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Eeturn the number of rows
        if self.fonts == nil {
            return 0
        }
        
        return self.fonts!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: FontVariantsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "variant.cell", for: indexPath) as! FontVariantsTableViewCell
        
        if let fonts: [UserFont] = self.fonts {
            let font: UserFont = fonts[indexPath.row]
            
            // Display the font variant type, extracted from the name:
            // eg. 'Audio-Regular' -> 'Regular'
            let name: NSString = font.name as NSString
            let index = name.range(of: "-")
            cell.name.text = name.substring(from: index.location + 1)
            
            // Back-up, just in case...
            if cell.name.text?.count == 0 {
                cell.name.text = font.name
            }
            
            // Set the current one
            cell.accessoryType = self.currentFont == indexPath.row ? .checkmark : .none
        }

        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let fonts: [UserFont] = self.fonts {
            let font: UserFont = fonts[indexPath.row]
            self.dvc!.detailItem = font
        }
        
        self.dismiss(animated: true, completion: nil)
    }

}
