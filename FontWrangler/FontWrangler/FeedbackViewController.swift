
//  FeedbackViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 25/01/2021.
//  Copyright © 2021 Tony Smith. All rights reserved.


import Foundation
import UIKit


class FeedbackViewController: UIViewController,
                              URLSessionDelegate,
                              URLSessionDataDelegate,
                              UITextViewDelegate {

    // MARK: - UI Outlets

    @IBOutlet var feedbackText: UITextView!
    @IBOutlet var connectionProgress: UIActivityIndicatorView!
    @IBOutlet var textLengthLabel: UILabel!
    @IBOutlet var sendButton: UIButton!
    
    // MARK: - Private Properties

    private var feedbackTask: URLSessionTask? = nil
    private var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()


    
    // MARK: - Lifecycle Functions

    override func viewDidLoad() {
        
        // Call the parent class' function
        super.viewDidLoad()
            
        // Set up the UITextView
        self.feedbackText.backgroundColor = UIColor.systemBackground
        self.feedbackText.textColor = UIColor.label
        self.feedbackText.layer.borderColor = UIColor.gray.cgColor;
        self.feedbackText.layer.borderWidth = 2.0;
        self.feedbackText.layer.cornerRadius = 8.0;
        self.feedbackText.textContainerInset = UIEdgeInsets.init(top: 8, left: 5, bottom: 8, right: 5)
        
        // Set the View Controller as the UITextView's delegate
        self.feedbackText.delegate = self
        
        // Set the tap recognizer that'll hide the keyboard
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {

        // Call the parent class' function
        super.viewWillAppear(animated)
        
        // Reset the UI: hide the progress indicator...
        self.connectionProgress.isHidden = true
        self.connectionProgress.stopAnimating()
        
        // ...and clear the feeback text entry field...
        self.feedbackText.text = ""
                
        // ...and set the text counter...
        self.textLengthLabel.text = "0/\(kMaxFeedbackCharacters)"
        
        // ..and the 'Send' button
        self.sendButton.setTitle("Cancel", for: .normal)
    }

    
    // MARK: - User Actions

    @IBAction @objc func doCancel(sender: Any?) {

        // User has clicked 'Cancel', so just close the sheet
        // 'Cancel' is the X button in the top right
        
        dismissKeyboard()
        self.dismiss(animated: true, completion: nil)
    }


    @IBAction @objc func doSend(sender: Any?) {

        // User clicked 'Send' so get the message (if there is one) from the text field and send it
        
        self.feedbackText.resignFirstResponder()
        let feedback: String = self.feedbackText.text

        if feedback.count > 0 {
            // Start the connection indicator if it's not already visible
            self.connectionProgress.isHidden = false
            self.connectionProgress.startAnimating()

            // Send the string etc.
            let userAgent: String = getUserAgent()
            let dateString = getDateString()
            
            // Assemble the message string
            let dataString: String = """
             *FEEDBACK REPORT*
             *Date:* \(dateString)
             *User Agent:* \(userAgent)
             *FEEDBACK:*
             \(feedback)
             """

            let dict: NSMutableDictionary = NSMutableDictionary()
            dict.setObject(dataString,
                           forKey: NSString.init(string: "text"))
            dict.setObject(true,
                           forKey: NSString.init(string: "mrkdwn"))

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
            // Cancel the sheet
            doCancel(sender: nil);
        }
    }

    
    @objc func dismissKeyboard() {
        
        // Tell the UITextView to end editing -- which will remove the keyboard
        
        self.feedbackText.resignFirstResponder()
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
        return "\(app)/\(version).\(build) (\(getDeviceType()) iOS \(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion))"
    }
    
    
    func getDeviceType() -> String {
        
        // FROM 1.1.2
        // Return a device-type string
        
        switch  UIDevice.current.userInterfaceIdiom {
            case .phone:
                    return "iPhone"
            case .pad:
                return "iPad"
            case .tv:
                return "ATV"
            case .carPlay:
                return "CarPlay Device"
            case .mac:
                return "Mac"
            default:
                return "Unknown"
        }
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
        
        // Trap text changes so that no more than kMaxFeedbackCharacters
        // can be entered into the UITextView
        
        if self.feedbackText.text.count > kMaxFeedbackCharacters {
            // Prune the feedback to kMaxFeedbackCharacters chars
            let edit: Substring = self.feedbackText.text.prefix(kMaxFeedbackCharacters)
            textView.text = String(edit)
            
            // Tell the user about the limit by flashing the
            // border colour red and back
            flashBorder()
        }
        
        // Set the button title according to the amount of feedback text
        self.sendButton.setTitle(self.feedbackText.text.count > 0 ? "Send" : "Cancel",
                                 for: .normal)
        
        // Set the text length label
        self.textLengthLabel.text = "\(self.feedbackText.text.count)/\(kMaxFeedbackCharacters)"
    }
    
    
    func flashBorder() {
        
        // Set the UITextView border colour red
        self.feedbackText.layer.borderColor = UIColor.red.cgColor
        
        // Switch the border back to grey in half a second
        _ = Timer.scheduledTimer(withTimeInterval: kFlashBorderTime, repeats: false, block: { (timer) in
            self.feedbackText.layer.borderColor = UIColor.gray.cgColor;
        })
    }

}
