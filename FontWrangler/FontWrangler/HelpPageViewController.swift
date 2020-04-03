
//  Created by Tony Smith on 02/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit
import WebKit


class HelpPageViewController: UIViewController {


    // MARK: - UI properties

    @IBOutlet weak var pageTextView: UITextView!

    // MARK: - Object properties

    var index: Int = 0

    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Load in page content using NSAttributedString
        let bundlePath = Bundle.main.bundlePath
        let url = URL.init(fileURLWithPath: bundlePath + "/help/page\(self.index).html")
        do {
            let helpString: NSAttributedString = try NSAttributedString.init(url: url,
                                                             options: [.documentType: NSAttributedString.DocumentType.html],
                                                             documentAttributes: nil)
            self.pageTextView.attributedText = helpString
        } catch {
            // Error
        }

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
