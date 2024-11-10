
//  Extensions.swift
//  Fontismo
//  iOS Class Extensions
//
//  Created by Tony Smith on 17/10/2024.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit
import StoreKit


extension NSLayoutManager {

    // FROM 1.1.1
    // Add alternative (and better) sample text line counter
    // Adapted from https://stackoverflow.com/a/49528540

    var lines: Int {
        guard let _ = textStorage else { return 0 }

        var lineCount = 0
        let range = NSMakeRange(0, numberOfGlyphs)
        enumerateLineFragments(forGlyphRange: range) { _, _, _, _, _ in
            lineCount += 1
        }

        return lineCount
    }
}


extension UISplitViewController {
    
    func toggleMasterView() {
        
        let barButtonItem = self.displayModeButtonItem
        let _ = UIApplication.shared.sendAction(barButtonItem.action!,
                                                to: barButtonItem.target,
                                                from: nil, for: nil)
    }
}


extension SKProduct {

    // Add a `localPrice` property which provides the local price with
    // an appropriate currency label attached
    
    var localPrice: String? {
        let priceFormatter: NumberFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = self.priceLocale
        return priceFormatter.string(from: self.price)
    }
}
