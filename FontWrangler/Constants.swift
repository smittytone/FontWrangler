/*
 *  Constants.swift
 *  Fontismo
 *
 *  Created by Tony Smith on 29/03/2020.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

import Foundation
import CoreGraphics


// MARK: Constants

struct FONTISMO_CONSTANTS {

    struct TIMEOUTS {

        static let FONT_DOWNLOAD                = 30.0
    }

    struct URLS {

        static let APP_STORE                    = "https://apps.apple.com/app/id1505396103"
        static let WEBSITE                      = "https://smittytone.net/fontismo/index.html"
    }

    struct PREFS_KEYS {

        static let APP_VERSION                  = "com.bps.fontwrangler.app.version"
        static let APP_BUILD                    = "com.bps.fontwrangler.app.build"
        static let SHOW_INTRO                   = "com.bps.fontwrangler.app.show.intro"
        static let AUTHORS                      = "com.bps.fontwrangler.app.licence.authors"
        static let FONT_INSTALL_COUNT           = "com.bps.fontismo.font.installs"
        static let LAST_REVIEW_VERSION          = "com.bps.fontismo.review.version"
        static let SHOW_NEW_FONTS               = "com.bps.fontismo.show.new"
        // FROM 2.0.0
        static let FONT_AUTO_INSTALL            = "com.bps.fontwrangler.app.auto.download"
    }

    struct FONT_STYLE_INDICES {

        static let CLASSIC                      = 0
        static let HEADLINE                     = 1
        static let DECORATIVE                   = 2
        static let MONOSPACE                    = 3
        static let NEW                          = 6
        static let UNKNOWN                      = 99
    }

    enum FONT_SHOW_MODE_INDICES {

        static let NEW                          = 0
        static let INSTALLED                    = 1
        static let UNINSTALLED                  = 2
    }

    struct  PAYMENT_NOTIFICATIONS {

        static let TIP                          = "com.bps.fontismo.notification.tip.received"
        static let RESTORED                     = "com.bps.fontismo.notification.purchases.restored"
        static let UPDATED                      = "com.bps.fontismo.notification.products.updated"
        static let FAILED                       = "com.bps.fontismo.notification.purchase.failed"
        static let CANCELLED                    = "com.bps.fontismo.notification.purchase.cancelled"
        static let INFLIGHT                     = "com.bps.fontismo.notification.purchase.inflight"
    }

    static let FONTS_DIR_PATH                   = "/fonts"
    static let FONT_LIST_SUB_PATH               = "/fontlist"
    static let FONT_DEFAULTS_FILENAME           = "/defaults.json"
    static let FONT_SAMPLE: [String]            = ["ABCDEFGHI\nJKLMNOPQ\nRSTUVWXYZ\n0123456789\nabcdefghi\njklmnopq\nrstuvwxyz\n!@£$%^&~*()[]{}",
                                                   "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!@£$%^&~*()[]{}"]
    static let FONT_SAMPLE_LINES                = 8
    static let FONT_SAMPLE_LIMIT                = 48.0
    static let FONT_SAMPLE_SIZE: CGFloat        = 20.0
    static let FONT_DYNAMIC_SIZE: CGFloat       = 32.0
#if DEBUG
    static let REVIEW_TRIGGER_INSTALL_COUNT     = 2000
#else
    static let REVIEW_TRIGGER_INSTALL_COUNT     = 20
#endif
    static let HELP_PAGE_COUNT                  = 5
    static let MAX_FEEDBACK_CHARACTERS          = 512
    static let FEEDBACK_BORDER_FLASH_TIME       = 0.2
    // FROM 1.2.0
    static let TIP_ITEM_SEPARATION              = 8.0
    static let TIP_LOGO_LANDSCAPE_SEPARATION    = -16.0
    static let TIP_TEXT_LANDSCAPE_SEPARATION    = 0.0
    // FROM 2.1.0
    static let ASYNC_QUEUE_ID                   = "com.bps.fontismo.async-queue"


}


/*
 LEGACY ITEMS

let kDeregisterFontTimeout              = 10.0

enum kFontStyleIndices {
    static let classic                  = 0
    static let headline                 = 1
    static let decorative               = 2
    static let monospace                = 3
    static let new                      = 6
    static let unknown                  = 99
}
*/
