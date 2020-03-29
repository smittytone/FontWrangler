
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit

class UserFont: NSObject, NSCoding, NSSecureCoding {

    // Instances of this class preserve metadata about a font
    // stored in the app's bundle (in '/fonts')

    // An NSSecureCoding required property
    static var supportsSecureCoding: Bool {
        return true
    }

    // MARK: - Object properties

    private var version: String = "1.0.0"   // Record version number - used to check for fields added later
    var name: String = ""                   // The font's PostScript name
    var path: String = ""                   // The location of the font file
    var isInstalled: Bool = false           // Is the font installed on the iPad?
    var isNew:Bool = true                   // Is the font newly extracted from the app's Documents folder?


    // MARK: - Initialization Methods

    override init() {

        // Set defaults
        self.name = ""
        self.path = ""
        self.isInstalled = false
        self.isNew = true
    }
    
    
    // MARK: - NSCoding Methods

    required init?(coder decoder: NSCoder) {

        // Set defaults
        self.name = ""
        self.path = ""
        self.isInstalled = false
        self.isNew = false
       
        // Support iOS 12+ secure method for decoding objects
        self.version = decoder.decodeObject(of: NSString.self, forKey: "font.version") as String? ?? ""
        self.name = decoder.decodeObject(of: NSString.self, forKey: "font.name") as String? ?? ""
        self.path = decoder.decodeObject(of: NSString.self, forKey: "font.path") as String? ?? ""
        self.isInstalled = decoder.decodeObject(of: NSNumber.self, forKey: "font.installed") as! Bool
        self.isNew = decoder.decodeObject(of: NSNumber.self, forKey: "font.new") as! Bool
    }

    
    func encode(with encoder: NSCoder) {

        // Support iOS 12+ secure method for decoding objects
        encoder.encode(self.version as NSString, forKey: "font.version")
        encoder.encode(self.name as NSString, forKey: "font.name")
        encoder.encode(self.path as NSString, forKey: "font.path")
        encoder.encode(NSNumber(value: self.isInstalled), forKey: "font.installed")
        encoder.encode(NSNumber(value: self.isNew), forKey: "font.new")
    }
}
