//
//  TipViewController.swift
//  FontWrangler
//
//  Created by Tony Smith on 03/04/2022.
//  Copyright © 2022 Tony Smith. All rights reserved.
//

import UIKit
import StoreKit


class TipViewController: UIViewController {
    
    // MARK: - UI Outlets

    @IBOutlet weak var cantMakePaymentsLabel: UILabel!
    @IBOutlet weak var thankYouLabel: UILabel!
    @IBOutlet weak var storeProgress: UIActivityIndicatorView!
    @IBOutlet weak var priceCollectionView: UICollectionView!
    @IBOutlet weak var makePaymentButton: UIButton!
    
    // MARK: Private Properties
    
    private var storeController: StoreController? = nil
    private var availableProducts: [SKProduct] = []
    private var productEmojis: [String] = ["👍", "👏", "🙌", "❤️", "😍"]
    
    
    // MARK: - Initialisation Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.storeController = StoreController.init()
        if self.storeController != nil {
            self.storeController!.initPaymentQueue()
        }
        
        self.title = "Make a Donation"
        let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done",
                                                          style: .done,
                                                          target: self,
                                                          action: #selector(self.doDone))
        navigationItem.rightBarButtonItem = doneButton
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Prep for a new appearance
        self.makePaymentButton.isEnabled = false
        self.thankYouLabel.isHidden = true
        self.cantMakePaymentsLabel.isHidden = true
        
        // Check payments can be made etc.
        initStore()
        
        // Handle super class stuff
        super.viewWillAppear(animated)
    }
    
    
    private func initStore() {
        self.storeProgress.startAnimating()
        
        // Check for the ability to purchase
        guard self.storeController!.canMakePayments else {
            self.storeProgress.stopAnimating()
            self.cantMakePaymentsLabel.isHidden = false
            hidePurchaseUI()
            return
        }
        
        // We're good to go, so prep the notifications
        let nc: NotificationCenter = .default
        nc.addObserver(self, selector: #selector(showThankYou), name: NSNotification.Name.init(rawValue: kPaymentNotifications.tip), object: nil)
        nc.addObserver(self, selector: #selector(showThankYou), name: NSNotification.Name.init(rawValue: kPaymentNotifications.restored), object: nil)
        nc.addObserver(self, selector: #selector(productListReceived), name: NSNotification.Name.init(rawValue: kPaymentNotifications.updated), object: nil)
        nc.addObserver(self, selector: #selector(storeFailure), name: NSNotification.Name.init(rawValue: kPaymentNotifications.failed), object: nil)
        
        // Check available products
        self.storeController!.validateProductIdentifiers()
    }
    
    
    private func hidePurchaseUI() {
        
        // The user can't make payments, so hide the UI
        self.makePaymentButton.isEnabled = false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Action Functions
    
    @IBAction @objc func doDone(_ sender: Any) {
        
        // User has clicked 'Done', so just close the sheet
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func showThankYou(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.thankYouLabel.isHidden = false
            self.hidePurchaseUI()
        }
    }
    
    @objc func productListReceived(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.cantMakePaymentsLabel.isHidden = false
            self.storeProgress.stopAnimating()
            self.hidePurchaseUI()
        }
    }
    
    @objc func storeFailure(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.cantMakePaymentsLabel.isHidden = false
            self.storeProgress.stopAnimating()
            self.hidePurchaseUI()
        }
    }
}
