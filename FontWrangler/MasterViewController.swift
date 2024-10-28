
//  MasterViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit
import StoreKit


enum FilterMenuItems: String {

    case classic
    case headline
    case decorative
    case monospace
    case viewOptions
    case new
    case installed
    case uninstalled
}


final class MasterViewController: UITableViewController,
                                  UIPopoverPresentationControllerDelegate,
                                  UIViewControllerTransitioningDelegate {

    
    // MARK: - UI properties

    @IBOutlet weak var titleView: MasterTitleView!
    @IBOutlet weak var tableHead: MasterTableHeaderView!
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
    internal var doIndicateNewFonts: Bool = true
    internal var hasShownClearedListWarning: Bool = false
    internal var shouldAutoInstallFonts: Bool = false
    
    // Collect all the font families. Each entry contains an array of the
    // indices of member fonts in the main font collection, `fonts`
    internal var families = [FontFamily]()
    internal var subFamilies = [FontFamily]()
    internal var viewOptions: [Bool] = [false, false, false]
    internal var viewStates: [FontFamilyStyle: Bool] = [
        .classic: true,
        .headline: true,
        .decorative: true,
        .monospace: true,
    ]
    
    internal var filterMenuItemIndices: [FilterMenuItems: Int] = [
        .classic: 0,
        .headline: 0,
        .decorative: 0,
        .monospace: 0,
        .new: 0,
        .installed: 0,
        .uninstalled: 0,
        .viewOptions: 0
    ]
    
    internal var viewMenu: UIMenu? = nil
    
    // MARK:- Private Instance Constants

    internal let DOCS_PATH = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    internal let BUNDLE_PATH = Bundle.main.bundlePath
    
    
    // MARK: - Lifecycle Functions

    override func viewDidLoad() {
        
        super.viewDidLoad()

        // FROM 2.0.0
        // Provide a contextual menu on iOS 14 and up, or an alert menu on iOS 13
        // NOTE We don't support iOS 12 and under (no font capability)
        var menuButton: UIBarButtonItem
        if #available(iOS 14, *) {
            // Generate the main contextual menu with the usual buttons
            let showHelpAction = UIAction(title: "Show Help",
                                          image: UIImage(systemName: "questionmark.circle"),
                                          handler: { (_) in
                                              self.doShowHelpSheet(self)
                                          })
            
            let showSettingsAction = UIAction(title: "Settings",
                                              image: UIImage(systemName: "gearshape"),
                                              handler: { (_) in
                                                  UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                              })
            
            let showFeedbackSheetAction = UIAction(title: "Give Feedback",
                                                   image: UIImage(systemName: "envelope"),
                                                   handler: { (_) in
                                                       self.doShowFeedbackSheet(self)
                                                   })
            
            let showReviewOfferAction = UIAction(title: "Review Fontismo",
                                                 image: UIImage(systemName: "pencil.and.scribble"),
                                                 handler: { (_) in
                                                     self.doReview()
                                                 })
            
            let showWebsiteAction = UIAction(title: "Visit Fontismo’s Website",
                                             image: UIImage(systemName: "globe"),
                                             handler: { (_) in
                                                 self.doShowWebsite(self)
                                             })
            
            let showTipsAction = UIAction(title: "Fuel Fontismo’s Development",
                                          image: UIImage(systemName: "fork.knife"),
                                          handler: { (_) in
                                              self.doShowTipSheet(self)
                                          })
            
            // Assemble the menu, add it to the central table header button,
            // and enable menu delivery by the button
            let mainMenu = UIMenu(title: "", children: [
                showHelpAction, showSettingsAction, showFeedbackSheetAction,
                showReviewOfferAction, showWebsiteAction, showTipsAction
            ])
            
            menuButton = UIBarButtonItem()
            menuButton.image = UIImage(systemName: "ellipsis.circle")
            menuButton.menu = mainMenu
            menuButton.style = .plain
        } else {
            // For iOS 13, use the old-style UIAlert menu
            menuButton = UIBarButtonItem(image: UIImage.init(systemName: "ellipsis.circle"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(self.doShowMenu(_:)))
        }
        
        // Add whatever menu button we've created to the navigation bar
        self.menuButton = menuButton
        self.navigationItem.rightBarButtonItem = menuButton
        
        /* REMOVED IN 2.0.0
        // Set up the 'Install' button on the right
        let addAllButton = UIBarButtonItem(image: UIImage.init(systemName: "square.and.arrow.down.on.square"),
                                           style: .plain,
                                           target: self,
                                           action: #selector(self.installAll(_:)))
        self.navigationItem.leftBarButtonItem = menuButton
        self.installButton = addAllButton
        */

        // FROM 2.0.0
        // Assemble a contextual menu for font list subdivision
        // NOTE This is only available in iOS 14 and up so we disable the options
        //      button for earlier iOS versions
        if #available(iOS 14, *) {
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
            
            let showNewFontsAction = UIAction(title: "New",
                                              handler: { (_) in
                                                  self.setViewOptions(kFontShowModeIndices.new)
                                              })
            
            let showInstalledFontsAction = UIAction(title: "Installed",
                                                    handler: { (_) in
                                                        self.setViewOptions(kFontShowModeIndices.installed)
                                                    })
            
            let showUninstalledFontsAction = UIAction(title: "Not Iinstalled",
                                                      handler: { (_) in
                                                          self.setViewOptions(kFontShowModeIndices.uninstalled)
                                                      })
            
            let showAllFontsAction = UIAction(title: "Show All",
                                              image: nil,
                                              handler: { (_) in
                                                  self.setContextMenu(true)
                                              })
            
            let clearAllFontsAction = UIAction(title: "Clear Selections",
                                               image: nil,
                                               handler: { (_) in
                                                   self.setContextMenu(false)
                                               })
            
            let viewSubMenu: UIMenu = UIMenu.init(title: "", options: .displayInline, children: [
                showNewFontsAction,
                showInstalledFontsAction,
                showUninstalledFontsAction
            ])
            
            let controlSubMenu: UIMenu = UIMenu.init(title: "", options: .displayInline, children: [
                showAllFontsAction,
                clearAllFontsAction
            ])
            
            // Set the state indicators to on, ie. show all
            showClassicFontsAction.state = .on
            showHeadlineFontsAction.state = .on
            showDecorativeFontsAction.state = .on
            showMonospaceFontsAction.state = .on
            
            self.filterMenuItemIndices[.classic] = 0
            self.filterMenuItemIndices[.headline] = 1
            self.filterMenuItemIndices[.decorative] = 2
            self.filterMenuItemIndices[.monospace] = 3
            
            // Assemble the menu, add it to the central table header button,
            // and enable menu delivery by the button
            let filterMenu = UIMenu(title: "Show Typefaces that are...", children: [
                showClassicFontsAction, showHeadlineFontsAction,
                showDecorativeFontsAction, showMonospaceFontsAction,
                viewSubMenu, controlSubMenu])
            
            self.filterMenuItemIndices[.classic] = 0
            self.filterMenuItemIndices[.headline] = 1
            self.filterMenuItemIndices[.decorative] = 2
            self.filterMenuItemIndices[.monospace] = 3
            self.filterMenuItemIndices[.viewOptions] = 4
            self.filterMenuItemIndices[.new] = 0
            self.filterMenuItemIndices[.installed] = 1
            self.filterMenuItemIndices[.uninstalled] = 2
            self.filterMenuItemIndices[.monospace] = 3
            
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
        
        // Record the number of installs
        UserDefaults.standard.set(self.installCount, forKey: kDefaultsKeys.fontInstallCount)
    }


    @objc func willForeground() {

        // Prepare the font list table
        self.initializeFontList()

        // Update the UI
        // NOT REQD. IN 2.0.0
        //self.setInstallButtonState()
        
        // FROM 1.2.0
        self.doIndicateNewFonts = UserDefaults.standard.bool(forKey: kDefaultsKeys.shouldShowNewFonts)
        
        // FROM 2.0.0
        // Check for auto-installation
        self.shouldAutoInstallFonts = UserDefaults.standard.bool(forKey: kDefaultsKeys.shouldAutoInstall)

        // Show the intro panel
        // NOTE `showIntroPanel()` checks whether the panel should
        //      actually be shown
        self.showIntroPanel()
    }


    private func showIntroPanel() {

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
        // We've removed the 'Help' menu and replaced it with an action menu,
        // which includes a Help option and space for other things
        
        // FROM 2.0.0
        // This is now only called if the host device is on iOS 13, our minimum
        // supported version. iOS 14 and up will result in a contextual menu
        
        let actionMenu: UIAlertController = UIAlertController.init(title: nil,
                                                                   message: nil,
                                                                   preferredStyle: .actionSheet)
        
        // Allow the user to view the Help screen
        var action: UIAlertAction!
        action = UIAlertAction.init(title: "Show Help",
                                    style: .default,
                                    handler: { (_) in
                                        self.doShowHelpSheet(self)
                                    })
        actionMenu.addAction(action)

        // Allow the user to view the app's settings
        action = UIAlertAction.init(title: "Fontismo Settings",
                                    style: .default,
                                    handler: { (_) in
                                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                    })

        actionMenu.addAction(action)
        
        // Allow the user to report a bug
        action = UIAlertAction.init(title: "Report a Bug",
                                    style: .default,
                                    handler: { (_) in
                                        self.doShowFeedbackSheet(self)
                                    })

        actionMenu.addAction(action)
        
        // Allow the user to review the app
        action = UIAlertAction.init(title: "Review Fontismo",
                                    style: .default,
                                    handler: { (_) in
                                        self.doReview()
                                    })
        
        actionMenu.addAction(action)
        
        // Allow the user to go to the website
        action = UIAlertAction.init(title: "Visit Fontismo’s Website",
                                    style: .default,
                                    handler: { (_) in
                                        self.doShowWebsite(self)
                                    })

        actionMenu.addAction(action)
        
        // FROM 1.2.0
        // Allow the user to report a bug
        action = UIAlertAction.init(title: "Fuel Fontismo’s Development",
                                    style: .default,
                                    handler: { (_) in
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

        // Load and configure the menu view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let hvc: HelpViewController = storyboard.instantiateViewController(withIdentifier: "help.view.controller") as! HelpViewController

        // Use the popover presentation style
        hvc.modalPresentationStyle = .pageSheet

        // Present the view controller (in a popover)
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
        // Display the StoreKit sheet for tips
        
        if self.tvc == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            self.tvc = storyboard.instantiateViewController(withIdentifier: "tip.view.controller") as? TipViewController
            self.tvc!.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .custom : .pageSheet
            self.tvc!.transitioningDelegate = self
        }
        
        self.present(self.tvc!, animated: true, completion: nil)
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
    
    private func setContextMenu(_ state: Bool) {
        
        // Enable or clear all the typeface classes
        self.viewStates[.classic] = state
        self.viewStates[.headline] = state
        self.viewStates[.decorative] = state
        self.viewStates[.monospace] = state
        
        // Clear the view options
        self.viewOptions = [false, false, false]
        
        // Update the menu and table
        self.doShowSome(nil, .unknown)
    }
    
    
    private func setViewOptions(_ index: Int) {
        
        // The view options are subdivisions of the class-based view
        
        // Invert the selected item
        self.viewOptions[index] = !self.viewOptions[index]
        
        // Make installed/uninstalled a radio
        if index == 1 && self.viewOptions[1] {
            self.viewOptions[2] = false
        } else if index == 2 && self.viewOptions[2] {
            self.viewOptions[1] = false
        }
        
        // Update the menu and table
        self.doShowSome(nil, .unknown)
    }
    
    
    private func doShowSome(_ item: UIAction?, _ style: FontFamilyStyle) {
        
        // General Filter contextual menu handler
        
        // NOTE We include the iOS 14 check here to avoid compiler warnings, even
        //      though this function will not be called on any system running iOS 13
        //      or lower.
        if #available(iOS 14.0, *) {
            // Set the view options based on current state:
            // If the item is on when clicked, it's going to be off, so
            // the viewStates entry should be `false`
            if item != nil {
                self.viewStates[style] = !(item!.state == .on)
            }
            
            // Set the menu items according to view state
            var menuItem: UIAction = self.viewOptionsButton.menu!.children[self.filterMenuItemIndices[.classic]!] as! UIAction
            menuItem.state = self.viewStates[.classic]! ? .on : .off
            
            menuItem = self.viewOptionsButton.menu!.children[self.filterMenuItemIndices[.headline]!] as! UIAction
            menuItem.state = self.viewStates[.headline]! ? .on : .off
            
            menuItem = self.viewOptionsButton.menu!.children[self.filterMenuItemIndices[.decorative]!] as! UIAction
            menuItem.state = self.viewStates[.decorative]! ? .on : .off
            
            menuItem = self.viewOptionsButton.menu!.children[self.filterMenuItemIndices[.monospace]!] as! UIAction
            menuItem.state = self.viewStates[.monospace]! ? .on : .off
            
            // Set the 'view options' submenu states
            // NOTE Only deal with menu's children 0 through 3, the specific option entries.
            let submenu: UIMenu = self.viewOptionsButton.menu!.children[self.filterMenuItemIndices[.viewOptions]!] as! UIMenu
            for i in 0..<submenu.children.count {
                menuItem = submenu.children[i] as! UIAction
                menuItem.state = self.viewOptions[i] ? .on : .off
            }
            
            // Update the table
            self.tableView.reloadData()
            
            // Check for nothing being shown, and if it's the first time,
            // present an informational alert about how to fix it
            if self.subFamilies.count == 0 && !self.hasShownClearedListWarning {
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
                
                self.hasShownClearedListWarning = true
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
            //self.setInstallButtonState()
            self.tableView.reloadData()
        }
    }


    internal func setInstallButtonState() {

        // If we have a list of fonts (see viewWillAppear()), determine whether
        // we need to enable or disable the install button
        
        // UNUSED in 2.0.0
        
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


    internal func showAlert(_ title: String, _ message: String) {
        
        // Generic alert display function which ensures
        // the alert is actioned on the main thread.

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
        
        // Generic alert display function which not only ensures
        // the alert is actioned on the main thread but also uses an
        // attributed string for the title.
        
        // FROM 2.0.0
        
        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: "",
                                               message: message,
                                               preferredStyle: .alert)
            alert.setValue(title, forKey: "attributedTitle")
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                          style: .default,
                                          handler: nil))
            
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }
    
    
    // MARK: - StoreKit Functions

    internal func requestReview() {

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


    private func makeRequest(_ currentVersion: String) {

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


    @objc private func doRequestReview() {

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


    private func doReview() {

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
                // FROM 2.0.0
                controller.shouldAutoInstallFonts = self.shouldAutoInstallFonts

                // This line updates the detail view, so keep it LAST
                controller.detailItem = font

                // Set a back button to show the master view
                // NOTE Apply to iPad only in 2.0.0 to avoid `Failed to create 0x132 image slot (alpha=1 wide=1) (client=0xcd7a6129) [0x5 (os/kern) failure]`
                if UIDevice.current.userInterfaceIdiom == .pad {
                    controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                }
                
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
