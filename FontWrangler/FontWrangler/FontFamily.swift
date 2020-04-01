
//  Created by Tony Smith on 01/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit


class FontFamily: NSObject {
    
    private var version: String = "1.0.0"       // Record version number - used to check for fields added later
    var name: String = ""                       // Family name, taken from the User Font tag
    var fonts: [UserFont]? = nil                // Array of UserFont instances
    
}
