//  Constants.swift
//  Fontismo
//
//  Created by Tony Smith on 29/03/2020.
//  Copyright © 2023 Tony Smith. All rights reserved.


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

let kAppStoreURL                        = "https://apps.apple.com/app/id1505396103"
let kWebsiteURL                         = "https://smittytone.net/fontismo/index.html"

enum kDefaultsKeys {
    static let appVersion               = "com.bps.fontwrangler.app.version"
    static let appBuild                 = "com.bps.fontwrangler.app.build"
    static let shouldShowIntro          = "com.bps.fontwrangler.app.show.intro"
    static let authors                  = "com.bps.fontwrangler.app.licence.authors"
    static let fontInstallCount         = "com.bps.fontismo.font.installs"
    static let lastReviewVersion        = "com.bps.fontismo.review.version"
    static let shouldShowNewFonts       = "com.bps.fontismo.show.new"
}

let kMaxFeedbackCharacters              = 512
let kFlashBorderTime                    = 0.2

// FROM 1.2.0

enum kPaymentNotifications {
    static let tip                      = "com.bps.fontismo.notification.tip.received"
    static let restored                 = "com.bps.fontismo.notification.purchases.restored"
    static let updated                  = "com.bps.fontismo.notification.products.updated"
    static let failed                   = "com.bps.fontismo.notification.purchase.failed"
    static let cancelled                = "com.bps.fontismo.notification.purchase.cancelled"
    static let inflight                 = "com.bps.fontismo.notification.purchase.inflight"
}

let kStandardSeparation                 = 8.0
let kLogoLandscapeSeparation            = -16.0
let kTextLandscapeSeparation            = 0.0
