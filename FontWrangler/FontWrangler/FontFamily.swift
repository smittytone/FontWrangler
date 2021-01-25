//  FontFamily.swift
//  Fontismo
//
//  Created by Tony Smith on 01/04/2020.
//  Copyright © 2021 Tony Smith. All rights reserved.


import UIKit


class FontFamily: NSObject {
    
    // Instances of this class are used to record a single
    // font family, eg. Comfortaa, encompassing its variants
    // NOTE Instances are not saved, and family instances
    //      are generated by the app as required
    
    
    // MARK: - Object properties
    
    private var version: String = "1.0.0"       // Record version number - used to check for fields added later
    var tag: String = ""                        // The family's asset catalog tag
    var name: String = ""                       // Family name, taken from the asset catalog tag
    var fontsAreDownloaded: Bool = false        // Are all the family's fonts downloaded?
    var fontsAreInstalled: Bool = false         // Are all the family's fonts installed?
    var fontIndices: [Int]? = nil               // Array of indices to fonts in primary array
    var progress: Progress? = nil               // NSProgress instances used during font installation
    var timer: Timer? = nil                     // Timer instance used to timeout installation 
}
