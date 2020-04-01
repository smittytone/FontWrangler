
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

extension UISplitViewController {
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem
        let _ = UIApplication.shared.sendAction(barButtonItem.action!, to: barButtonItem.target, from: nil, for: nil)
    }
}

class MasterViewController: UITableViewController {

    // MARK:- Private Instance Properties

    private var detailViewController: DetailViewController? = nil
    private var fonts = [UserFont]()
    private var families = [FontFamily]()
    private var installButton: UIBarButtonItem? = nil
    private var isFontListLoaded: Bool = false
    private var gotFontFamilies: Bool = false
    
    // MARK:- Private Instance Constants

    private let docsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    private let bundlePath = Bundle.main.bundlePath

    
    // MARK:- Lifecycle Functions

    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Set up the 'Edit' button on the left
        //navigationItem.leftBarButtonItem = editButtonItem

        // Set up the 'Install' button on the right
        let rightButton = UIBarButtonItem(title: "Add All",
                                          style: .plain,
                                          target: self,
                                          action: #selector(self.installAll(_:)))
        navigationItem.rightBarButtonItem = rightButton

        // Retain button for future use (enable and disable)
        self.installButton = rightButton

        // Set up the split view
        if let split = splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }

        // Watch for app moving into the background
        let nc: NotificationCenter = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.hasBackgrounded),
                       name: UIApplication.didEnterBackgroundNotification,
                       object: nil)

        nc.addObserver(self,
                       selector: #selector(self.willForeground),
                       name: UIApplication.willEnterForegroundNotification,
                       object: nil)

        // Watch for font state changes
        nc.addObserver(self,
                       selector: #selector(fontStatesChanged(_:)),
                       name: kCTFontManagerRegisteredFontsChangedNotification as NSNotification.Name,
                       object: nil)

        // Load up the default list
        self.loadDefaults()
    }

    
    override func viewWillAppear(_ animated: Bool) {

        // Clear selection if the split view isn't collapsed
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        self.willForeground()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)

        // Stop editing the table view if it's in that state
        if self.tableView.isEditing {
            self.tableView.isEditing = false
            self.isEditing = false
        }
    }


    @objc func hasBackgrounded() {

        // The View Controller has been notified that the app has
        // gone into the background

        // Save the list
        self.saveFontList()
    }


    @objc func willForeground() {

        // Prepare the font list table
        self.initializeFontList()
        self.setInstallButtonState()
    }
    

    // MARK: - Font List Management Functions

    func loadDefaults() {
        
        // Load in the default list of available fonts
        let fm = FileManager.default
        let defaultFontsPath = self.bundlePath + kDefaultsPath
        var fontDictionary: [String: Any] = [:]
        
        if fm.fileExists(atPath: defaultFontsPath) {
            do {
                let fileData = try Data(contentsOf: URL.init(fileURLWithPath: defaultFontsPath))
                fontDictionary = try JSONSerialization.jsonObject(with: fileData, options: []) as! [String: Any]
            } catch {
                NSLog("[ERROR] can't load defaults: \(error.localizedDescription)")
                self.showAlert("Can’t load defaults", "Sorry, FontWrangler has become damaged. Please delete and reinstall it.")
                return
            }
            
            // Extract the JSON data into UserFont instances
            let fonts = fontDictionary["fonts"] as! [Any]
            
            for font in fonts {
                let aFont = font as! [String:String]
                let newFont = UserFont()
                newFont.name = aFont["name"] ?? ""
                newFont.path = aFont["path"] ?? ""
                newFont.tag = aFont["tag"] ?? ""
                self.fonts.append(newFont)
            }
        }
        
        // Sort the list
        self.sortFonts()
    }
    
    
    @objc func initializeFontList() {

        // Update and display the list of available fonts that
        // the app knows about and is managing

        // Load the saved list from disk
        // NOTE If nothing is loaded from disk, 'self.fonts' will be the defaults
        self.loadFontList()
        
        // get the font families
        self.getFamilies()

        // Double-check what's installed and what isn't and
        // update the fonts' status
        // NOTE This will save the list always
        self.updateListedFonts()

        // Reload the table
        self.tableView.reloadData()
    }


    func loadFontList() {

        // Load in the persisted font list, if it is present
        
        if !self.isFontListLoaded {
            // Get the path to the list file
            let loadPath = self.docsPath + kFontListFileSubPath
            
            if FileManager.default.fileExists(atPath: loadPath) {
                // Create an array of UserFont instances to hold the loaded data
                var loadedFonts = [UserFont]()

                do {
                    // Try to load in the file as data then unarchive that data
                    let data: Data = try Data(contentsOf: URL.init(fileURLWithPath: loadPath))
                    loadedFonts = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [UserFont]
                } catch {
                    // Font list is damaged in some way - remove it and warn the user
                    NSLog("[ERROR] Could not font load list file: \(error.localizedDescription)")

                    do {
                        try FileManager.default.removeItem(atPath: loadPath)
                    } catch {
                        NSLog("[ERROR] Could not delete damaged font list file: \(error.localizedDescription)")
                    }

                    self.showAlert("Sorry, your font database has become damaged", "Please re-install your fonts")
                    return
                }

                if loadedFonts.count > 0 {
                    // We loaded in some valid data so set it as the primary store
                    // NOTE This must come before any other font addition/removal code
                    //      because it resets 'self.fonts'
                    self.fonts = loadedFonts
                    self.isFontListLoaded = true

                    #if DEBUG
                        print("Font list file loaded: \(loadPath)")
                    #endif
                }
            } else {
                // NOTE If the file doesn't exist, we use the defaults we previously loaded
                // TODO Should this be an error we expose to the user? If so, only only later calls
                self.saveFontList()
            }
        }
    }
    
    
    func getFamilies() {
        
        // Create a list of font families if we don't have one
        
        if !self.gotFontFamilies {
            // Clear the existing list before we begin
            self.families = [FontFamily]()
            
            // Run through the font list to extract family names via tags
            // NOTE This may change
            for font: UserFont in self.fonts {
                var got = false
                for family: FontFamily in self.families {
                    if family.tag == font.tag {
                        got = true
                        break
                    }
                }
                
                if !got {
                    let newFamily: FontFamily = FontFamily()
                    newFamily.tag = font.tag
                    newFamily.name = self.getPrinteableName(font.tag)
                    self.families.append(newFamily)
                }
            }
            
            // Sort the family list A-Z
            self.families.sort{ (family_1, family_2) -> Bool in
                return (family_1.name < family_2.name)
            }
            
            // For each family we now know about, add member fonts
            // to its own array of fonts
            for family: FontFamily in self.families {
                for font: UserFont in self.fonts {
                    if font.tag == family.tag {
                        if family.fonts == nil {
                            family.fonts = [UserFont]()
                        }
                        
                        if family.fonts != nil {
                            family.fonts!.append(font)
                        }
                    }
                }
            }
            
            // Set the font counts
            //self.setFamilyCounts()
            
            // Mark that we're done
            self.gotFontFamilies = true
        }
    }
    
    
    func setFamilyCounts() {
        
       for font: UserFont in self.fonts {
            for family: FontFamily in self.families {
                if font.tag == family.tag {
                    font.familyCount = family.fonts!.count
                    break
                }
            }
        }
    }
    
    
    @objc func saveFontList() {

        // Persist the app's font database

        // The app is going into the background or closing, so save the list of devices
        let savePath = self.docsPath + kFontListFileSubPath

        do {
            // Try to encode the object to data and then try to write out the data
            let data: Data = try NSKeyedArchiver.archivedData(withRootObject: self.fonts,
                                                              requiringSecureCoding: true)
            try data.write(to: URL.init(fileURLWithPath: savePath))

            #if DEBUG
                print("Font state saved \(savePath)")
            #endif

        } catch {
            NSLog("Can't write font state file: \(error.localizedDescription)")
        }
    }


    func sortFonts() {

        // Simple font name sorting routine

        self.fonts.sort { (font_1, font_2) -> Bool in
            return (font_1.name < font_2.name)
        }
    }


    // MARK: - Font Handling

    @objc func installAll(_ sender: Any) {
        
        // Install all available fonts, downloading as necessary
        if self.fonts.count > 0 {
            for font: UserFont in self.fonts {
                // Only attempt to get uninstalled fonts
                if !font.isInstalled {
                    self.getFont(font)
                }
            }
        }
    }


    func removeAll() {

        var fontDescs = [UIFontDescriptor]()
        for font: UserFont in self.fonts {
            let fontDesc: UIFontDescriptor = UIFontDescriptor.init(name: font.name, size: 48.0)
            fontDescs.append(fontDesc)
            font.isInstalled = false
            font.isDownloaded = false
        }

        CTFontManagerUnregisterFontDescriptors(fontDescs as CFArray,
                                               .persistent,
                                               self.registrationHandler(errors:done:))
    }
    
    
    func getFont(_ font: UserFont) {
        
        if !font.isDownloaded {
            // Get the font's assect catalog tag and assemble a Bundle request
            let tags: Set<String> = Set.init([font.tag])
            let fontRequest = NSBundleResourceRequest.init(tags: tags)

            font.progress = fontRequest.progress
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

            fontRequest.beginAccessingResources { (error) in
                // Check for a download error
                if error != nil {
                    // Handle errors on main thread
                    NSLog("[ERROR] \(error!.localizedDescription)")
                    return
                } else {
                    // Keep the downloaded file around permanently
                    Bundle.main.setPreservationPriority(1.0, forTags: tags)
                }

                // Register the font with the OS
                self.registerFont(font)
                font.progress = nil
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }

            }
        }

        // Register the font with the OS
        self.registerFont(font)
    }
    
    
    func registerFont(_ font: UserFont) {
        
        // Register a single font
        // NOTE This displays the system's Install dialog
        
        font.isDownloaded = true
        CTFontManagerRegisterFontsWithAssetNames([font.name] as CFArray,
                                                 nil,
                                                 .persistent,
                                                 true,
                                                 self.registrationHandler(errors:done:))
    }
    
    
    func registrationHandler(errors: CFArray, done: Bool) -> Bool {

        // A callback triggered in response to system-level font registration
        // and re-registrations - see 'installFonts()' and 'uninstallFonts()'

        // Process any errors passed in
        let errs = errors as NSArray
        if errs.count > 0 {
            for err in errs {
                // For now, just print the error
                // TODO better error handling
                NSLog("[ERROR] \(err)")
            }

            // As recommended, return false on error to
            // halt further processing
            return false
        }

        // System sets 'done' to true on the final call
        // (according to the header file)
        if done {
            self.updateListedFonts()
            self.saveFontList()
            
            // Update table on main thread
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }

        return true
    }


    @objc func fontStatesChanged(_ sender: Any) {
        
        // The app has received a font status update notification
        // eg. the user removed a font using the system UI

        // Update the font list's recorded installations
        self.updateListedFonts()

        // Update the UI on the main thread
        // (as this is a callback)
        DispatchQueue.main.async {
            if let dvc = self.detailViewController {
                dvc.configureView()
            }
            
            // Set the 'Add All' button state and update the table
            self.setInstallButtonState()
            self.tableView.reloadData()
        }
    }


    func updateListedFonts() {

        // Update the app's record of fonts in response to a notification
        // from the system that some fonts' status has changed

        // Get the registered (installed) fonts from the CTFontManager
        if let registeredDescriptors = CTFontManagerCopyRegisteredFontDescriptors(.persistent, true) as? [CTFontDescriptor] {

            // Assume no fonts hve been installed
            for font: UserFont in self.fonts {
                font.isInstalled = false
            }
            
            // Map regsitered fonts to our list to record which have been registered
            for registeredDescriptor in registeredDescriptors {
                if let fontName = CTFontDescriptorCopyAttribute(registeredDescriptor, kCTFontNameAttribute) as? String {
                    for font: UserFont in self.fonts {
                        if font.name == fontName {
                            font.isInstalled = true
                            break
                        }
                    }
                }
            }

            // Persist the updated font list
            self.saveFontList()
        }
    }
    
    
    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        // NOTE Add one for the header cell
        return self.families.count + 1
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            // Show the header cell
            let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "header.cell", for: indexPath)
            return cell
        } else {
            // Show a font cell
            let cell: FontWranglerFontListTableViewCell = tableView.dequeueReusableCell(withIdentifier: "custom.cell",
                                                                                        for: indexPath) as! FontWranglerFontListTableViewCell

            // Get the referenced family and use its name
            let family = self.families[indexPath.row - 1]
            cell.fontNameLabel!.text = family.name
            
            if let fonts = family.fonts {
                cell.fontCountLabel.text = "Fonts: \(fonts.count)"
                
                let font: UserFont = fonts[0]
                // Add a tick if the font is installed
                if font.isInstalled {
                    if let accessoryImage: UIImage = UIImage.init(systemName: "checkmark.circle.fill") {
                        let accessoryView: UIView = UIImageView.init(image: accessoryImage)
                        cell.accessoryView = accessoryView
                    } else {
                        cell.accessoryView = nil
                    }
                } else {
                    if let accessoryImage: UIImage = UIImage.init(named: "spacer") {
                        let accessoryView: UIView = UIImageView.init(image: accessoryImage)
                        cell.accessoryView = accessoryView
                    } else {
                        cell.accessoryView = nil
                    }
                }
                
                // Show and animate the UIActivityIndicator during downloads
                if font.progress != nil {
                    if !cell.downloadProgressView.isAnimating {
                        cell.downloadProgressView!.startAnimating()
                    }
                } else {
                    if cell.downloadProgressView.isAnimating {
                        cell.downloadProgressView!.stopAnimating()
                    }
                }
            } else {
                cell.fontCountLabel.text = "Fonts: 0"
            }
            
            // Set preview image
            cell.fontPreviewImageView.image = UIImage.init(named: family.tag)

            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        // Actions that appear when the table view cell is swiped L-R

        var config: UISwipeActionsConfiguration
        var action: UIContextualAction

        // Get the referenced family
        let family = self.families[indexPath.row - 1]
        
        // Get the first font in the family as a status check for the whole family
        let font = family.fonts![0]
        
        if font.isInstalled {
            // Configure a 'Remove All' action
            action = UIContextualAction.init(style: .normal,
                                             title: "Remove All") { (theAction, theView, handler) in
                                                self.removeAll()
                                                handler(true)
            }

            // Set the colour to red
            action.backgroundColor = UIColor.red
        } else {
            // Configure an 'Add All' action
            action = UIContextualAction.init(style: .normal,
                                             title: "Add All") { (theAction, theView, handler) in
                                                self.installAll(self)
                                                handler(true)
            }

            // Set the colour to blue
            action.backgroundColor = UIColor.systemBlue
        }

        // Create the config to be returned, making sure a full swipe DOESN'T auto-trigger
        config = UISwipeActionsConfiguration.init(actions: [action])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Actions that appear when the table view cell is swiped R-Ls

        var config: UISwipeActionsConfiguration
        var action: UIContextualAction

        // Get the referenced family
        let family = self.families[indexPath.row - 1]
        
        // Get the first font in the family as a status check for the whole family
        let font: UserFont = family.fonts![0]
        
        if font.isInstalled {
            // Configure a 'Remove' action -- only one item affected: the table view cell's family
            action = UIContextualAction.init(style: .normal,
                                             title: "Remove") { (theAction, theView, handler) in
                                                // We're removing all of the family's fonts, so get them
                                                if let fonts = family.fonts {
                                                    var fontDescs = [UIFontDescriptor]()
                                                    
                                                    // Iterate the fonts, clearing their flags and adding their
                                                    // FontDescriptors to the array we'll use to deregister them
                                                    for font in fonts {
                                                        font.isInstalled = false
                                                        font.isDownloaded = false
                                                        let fontDesc: UIFontDescriptor = UIFontDescriptor.init(name: font.name, size: 48.0)
                                                        fontDescs.append(fontDesc)
                                                    }
                                                    
                                                    CTFontManagerUnregisterFontDescriptors(fontDescs as CFArray,
                                                                                           .persistent,
                                                                                           self.registrationHandler(errors:done:))
                                                    handler(true)
                                                } else {
                                                    handler(false)
                                                }
            }

            // Configure a 'Remove All' action
            action.backgroundColor = UIColor.red
        } else {
            // Configure an 'Add' action -- only one item affected: the table view cell's
            action = UIContextualAction.init(style: .normal,
                                             title: "Add") { (theAction, theView, handler) in
                                                // We're adding all of the family's fonts, so get them
                                                if let fonts = family.fonts {
                                                    // Iterate the fonts, adding them one by one
                                                    for font in fonts {
                                                        self.getFont(font)
                                                    }
                                                    
                                                    handler(true)
                                                } else {
                                                    handler(false)
                                                }
            }

            // Set the colour to blue
            action.backgroundColor = UIColor.systemBlue
        }

        // Create the config to be returned, making sure a full swipe DOESN'T auto-trigger
        config = UISwipeActionsConfiguration.init(actions: [action])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    
    // MARK: - UI Utility Functions
    
    func showAlert(_ title: String, _ message: String) {
        
        // Generic alert display function
        
        let alert = UIAlertController.init(title: title,
                                           message: message,
                                           preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                      style: .`default`,
                                      handler: nil))
        self.present(alert,
                     animated: true,
                     completion: nil)
    }


    func setInstallButtonState() {

        // If we have a list of fonts (see viewWillAppear()), determine whether
        // we need to enable or disable the install button
        
        if self.fonts.count > 0 {
            var installedCount = 0

            for font in self.fonts {
                if font.isInstalled {
                    installedCount += 1
                }
            }

            // Only enable the install button if the number of fonts installed
            // doesn't equal the number listed
            self.installButton?.isEnabled = (self.fonts.count != installedCount)
        } else {
            // No listed fonts, so enable the install button
            self.installButton?.isEnabled = true
        }
    }


    func getPrinteableName(_ name: String, _ separator: String = "_") -> String {
        
        // Get the family human-readable name from the tag,
        // eg. convert 'my_font_one' to 'My Font One'
        
        var printeableName: String = ""
        let parts = (name as NSString).components(separatedBy: separator)
        
        if parts.count > 1 {
            for part in parts {
                printeableName += part.capitalized + " "
            }
        } else {
            printeableName = parts[0].capitalized
        }
        
        return printeableName
    }
    
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "show.detail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let family: FontFamily = families[indexPath.row - 1]
                
                var font: UserFont? = nil
                if let fonts = family.fonts {
                    font = fonts[0]
                }
                
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.currentFamily = family
                controller.detailItem = font
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                self.detailViewController = controller
                self.detailViewController?.mvc = self
            }
        }
    }
    
}

