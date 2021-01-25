//
//  FeedbackViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 25/01/2021.
//  Copyright © 2021 Tony Smith. All rights reserved.
//


import Foundation
import UIKit


class FeedbackViewController: UIViewController, URLSessionDelegate, URLSessionDataDelegate {

    // MARK: - UI Outlets

    @IBOutlet var feedbackText: UITextView!
    @IBOutlet var connectionProgress: UIActivityIndicatorView!


    // MARK: - Class Properties

    private var feedbackTask: URLSessionTask? = nil


    // MARK: - Lifecycle Functions

    override func viewDidLoad() {

    }


    override func viewWillAppear(_ animated: Bool) {

        // Reset the UI
        self.connectionProgress.isHidden = true
        self.connectionProgress.stopAnimating()
        self.feedbackText.text = ""
    }

    
    // MARK: - User Actions

    @IBAction @objc func doCancel(sender: Any?) {

        // User has clicked 'Cancel', so just close the sheet

        self.dismiss(animated: true, completion: nil)
    }


    @IBAction @objc func doSend(sender: Any?) {

        // User clicked 'Send' so get the message (if there is one) from the text field and send it

        let feedback: String = self.feedbackText.text

        if feedback.count > 0 {
            // Start the connection indicator if it's not already visible
            self.connectionProgress.isHidden = false
            self.connectionProgress.startAnimating()

            // Send the string etc.
            let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
            let bundle: Bundle = Bundle.main
            let app: String = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
            let version: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            let build: String = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String
            let userAgent: String = "\(app) \(version) (build \(build)) (macOS \(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion))"

            let date: Date = Date()
            var dateString = "Unknown"

            let def: DateFormatter = DateFormatter()
            def.locale = Locale(identifier: "en_US_POSIX")
            def.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            def.timeZone = TimeZone(secondsFromGMT: 0)
            dateString = def.string(from: date)

            let dict: NSMutableDictionary = NSMutableDictionary()
            dict.setObject("*FEEDBACK REPORT*\n*DATE* \(dateString))\n*USER AGENT* \(userAgent)\n*FEEDBACK* \(feedback)",
                            forKey: NSString.init(string: "text"))
            dict.setObject(true, forKey: NSString.init(string: "mrkdown"))

            if let url: URL = URL.init(string: MNU_SECRETS.ADDRESS.A + MNU_SECRETS.ADDRESS.B) {
                var request: URLRequest = URLRequest.init(url: url)
                request.httpMethod = "POST"
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: dict,
                                                                  options:JSONSerialization.WritingOptions.init(rawValue: 0))

                    request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
                    request.addValue("application/json", forHTTPHeaderField: "Content-type")

                    let config: URLSessionConfiguration = URLSessionConfiguration.ephemeral
                    let session: URLSession = URLSession.init(configuration: config,
                                                              delegate: self,
                                                              delegateQueue: OperationQueue.main)
                    self.feedbackTask = session.dataTask(with: request)
                    self.feedbackTask?.resume()
                } catch {
                    sendFeedbackError()
                }
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }


    // MARK: - URLSession Delegate Functions

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {

        // Some sort of connection error - report it

        sendFeedbackError()
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        // The operation to send the comment completed

        if let _ = error {
            // An error took place - report it
            sendFeedbackError()
        } else {
            // The comment was submitted successfully
            DispatchQueue.main.async {
                let alert = UIAlertController.init(title: "Thanks For Your Feedback!",
                                                   message: "Your comments have been received and we’ll take a look at them shortly.",
                                                   preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                              style: .default,
                                              handler: nil))
                self.present(alert,
                             animated: true,
                             completion: nil)
            }

            self.dismiss(animated: true, completion: nil)
        }
    }


    // MARK: - Misc Functions

    func sendFeedbackError() {

        // Present an error message specific to sending feedback
        // This is called from multiple locations: if the initial request can't be created,
        // there was a send failure, or a server error

        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: "Feedback Could Not Be Sent",
                                               message: "Unfortunately, your comments could not be send at this time. Please try again later.",
                                               preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                          style: .default,
                                          handler: nil))
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }

}
