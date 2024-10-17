
//  MasterViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit
import StoreKit


class MasterViewController: UITableViewController,
                            UIPopoverPresentationControllerDelegate,
                            UIViewControllerTransitioningDelegate {

    
    // MARK: - UI properties

    @IBOutlet weak var titleView: MasterTitleView!
    @IBOutlet weak var tableHead: UIView!
    @IBOutlet weak var viewOptionsButton: UIButton!
    
    
    // MARK:- Public Instance Properties
    
    // Collect all the individual fonts
    var fonts = [UserFont]()
    
    
    // MARK:- Private Instance Properties

    private  var installButton: UIBarButtonItem? = nil
    private  var menuButton: UIBarButtonItem? = nil
    private  var tvc: TipViewController? = nil
    
    internal var detailViewController: DetailViewController? = nil
    internal var installCount: Int = -1
    internal var isFontListLoaded: Bool = false
    internal var gotFontFamilies: Bool = false
    
    // Collect all the font families. Each entry contains an array of the
    // indices of member fonts in the main font collection, `fonts`
    internal var doIndicateNewFonts: Bool = true
    internal var families = [FontFamily]()
    internal var subFamilies = [FontFamily]()
    internal var viewStates: [FontFamilyStyle: Bool] = [
        .classic: true,
        .headline: true,
        .decorative: true,
        .monospace: true
    ]
    
    
    // MARK:- Private Instance Constants

    internal let DOCS_PATH = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    internal let BUNDLE_PATH = Bundle.main.bundlePath
    
    
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
        self.navigationItem.leftBarButtonItem = menuButton

        // Set up the 'Install' button on the right
        let addAllButton = UIBarButtonItem(image: UIImage.init(systemName: "square.and.arrow.down.on.square"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(self.installAll(_:)))
        self.navigationItem.rightBarButtonItem = addAllButton

        // Retain button for future use (enable and disable)
        self.installButton = addAllButton
        self.menuButton = menuButton
        
        // FROM 2.0.0
        // Assemble a contextual menu for font list subdivision
        // NOTE This is only available in iOS 14 and up so we disable the options
        //      button for earlier iOS versions
        if #available(iOS 14, *) {
            let showAllFontsAction = UIAction(title: "Show All",
                                              image: nil,
                                              handler: { (_) in
                                                  self.doShowAll(self)
                                              })
            
            let showClassicFontsAction = UIAction(title: "Classic",
                                                  image: UIImage(named: "style_class"),
                                                  handler: { (action) in
                                                      self.doShowSome(action, .classic)
                                                  })
            
            let showHeadlineFontsAction = UIAction(title: "Headline",
                                                   image: UIImage(named: "style_head"),
                                                   handler: { (action) in
                                                       self.doShowSome(action, .headline)
                                                   })
            
            let showDecorativeFontsAction = UIAction(title: "Decorative",
                                                     image: UIImage(named: "style_dec"),
                                                     handler: { (action) in
                                                         self.doShowSome(action, .decorative)
                                                     })
            
            let showMonospaceFontsAction = UIAction(title: "Monospace",
                                                     image: UIImage(named: "style_mono"),
                                                     handler: { (action) in
                                                         self.doShowSome(action, .monospace)
                                                     })
            
            // Set the state indicators to on, ie. show all
            showClassicFontsAction.state = .on
            showHeadlineFontsAction.state = .on
            showDecorativeFontsAction.state = .on
            showMonospaceFontsAction.state = .on
            
            // Assemble the menu, add it to the central table header button,
            // and enable menu delivery by the button
            let filterMenu = UIMenu(title: "Show Typefaces that are...", options: .displayInline, children: [showClassicFontsAction, showHeadlineFontsAction, showDecorativeFontsAction, showMonospaceFontsAction, showAllFontsAction])
            self.viewOptionsButton.menu = filterMenu
            self.viewOptionsButton.showsMenuAsPrimaryAction = true
        } else {
            // iOS 13: hide the button
            self.viewOptionsButton.isHidden = true
        }
        

        // Set the title view and its font count info
        // NOTE The title view is placed in the centre of the nav bar
        self.navigationItem.titleView = self.titleView
        self.titleView.infoLabel.text = "No fonts installed (of 0)"

        // Set up the split view controller
        if let split = self.splitViewController {
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
                       selector: #selector(self.fontStatesChanged(_:)),
                       name: kCTFontManagerRegisteredFontsChangedNotification as NSNotification.Name,
                       object: nil)

        // FROM 1.1.1
        // Ask for a review on a long press
        let pressLong: UILongPressGestureRecognizer = UILongPressGestureRecognizer.init(target: self,
                                                                                        action: #selector(self.doRequestReview))
        self.view?.addGestureRecognizer(pressLong)
        
        // FROM 2.0.0
        let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self,
                                                                            action: #selector(self.doRequestReview))
        doubleTap.numberOfTapsRequired = 2
        self.view?.addGestureRecognizer(doubleTap)

        // Load up the default list
        self.loadDefaults()

        // FROM 1.1.1
        // Get the font install count
        self.installCount = UserDefaults.standard.integer(forKey: kDefaultsKeys.fontInstallCount)
        UserDefaults.standard.set(self.installCount, forKey: kDefaultsKeys.fontInstallCount)
    }

    
    override func viewWillAppear(_ animated: Bool) {

        // Clear selection if the split view isn't collapsed
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        self.willForeground()
        if self.clearsSelectionOnViewWillAppear {
            self.navigationItem.titleView = self.titleView
        }
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
        self.doIndicateNewFonts = UserDefaults.standard.bool(forKey: kDefaultsKeys.shouldShowNewFonts)

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
        let shouldShowIntro = defaults.bool(forKey: kDefaultsKeys.shouldShowIntro)

        if shouldShowIntro {
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


    // MARK: - UI Action Functions — Top-Left Menu

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
        action = UIAlertAction.init(title: "Visit Fontismo’s Website",
                                    style: .default,
                                    handler: { (anAction) in
                                        self.doShowWebsite(self)
                                    })

        actionMenu.addAction(action)
        
        // FROM 1.2.0
        // Allow the user to report a bug
        action = UIAlertAction.init(title: "Fuel Fontismo’s Development",
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
        
        if self.tvc == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            tvc = storyboard.instantiateViewController(withIdentifier: "tip.view.controller") as? TipViewController
            tvc!.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .custom : .pageSheet
            tvc!.transitioningDelegate = self
        }
        
        self.present(tvc!, animated: true, completion: nil)
    }
    
    
    @objc func doShowWebsite(_ sender: Any) {
        
        // FROM 1.1.2
        // Open the Fontismo web page in Safari
        
        guard let webURL = URL(string: kWebsiteURL) else { fatalError("Expected a valid Fontismo website URL") }
        
        UIApplication.shared.open(webURL,
                                  options: [:],
                                  completionHandler: nil)
    }
    
    
    // MARK: - UIAction Functions — Filter Contextual Menu
    
    private func doShowAll(_ sender: Any) {
        
        if #available(iOS 14.0, *) {
            self.viewStates[.classic] = true
            self.viewStates[.headline] = true
            self.viewStates[.decorative] = true
            doShowSome(nil, .unknown)
        }
    }
    
    
    private func doShowSome(_ item: UIAction?, _ style: FontFamilyStyle) {
        
        if #available(iOS 14.0, *) {
            // Set the view options based on current state:
            // If the item is on when clicked, it's going to be off, so
            // the viewStates entry should be `false`
            if item != nil {
                self.viewStates[style] = !(item!.state == .on)
            }
            
            // Set the menu items according to view state
            var menuItem: UIAction = self.viewOptionsButton.menu!.children[0] as! UIAction
            menuItem.state = self.viewStates[.classic]! ? .on : .off
            
            menuItem = self.viewOptionsButton.menu!.children[1] as! UIAction
            menuItem.state = self.viewStates[.headline]! ? .on : .off
            
            menuItem = self.viewOptionsButton.menu!.children[2] as! UIAction
            menuItem.state = self.viewStates[.decorative]! ? .on : .off
            
            self.tableView.reloadData()
            
            if self.subFamilies.count == 0 {
                // Empty display
                let paraStyle: NSMutableParagraphStyle = NSMutableParagraphStyle.init()
                paraStyle.alignment = .center
                
                let attributes: [NSAttributedString.Key : Any] = [
                    .paragraphStyle: paraStyle,
                    .font: UIFont.systemFont(ofSize: 18.0, weight: .bold)
                ]
                
                let titleString: NSMutableAttributedString = NSMutableAttributedString.init(string: "Use the ", attributes: attributes)
                if let buttonImage = UIImage.init(systemName: "line.3.horizontal.decrease.circle") {
                    let imageAttachment: NSTextAttachment = NSTextAttachment.init()
                    imageAttachment.image = buttonImage.withTintColor(UIColor.systemBlue)
                    let imageString = NSAttributedString(attachment: imageAttachment)
                    titleString.append(imageString)
                } else {
                    let nameString: NSAttributedString = NSAttributedString.init(string: "Sort", attributes: attributes)
                    titleString.append(nameString)
                }
                
                let endString: NSAttributedString = NSAttributedString.init(string: " button above to select the styles of face you’d like to see listed", attributes: attributes)
                titleString.append(endString)
                
                self.showFancyAlert(titleString, "")
            }
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
        
        // Report if any number of fonts have been installed
        
        var installedCount: Int = 0
        
        for family: FontFamily in self.families {
            installedCount += (family.fontsAreInstalled ? 1 : 0)
        }
        
        return (installedCount != 0)
    }
    
    
    func allFontsInstalled() -> Bool {
        
        // Report if all the available fonts have been installed
        
        var installedCount: Int = 0
        
        for family: FontFamily in self.families {
            installedCount += (family.fontsAreInstalled ? 1 : 0)
        }
        
        return (installedCount == self.families.count)
    }
    
    
    internal func showAlert(_ title: String, _ message: String) {
        
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
    
    
    internal func showFancyAlert(_ title: NSAttributedString, _ message: String) {
        
        
        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: "",
                                               message: message,
                                               preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                          style: .default,
                                          handler: nil))
            
            alert.setValue(title, forKey: "attributedTitle")
            
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
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
                let family: FontFamily = self.subFamilies[indexPath.row]
                
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
