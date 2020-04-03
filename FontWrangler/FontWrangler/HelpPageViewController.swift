
//  Created by Tony Smith on 02/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit
import WebKit


class HelpPageViewController: UIViewController {


    // MARK: - UI properties

    @IBOutlet weak var pageWebView: WKWebView!

    // MARK: - Object properties

    var index: Int = 0

    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Load in page content using WKWebView
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

}
