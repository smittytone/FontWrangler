//  Constants.swift
//  Fontismo
//
//  Created by Tony Smith on 29/03/2020.
//  Copyright © 2022 Tony Smith. All rights reserved.


import Foundation
import CoreGraphics


// MARK: Constants

let kFontsDirectoryPath                 = "/fonts"
let kFontListFileSubPath                = "/.fontlist"
let kDefaultsPath                       = "/defaults.json"

let kDeregisterFontTimeout              = 10.0
let KBaseUserSampleFontSize: CGFloat    = 20.0
let kBaseDynamicSampleFontSize: CGFloat = 32.0
let kFontDownloadTimeout                = 30.0

let kFontSampleText_1                   = "ABCDEFGHI\nJKLMNOPQ\nRSTUVWXYZ\n0123456789\nabcdefghi\njklmnopq\nrstuvwxyz\n!@£$%^&~*()[]{}"
let kFontSampleText_2                   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!@£$%^&~*()[]{}"
let kFontSampleText_1_Lines             = 8
let kFontSampleText_1_Limit             = 48.0

let kHelpPageCount                      = 4

let kFontInstallCountBeforeReviewRequest = 20

let kAppStoreURL                       = "https://apps.apple.com/app/id1505396103"
let kWebsiteURL                        = "https://smittytone.net/fontismo/index.html"

enum kDefaultsKeys {
    static let fontInstallCount        = "com.bps.fontismo.font.installs"
    static let lastReviewVersion       = "com.bps.fontismo.review.version"
    static let shouldShowNewFonts      = "com.bps.fontismo.show.new"
}

let kMaxFeedbackCharacters              = 512
let kFlashBorderTime                    = 0.2
