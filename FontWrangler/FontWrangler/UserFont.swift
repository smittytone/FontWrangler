
//  UserFont.swift
//  Fontismo
//
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2023 Tony Smith. All rights reserved.


import UIKit


class UserFont: NSObject,
                NSCoding,
                NSSecureCoding {

    // Instances of this class preserve metadata about a font
    // stored in the app's bundle (in '/fonts')

    
    // An NSSecureCoding required property
    static var supportsSecureCoding: Bool {
        return true
    }
    

    // MARK: - Object properties

    private var version: String = "1.0.0"   // Record version number - used to check for fields added later
    var name: String = ""                   // The font's file name, eg. 'Smythe-Regular'
    var path: String = ""                   // The font's file extension, eg. 'ttf'
    var psname: String = ""                 // The font's PostScript name, eg. 'Smythe'
    var tag: String = ""                    // The font's asset catalog tag
    var isInstalled: Bool = false           // Is the font installed on the iPad?
    var isDownloaded: Bool = false          // Is the font newly extracted from the app's Documents folder?
    var updated: Bool = false               // Temporary use flag
    
    // FROM 1.2.0
    var isNew: Bool = false                 // Is the font a new addition?
    
    
    // MARK: - Initialization Methods

    override init() {

        // Set defaults
        self.name = ""
        self.psname = ""
        self.path = ""
        self.tag = ""
        self.isInstalled = false
        self.isDownloaded = false
        self.isNew = false
    }
    
    
    // MARK: - NSCoding Methods

    required init?(coder decoder: NSCoder) {

        // Set defaults
        self.name = ""
        self.psname = ""
        self.path = ""
        self.tag = ""
        self.isInstalled = false
        self.isDownloaded = false
        self.isNew = false
       
        // Support iOS 12+ secure method for decoding objects
        self.version = decoder.decodeObject(of: NSString.self, forKey: "font.version") as String? ?? ""
        self.name = decoder.decodeObject(of: NSString.self, forKey: "font.name") as String? ?? ""
        self.psname = decoder.decodeObject(of: NSString.self, forKey: "font.psname") as String? ?? ""
        self.path = decoder.decodeObject(of: NSString.self, forKey: "font.path") as String? ?? ""
        self.tag = decoder.decodeObject(of: NSString.self, forKey: "font.tag") as String? ?? ""
        self.isInstalled = decoder.decodeObject(of: NSNumber.self, forKey: "font.installed") as! Bool
        self.isDownloaded = decoder.decodeObject(of: NSNumber.self, forKey: "font.downloaded") as! Bool
        
        // FROM 1.2.0
        // Catch old versions that may not include this key
        let result: NSNumber = decoder.decodeObject(of: NSNumber.self, forKey: "font.new") ?? 0
        self.isNew = result as! Bool
    }

    
    func encode(with encoder: NSCoder) {

        // Support iOS 12+ secure method for decoding objects
        encoder.encode(self.version as NSString, forKey: "font.version")
        encoder.encode(self.name as NSString, forKey: "font.name")
        encoder.encode(self.psname as NSString, forKey: "font.psname")
        encoder.encode(self.path as NSString, forKey: "font.path")
        encoder.encode(self.tag as NSString, forKey: "font.tag")
        encoder.encode(NSNumber(value: self.isInstalled), forKey: "font.installed")
        encoder.encode(NSNumber(value: self.isDownloaded), forKey: "font.downloaded")
        encoder.encode(NSNumber(value: self.isNew), forKey: "font.new")
    }
}
