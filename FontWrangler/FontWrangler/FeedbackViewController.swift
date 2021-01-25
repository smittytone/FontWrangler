//
//  FeedbackViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 25/01/2021.
//  Copyright © 2021 Tony Smith. All rights reserved.
//


import Foundation
import UIKit


class FeedbackViewController: UIViewController, URLSessionDelegate, URLSessionDataDelegate, UITextViewDelegate {

    // MARK: - UI Outlets

    @IBOutlet var feedbackText: UITextView!
    @IBOutlet var connectionProgress: UIActivityIndicatorView!
    @IBOutlet var textLengthLabel: UILabel!


    // MARK: - Class Properties

    private var feedbackTask: URLSessionTask? = nil
    var myself: FeedbackViewController? = nil


    // MARK: - Lifecycle Functions

    override func viewWillAppear(_ animated: Bool) {

        // Reset the UI
        self.connectionProgress.isHidden = true
        self.connectionProgress.stopAnimating()
        
        self.feedbackText.delegate = self
        self.feedbackText.text = ""
        self.feedbackText.textColor = UIColor.black
        self.feedbackText.backgroundColor = UIColor.init(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        
        self.textLengthLabel.text = "0/512"
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
            let userAgent: String = getUserAgent()
            let dateString = getDateString()

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
            // The comment was submitted successfully, so thank the user
            self.connectionProgress.stopAnimating()

            DispatchQueue.main.async {
                let alert = UIAlertController.init(title: "Thanks For Your Feedback!",
                                               message: "Your comments have been received and we’ll take a look at them shortly.",
                                               preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                              style: .default,
                                              handler: { (action) in
                    
                    // Dismiss the FeedbackViewController now we're done
                    self.dismiss(animated: true, completion: nil)
                }))
                
                // Present the thanks
                self.present(alert, animated: true, completion: nil)
            }
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
    
    
    func getUserAgent() -> String {
        
        // Return the user-agent string
        
        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let bundle: Bundle = Bundle.main
        let app: String = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
        let version: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        return "\(app) \(version) (build \(build)) (iOS \(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion))"
    }
    
    
    func getDateString() -> String {
        
        // Return the current date as formatted string
        
        let date: Date = Date()
        let def: DateFormatter = DateFormatter()
        def.locale = Locale(identifier: "en_US_POSIX")
        def.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        def.timeZone = TimeZone(secondsFromGMT: 0)
        return def.string(from: date)
    }
    
    
    // MARK: - UITextViewDelegate Functions
    
    func textViewDidChange(_ textView: UITextView) {
        
        // Trap text changes so that no more than
        
        // The maximum we are allowing is 512 chars
        if self.feedbackText.text.count > 512 {
            // Prune the feedback to 512 chars
            let edit: Substring = self.feedbackText.text.prefix(512)
            self.feedbackText.text = String(edit)
            
            // Tell the user about the limit
            DispatchQueue.main.async {
                let alert = UIAlertController.init(title: "512 characters max.",
                                               message: "Please ensure your comment is no more than 512 characters in length.",
                                               preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                              style: .default,
                                              handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        // Set the text length label
        self.textLengthLabel.text = "\(self.feedbackText.text.count)/512"
    }

}
