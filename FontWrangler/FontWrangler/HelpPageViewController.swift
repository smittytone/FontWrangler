
//  Created by Tony Smith on 02/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit
import WebKit


class HelpPageViewController: UIViewController {

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var webpageView: WKWebView!
    
    var index: Int = 0
    private let bundlePath = Bundle.main.bundlePath
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
