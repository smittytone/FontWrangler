
//  MasterViewControllerTable.swift
//  Fontismo
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
        
        // Return the number of families to display
        
        return self.displayFamilies.count
    }


    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        // Return the custom table header row
        
        self.tableHead.parent = tableView
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
            let family = self.displayFamilies[indexPath.row]
            
            // FROM 1.2.0
            // Highlight new fonts
            if family.isNew && self.doIndicateNewFonts {
                let labelString = NSMutableAttributedString(string: family.name + (family.isNerdFont ? " Nerd Font " : " "))
                let imageAttachment: NSTextAttachment = NSTextAttachment.init()
                if let sealImage = UIImage.init(systemName: "checkmark.seal.fill") {
                    imageAttachment.image = sealImage.withTintColor(UIColor.systemBlue)
                    let imageString = NSAttributedString(attachment: imageAttachment)
                    labelString.append(imageString)
                }
                cell.fontNameLabel!.attributedText = labelString
            } else {
                cell.fontNameLabel!.text = family.name + (family.isNerdFont ? "Nerd Font" : "")
            }

            // Get all the fonts in the family
            if let fontIndexes: [Int] = family.fontIndices {
                // Update the number of fonts in the family
                cell.fontCountLabel.text = "\(fontIndexes.count) " + (fontIndexes.count == 1 ? "font" : "fonts")

                // Set the accessory view
                if family.fontsAreInstalled {
                    // Add a circled tick as the accessory if the font is installed
                    if let accessoryImage: UIImage = UIImage.init(systemName: "checkmark.circle.fill") {
                        let accessoryView: UIView = UIImageView.init(image: accessoryImage)
                        cell.accessoryView = accessoryView
                    } else {
                        cell.accessoryView = nil
                    }
                } else {
                    // Family is not installed: are we downloading it?
                    if family.progress != nil {
                        // FROM 2.0.0
                        // Set an activity indicator as the cell's accessory view
                        let av: UIActivityIndicatorView = UIActivityIndicatorView.init(frame: CGRect.init(x: 0.0, y: 0.0, width: 24.0, height: 24.0))
                        av.color = UIColor.systemBlue
                        av.style = .medium
                        av.contentMode = .scaleToFill
                        av.startAnimating()
                        cell.accessoryView = av
                    } else if let accessoryImage: UIImage = UIImage.init(named: "spacer") {
                        // The family's not being downloaded, so just place the space image
                        // to maintain the size
                        let accessoryView: UIView = UIImageView.init(image: accessoryImage)
                        cell.accessoryView = accessoryView
                    } else {
                        // Nothing to show at all, so clear the accessory view
                        cell.accessoryView = nil
                    }
                }
                
                // Show and animate the Activity Indicator during downloads
                // UNUSED FROM 2.0.0
                /*
                if family.progress != nil {
                    if !cell.downloadProgressView.isAnimating {
                        cell.downloadProgressView!.startAnimating()
                    }
                } else {
                    if cell.downloadProgressView.isAnimating {
                        cell.downloadProgressView!.stopAnimating()
                    }
                }
                */
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
        
        // Actions that appear when the table view cell is swiped R-L
        // NOTE These actions are family specific

        var config: UISwipeActionsConfiguration? = nil
        var action: UIContextualAction

        // Get the referenced family
        let family: FontFamily = self.displayFamilies[indexPath.row]

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
    
    
    internal func setDisplayFamilies() {
        
        // Determine which sub-set of the font families we will actually show
        
        // To start with, clear the list: we'll add the families
        // we will actually display
        self.displayFamilies.removeAll()
        
        // Show all is a match against any criteria, but we can shortcut just
        // by checking that all view options are `false` and all view states are `true`.
        if !self.viewOptions.contains(true) && !self.viewStates.values.contains(false) {
            self.displayFamilies = self.families
            self.updateFamilyStatus()
            return
        }
        
        // Iterate over the list of families. Check if it is one of the selected
        // family classess. If so set a flag.
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
                // Family meets the class criterion, but does it also match on
                // view options?
                if !self.viewOptions.contains(true) {
                    // No view options set, so add the family and continue
                    self.displayFamilies.append(family)
                    continue
                }
                
                // If any of the options are `true` and the relevant family property is set, add the family
                if self.viewOptions[kFontShowModeIndices.new] && !family.isNew {
                    // Family isn't new, so move to the next one
                    continue
                }

                if self.viewOptions[kFontShowModeIndices.installed] == self.viewOptions[kFontShowModeIndices.uninstalled] {
                    self.displayFamilies.append(family)
                    continue
                }
                
                if self.viewOptions[kFontShowModeIndices.installed] && family.fontsAreInstalled {
                    self.displayFamilies.append(family)
                    continue
                }
                
                if self.viewOptions[kFontShowModeIndices.uninstalled] && !family.fontsAreInstalled {
                    self.displayFamilies.append(family)
                }
            }
        }
        
        self.updateFamilyStatus()
    }
    
    
    internal func reloadFontList() {
        
        // Update the displayed list of fonts
        
        // FROM 2.0.0
        
        self.updateFamilyStatus()
        self.tableView.reloadData()
    }
}
