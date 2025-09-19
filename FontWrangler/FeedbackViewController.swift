/*
 *  FeedbackViewController.swift
 *  Fontismo
 *
 *  Created by Tony Smith on 25/01/2021.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

import UIKit


class FeedbackViewController: UIViewController,
                              URLSessionDelegate,
                              URLSessionDataDelegate,
                              UITextViewDelegate {

    // MARK: - UI Outlets

    @IBOutlet weak var feedbackText: UITextView!
    @IBOutlet weak var connectionProgress: UIActivityIndicatorView!
    @IBOutlet weak var textLengthLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    // FROM 2.1.1
    @IBOutlet weak var textTopContstraint: NSLayoutConstraint!
    @IBOutlet weak var exitButtonTopContstraint: NSLayoutConstraint!


    // MARK: - Private Properties

    private var feedbackTask: URLSessionTask? = nil
    private var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()


    // MARK: - Lifecycle Functions

    override func viewDidLoad() {
        
        // Call the parent class' function
        super.viewDidLoad()
            
        // Set up the UITextView
        self.feedbackText.backgroundColor = .systemBackground
        self.feedbackText.layer.borderColor = UIColor.gray.cgColor;
        self.feedbackText.layer.borderWidth = 2.0;
        self.feedbackText.layer.cornerRadius = 8.0;
        self.feedbackText.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        
        // Set the View Controller as the UITextView's delegate
        self.feedbackText.delegate = self

        // Set the tap recognizer that'll hide the keyboard
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(self.tapGestureRecognizer)

        // FROM 2.1.1
        // Adjust the items at the top of the view under iOS 26+
        if #available(iOS 26, *) {
            self.textTopContstraint.constant = 22
            self.exitButtonTopContstraint.constant = 25
        }
    }


    override func viewWillAppear(_ animated: Bool) {

        // Call the parent class' function
        super.viewWillAppear(animated)
        
        // Reset the UI: hide the progress indicator...
        self.connectionProgress.isHidden = true
        self.connectionProgress.stopAnimating()
        
        // FROM 1.2.0
        // Set fake placeholder text: enter the text and colour it light grey.
        // As soon as the user enters their own text, the delegate method `didBeginEditing()`
        // is called and this removes the placeholder and sets the colour to `.label`
        self.feedbackText.text = "Please note that we can’t respond to support requests if you don’t include an email address. If you provide an email address, it will not be retained or recorded, and used only to contact you for support reasons."
        self.feedbackText.textColor = .lightGray

        // ...and set the text counter...
        self.textLengthLabel.text = "0/\(FONTISMO_CONSTANTS.MAX_FEEDBACK_CHARACTERS)"
        
        // ..and the 'Send' button
        self.sendButton.setTitle("Cancel", for: .normal)
    }


    // MARK: - User Action Functions

    /**
     User has clicked 'Cancel', so just close the sheet.

     'Cancel' is the X button in the top right.
     */
    @IBAction
    @objc
    func doCancel(sender: Any?) {

        dismissKeyboard()
        self.dismiss(animated: true, completion: nil)
    }


    /**
     User clicked 'Send' so get the message (if there is one) from the text field and send it.
     */
    @IBAction
    @objc
    func doSend(sender: Any?) {

        self.feedbackText.resignFirstResponder()
        let feedback: String = self.feedbackText.text

        if self.feedbackText.textColor != .lightGray && feedback.count > 0 {
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
            dict.setObject(dataString, forKey: NSString(string: "text"))
            dict.setObject(true, forKey: NSString(string: "mrkdwn"))

            if let url: URL = URL(string: MNU_SECRETS.ADDRESS.B + MNU_SECRETS.ADDRESS.A) {
                var request: URLRequest = URLRequest(url: url)
                request.httpMethod = "POST"
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: dict,
                                                                  options:JSONSerialization.WritingOptions(rawValue: 0))

                    request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
                    request.addValue("application/json", forHTTPHeaderField: "Content-type")

                    let config: URLSessionConfiguration = URLSessionConfiguration.ephemeral
                    let session: URLSession = URLSession(configuration: config,
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


    /**
     Tell the UITextView to end editing -- which will remove the keyboard.
     */
    @objc
    func dismissKeyboard() {

        self.feedbackText.resignFirstResponder()
    }


    // MARK: - URLSession Delegate Functions

    /**
     Some sort of connection error has occurred - report it.
     */
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {

        self.sendFeedbackError()
    }


    /**
     The operation to send the comment completed.
     */
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        if let _ = error {
            // An error took place - report it
            self.sendFeedbackError()
        } else {
            // The comment was submitted successfully, so thank the user
            DispatchQueue.main.async(qos: .userInteractive) {
                self.connectionProgress.stopAnimating()

                let alert = UIAlertController(title: "Thanks For Your Feedback!",
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

    /**
     Present an error message specific to sending feedback.

     This is called from multiple locations: if the initial request can't be created,
     there was a send failure, or a server error.
     */
    func sendFeedbackError() {

        DispatchQueue.main.async(qos: .userInteractive) {
            self.connectionProgress.stopAnimating()
            
            let alert = UIAlertController(title: "Feedback Could Not Be Sent",
                                          message: "Unfortunately, your comments could not be send at this time. Please try again later.",
                                          preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                          style: .default,
                                          handler: nil))

            self.present(alert, animated: true, completion: nil)
        }
    }


    /**
     Generate the user-agent string.

     - Returns The user-agent string.
     */
    func getUserAgent() -> String {
        
        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let bundle: Bundle = Bundle.main
        let app: String = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
        let version: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        return "\(app)/\(version).\(build) (\(FeedbackViewController.getDeviceType()) iOS \(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion))"
    }


    /**
     Generate a device-type string, consumed by `getUserAgent()`.

     FROM 1.1.2

     - Returns The device-type string.
     */
    static func getDeviceType() -> String {
        
        switch UIDevice.current.userInterfaceIdiom {
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


    /**
     Return the current date as formatted string.

     - Returns The current date.
     */
    func getDateString() -> String {
        
        let date: Date = Date()
        let def: DateFormatter = DateFormatter()
        def.locale = Locale(identifier: "en_US_POSIX")
        def.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        def.timeZone = TimeZone(secondsFromGMT: 0)
        return def.string(from: date)
    }


    // MARK: - UITextViewDelegate Functions

    /**
     Trap text changes so that no more than FONTISMO_CONSTANTS.MAX_FEEDBACK_CHARACTERS
     can be entered into the UITextView
     */
    func textViewDidChange(_ textView: UITextView) {
        
        if self.feedbackText.text.count > FONTISMO_CONSTANTS.MAX_FEEDBACK_CHARACTERS {
            // Prune the feedback to FONTISMO_CONSTANTS.MAX_FEEDBACK_CHARACTERS chars
            let edit: Substring = self.feedbackText.text.prefix(FONTISMO_CONSTANTS.MAX_FEEDBACK_CHARACTERS)
            textView.text = String(edit)
            
            // Tell the user about the limit by flashing the
            // border colour red and back
            flashBorder()
        }
        
        // Set the button title according to the amount of feedback text
        self.sendButton.setTitle(self.feedbackText.text.count > 0 ? "Send" : "Cancel", for: .normal)

        // Set the text length label
        self.textLengthLabel.text = "\(self.feedbackText.text.count)/\(FONTISMO_CONSTANTS.MAX_FEEDBACK_CHARACTERS)"
    }


    /**
     When the user starts enterting text, remove the placeholder text
     // and set the correct text colour.

     FROM 1.2.0
     */
    func textViewDidBeginEditing(_ textView: UITextView) {

        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .label
        }
    }


    /**
     Briefly outline the UITextView border red and then reset it back.
     
     This is called to show that too many characters have been entered
     */
    func flashBorder() {
        
        // Set the UITextView border colour red
        self.feedbackText.layer.borderColor = UIColor.red.cgColor
        
        // Switch the border back to grey in half a second
        _ = Timer.scheduledTimer(withTimeInterval: FONTISMO_CONSTANTS.FEEDBACK_BORDER_FLASH_TIME, repeats: false, block: { (timer) in
            self.feedbackText.layer.borderColor = UIColor.gray.cgColor;
        })
    }
}
