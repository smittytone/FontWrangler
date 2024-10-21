
//  UserFont.swift
//  Fontismo
//
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit


class UserFont: Codable {

    // Instances of this class preserve metadata about a font
    // stored in the app's bundle (in '/fonts')

    // FROM 1.2.2
    // NSCoding support removed and replaced by Codable support


    // MARK: - Object properties

    private var version: String = "1.0.0"   // Record version number - used to check for fields added later
                                            // NOTE This is NOT the app version
    var name: String = ""                   // The font's file name, eg. 'Smythe-Regular'
    var path: String = ""                   // The font's file extension, eg. 'ttf'
    var psname: String = ""                 // The font's PostScript name, eg. 'Smythe'
    var tag: String = ""                    // The font's asset catalog tag
    var isInstalled: Bool = false           // Is the font installed on the iPad?
    var isDownloaded: Bool = false          // Is the font newly extracted from the app's Documents folder?
    var updated: Bool = false               // Temporary use flag
    
    // FROM 1.2.0
    var isNew: Bool = false                 // Is the font a new addition?
    
    // FROM 2.0.0
    var isSerif: Bool = true                // Does the font have serifs?
    var style: String = ""                  // The font's Fontismo style: classic, headline, decorative
    var creator: String? = nil              // The font's creator, pulled from `defaults.json`
}
