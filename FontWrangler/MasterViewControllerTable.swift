
//  MasterViewControllerTable.swift
//  FontWrangler
//  UITableViewDelegate and UITableViewDataSource functions
//
//  Created by Tony Smith on 17/10/2024.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit


extension MasterViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        // Just return 1
        
        return 1
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        self.subFamilies.removeAll()
        
        // Show all is a match against any criteria, but we can shortcut just
        // by checking that all viewStates are true.
        if !self.viewStates.values.contains(false) {
            self.subFamilies = self.families
            return self.subFamilies.count
        }
        
        // Iterate over the list of families. Check if any of the criteria are met:
        // if so, add the family to the display list, `subFamilies`.
        for family in self.families {
            var includeFamily: Bool = false
            for viewState in self.viewStates {
                if viewState.value {
                    if family.style == viewState.key {
                        includeFamily = true
                    }
                }
            }
            
            if includeFamily {
                self.subFamilies.append(family)
            }
        }
        
        return self.subFamilies.count
    }


    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        // Return the custom table header row
        //let fittingSize = CGSize(width: tableView.frame.width - (tableView.safeAreaInsets.left + tableView.safeAreaInsets.right), height: 0)
        //let size = self.tableHead.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        //self.tableHead.frame = CGRect(origin: .zero, size: size)
        
        self.tableHead.parent = tableView
        //let r = tableView.rectForHeader(inSection: section)
        //self.tableHead.frame = r
        return self.tableHead
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Return the requested table cell
        
        if indexPath.row == 999 {
            // Show the header cell
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "header.cell", for: indexPath)
            return cell
        } else {
            // Show a font cell
            let cell: FontWranglerFontListTableViewCell = tableView.dequeueReusableCell(withIdentifier: "custom.cell",
                                                                                        for: indexPath) as! FontWranglerFontListTableViewCell
            
            // Get the referenced family and use its name
            // NOTE Name is already human-readable
            let family = self.subFamilies[indexPath.row]
            
            // FROM 1.2.0
            // Highlight new fonts
            if family.isNew && self.doIndicateNewFonts {
                let labelString = NSMutableAttributedString(string: family.name + " ")
                let imageAttachment: NSTextAttachment = NSTextAttachment.init()
                if let sealImage = UIImage.init(systemName: "checkmark.seal.fill") {
                    imageAttachment.image = sealImage.withTintColor(UIColor.systemBlue)
                    let imageString = NSAttributedString(attachment: imageAttachment)
                    labelString.append(imageString)
                }
                cell.fontNameLabel!.attributedText = labelString
            } else {
                cell.fontNameLabel!.text = family.name
            }

            // Get all the fonts in the family
            if let fontIndexes: [Int] = family.fontIndices {
                // Update the number of fonts in the family
                cell.fontCountLabel.text = "\(fontIndexes.count) " + (fontIndexes.count == 1 ? "font" : "fonts")

                // Get the first font in the list, which should have the same
                // status as the others
                // TODO handle cases where it is not the same
                //let font: UserFont = fonts[0]

                if family.fontsAreInstalled {
                    // Add a circled tick as the accessory if the font is installed
                    if let accessoryImage: UIImage = UIImage.init(systemName: "checkmark.circle.fill") {
                        let accessoryView: UIView = UIImageView.init(image: accessoryImage)
                        cell.accessoryView = accessoryView
                    } else {
                        cell.accessoryView = nil
                    }
                } else {
                    // Family is not installed, so add a spacer to ensure consitent column widths
                    if let accessoryImage: UIImage = UIImage.init(named: "spacer") {
                        let accessoryView: UIView = UIImageView.init(image: accessoryImage)
                        cell.accessoryView = accessoryView
                    } else {
                        cell.accessoryView = nil
                    }
                }
                
                // Show and animate the Activity Indicator during downloads
                if family.progress != nil {
                    if !cell.downloadProgressView.isAnimating {
                        cell.downloadProgressView!.startAnimating()
                    }
                } else {
                    if cell.downloadProgressView.isAnimating {
                        cell.downloadProgressView!.stopAnimating()
                    }
                }
            } else {
                // Display a default font count, but this should never be seen
                cell.fontCountLabel.text = "No fonts"
            }
            
            // Set preview image using the font family's tags
            cell.fontPreviewImageView.image = UIImage.init(named: family.tag)
            
            // FROM 2.0.0 Set the image tint as we're now using template images
            cell.fontPreviewImageView.tintColor = .label
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        // Actions that appear when the table view cell is swiped L-R
        // NOTE These actions affect all families
    
        var config: UISwipeActionsConfiguration? = nil
        var actions = [UIContextualAction]()
        var action: UIContextualAction = UIContextualAction.init(style: .destructive,
                                         title: "") { (theAction, theView, handler) in
                                            // Check that there are fonts to be removed
                                            if self.anyFontsInstalled() {
                                                // Remove the installed fonts
                                                let alert = UIAlertController.init(title: "Are You Sure?",
                                                                                   message: "Tap OK to uninstall all the typefaces, or Cancel to quit. You can reinstall uninstalled typefaces at any time.",
                                                                                   preferredStyle: .alert)
                                                
                                                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Default action"),
                                                                                style: .default,
                                                                                handler: nil))
                                                
                                                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                                                              style: .default,
                                                                              handler: { (action) in
                                                    self.removeAll()
                                                }))
                                                
                                                self.present(alert,
                                                             animated: true,
                                                             completion: nil)
                                            } else {
                                                self.showAlert("No Typefaces Installed", "You have not yet installed any of the available typefaces")
                                            }
                                            
                                            handler(true)
        }
        action.image = UIImage.init(systemName: "trash")
        actions.append(action)
        
        // Configure an 'Add All' action
        action = UIContextualAction.init(style: .normal,
                                         title: "") { (theAction, theView, handler) in
                                            // Check that there are fonts to be installed
                                            if self.allFontsInstalled() {
                                                self.showAlert("All Typefaces Installed", "You have already installed all of the available typefaces")
                                            } else {
                                                // Install any remaining fonts
                                                self.installAll(self)
                                            }
                                            
                                            handler(true)
        }
        action.image = UIImage(systemName: "square.and.arrow.down.on.square")

        // Set the colour to blue
        action.backgroundColor = UIColor.systemBlue
        actions.append(action)
        
        // Create the config to be returned, making sure a full swipe DOESN'T auto-trigger
        config = UISwipeActionsConfiguration.init(actions: actions)
        config?.performsFirstActionWithFullSwipe = false
        return config
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Actions that appear when the table view cell is swiped R-Ls
        // NOTE These actions are family specific

        var config: UISwipeActionsConfiguration? = nil
        var action: UIContextualAction

        // Get the referenced family
        let family: FontFamily = self.families[indexPath.row]

        // Show the controls only if we're not already downloading
        if family.progress == nil {
            if family.fontsAreInstalled {
                // Configure a 'Remove' action -- only one item affected: the table view cell's family
                action = UIContextualAction.init(style: .destructive,
                                                 title: "") { (theAction, theView, handler) in
                                                    // Remove the single, row-referenced font
                                                    self.removeOneFontFamily(family)
                                                    handler(true)
                }
                action.image = UIImage.init(systemName: "trash")
            } else {
                // Configure an 'Add' action -- only one item affected: the table view cell's
                action = UIContextualAction.init(style: .normal,
                                                 title: "") { (theAction, theView, handler) in
                                                    // Install the single, row-referenced font
                                                    self.getOneFontFamily(family)
                                                    handler(true)
                }
                action.image = UIImage.init(systemName: "square.and.arrow.down")
                
                // Set the colour to blue
                action.backgroundColor = UIColor.systemBlue
            }

            // Create the config to be returned, making sure a full swipe DOESN'T auto-trigger
            config = UISwipeActionsConfiguration.init(actions: [action])
        }

        config?.performsFirstActionWithFullSwipe = false
        return config
    }
}
