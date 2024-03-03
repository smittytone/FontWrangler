
//  HelpPageViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 02/04/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit
import WebKit


class HelpPageViewController: UIViewController,
                              WKNavigationDelegate {


    // MARK: - UI properties

    @IBOutlet weak var pageWebView: WKWebView!

    // MARK: - Object properties

    var index: Int = 0

    
    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Load in page content using WKWebView
        self.pageWebView.isHidden = true
        self.pageWebView.navigationDelegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // FROM 1.1.2
        // Switch the WKWebView to a non-persistent (RAM only)
        // website data store
        let wc: WKWebViewConfiguration = self.pageWebView.configuration
        wc.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        
        // FROM 1.2.0
        // Add separate CSS, HTML for iPhone and iPad versions
        let pagePrefix = UIDevice.current.userInterfaceIdiom == .phone ? "phone" : "pad"
        let page_url = Bundle.main.url(forResource: "\(pagePrefix)_page\(self.index)",
                                  withExtension: "html",
                                  subdirectory: "help")!
        
        // Load up the page data
        let dir_url = Bundle.main.bundleURL.appendingPathComponent("help")
        self.pageWebView.loadFileURL(page_url,
                                     allowingReadAccessTo: dir_url)
        //let request = URLRequest(url: page_url)
        //self.pageWebView.load(request)
        
        self.pageWebView.evaluateJavaScript("window.scrollTo(0,0)",
                                            completionHandler: nil)
        
        self.pageWebView.isHidden = false
    }
    
    
    // MARK: - WKWebView Navigation Functions
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

    }


    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {

        // Process clicked links to send them via Safari - all other
        // actions are handled by the WKWebView
        var policy: WKNavigationActionPolicy

        if navigationAction.navigationType == .linkActivated {
            // The user clicked on a link
            if let linkURL = navigationAction.request.url {

                #if DEBUG
                print(linkURL.absoluteString)
                #endif

                if linkURL.absoluteString == "https://settings/" {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        self.openURL(settingsURL)
                    }
                } else {
                    // It's a regular URL
                    self.openURL(linkURL)
                }
            }

            policy = .cancel
        } else {
            policy = .allow
        }

        // Emit the policy outcome
        decisionHandler(policy, preferences)

        // Close the help box on link clicks
        if policy == .cancel {
            if let parent = self.parent {
                parent.dismiss(animated: false, completion: nil)
            }
        }
    }

    
    // MARK: - Action Functions
    
    func openURL(_ url: URL) {

        // Just open the external URL specified

        UIApplication.shared.open(url,
                                  options: [.universalLinksOnly: false],
                                  completionHandler: nil)
    }
}
