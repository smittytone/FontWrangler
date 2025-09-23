/*
 *  MasterViewControllerTable.swift
 *  Fontismo
 *
 *  Created by Tony Smith on 23/09/2025.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

import UIKit
import StoreKit


extension MasterViewController {

    /**
     Show the 'please review' dialog if the user is on a new version
     and has installed at least 20 fonts.

     FROM 1.1.1
     */
    internal func requestReview() {

        let infoDictionaryKey = kCFBundleVersionKey as String
        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
            else { fatalError("Expected to find a bundle version in the info dictionary") }

        if let lastVersionChecked = UserDefaults.standard.string(forKey: FONTISMO_CONSTANTS.PREFS_KEYS.LAST_REVIEW_VERSION) {
            // Make sure the user has not already been prompted for this version
            if currentVersion != lastVersionChecked {
                makeRequest(currentVersion)
            }
        } else {
            // Just in case...
            UserDefaults.standard.set("1.0.0", forKey: FONTISMO_CONSTANTS.PREFS_KEYS.LAST_REVIEW_VERSION)
            makeRequest(currentVersion)
        }
    }


    /**
     Configure the rating dialog to appear in two seconds' time.

     FROM 1.1.1

     - Parameters:
        - currentVersion The current version of the app.
     */
    internal func makeRequest(_ currentVersion: String) {

        let twoSecondsFromNow = DispatchTime.now() + 2.0
        DispatchQueue.main.asyncAfter(deadline: twoSecondsFromNow, qos: .userInteractive) { [navigationController] in
            if navigationController?.topViewController is MasterViewController {
                // Show the rating request dialog if 'self' is present
                // FROM 2.2.0 Update to iOS 14 API
                let scenes: [UIScene] = Array(UIApplication.shared.connectedScenes)
                for scene in scenes {
                    if scene.isKind(of: UIWindowScene.self) {
                        let currentWindowScene = scene as! UIWindowScene
                        SKStoreReviewController.requestReview(in: currentWindowScene)
                        UserDefaults.standard.set(currentVersion, forKey: FONTISMO_CONSTANTS.PREFS_KEYS.LAST_REVIEW_VERSION)
                        break
                    }
                }
            }
        }
    }


    /**
     Display an option to review the app on a long press of the master view.

     FROM 1.1.1
     */
    @objc
    internal func doRequestReview() {

        if self.reviewAlert == nil {
            DispatchQueue.main.async(qos: .userInteractive) {
                self.reviewAlert = UIAlertController(title: "Would you like to rate or review this app?",
                                              message: "If you have found Fontismo useful, please consider writing a short App Store review.",
                                              preferredStyle: .alert)

                self.reviewAlert?.addAction(UIAlertAction(title: NSLocalizedString("Not Now", comment: "Default action"),
                                              style: .default,
                                              handler: { (_) in
                    self.reviewAlert = nil
                }))

                self.reviewAlert?.addAction(UIAlertAction(title: NSLocalizedString("Yes, Please", comment: "Default action"),
                                              style: .default,
                                              handler: { (_) in
                    self.reviewAlert = nil
                    self.doReview()
                }))

                self.present(self.reviewAlert!,
                             animated: true,
                             completion: nil)
            }
        }
    }


    /**
     User has chosen to review the app, so pass them on to where they can do so.

     FROM 1.1.2
     */
    internal func doReview() {

        guard let writeReviewURL = URL(string: FONTISMO_CONSTANTS.URLS.APP_STORE + "?action=write-review") else { fatalError("Expected a valid Fontismo review URL") }

        UIApplication.shared.open(writeReviewURL, options: [:]) { (returnValue) in

            let infoDictionaryKey = kCFBundleVersionKey as String
            guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
                else { fatalError("Expected to find a bundle version in the info dictionary") }

            if let lastVersionChecked = UserDefaults.standard.string(forKey: FONTISMO_CONSTANTS.PREFS_KEYS.LAST_REVIEW_VERSION) {
                // Make sure the user has not already been prompted for this version
                if currentVersion != lastVersionChecked {
                    UserDefaults.standard.set(currentVersion, forKey: FONTISMO_CONSTANTS.PREFS_KEYS.LAST_REVIEW_VERSION)
                }
            }
        }
    }

    
}
