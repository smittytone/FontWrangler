
//  AppDelegate.swift
//  Fontismo
//
//  Created by Tony Smith on 27/03/2020.
//  Copyright © 2022 Tony Smith. All rights reserved.


import UIKit


@UIApplicationMain
class AppDelegate: UIResponder,
                   UIApplicationDelegate {


    private let bundlePath = Bundle.main.bundlePath
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Set data for app settings bundle
        let defaults: UserDefaults = UserDefaults.standard

        // The app version
        defaults.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                     forKey: kDefaultsKeys.appVersion)

        // The app build
        defaults.set(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String,
                     forKey: kDefaultsKeys.appBuild)

        // Whether the app should show first-run guidance
        // NOTE Check for key presence before writing a default value, otherwise
        //      the panel is always shown when the app launches
        let introKeyIsPresent = defaults.object(forKey: kDefaultsKeys.shouldShowIntro)
        if introKeyIsPresent == nil {
            defaults.set(true, forKey: kDefaultsKeys.shouldShowIntro)
        }
        
        // Set the creators string for the Settings > Authors readout
        let creators = self.getCreators()
        if creators != "" {
            defaults.set(creators, forKey: kDefaultsKeys.authors)
        }
        
        // FROM 1.2.0
        let newKeyIsPresent = defaults.object(forKey: kDefaultsKeys.shouldShowNewFonts)
        if newKeyIsPresent == nil {
            defaults.set(true, forKey: kDefaultsKeys.shouldShowNewFonts)
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
    
    
    func getCreators() -> String {
        
        // Load in the default list of available fonts and extract their creators
        // and licence details into a string, which is returned.
        // Returns an empty string on failure

        let fm = FileManager.default
        let defaultFontsPath = self.bundlePath + kDefaultsPath
        var fontDictionary: [String: Any] = [:]
        
        if fm.fileExists(atPath: defaultFontsPath) {
            do {
                let fileData = try Data(contentsOf: URL.init(fileURLWithPath: defaultFontsPath))
                fontDictionary = try JSONSerialization.jsonObject(with: fileData, options: []) as! [String: Any]
            } catch {
                NSLog("[ERROR] can't load defaults: \(error.localizedDescription) from App Delegate")
                return ""
            }
            
            // Extract the creator data into an a array of dictionaries, one
            // dictionary per typeface
            // NOTE There should be only one creator field PER TYPEFACE
            var creators = [[String:String]]()
            let fonts = fontDictionary["fonts"] as! [Any]
            for font in fonts {
                let aFont = font as! [String:String]
                
                var item = [String:String]()
                item["c"] = aFont["creator"] ?? ""
                item["l"] = aFont["licence"] ?? ""
                item["t"] = aFont["tag"] ?? ""
                
                if item["c"] != "" {
                    creators.append(item)
                }
            }
            
            // Sort the list alphabetically
            creators.sort { (item_1, item_2) -> Bool in
                return (item_1["t"]! < item_2["t"]!)
            }
            
            // Assemble the string
            // NOTE Use '\r\n' for newlines - required by iOS settings
            var creatorString = ""
            for item in creators {
                creatorString += (item["t"]!.capitalized + " by " + item["c"]! + " " + (item["l"]! == "OFT" ? "*" : "†") + "\r\n")
            }
            
            // Add the footnotes and return the completed string
            creatorString += "\r\n* Open Font Licence\r\n† Apache Licence 2.0"
            return creatorString
        } else {
            NSLog("[ERROR] can't find defaults from App Delegate")
        }
        
        return ""
    }
    
}

