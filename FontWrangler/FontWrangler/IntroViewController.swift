
//  Created by Tony Smith on 10/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit


class IntroViewController: UIViewController {

    // Subclass UIViewController in order to add the close button

    @IBAction func doClose(_ sender: Any) {

        // Close the Help panel
        
        self.dismiss(animated: true, completion: nil)
    }

}
