
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class UserFont: NSObject, NSCoding, NSSecureCoding {
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    var path: String = ""
    var isInstalled: Bool = false
    var name: String = ""
    
    
    // MARK: - Initialization Methods

    override init() {

        self.name = ""
        self.path = ""
        self.isInstalled = false
    }
    
    
    // MARK: - NSCoding Methods

    required init?(coder decoder: NSCoder) {

        self.name = ""
        self.path = ""
        self.isInstalled = false
       
        // Support iOS 12+ secure method for decoding objects
        self.name = decoder.decodeObject(of: NSString.self, forKey: "font.name") as String? ?? ""
        self.path = decoder.decodeObject(of: NSString.self, forKey: "font.path") as String? ?? ""
        self.isInstalled = decoder.decodeObject(of: NSNumber.self, forKey: "font.installed") as! Bool
    }

    
    func encode(with encoder: NSCoder) {

        // Support iOS 12+ secure method for decoding objects
        encoder.encode(self.name as NSString, forKey: "font.name")
        encoder.encode(self.path as NSString, forKey: "font.path")
        encoder.encode(NSNumber(value: self.isInstalled), forKey: "font.installed")
    }
}
