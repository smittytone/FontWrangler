
//  MasterViewControllerFonts.swift
//  FontWrangler
//
//  Created by Tony Smith on 17/10/2024.
//  Copyright © 2024 Tony Smith. All rights reserved.


import Foundation
import UIKit


extension MasterViewController  {
    
    
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
                let flag: String = aFont["new"] ?? ""
                newFont.isNew = (flag == "true")
                newFont.name = aFont["name"] ?? ""
                newFont.psname = aFont["name"] ?? ""
                newFont.path = aFont["path"] ?? ""
                newFont.tag = aFont["tag"] ?? ""
                
                // FROM 2.0.0
                let serifFlag: String = aFont["serif"] ?? ""
                newFont.isSerif = (serifFlag == "true" || serifFlag == "")
                newFont.style = aFont["class"] ?? "Unknown"
                
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
        
        /*
        // EXPERIMENT
        // Register downloaded, ie. in-bundle, fonts
        for (index, font) in self.fonts.enumerated() {
            if font.isDownloaded {
                registerFontFamily(familyFromFontIndex(index))
            }
        }
        */
        
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
                    // FROM 1.2.2
                    // Replace deprecated calls for NSCoding with Codable
                    let data: Data = try Data(contentsOf: URL.init(fileURLWithPath: loadPath))
                    let decoder = PropertyListDecoder.init()
                    loadedFonts = try decoder.decode([UserFont].self, from: data)
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
                    
                    // Update the fonts collection (build from defaults.json) using values loaded
                    // NOTE This should mean that changes in defaults.json should be preserved.
                    for font: UserFont in self.fonts {
                        for loadedFont: UserFont in loadedFonts {
                            // Compare file names when looking for added fonts
                            if loadedFont.name == font.name {
                                font.isInstalled = loadedFont.isInstalled
                                font.isDownloaded = loadedFont.isDownloaded
                                
                                /*
                                // EXPERIMENTAL
                                // Set known downloads' records
                                if font.name == "Abel-Regular" || font.name == "AlfaSlabOne-Regular" {
                                    font.isDownloaded = true
                                }
                                */
                                
                                break
                            }
                        }
                    }
                    
                    // Store it
                    // self.saveFontList()
                    self.isFontListLoaded = true
                }
            } else {
                // NOTE If the file doesn't exist, we use the defaults we previously loaded
                // TODO Should this be an error we expose to the user?
                if self.fonts.count == 0 {
                    // Load in the defaults if there's no font list in place
                    self.showAlert("Sorry!", "Fontismo’s default font list can’t be loaded — the app may have become damaged. Please reinstall it.")
                    return
                }
                
                // Save the defaults
                self.saveFontList()
            }
        }
    }
    
    
    private func familyFromFontIndex(_ index: Int) -> FontFamily {
        
        // Using an index in the main fonts collection, identify
        // the indexed font's family and return it
        
        for family: FontFamily in self.families {
            if let fontIndices: [Int] = family.fontIndices {
                for fontIndex: Int in fontIndices {
                    if fontIndex == index {
                        return family
                    }
                }
            }
        }
        
        // ERROR
        return self.families[0]
    }

    
    private func setFontFamilies() {
        
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
                    
                    // FROM 2.0.0
                    newFamily.isSerif = font.isSerif
                    newFamily.style = FontFamilyStyle(rawValue: font.style) ?? .unknown
                    
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
                
                /*
                if family.name == "Abel" || family.name == "Alfa Slab One" {
                    family.fontsAreDownloaded = true
                }
                */
            }
            
            // Mark that we're done
            self.gotFontFamilies = true
        }
    }
    
    
    internal func saveFontList() {

        // Persist the app's font database

        // The app is going into the background or closing, so save the list of devices
        let savePath = self.DOCS_PATH + kFontListFileSubPath

        do {
            // Try to encode the object to data and then try to write out the data
            //let data: Data = try NSKeyedArchiver.archivedData(withRootObject: self.fonts, requiringSecureCoding: true)
            // FROM 1.2.2
            // Replace deprecated calls for NSCoding with Codable
            let encoder: PropertyListEncoder = PropertyListEncoder.init()
            encoder.outputFormat = .binary
            let data: Data = try encoder.encode(self.fonts)
            try data.write(to: URL.init(fileURLWithPath: savePath))
            
#if DEBUG
            // Also save a JSON file for easy checking
            let jsonEncoder: JSONEncoder = JSONEncoder.init()
            let jsonData: Data = try jsonEncoder.encode(self.fonts)
            try jsonData.write(to: URL.init(fileURLWithPath: savePath + ".json"))
            print("Font state saved \(savePath)")
#endif

        } catch {
            NSLog("[ERROR] Can't write font file: \(error.localizedDescription) - saveFontList()")
            self.showAlert("Error", "Sorry, Fontismo can’t access internal storage. It may have been damaged or mis-installed. Please re-installed from the App Store.")
        }
    }
    
    
    @objc internal func fontStatesChanged(_ sender: Any) {
        
        // The app has received a font status update notification
        // eg. the user removed a font using the system UI
        
        // NOTE Set to @objc because it's called as a selector

        // Update the families' status the UI
        self.updateFamilyStatus()
        self.updateUIonMain()
    }


    // MARK: - Family Handling Action Functions

    @objc func installAll(_ sender: Any) {
        
        // Install all available font families, downloading as necessary
        
        // NOTE Set to @objc because it's called as a selector
        
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
            
            /*
            // EXPERIMENTAL
            var fontUrls = [URL]()
            for fontName in fontNames {
                fontUrls.append(Bundle.main.bundleURL.appendingPathComponent("Fonts/" + fontName + ".ttf"))
            }
            
            CTFontManagerRegisterFontURLs(fontUrls as CFArray,
                                          .persistent,
                                          true,
                                          self.familyRegistrationHandler(errors:done:))
            */
        }
    }


    func familyRegistrationHandler(errors: CFArray, done: Bool) -> Bool {

        // A callback triggered in response to system-level font registration
        // and re-registrations - see 'installFonts()' and 'uninstallFonts()'

        /*
         An empty array indicates no errors. Each error reference will contain a CFArray of font asset names corresponding to kCTFontManagerErrorFontAssetNameKey. These represent the font asset names that were not successfully registered. Note, the handler may be called multiple times during the registration process. The done parameter will be set to true when the registration process has completed. The handler should return `false` if the operation is to be stopped. This may be desirable after receiving an error.
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
                var errFont = error.userInfo[kCTFontManagerErrorFontAssetNameKey as String] ?? "unknown"
                if errFont as! String == "unknown" {
                    errFont = error.userInfo[kCTFontManagerErrorFontURLsKey as String] ?? "unknown"
                }
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
                print("Family '\(family.name)': downloads: \(downloaded), installs: \(installed) of \(fontIndexes.count). Style: \(family.style), serif: \(family.isSerif ? "YES" : "NO")")
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
                font.updated = false
                font.isDownloaded = false
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
}
