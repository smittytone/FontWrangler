/*
 *  Extensions.swift
 *  Fontismo
 *
 *  Created by Tony Smith on 17/10/2024.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

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

        // FROM 2.2.0
        // Wrap the detail view trigger, or it'll crash on iOS 26
        let barButtonItem = self.displayModeButtonItem
        if let action = barButtonItem.action {
            let _ = UIApplication.shared.sendAction(action,
                                                    to: barButtonItem.target,
                                                    from: nil,
                                                    for: nil)
        }
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


extension UIImage {

    // Return a version of the image scaled to the specified size
    // (or just return the image on iOS 18 or under)

    func scale(to: CGSize) -> UIImage {
        if #available(iOS 26, *) {
            return UIGraphicsImageRenderer(size: to).image { _ in
                draw(in: CGRect(origin: .zero, size: to))
            }
        }

        return self
    }
}
