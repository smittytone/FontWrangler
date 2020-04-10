
//  Created by Tony Smith on 02/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


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
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url,
                                          options: [.universalLinksOnly: false],
                                          completionHandler: nil)
            }

            policy = .cancel
        } else {
            policy = .allow
        }

        // Emit the policy outcome
        decisionHandler(policy, preferences)
    }
}
