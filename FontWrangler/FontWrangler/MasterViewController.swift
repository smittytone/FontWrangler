
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var fonts = [UserFont]()
    var installButton: UIBarButtonItem? = nil
    
    let docsDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(title: "Install", style: .plain, target: self, action: #selector(self.installFont(_:)))
        navigationItem.rightBarButtonItem = addButton
        self.installButton = addButton
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        let nc: NotificationCenter = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.saveFontList),
                       name: UIApplication.didEnterBackgroundNotification,
                       object: nil)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        if self.fonts.count == 0 {
            self.loadInitialList()
        }
        
        self.loadFontList()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if self.fonts.count > 0 {
            var installed = 0
            for font in self.fonts {
                if font.isInstalled {
                    installed += 1
                }
            }
            
            self.installButton?.isEnabled = (self.fonts.count != installed)
        } else {
            self.installButton?.isEnabled = true
        }
        
        self.tableView.reloadData()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        self.saveFontList()
    }
    
    
    func loadInitialList() {
        
        // Load in a list of font files
        let docsPath = self.docsDir[0]
        print(docsPath)
        
        let bundlePath = Bundle.main.bundlePath
        print(bundlePath)
        
        let fm = FileManager.default
        
        do {
            let fontFiles = try fm.contentsOfDirectory(atPath: docsPath)
            if fontFiles.count != 0 {
                for fontFile in fontFiles {
                    let extn = (fontFile as NSString).pathExtension.lowercased()
                    if extn == "otf" || extn == "ttf" {
                        let sourcePath = (docsPath as NSString).appendingPathComponent(fontFile)
                        let destPath = (bundlePath as NSString).appendingPathComponent(fontFile)
                        var success = false
                        
                        if !fm.fileExists(atPath: destPath) {
                            do {
                                try fm.copyItem(atPath: sourcePath, toPath: destPath)
                                success = true
                            } catch {
                                print("CANT COPY FILE \(fontFile)")
                            }
                        }
                        
                        if success {
                            let font = UserFont()
                            font.name = (fontFile as NSString).deletingPathExtension
                            font.path = destPath
                            self.fonts.append(font)
                        }
                    }
                }
                
                // Watch for font state changes
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(fontStateChanged(_:)),
                                                       name: kCTFontManagerRegisteredFontsChangedNotification as NSNotification.Name,
                                                       object: nil)
            } else {
                self.installButton?.isEnabled = false
                self.showAlert("No Font Files", "Connect your iPad to a Mac and copy your font files to this app’s Documents folder.")
            }
        } catch {
            // App's Documents folder missing -- unlikely, but...
            self.showAlert("Missing Docs Folder", "This app is damage and will need to be deleted and re-installed.")
        }
    }
    
    
    func loadFontList() {
        // Load in default device list if the file has already been saved
        let loadPath = self.docsDir[0] + "/.fontlist"

        if FileManager.default.fileExists(atPath: loadPath) {
            // Support iOS 12+ secure method for decoding objects
            // Devices file is present on the iDevice, so load it in
            var loadedFonts = [UserFont]()

            do {
                let data: Data = try Data(contentsOf: URL.init(fileURLWithPath: loadPath))
                loadedFonts = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [UserFont]
            } catch {
                NSLog("Could not load list file. Error: \(error.localizedDescription)")
            }

            if loadedFonts.count > 0 {
                self.fonts = loadedFonts
                print("List file loaded: \(loadPath)");
            }
        }
    }
    

    @objc
    func saveFontList() {
        
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


    // MARK: - Font Handling

    @objc
    func installFont(_ sender: Any) {
        
        //self.fonts.insert(NSDate(), at: 0)
        //let indexPath = IndexPath(row: 0, section: 0)
        //tableView.insertRows(at: [indexPath], with: .automatic)
        
        /*
         Block called as errors are discovered or upon completion. The errors parameter will be an empty array if all files are unregistered. Otherwise, it will contain an array of CFError references. Each error reference will contain a CFArray of font URLs corresponding to kCTFontManagerErrorFontURLsKey. These URLs represent the font files that caused the error, and were not successfully unregistered. Note, the handler may be called multiple times during the unregistration process. The done parameter will be set to true when the unregistration process has completed. The handler should return false if the operation is to be stopped. This may be desirable after receiving an error.
         */
        
        var fontURLs = [URL]()
        var index = 0
        for font: UserFont in self.fonts {
            if !font.isInstalled {
                let url = URL(fileURLWithPath: font.path)
                fontURLs.append(url)
            }
            
            index += 1
        }
        
        CTFontManagerRegisterFontURLs(fontURLs as CFArray, .persistent, true) {
            (errors: CFArray, done: Bool) -> Bool in
            let errs = errors as NSArray
            if errs.count > 0 {
                for err in errs {
                    print(err)
                }
                
                return false
            }
            
            return true
        }
    }
    
    @objc
    func fontStateChanged(_ sender: Any) {
        
        self.updateRegisteredFonts()
        DispatchQueue.main.async {
            self.detailViewController?.configureView()
            self.tableView.reloadData()
        }
    }
    
    func updateRegisteredFonts() {
        guard let registeredDescriptors = CTFontManagerCopyRegisteredFontDescriptors(.persistent, true) as? [CTFontDescriptor] else { return }
        
        for font: UserFont in self.fonts {
            font.isInstalled = false
        }
        
        for registeredDescriptor in registeredDescriptors {
            if let fontURL = CTFontDescriptorCopyAttribute(registeredDescriptor, kCTFontURLAttribute) as? URL {
                let fontPath = fontURL.path
                for font: UserFont in self.fonts {
                    if font.path == fontPath {
                        font.isInstalled = true
                        break
                    }
                }
            }
        }
    }
    
    
    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let font: UserFont = fonts[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = font.name
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let font = self.fonts[indexPath.row]
        cell.textLabel!.textColor = font.isInstalled ? UIColor.green : UIColor.red
        cell.textLabel!.text = font.name
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
            
            // TODO Remove font from Documents folder
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }

    // MARK: - Utility Functions
    
    func showAlert(_ title: String, _ message: String) {
        
        // Generic alert display function
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

