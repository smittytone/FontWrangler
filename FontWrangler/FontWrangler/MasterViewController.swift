
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class MasterViewController: UITableViewController {

    // MARK:- Instance Properties

    var detailViewController: DetailViewController? = nil
    var fonts = [UserFont]()
    var installButton: UIBarButtonItem? = nil
    
    let docsDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    

    // MARK:- Lifecycle Functions

    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Set up the 'Edit' button
        navigationItem.leftBarButtonItem = editButtonItem

        // Set up the 'Install' button
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
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }

        // Set up the refresh control - the searching indicator
        self.refreshControl = UIRefreshControl.init()
        self.refreshControl!.backgroundColor = UIColor.systemBackground
        self.refreshControl!.tintColor = UIColor.label

        self.refreshControl!.attributedTitle = NSAttributedString.init(string: "Checking for new fonts...",
                                                                       attributes: [ NSAttributedString.Key.foregroundColor : UIColor.black ])
        self.refreshControl!.addTarget(self,
                                       action: #selector(self.initializeDisplay),
                                       for: UIControl.Event.valueChanged)


        // Watch for app moving into the background
        let nc: NotificationCenter = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.saveFontList),
                       name: UIApplication.didEnterBackgroundNotification,
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

        // Stop the refresh control if it's running
        if self.refreshControl!.isRefreshing { self.refreshControl!.endRefreshing() }

        self.initializeDisplay()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)

        self.setInstallButtonState()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)

        // Stop editing the table view
        if self.tableView.isEditing {
            self.tableView.isEditing = false
            self.isEditing = false
        }
    }
    

    // MARK: - Font List Management Functions

    @objc func initializeDisplay() {

        // Load the saved list
        self.loadFontList()

        // Check for any added fonts
        self.processNewFonts()

        // Remove any dead fonts
        self.processDeadFonts()

        // Sort the list
        self.sortFonts()

        // Reload the table data
        self.tableView.reloadData()
    }


    func loadFontList() {

        // Load in the font list if the file has been saved

        // Get the path to the list file
        let loadPath = self.docsDir[0] + "/.fontlist"

        if FileManager.default.fileExists(atPath: loadPath) {
            // Support iOS 12+ secure method for decoding objects
            var loadedFonts = [UserFont]()

            do {
                let data: Data = try Data(contentsOf: URL.init(fileURLWithPath: loadPath))
                loadedFonts = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [UserFont]
            } catch {
                print("[ERROR] Could not load list file: \(error.localizedDescription)")
            }

            if loadedFonts.count > 0 {
                self.fonts = loadedFonts
                print("List file loaded: \(loadPath)");
            }
        }
    }


    @objc func processNewFonts() {

        // Read in any font files in the app's Documents folder and move
        // them into the bundle folder, if they have not yet been moved

        let fm = FileManager.default
        let docsPath = self.docsDir[0]
        let bundlePath = (Bundle.main.bundlePath as NSString).appendingPathComponent("fonts")

        print(docsPath)
        print(bundlePath)

        // Make sure the bundle contains a 'fonts' folder - if it
        // doesn't, attempt to create one
        if !fm.fileExists(atPath: bundlePath) {
            do {
                try fm.createDirectory(atPath: bundlePath,
                                       withIntermediateDirectories: false,
                                       attributes: nil)
            } catch {
                print("[ERROR] Can't create fonts folder in bundle")
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
                                print("[ERROR] can't transfer font \(file)")
                            }
                        }
                        
                        if success {
                            // Copy to bundle was successful, so record the font
                            let font = UserFont()
                            font.name = (file as NSString).deletingPathExtension
                            font.path = destPath
                            self.fonts.append(font)
                            fontsWereAdded = true

                            // Get the font's PostScript name
                            if let fileDescCFArray = CTFontManagerCreateFontDescriptorsFromURL(URL(fileURLWithPath: destPath) as CFURL) {
                                let fileDescArray = fileDescCFArray as Array
                                let fileDesc: UIFontDescriptor = fileDescArray[0] as! UIFontDescriptor
                                font.name = fileDesc.postscriptName
                            }
                        }
                    }
                }

                if fontsWereAdded {
                    self.saveFontList()
                }
            } else {
                // No font files in Documents, so issue a warning
                if self.fonts.count == 0 {
                    self.showAlert("No Font Files", "Connect your iPad to a Mac and copy your font files to this app’s Documents folder.")
                }
            }
        } catch {
            // App's Documents folder missing -- unlikely, but...
            self.showAlert("Missing Docs Folder", "This app is damage and will need to be deleted and re-installed.")
        }

        if self.refreshControl!.isRefreshing { self.refreshControl!.endRefreshing() }
    }


    func processDeadFonts() {

        // Remove any font files in the bundle that are no longer in the list

        let fm = FileManager.default
        let bundlePath = (Bundle.main.bundlePath as NSString).appendingPathComponent("fonts")
        do {
            // Get a list of the app's fonts
            let bundleFiles = try fm.contentsOfDirectory(atPath: bundlePath)
            if bundleFiles.count > 0 {
                var deletables = [String]()

                // Run through the list of bundle font files and if any are
                // not listed, mark them for deletion
                for file in bundleFiles {
                    let fileExtension = (file as NSString).pathExtension.lowercased()
                    if fileExtension == "otf" || fileExtension == "ttf" {
                        // Only process .otf and .ttf files
                        let filePath = (bundlePath as NSString).appendingPathComponent(file)
                        var got = false
                        for font in self.fonts {
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
                    uninstallFonts(deletables)

                    // EXPERIMENTAL Delete the dead files after 10s to allow time for
                    //              asynchronous font de-registration to complete
                    let _ = Timer.scheduledTimer(withTimeInterval: 10.0,
                                                 repeats: false) { (timer) in
                                                    let fm = FileManager.default
                                                    for filePath in deletables {
                                                        do {
                                                            try fm.removeItem(atPath: filePath)
                                                        } catch {
                                                            print("[ERROR] Can't delete file \(filePath)")
                                                        }
                                                    }
                                                }
                }
            }
        } catch {
            print("[ERROR] Can't get the bundle files list")
        }
    }
    

    @objc func saveFontList() {
        
        // The app is going into the background or closing, so save the list of devices
        let savePath = self.docsDir[0] + "/.fontlist"
        
        // Support iOS 12+ secure method for decoding objects
        var success: Bool = false

        do {
            // Encode the object to data
            let data: Data = try NSKeyedArchiver.archivedData(withRootObject: self.fonts,
                                                              requiringSecureCoding: true)

            try data.write(to: URL.init(fileURLWithPath: savePath))
            success = true
        } catch {
            print("Couldn't write to save file: " + error.localizedDescription)
        }

        if success {
            print("Device list saved (%@)", savePath)
        } else {
            print("Device list save failed")
        }
    }


    func sortFonts() {

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
        for font in fontsToGo {
            fontURLs.append(URL(fileURLWithPath: font))
        }

        // De-regsiter (uninstall) the font with the system
        if fontURLs.count > 0 {
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
            print("REG/DEREG DONE")
            //self.saveFontList()
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
        // cell.textLabel!.textColor = font.isInstalled ? UIColor.green : UIColor.red
        cell.textLabel!.text = font.name
        cell.accessoryType = font.isInstalled ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
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

