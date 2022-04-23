
//  MasterViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2022 Tony Smith. All rights reserved.


import UIKit
import StoreKit


class MasterViewController: UITableViewController,
                            UIPopoverPresentationControllerDelegate,
                            UIViewControllerTransitioningDelegate {

    
    // MARK: - UI properties

    @IBOutlet weak var titleView: MasterTitleView!
    @IBOutlet weak var tableHead: UIView!
    
    // MARK:- Private Instance Properties

    private var detailViewController: DetailViewController? = nil
    private var installButton: UIBarButtonItem? = nil
    private var families = [FontFamily]()
    private var isFontListLoaded: Bool = false
    private var gotFontFamilies: Bool = false
    private var installCount: Int = -1
    // FROM 1.1.2
    private var menuButton: UIBarButtonItem? = nil
    // FROM 1.2.0
    private var doShowNew: Bool = true
    
    // MARK:- Public Instance Properties
    
    var fonts = [UserFont]()
    
    // MARK:- Private Instance Constants

    private let DOCS_PATH = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    private let BUNDLE_PATH = Bundle.main.bundlePath
    
    
    
    // MARK:- Lifecycle Functions

    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Set up the 'Help' button on the left
        /*navigationItem.leftBarButtonItem = editButtonItem
        let helpButton = UIBarButtonItem(title: "Help",
                                          style: .plain,
                                          target: self,
                                          action: #selector(self.doShowHelpSheet(_:)))
        */
        
        // FROM 1.1.2
        // Add a standard iOS menu icon in place of the 'Help' menu
        // Users can get help via the menu
        let menuButton = UIBarButtonItem(image: UIImage.init(systemName: "ellipsis.circle"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(self.doShowMenu(_:)))
        navigationItem.leftBarButtonItem = menuButton

        // Set up the 'Install' button on the right
        let addAllButton = UIBarButtonItem(title: "Add All",
                                           style: .plain,
                                           target: self,
                                           action: #selector(self.installAll(_:)))
        navigationItem.rightBarButtonItem = addAllButton

        // Retain button for future use (enable and disable)
        self.installButton = addAllButton
        self.menuButton = menuButton

        // Set the title view and its font count info
        navigationItem.titleView = self.titleView
        self.titleView.infoLabel.text = "No fonts installed (of 0)"

        // Set up the split view controller
        if let split = splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count - 1] as! UINavigationController).topViewController as? DetailViewController
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

        // FROM 1.1.1
        // Ask for a review on a long press
        let pressRec: UILongPressGestureRecognizer = UILongPressGestureRecognizer.init(target: self,
                                                                                       action: #selector(self.doRequestReview))
        self.view?.addGestureRecognizer(pressRec)

        // Load up the default list
        self.loadDefaults()

        // FROM 1.1.1
        // Get the font install count
        self.installCount = UserDefaults.standard.integer(forKey: kDefaultsKeys.fontInstallCount)
        UserDefaults.standard.set(self.installCount, forKey: kDefaultsKeys.fontInstallCount)
    }

    
    override func viewWillAppear(_ animated: Bool) {

        // Clear selection if the split view isn't collapsed
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        self.willForeground()
    }
    
    
    @objc func hasBackgrounded() {

        // The View Controller has been notified that the app has
        // gone into the background

        // Save the list
        // NOTE This is probably unnecessary now
        self.saveFontList()
        UserDefaults.standard.set(self.installCount, forKey: kDefaultsKeys.fontInstallCount)
    }


    @objc func willForeground() {

        // Prepare the font list table
        self.initializeFontList()

        // Update the UI
        self.setInstallButtonState()
        
        // FROM 1.2.0
        self.doShowNew = UserDefaults.standard.bool(forKey: kDefaultsKeys.shouldShowNewFonts)

        // Show the intro panel
        // NOTE 'showIntroPanel()' checks whether the panel should
        //      actually be shown
        self.showIntroPanel()
    }


    func showIntroPanel() {

        // If required, display an introductory page of guidance on app usage
        // NOTE This should appear on the first use of the app, but never again.
        //      However, the user can choose to re-show the panel by flipping a
        //      switch in the app settings

        // Get the default to see if we go ahead and display the intro panel
        let defaults: UserDefaults = UserDefaults.standard
        let showIntro = defaults.bool(forKey: kDefaultsKeys.shouldShowIntro)

        if showIntro {
            // Load and configure the menu view controller.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let ivc: IntroViewController = storyboard.instantiateViewController(withIdentifier: "intro.view.controller") as! IntroViewController

            // Use the popover presentation style for your view controller.
            ivc.modalPresentationStyle = .formSheet

            // Present the view controller (in a popover).
            self.splitViewController!.present(ivc, animated: true, completion: nil)

            // Write out to defaults so that the panel isn't shown again
            defaults.set(false, forKey: kDefaultsKeys.shouldShowIntro)
        }
    }
    

    // MARK: - Font List Management Functions

    func loadDefaults() {
        
        // Load in the default list of available fonts and then sort it A-Z
        // This is stored in the main bundle

        let fm = FileManager.default
        let defaultFontsPath = self.BUNDLE_PATH + kDefaultsPath
        var fontDictionary: [String: Any] = [:]
        
        if fm.fileExists(atPath: defaultFontsPath) {
            do {
                let fileData = try Data(contentsOf: URL.init(fileURLWithPath: defaultFontsPath))
                fontDictionary = try JSONSerialization.jsonObject(with: fileData, options: []) as! [String: Any]
            } catch {
                NSLog("[ERROR] can't load defaults: \(error.localizedDescription) - loadDefaults()")
                self.showAlert("Sorry!", "Fontismo’s default font list can’t be loaded — it has become damaged. Please reinstall the app.")
                return
            }
            
            // Extract the data into UserFont instances
            let fonts = fontDictionary["fonts"] as! [Any]
            for font in fonts {
                let aFont = font as! [String:String]
                let newFont = UserFont()
                newFont.name = aFont["name"] ?? ""
                newFont.psname = aFont["name"] ?? ""
                newFont.path = aFont["path"] ?? ""
                newFont.tag = aFont["tag"] ?? ""
                
                let flag: String = aFont["new"] ?? ""
                newFont.isNew = (flag == "true")
                self.fonts.append(newFont)
            }
            
            // Sort the list
            self.sortFonts()
        } else {
            NSLog("[ERROR] can't load defaults - loadDefaults()")
            self.showAlert("Error", "Sorry, the default font list is missing — Fontismo has become damaged. Please reinstall the app.")
        }
    }
    
    
    @objc func initializeFontList() {

        // Update and display the list of available fonts that the app knows about and is managing
        //
        // This is the called when the app comes into the foreground
        // and when viewWillAppear() is callled

        // Load the saved list from disk
        // NOTE If nothing is loaded from disk, 'self.fonts' will be the defaults
        self.loadFontList()
        
        // Determing the font families available in the font list
        self.setFontFamilies()

        // Double-check what's installed and what isn't and
        // update the fonts' status
        // NOTE This will save the list always
        self.updateFamilyStatus()

        // Reload the table
        self.tableView.reloadData()
    }


    func loadFontList() {

        // Load in the persisted font list, if it is present
        
        if !self.isFontListLoaded {
            // Get the path to the list file
            let loadPath = self.DOCS_PATH + kFontListFileSubPath
            
            if FileManager.default.fileExists(atPath: loadPath) {
                // Create an array of UserFont instances to hold the loaded data
                var loadedFonts = [UserFont]()

                do {
                    // Try to load in the file as data then unarchive that data
                    let data: Data = try Data(contentsOf: URL.init(fileURLWithPath: loadPath))
                    loadedFonts = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [UserFont]
                } catch {
                    // Font list is damaged in some way - remove it and warn the user
                    NSLog("[ERROR] Could not font load list file: \(error.localizedDescription) - loadFontList()")

                    do {
                        try FileManager.default.removeItem(atPath: loadPath)
                    } catch {
                        NSLog("[ERROR] Could not delete damaged font list file: \(error.localizedDescription) - loadFontList()")
                    }

                    return
                }

                if loadedFonts.count > 0 {
                    // We loaded in some valid data so set it as the primary store
                    // NOTE This must come before any other font addition/removal code
                    //      because it resets 'self.fonts'
                    
                    // Check sizes in case we are updating from an old version and therefore the defaults will
                    // be larger than the loaded file. BUT we need to port across status values!
                    if loadedFonts.count != self.fonts.count {
                        // Copy the loaded status data to the new defaults
                        #if DEBUG
                            print("\(self.fonts.count - loadedFonts.count) new fonts added to defaults")
                        #endif
                        
                    }
                    
                    for font: UserFont in self.fonts {
                        for loadedFont: UserFont in loadedFonts {
                            // Compare file names when looking for added fonts
                            if loadedFont.name == font.name {
                                font.isInstalled = loadedFont.isInstalled
                                font.isDownloaded = loadedFont.isDownloaded
                                break
                            }
                        }
                    }
                    
                    // Store it
                    self.saveFontList()
                    
                    /*
                    } else {
                        self.fonts = loadedFonts
                    }
                    */
                    self.isFontListLoaded = true
                }
            } else {
                // NOTE If the file doesn't exist, we use the defaults we previously loaded
                // TODO Should this be an error we expose to the user? If so, only only later calls
                if self.fonts.count == 0 {
                    // Load in the defaults if there's no font list in place
                    self.showAlert("Sorry!", "Fontismo’s default font list can’t be loaded — the app may have become damaged. Please reinstall it.")
                    return
                }

                self.saveFontList()
            }
        }
    }
    
    
    func setFontFamilies() {
        
        // Create a list of font families if we don't have one
        
        if !self.gotFontFamilies {
            // Clear the existing list before we begin
            self.families = [FontFamily]()
            
            // Run through the font list to extract family names via tags
            // NOTE This may change
            var got: Bool = false
            for font: UserFont in self.fonts {
                got = false
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
                    newFamily.isNew = font.isNew
                    self.families.append(newFamily)
                }
            }
            
            // Sort the family list A-Z
            self.families.sort{ (family_1, family_2) -> Bool in
                return (family_1.name < family_2.name)
            }
            
            // For each family we now know about, add the member fonts
            // to its own array of font references
            for family: FontFamily in self.families {
                for i in 0..<self.fonts.count {
                    let font: UserFont = self.fonts[i]
                    if font.tag == family.tag {
                        if family.fontIndices == nil {
                            family.fontIndices = [Int]()
                        }
                        
                        // Add the font's index in the primary font array
                        // to its family's own list of fonts
                        family.fontIndices!.append(i)
                    }
                }
            }
            
            // Mark that we're done
            self.gotFontFamilies = true
        }
    }
    
    
    @objc func saveFontList() {

        // Persist the app's font database

        // The app is going into the background or closing, so save the list of devices
        let savePath = self.DOCS_PATH + kFontListFileSubPath

        do {
            // Try to encode the object to data and then try to write out the data
            let data: Data = try NSKeyedArchiver.archivedData(withRootObject: self.fonts,
                                                              requiringSecureCoding: true)
            try data.write(to: URL.init(fileURLWithPath: savePath))

            #if DEBUG
                //print("Font state saved \(savePath)")
            #endif

        } catch {
            NSLog("[ERROR] Can't write font file: \(error.localizedDescription) - saveFontList()")
            self.showAlert("Error", "Sorry, Fontismo can’t access internal storage. It may have been damaged or mis-installed. Please re-installed from the App Store.")
        }
    }
    
    
    @objc func fontStatesChanged(_ sender: Any) {
        
        // The app has received a font status update notification
        // eg. the user removed a font using the system UI

        // Update the families' status the UI
        self.updateFamilyStatus()
        self.updateUIonMain()
    }


    // MARK: - Family Handling Action Functions

    @objc func installAll(_ sender: Any) {
        
        // Install all available font families, downloading as necessary
        
        if self.families.count > 0 {
            for family: FontFamily in self.families {
                if !family.fontsAreInstalled && family.progress == nil {
                    // If the family is not marked as installed,
                    // assume it is not downloaded (it might be
                    // present) and attempt to get it
                    self.getOneFontFamily(family)
                }
            }
        }
    }

    
    func removeAll() {

        // Uninstall all available fonts
        
        if self.families.count > 0 {
            // Assemble font descriptors for each of the family's fonts.
            // These will be passed to the API for deregistration.
            var fontDescs = [UIFontDescriptor]()
            for family: FontFamily in self.families {
                if family.fontsAreDownloaded {
                    // Update the family's state information
                    family.fontsAreInstalled = false
                    family.fontsAreDownloaded = false
                    
                    if let fontIndexes: [Int] = family.fontIndices {
                        for fontIndex: Int in fontIndexes {
                            let font: UserFont = self.fonts[fontIndex]

                            // Font Descriptors take POSTSCRIPT NAMES
                            let fontDesc: UIFontDescriptor = UIFontDescriptor.init(name: font.psname, size: 48.0)
                            fontDescs.append(fontDesc)
                            
                            // Update the font's state information
                            font.isInstalled = false
                            font.isDownloaded = false
                        }
                    }
                }
            }
            
            if fontDescs.count > 0 {
                // Unregister the fonts via the API
                CTFontManagerUnregisterFontDescriptors(fontDescs as CFArray,
                                                       .persistent,
                                                       self.familyRegistrationHandler(errors:done:))
            }

            // FROM 1.1.1
            // Add the number of fonts removed to the current total
            self.installCount += fontDescs.count
        }
    }
    

    func removeOneFontFamily(_ family: FontFamily) {

        // Remove a single font family

        if let fontIndexes: [Int] = family.fontIndices {
            // Iterate the family's fonts, clearing their flags and adding their
            // FontDescriptors to the array we'll use to deregister them
            var fontDescs = [UIFontDescriptor]()
            family.fontsAreInstalled = false
            family.fontsAreDownloaded = false

            for fontIndex: Int in fontIndexes {
                let font: UserFont = self.fonts[fontIndex]
                font.isInstalled = false
                font.isDownloaded = false

                // Font Descriptors take the POSTSCRIPT NAME
                let fontDesc: UIFontDescriptor = UIFontDescriptor.init(name: font.psname,
                                                                       size: 48.0)
                fontDescs.append(fontDesc)
            }

            // Deregister the fonts using the API
            CTFontManagerUnregisterFontDescriptors(fontDescs as CFArray,
                                                   .persistent,
                                                   self.fontRegistrationHandler(errors:done:))
        }

        // FROM 1.1.1
        // Add the number of fonts removed to the current total
        self.installCount += 1
    }


    func getOneFontFamily(_ family: FontFamily) {

        // Acquire a single font fsmily resource using on-demand

        if !family.fontsAreDownloaded {
            
            #if DEBUG
                print("Family '\(family.name)' not downloaded")
            #endif
            
            // The fsmily's font resource has not been downloaded so get its asset catalog tag
            // ('family.tag') and assemble an asset request
            let tags: Set<String> = Set.init([family.tag])
            let fontRequest = NSBundleResourceRequest.init(tags: tags)

            // Store the progress recorder and update the UI on
            // the main thread so the Activity Indicator is shown
            family.progress = fontRequest.progress
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

            // Set a timeout timer on this family-specific request
            family.timer = Timer.scheduledTimer(withTimeInterval: kFontDownloadTimeout,
                                                repeats: false,
                                                block: { (firedTimer) in
                // Find the family associated with the fired timer
                for family: FontFamily in self.families {
                    if let familyTimer = family.timer {
                        if familyTimer == firedTimer {
                            if !family.fontsAreDownloaded {
                                self.showAlert("Sorry!", "Fontismo could not access the requested typeface because it could not connect to the App Store. Please check your Internet connection and try again.")
                            }

                            family.timer = nil
                            family.progress = nil

                            DispatchQueue.main.async {
                                // FROM 1.2.0
                                // Turn off the detail view controller's progress indicator
                                if let dvc: DetailViewController = self.detailViewController {
                                    if !dvc.downloadProgress.isHidden {
                                        dvc.downloadProgress.stopAnimating()
                                    }
                                }
                                
                                // Update the typeface table
                                self.tableView.reloadData()
                            }

                            break
                        }
                    }
                }
            })

            fontRequest.beginAccessingResources { (error) in
                // THIS BLOCK IS A CLOSURE

                // Update the UI (on the main thread) to remove the
                // Activity Indicator
                family.progress = nil
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }

                // Check for a download error
                if error != nil {
                    // Handle errors
                    // NOTE #1 Item not downloaded if 'error' != nil
                    // NOTE #2 Not sure if this ever gets called... app usually timeouts
                    //         It does get called if we download in Airplane Mode.
                    NSLog("[ERROR] \(error!.localizedDescription)")

                    // Zap the associated timer early
                    if family.timer != nil {
                        family.timer!.invalidate()
                        family.timer = nil
                    }

                    self.showAlert("Sorry!", "Fontismo could not access the requested typeface because it was unable to connect to the App Store. Please check your Internet connection and try again.\n(\(error!.localizedDescription))")
                    
                    // FROM 1.2.0
                    // Turn off the detail view controller's progress indicator
                    DispatchQueue.main.async {
                        if let dvc: DetailViewController = self.detailViewController {
                            if !dvc.downloadProgress.isHidden {
                                dvc.downloadProgress.stopAnimating()
                            }
                        }
                    }
                    
                    return
                }
                
                #if DEBUG
                    print("Family '\(family.name)' downloaded")
                #endif
                
                // Keep the downloaded file around permanently, ie.
                // until the app is deleted
                Bundle.main.setPreservationPriority(1.0, forTags: tags)

                // Update the font's state
                family.fontsAreDownloaded = true

                // Register the font with the OS
                self.registerFontFamily(family)
            }
        } else {
            // Font family should already be downloaded
            #if DEBUG
                print("Family '\(family.name)' already downloaded")
            #endif
            
            self.registerFontFamily(family)
        }
    }


    func registerFontFamily(_ family: FontFamily) {

        // Register the family's fonts
        // NOTE This displays the system's Install dialog

        if let fontIndexes: [Int] = family.fontIndices {
            // Add the fonts' FILE NAMEs to 'fontNames'
            var fontNames = [String]()
            for fontIndex: Int in fontIndexes {
                let font: UserFont = self.fonts[fontIndex]
                fontNames.append(font.name)
            }
            
            #if DEBUG
                print("Registering family '\(family.name)'...")
            #endif

            // Register the family's fonts using the API
            // NOTE Outcome is operated asynchronously
            self.installCount += 1
            CTFontManagerRegisterFontsWithAssetNames(fontNames as CFArray,
                                                     nil,
                                                     .persistent,
                                                     true,
                                                     self.familyRegistrationHandler(errors:done:))
        }
    }


    func familyRegistrationHandler(errors: CFArray, done: Bool) -> Bool {

        // A callback triggered in response to system-level font registration
        // and re-registrations - see 'installFonts()' and 'uninstallFonts()'

        /*
         An empty array indicates no errors. Each error reference will contain a CFArray of font asset names corresponding to kCTFontManagerErrorFontAssetNameKey. These represent the font asset names that were not successfully registered. Note, the handler may be called multiple times during the registration process. The done parameter will be set to true when the registration process has completed. The handler should return false if the operation is to be stopped. This may be desirable after receiving an error.
         */

        // Set the return value
        let returnValue: Bool = true

        // Process any errors passed in
        let errs = errors as NSArray
        if errs.count > 0 {
            for err in errs {
                // For now, just print the error
                // TODO better error handling
                let error: NSError = err as! NSError
                NSLog("[ERROR] \(error.localizedDescription)")
                let errFont = error.userInfo[kCTFontManagerErrorFontAssetNameKey as String] ?? "unknown"
                self.showAlert("Sorry!", "Fontismo had a problem registering typeface \(errFont).\n(\(error.localizedDescription))")
            }

            // As recommended, return false on error to
            // halt further processing
            // returnValue = false
        }

        // System sets 'done' to true on the final call
        // (according to the header file)
        if done {
            #if DEBUG
                print("(De)registration operation complete")
            #endif
            
            // Update the fonts' status and update the UI
            // NOTE Have to do all families becuase we can't know
            //      which family has been registered
            DispatchQueue.main.async {
                self.updateFamilyStatus()
                self.setInstallButtonState()
                self.tableView.reloadData()

                // FROM 1.1.1
                // Check if we need to run a review prompt
                if self.installCount > kFontInstallCountBeforeReviewRequest {
                    self.installCount = 0
                    UserDefaults.standard.set(self.installCount, forKey: kDefaultsKeys.fontInstallCount)
                    self.requestReview()
                }
            }
        }

        // Signal state of operation
        return returnValue
    }
    
    
    func updateFamilyStatus() {
        
        // Update family status properties
        // Where possible rely on the OS for state data
        
        // Update the status of all the fonts
        self.updateFontStatus()
        
        #if DEBUG
            print("---------------------------------------------------")
        #endif
        
        // Use the font data to set the familiies' status
        var installedCount = 0
        for family: FontFamily in self.families {
            // Familities fonts have been downloaed - have they been installed?
            // The number of font installations should match the number of
            // fonts in the family
            var installed: Int = 0
            var downloaded: Int = 0
            
            if let fontIndexes: [Int] = family.fontIndices {
                for fontIndex: Int in fontIndexes {
                    let font: UserFont = self.fonts[fontIndex]
                    installed += (font.isInstalled ? 1 : 0)
                    downloaded += (font.isDownloaded ? 1 : 0)
                }
                
                // Families are only considered installed if all their members are
                family.fontsAreInstalled = installed == fontIndexes.count
                family.fontsAreDownloaded = downloaded == fontIndexes.count

                installedCount += (family.fontsAreInstalled ? 1 : 0)

                #if DEBUG
                    print("Family '\(family.name)': downloads: \(downloaded), installs: \(installed) of \(fontIndexes.count)")
                #endif

                // Turn of progress and/or timers if they're still active
                if fontIndexes.count == installed {
                    if family.progress != nil {
                        family.progress = nil
                    }

                    if family.timer != nil {
                        family.timer!.invalidate()
                        family.timer = nil
                    }
                }
            }
        }

        // Set the font installed/not installed count
        let fontString = installedCount == 1 ? "typeface" : "typefaces"
        let headString = installedCount == 0 ? "No" : "\(installedCount)"
        self.titleView.infoLabel.text = "\(headString) \(fontString) installed (of \(self.families.count))"
    }
    
    
    // MARK: - Font Handling Action Functions
    
    func updateFontStatus() {

        // Update the app's record of fonts in response to a notification
        // from the system that some fonts' status has changed
        // Called by 'updateFamilyStatus()'

        // Get the registered (installed) fonts from the CTFontManager
        if let registeredDescriptors = CTFontManagerCopyRegisteredFontDescriptors(.persistent, true) as? [CTFontDescriptor] {

            // Assume no fonts hve been installed
            for font: UserFont in self.fonts {
                font.isInstalled = false
                font.isDownloaded = false
                font.updated = false
            }

            // Map regsitered fonts to our list to record which have been registered
            var setCount: Int = 0
            for registeredDescriptor in registeredDescriptors {
                if let fontName = CTFontDescriptorCopyAttribute(registeredDescriptor, kCTFontNameAttribute) as? String {

                    #if DEBUG
                        print("CoreText Font Manager says '\(fontName)' is registered...")
                    #endif

                    for font: UserFont in self.fonts {
                        // Match against PostScript name
                        if font.psname == fontName {
                            font.isInstalled = true
                            font.isDownloaded = true
                            font.updated = true
                            setCount += 1
                            #if DEBUG
                                print("  ...and matched for '\(font.name)'")
                            #endif

                            break
                        }
                    }
                }
            }
            
            // Did we just update fewer fonts than are registered?
            // If so it's probably because there's a name mismatch, ie.
            // the filename-derived name != the PostScript name
            if setCount < registeredDescriptors.count {
                // Some missing fonts, so check by URL
                for registeredDescriptor in registeredDescriptors {
                    if let fontName = CTFontDescriptorCopyAttribute(registeredDescriptor, kCTFontNameAttribute) as? String {
                        for font: UserFont in self.fonts {
                            if !font.updated {
                                // Eg. 'TradeWinds' and 'TradeWinds-Regular'
                                // TODO Needs some safety checking/more efficient
                                if (font.psname as NSString).contains(fontName) {
                                    font.isInstalled = true
                                    font.isDownloaded = true
                                    font.updated = true
                                    
                                    #if DEBUG
                                        print("Font PostScript name changed from '\(font.name)' to '\(fontName)'")
                                    #endif
                                    
                                    font.psname = fontName
                                    break
                                }
                            }
                        }
                    }
                }
            }

            // Persist the updated font list
            self.saveFontList()
        } else {
            NSLog("[ERROR] Could not list new registrations")
        }
    }
    
    
    func fontRegistrationHandler(errors: CFArray, done: Bool) -> Bool {

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
            // Update the fonts' status to match the system,
            // save, and update the UI
            //self.updateFontStatus()
            self.updateUIonMain()
        }

        // Signal OK
        return true
    }


    // MARK: - Table View Data Source and Delegate Functions

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        // Just return 1
        
        return 1
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        // NOTE Add one for the header cell
        
        return self.families.count
    }


    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        // Return the custom table header row
        
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
            let family = self.families[indexPath.row]
            
            // FROM 1.2.0
            // Highlight new fonts
            if family.isNew && self.doShowNew {
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
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        // Actions that appear when the table view cell is swiped L-R
        // NOTE These actions affect all families
    
        var config: UISwipeActionsConfiguration? = nil
        var actions = [UIContextualAction]()
        var action: UIContextualAction = UIContextualAction.init(style: .destructive,
                                         title: "Remove All") { (theAction, theView, handler) in
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
        
        actions.append(action)
        
        // Configure an 'Add All' action
        action = UIContextualAction.init(style: .normal,
                                         title: "Add All") { (theAction, theView, handler) in
                                            // Check that there are fonts to be installed
                                            if self.allFontsInstalled() {
                                                self.showAlert("All Typefaces Installed", "You have already installed all of the available typefaces")
                                            } else {
                                                // Install any remaining fonts
                                                self.installAll(self)
                                            }
                                            
                                            handler(true)
        }

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
                                                 title: "Remove") { (theAction, theView, handler) in
                                                    // Remove the single, row-referenced font
                                                    self.removeOneFontFamily(family)
                                                    handler(true)
                }
            } else {
                // Configure an 'Add' action -- only one item affected: the table view cell's
                action = UIContextualAction.init(style: .normal,
                                                 title: "Add") { (theAction, theView, handler) in
                                                    // Install the single, row-referenced font
                                                    self.getOneFontFamily(family)
                                                    handler(true)
                }

                // Set the colour to blue
                action.backgroundColor = UIColor.systemBlue
            }

            // Create the config to be returned, making sure a full swipe DOESN'T auto-trigger
            config = UISwipeActionsConfiguration.init(actions: [action])
        }

        config?.performsFirstActionWithFullSwipe = false
        return config
    }

    
    // MARK: - UI Action Functions

    @objc func doShowMenu(_ sender: Any) {

        // FROM 1.1.2
        // We've removed the 'Help' menu and replace it with an action menu,
        // which includes a Help option and space for other things
        
        let actionMenu: UIAlertController = UIAlertController.init(title: nil,
                                                                    message: nil,
                                                                    preferredStyle: .actionSheet)
        
        // Allow the user to view the Help screen
        var action: UIAlertAction!
        action = UIAlertAction.init(title: "Show Help",
                                    style: .default,
                                    handler: { (anAction) in
                                        self.doShowHelpSheet(self)
                                    })

        actionMenu.addAction(action)

        // Allow the user to view the app's settings
        action = UIAlertAction.init(title: "Fontismo Settings",
                                    style: .default,
                                    handler: { (anAction) in
                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                    })

        actionMenu.addAction(action)
        
        // Allow the user to report a bug
        action = UIAlertAction.init(title: "Report a Bug",
                                    style: .default,
                                    handler: { (anAction) in
                                        self.doShowFeedbackSheet(self)
                                    })

        actionMenu.addAction(action)
        
        // Allow the user to review the app
        action = UIAlertAction.init(title: "Review Fontismo",
                                    style: .default,
                                    handler: { (anAction) in
                                        self.doReview()
                                    })
        
        actionMenu.addAction(action)
        
        // Allow the user to go to the website
        action = UIAlertAction.init(title: "Visit the Fontismo Website",
                                    style: .default,
                                    handler: { (anAction) in
                                        self.doShowWebsite(self)
                                    })

        actionMenu.addAction(action)
        
        // FROM 1.2.0
        // Allow the user to report a bug
        action = UIAlertAction.init(title: "Tip the Developer",
                                    style: .default,
                                    handler: { (anAction) in
                                        self.doShowTipSheet(self)
                                    })

        actionMenu.addAction(action)
        
        // If we're on an iPad we need to do a little extra setup
        // before presenting it, in order to set the menu below the
        // menu button which triggers it
        if UIDevice.current.userInterfaceIdiom == .pad {
            actionMenu.popoverPresentationController?.barButtonItem = self.menuButton;
            actionMenu.popoverPresentationController?.sourceView = self.view;
        } else {
            // Allow the user to cancel the menu on an iPhone,
            // which treats the menu modally
            action = UIAlertAction.init(title: "Cancel",
                                        style: .cancel,
                                        handler: nil)
            actionMenu.addAction(action)
        }
        
        // Present the menu
        self.present(actionMenu,
                     animated: true,
                     completion: nil)
    }


    @objc func doShowHelpSheet(_ sender: Any) {

        // Display the Help panel

        // Load and configure the menu view controller.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let hvc: HelpViewController = storyboard.instantiateViewController(withIdentifier: "help.view.controller") as! HelpViewController

        // Use the popover presentation style for your view controller.
        hvc.modalPresentationStyle = .pageSheet

        // Present the view controller (in a popover).
        self.present(hvc, animated: true, completion: nil)
    }


    @objc func doShowFeedbackSheet(_ sender: Any) {

        // FROM 1.1.2
        // Display the Feedback alert
        
        // Load and configure the menu view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let fvc: FeedbackViewController = storyboard.instantiateViewController(withIdentifier: "feedback.view.controller") as! FeedbackViewController
        
        // Select the type of presentation according to the device
        // we're operating on:
        // - iPads will have a custom view to better adjust it to the size of the display
        // - iPhones will present a standard page sheet
        // By setting iPads to .custom, we ensure the UIViewControllerTransitioningDelegate
        // is called, and it's there that we set up and use our UIPresentationController
        fvc.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .custom : .pageSheet
        fvc.transitioningDelegate = self
        
        // Show the feedback view controller
        self.present(fvc, animated: true, completion: nil)
    }
    
    
    @objc func doShowTipSheet(_ sender: Any) {
        
        // FROM 1.2.0
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tvc: TipViewController = storyboard.instantiateViewController(withIdentifier: "tip.view.controller") as! TipViewController
        tvc.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .custom : .pageSheet
        tvc.transitioningDelegate = self
        self.present(tvc, animated: true, completion: nil)
    }
    
    
    func doShowWebsite(_ sender: Any) {
        
        // FROM 1.1.2
        // Open the Fontismo web page in Safari
        
        guard let webURL = URL(string: kWebsiteURL) else { fatalError("Expected a valid Fontismo website URL") }
        
        UIApplication.shared.open(webURL,
                                  options: [:],
                                  completionHandler: nil)
    }
    
    
    func showAlert(_ title: String, _ message: String) {
        
        // Generic alert display function which ensures
        // the alert is actioned on the main thread

        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: title,
                                               message: message,
                                               preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                          style: .default,
                                          handler: nil))
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }


    // MARK: - Utility Functions

    func updateUIonMain() {

        // Update the UI on the main thread
        // (This function usually called from callbacks)

        DispatchQueue.main.async {
            if let dvc = self.detailViewController {
                dvc.configureView()
            }

            // Set the 'Add All' button state and update the table
            self.setInstallButtonState()
            self.tableView.reloadData()
        }
    }


    func setInstallButtonState() {

        // If we have a list of fonts (see viewWillAppear()), determine whether
        // we need to enable or disable the install button
        
        if self.fonts.count > 0 {
            var installedCount = 0

            for font: UserFont in self.fonts {
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
        
        // FROM 1.2.0
        // Hack for Amatic Sc -> Amatic Small Caps
        if name == "amatic_sc" {
            return "Amatic Small Caps"
        }
        
        var printeableName: String = ""
        let parts = (name as NSString).components(separatedBy: separator)
        
        if parts.count > 1 {
            for part in parts {
                printeableName += part.capitalized + " "
            }

            // Remove the final ' '
            let ps = printeableName as NSString
            printeableName = ps.substring(to: ps.length - 1)
        } else {
            printeableName = parts[0].capitalized
        }
        
        return printeableName
    }
    
    
    func sortFonts() {

        // Simple font name sorting routine

        self.fonts.sort { (font_1, font_2) -> Bool in
            return (font_1.name < font_2.name)
        }
    }


    func anyFontsInstalled() -> Bool {
        
        var installedCount: Int = 0
        
        for family: FontFamily in self.families {
            installedCount += (family.fontsAreInstalled ? 1 : 0)
        }
        
        return (installedCount != 0)
    }
    
    
    func allFontsInstalled() -> Bool {
        
        var installedCount: Int = 0
        
        for family: FontFamily in self.families {
            installedCount += (family.fontsAreInstalled ? 1 : 0)
        }
        
        return (installedCount == self.families.count)
    }

    
    
    // MARK: - StoreKit Functions

    func requestReview() {

        // FROM 1.1.1
        // Show the 'please review' dialog if the user is on a new version
        // and has installed at least 20 fonts
        
        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            else { fatalError("Expected to find a bundle version in the info dictionary") }

        if let lastVersionChecked = UserDefaults.standard.string(forKey: kDefaultsKeys.lastReviewVersion) {
            // Make sure the user has not already been prompted for this version
            if currentVersion != lastVersionChecked {
                makeRequest(currentVersion)
            }
        } else {
            // Just in case...
            UserDefaults.standard.set("1.0.0", forKey: kDefaultsKeys.lastReviewVersion)
            makeRequest(currentVersion)
        }
    }


    func makeRequest(_ currentVersion: String) {

        // FROM 1.1.1
        // Configure the rating dialog to appear in two seconds' time
        
        let twoSecondsFromNow = DispatchTime.now() + 2.0
        DispatchQueue.main.asyncAfter(deadline: twoSecondsFromNow) { [navigationController] in
            if navigationController?.topViewController is MasterViewController {
                // Show the rating request dialog if 'self' is present
                SKStoreReviewController.requestReview()
                UserDefaults.standard.set(currentVersion, forKey: kDefaultsKeys.lastReviewVersion)
            }
        }
    }


    @objc func doRequestReview() {

        // FROM 1.1.1
        // Display an option to review the app on a long press of the master view
        
        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: "Would you like to rate or review this app?",
                                               message: "If you have found Fontismo useful, please consider writing a short App Store review.",
                                               preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: NSLocalizedString("Not Now",
                                                                   comment: "Default action"),
                                          style: .default,
                                          handler: nil))

            alert.addAction(UIAlertAction(title: NSLocalizedString("Yes, Please",
                                                                   comment: "Default action"),
                                          style: .default,
                                          handler: { (action) in
                                            self.doReview()
                                          }))

            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }


    func doReview() {

        // FROM 1.1.2
        // Refactor this action into a separate function

        guard let writeReviewURL = URL(string: kAppStoreURL + "?action=write-review") else { fatalError("Expected a valid Fontismo review URL") }

        UIApplication.shared.open(writeReviewURL, options: [:]) { (returnValue) in

            let infoDictionaryKey = kCFBundleVersionKey as String
            guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
                else { fatalError("Expected to find a bundle version in the info dictionary") }

            if let lastVersionChecked = UserDefaults.standard.string(forKey: kDefaultsKeys.lastReviewVersion) {
                // Make sure the user has not already been prompted for this version
                if currentVersion != lastVersionChecked {
                    UserDefaults.standard.set(currentVersion, forKey: kDefaultsKeys.lastReviewVersion)
                }
            }
        }
    }

    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "show.detail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                // Get the referenced font family
                let family: FontFamily = families[indexPath.row]
                
                // Get the first font on the list
                var font: UserFont? = nil
                if let fontIndexes: [Int] = family.fontIndices {
                    font = self.fonts[fontIndexes[0]]
                }

                // Get the detail controller and set key properties
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.currentFamily = family
                controller.mvc = self
                controller.currentFontIndex = 0
                controller.hasCustomText = false

                // This line updates the detail view, so keep it LAST
                controller.detailItem = font

                // Set a back button to show the master view
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true

                // Keep a reference to the detail view controller
                self.detailViewController = controller
            }
        }
    }
    

    // MARK: - UIViewControllerTransitioningDelegate Functions

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        // Instantiate and return the Presentation Controller
        // NOTE This delegate method should only be called on an iPad
        //      (see 'doShowFeedbackSheet()')
        
        return FeedbackPresentationController.init(presentedViewController: presented,
                                                   presenting: source)
    }

}


// MARK: - Extensions

extension UISplitViewController {
    
    func toggleMasterView() {
        
        let barButtonItem = self.displayModeButtonItem
        let _ = UIApplication.shared.sendAction(barButtonItem.action!,
                                                to: barButtonItem.target,
                                                from: nil, for: nil)
    }
}
