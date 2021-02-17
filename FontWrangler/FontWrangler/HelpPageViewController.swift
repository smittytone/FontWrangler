
//  HelpPageViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 02/04/2020.
//  Copyright © 2021 Tony Smith. All rights reserved.


import UIKit
import WebKit


class HelpPageViewController: UIViewController, WKNavigationDelegate {


    // MARK: - UI properties

    @IBOutlet weak var pageWebView: WKWebView!

    // MARK: - Object properties

    var index: Int = 0

    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Load in page content using WKWebView
        self.pageWebView.navigationDelegate = self
        self.pageWebView.isHidden = true
        
        // FROM 1.1.2
        // Switch the WKWebView to a non-persistent (RAM only)
        // website data store
        let wc: WKWebViewConfiguration = self.pageWebView.configuration
        wc.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        
        // Load up the page data
        let url = Bundle.main.url(forResource: "page\(self.index)", withExtension: "html", subdirectory: "help")!
        self.pageWebView.loadFileURL(url, allowingReadAccessTo: url)
        let request = URLRequest(url: url)
        self.pageWebView.load(request)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        self.pageWebView.isHidden = false
    }


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


    func openURL(_ url: URL) {

        // Just open the external URL specified

        UIApplication.shared.open(url,
                                  options: [.universalLinksOnly: false],
                                  completionHandler: nil)
    }
}
