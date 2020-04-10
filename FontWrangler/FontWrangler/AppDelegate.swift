//
//  AppDelegate.swift
//  FontWrangler
//
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Set data for app settings bundle
        let defaults: UserDefaults = UserDefaults.standard

        // The app version
        defaults.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                     forKey: "com.bps.fontwrangler.app.version")

        // The app build
        defaults.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String,
                     forKey: "com.bps.fontwrangler.app.build")

        // Whether the app should show first-run guidance
        // NOTE Check for key presence before writing a default value, otherwise
        //      the panel is always shown when the app launches
        let introKeyIsPresent = defaults.object(forKey: "com.bps.fontwrangler.app.show.intro")
        if introKeyIsPresent == nil {
            defaults.set(true, forKey: "com.bps.fontwrangler.app.show.intro")
        }

        return true
    }


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

