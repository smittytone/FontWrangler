
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class MasterViewController: UITableViewController {

    // MARK:- Private Instance Properties

    private var detailViewController: DetailViewController? = nil
    private var fonts = [UserFont]()
    private var installButton: UIBarButtonItem? = nil
    
    // MARK:- Private Instance Constants

    private let docsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    private let bundlePath = Bundle.main.bundlePath
    

    // MARK:- Lifecycle Functions

    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Set up the 'Edit' button on the left
        navigationItem.leftBarButtonItem = editButtonItem

        // Set up the 'Install' button on the right
        let rightButton = UIBarButtonItem(title: "Install",
                                          style: .plain,
                                          target: self,
                                          action: #selector(self.installFont(_:)))
        navigationItem.rightBarButtonItem = rightButton

        // Retain button for future use (enable and disable)
        self.installButton = rightButton

        // Set up the split view
        if let split = splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }

        // Set up the refresh control - the searching indicator
        self.refreshControl = UIRefreshControl.init()
        self.refreshControl!.backgroundColor = UIColor.systemBackground
        self.refreshControl!.tintColor = UIColor.label
        self.refreshControl!.attributedTitle = NSAttributedString.init(string: "Checking for new fonts...",
                                                                       attributes: [ NSAttributedString.Key.foregroundColor : UIColor.black ])
        self.refreshControl!.addTarget(self,
                                       action: #selector(self.initializeFontList),
                                       for: UIControl.Event.valueChanged)


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

        // Mark all new fonts as old
        if self.fonts.count > 0 {
            for font: UserFont in self.fonts {
                font.isNew = false
            }
        }

        // Save the list
        self.saveFontList()
    }


    @objc func willForeground() {

        // Stop the refresh control if it's running
        if self.refreshControl!.isRefreshing { self.refreshControl!.endRefreshing() }

        // Prepare the font list table
        self.initializeFontList()
        self.setInstallButtonState()
    }
    

    // MARK: - Font List Management Functions

    @objc func initializeFontList() {

        // Update and display the list of available fonts that
        // the app knows about and is managing

        // Load the saved list from disk
        self.loadFontList()

        // Check for any new fonts in the Documents folder
        self.processNewFonts()

        // Remove any stored fonts that are no longer referenced
        self.processDeadFonts()

        // Sort the list of fonts A-Z
        self.sortFonts()

        // Reload the table
        self.tableView.reloadData()
    }


    func loadFontList() {

        // Load in the persisted font list, if it is present

        // Get the path to the list file
        let loadPath = self.bundlePath + kFontListFileSubPath

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

                #if DEBUG
                    print("Font list file loaded: \(loadPath)")
                #endif
            }
        }
    }


    @objc func processNewFonts() {

        // Read in any font files in the app's Documents folder and move
        // them into the bundle folder, if they have not yet been moved

        let fm = FileManager.default
        let docsPath = self.docsPath[0]
        let bundlePath = self.bundlePath + kFontsDirectoryPath

        #if DEBUG
            print(docsPath)
            print(bundlePath)
        #endif

        // Make sure the bundle contains a 'fonts' folder - if it
        // doesn't, attempt to create one now
        if !fm.fileExists(atPath: bundlePath) {
            do {
                try fm.createDirectory(atPath: bundlePath,
                                       withIntermediateDirectories: false,
                                       attributes: nil)
            } catch {
                NSLog("[ERROR] Can't create fonts folder in bundle: \(error.localizedDescription)")
                return
            }
        }

        do {
            // Get all the files in the Documents folder
            var docsFiles = try fm.contentsOfDirectory(atPath: docsPath)

            // Remove all non-font files from the list
            var index = 0
            for file in docsFiles {
                // Get the current file's extension
                let fileExtension = (file as NSString).pathExtension.lowercased()
                if fileExtension == "otf" || fileExtension == "ttf" {
                    index += 1
                } else {
                    docsFiles.remove(at: index)
                }
            }

            if docsFiles.count != 0 {
                // We have some fonts to process
                var fontsWereAdded = false
                for file in docsFiles {
                    // Get the current file's extension
                    let fileExtension = (file as NSString).pathExtension.lowercased()
                    if fileExtension == "otf" || fileExtension == "ttf" {
                        // Only process OTF and TTF files
                        let sourcePath = (docsPath as NSString).appendingPathComponent(file)
                        let destPath = (bundlePath as NSString).appendingPathComponent(file)
                        var success = false
                        
                        if !fm.fileExists(atPath: destPath) {
                            // Font file has not been copied to the bundle yet...
                            do {
                                // ...so try to move it thers
                                try fm.moveItem(atPath: sourcePath, toPath: destPath)
                                success = true
                            } catch {
                                NSLog("[ERROR] can't transfer font \(file): \(error.localizedDescription)")
                            }
                        }
                        
                        if success {
                            // The move to bundle was successful, so record the font
                            let font = UserFont()

                            // Use the file name as a fallback, but we will shortly attempt
                            // to get the font's PostScript name
                            font.name = (file as NSString).deletingPathExtension
                            font.path = destPath
                            font.isNew = true
                            self.fonts.append(font)
                            fontsWereAdded = true

                            // Get the font's PostScript name if we can
                            if let fileDescCFArray = CTFontManagerCreateFontDescriptorsFromURL(URL(fileURLWithPath: destPath) as CFURL) {
                                let fileDescArray = fileDescCFArray as Array
                                let fileDesc: UIFontDescriptor = fileDescArray[0] as! UIFontDescriptor
                                font.name = fileDesc.postscriptName
                            }
                        }
                    }
                }

                if fontsWereAdded {
                    // Persist the fonts database if changes were made
                    self.saveFontList()
                }
            } else {
                // No font files found in Documents. Issue a guide note if
                // there are no previously added files either
                if self.fonts.count == 0 {
                    self.showAlert("You have not added any font files", "Connect your iPad to a Mac and copy your font files to this app’s Documents folder.")
                }
            }
        } catch {
            // App's Documents folder missing -- VERY unlikely, but...
            NSLog("[ERROR] Missing Documents folder")
            self.showAlert("Missing Docs Folder", "Sorry, thsis app has become damaged and will need to be deleted and re-installed.")
        }

        // Turn off the refresh control, if it's active
        if self.refreshControl!.isRefreshing { self.refreshControl!.endRefreshing() }
    }


    func processDeadFonts() {

        // Remove any font files in the bundle that are no longer in the list

        let fm = FileManager.default
        let bundlePath = self.bundlePath + kFontsDirectoryPath
        do {
            // Get a list of the app's fonts
            let bundleFiles = try fm.contentsOfDirectory(atPath: bundlePath)
            if bundleFiles.count > 0 {
                var deletables = [String]()

                // Run through the list of bundle font files and if any are
                // not listed in the app font database, mark them for deletion
                for file in bundleFiles {
                    let fileExtension = (file as NSString).pathExtension.lowercased()
                    if fileExtension == "otf" || fileExtension == "ttf" {
                        // Only process .otf and .ttf files
                        let filePath = (bundlePath as NSString).appendingPathComponent(file)
                        var got = false
                        for font: UserFont in self.fonts {
                            if filePath == font.path {
                                got = true
                                break
                            }
                        }

                        if !got {
                            // Mark the font for deletion
                            deletables.append(filePath)
                        }
                    }
                }

                // Do we have any fonts to remove?
                if deletables.count > 0 {
                    // We do, so deregister them first
                    uninstallFonts(deletables)

                    // EXPERIMENTAL Delete the dead files after 10s to allow time for
                    //              asynchronous font de-registration to complete
                    let _ = Timer.scheduledTimer(withTimeInterval: kDeregisterFontTimeout,
                                                 repeats: false) { (timer) in
                                                    let fm = FileManager.default
                                                    for filePath in deletables {
                                                        do {
                                                            try fm.removeItem(atPath: filePath)
                                                        } catch {
                                                            NSLog("[ERROR] Can't delete file \(filePath) :\(error.localizedDescription)")
                                                        }
                                                    }
                                                }
                }
            }
        } catch {
            NSLog("[ERROR] Can't get contents of bundle :\(error.localizedDescription)")
        }
    }
    

    @objc func saveFontList() {

        // Persist the app's font database

        // The app is going into the background or closing, so save the list of devices
        let savePath = self.bundlePath + kFontListFileSubPath

        do {
            // Try to encode the object to data and then try to write out the data
            let data: Data = try NSKeyedArchiver.archivedData(withRootObject: self.fonts,
                                                              requiringSecureCoding: true)
            try data.write(to: URL.init(fileURLWithPath: savePath))

            #if DEBUG
                print("Device list saved (%@)", savePath)
            #endif

        } catch {
            NSLog("Couldn't write to save file: \(error.localizedDescription)")
        }
    }


    func sortFonts() {

        // Simple font name sorting routine

        self.fonts.sort { (font_1, font_2) -> Bool in
            return (font_1.name < font_2.name)
        }
    }


    // MARK: - Font Handling

    @objc func installFont(_ sender: Any) {

        // The user has clicked on the Install button
        // For now we assume all uninstalled fonts are to be installed

        // Assemble the URLs of the fonts for installation
        var fontURLs = [URL]()
        for font: UserFont in self.fonts {
            if !font.isInstalled {
                fontURLs.append(URL(fileURLWithPath: font.path))
            }
        }

        // Regsiter (install) the font with the system
        // NOTE This pops up the 'do you want to install' dialog
        if fontURLs.count > 0 {

            #if DEBUG
                print("\(fontURLs.count) fonts to be registered")
            #endif

            CTFontManagerRegisterFontURLs(fontURLs as CFArray,
                                          .persistent,
                                          true,
                                          self.registrationHandler(errors:done:))
        }
    }


    func uninstallFonts(_ fontsToGo: [String]) {

        // The user has deleted some fonts from the list, so
        // we need to de-register them

        // Assemble the URLs of the fonts for removal
        var fontURLs = [URL]()
        for fontPath in fontsToGo {
            fontURLs.append(URL(fileURLWithPath: fontPath))
        }

        // De-regsiter (uninstall) the font with the system
        if fontURLs.count > 0 {

            #if DEBUG
                print("\(fontURLs.count) fonts to be deregistered")
            #endif

            CTFontManagerUnregisterFontURLs(fontURLs as CFArray,
                                            .persistent,
                                            self.registrationHandler(errors:done:))
        }
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
                print(err)
            }

            // As recommended, return false on error to
            // halt further processing
            return false
        }

        // System sets 'done' to true on the final call
        // (according to the header file)
        if done {
            self.saveFontList()
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
                font.isNew = false
            }

            // Map regsitered fonts to our list to record which have been registered
            for registeredDescriptor in registeredDescriptors {
                if let fontURL = CTFontDescriptorCopyAttribute(registeredDescriptor, kCTFontURLAttribute) as? URL {
                    for font: UserFont in self.fonts {
                        if font.path == fontURL.path {
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
    
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let font: UserFont = fonts[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = font
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                self.detailViewController = controller
            }
        }
    }


    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.fonts.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "master.cell", for: indexPath)
        let font = self.fonts[indexPath.row]
        cell.textLabel!.text = font.name
        cell.textLabel!.textColor = font.isNew ? UIColor.systemBlue : UIColor.label

        if let accessoryImage: UIImage = font.isInstalled ? UIImage.init(systemName: "checkmark.circle.fill") : UIImage.init(systemName: "circle") {
            let accessoryView: UIView = UIImageView.init(image: accessoryImage)
            cell.accessoryView = accessoryView
        }

        return cell
    }


    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // Return false if you do not want the specified item to be editable.
        return true
    }


    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            self.fonts.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Remove font from bundle
            // NOTE This deregisters the font
            //      and deletes the file
            self.processDeadFonts()
            self.setInstallButtonState()
            self.detailViewController?.detailItem = nil

            // Save the list
            self.saveFontList()
        }
    }


    // MARK: - Utility Functions
    
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
}

