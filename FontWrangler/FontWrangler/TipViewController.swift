//
//  TipViewController.swift
//  FontWrangler
//
//  Created by Tony Smith on 03/04/2022.
//  Copyright © 2022 Tony Smith. All rights reserved.
//

import UIKit
import StoreKit


class TipViewController: UIViewController,
                         UICollectionViewDelegate,
                         UICollectionViewDataSource,
                         UICollectionViewDelegateFlowLayout {
    
    // MARK: - UI Outlets

    @IBOutlet weak var cantMakePaymentsLabel: UILabel!
    @IBOutlet weak var thankYouLabel: UILabel!
    @IBOutlet weak var storeProgress: UIActivityIndicatorView!
    @IBOutlet weak var priceCollectionView: UICollectionView!
    
    // MARK: Private Properties
    
    private var storeController: StoreController? = nil
    private var productEmojis: [String] = ["🪙", "☕️", "🍩", "🍕", "🍱"]
    
    
    // MARK: - Initialisation Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Set up the App Store mediatator
        self.storeController = StoreController.init()
        if self.storeController != nil {
            self.storeController!.initPaymentQueue()
        }
        
        // Set up the window and the `Done` button
        self.title = "Make a Donation"
        let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done",
                                                          style: .done,
                                                          target: self,
                                                          action: #selector(self.doDone))
        navigationItem.rightBarButtonItem = doneButton
        
        // Wire it all up
        self.priceCollectionView.delegate = self
        self.priceCollectionView.dataSource = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Prepare for a new appearance
        self.thankYouLabel.isHidden = true
        self.cantMakePaymentsLabel.isHidden = true
        hidePurchaseUI()
        
        // Check payments can be made, etc.
        // NOTE Here in case ability is lost between appearances
        initStore()
        
        // Handle super class stuff
        super.viewWillAppear(animated)
    }
    
    
    private func initStore() {
        
        // Start the loading animation
        self.storeProgress.startAnimating()
        
        // Check for the ability to purchase
        guard self.storeController!.canMakePayments else {
            self.storeProgress.stopAnimating()
            self.cantMakePaymentsLabel.isHidden = false
            return
        }
        
        // We're good to go, so prep the notifications
        let nc: NotificationCenter = .default
        nc.addObserver(self,
                       selector: #selector(productListReceived),
                       name: NSNotification.Name.init(rawValue: kPaymentNotifications.updated),
                       object: nil)

        nc.addObserver(self,
                       selector: #selector(showThankYou),
                       name: NSNotification.Name.init(rawValue: kPaymentNotifications.tip),
                       object: nil)
        
        nc.addObserver(self,
                       selector: #selector(storeFailure),
                       name: NSNotification.Name.init(rawValue: kPaymentNotifications.failed),
                       object: nil)
        
        nc.addObserver(self,
                       selector: #selector(showThankYou),
                       name: NSNotification.Name.init(rawValue: kPaymentNotifications.restored),
                       object: nil)
        
        // Check available products
        self.storeController!.validateProductIdentifiers()
    }
    
    
    private func hidePurchaseUI() {
        
        // The user can't make payments, so hide the UI
        
        self.priceCollectionView.isHidden = true
    }

    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _  in
            self?.updateCollectionViewSize()
            self?.priceCollectionView.layoutIfNeeded()
            self?.priceCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    
    private func showPurchaseUI() {
        
        // Present the products UI
        
        self.priceCollectionView.reloadData()
        updateCollectionViewSize()
        self.priceCollectionView.isHidden = false
    }

    
    // MARK: - Action Functions
    
    @IBAction @objc func doDone(_ sender: Any) {
        
        // User has clicked 'Done', so just close the sheet
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func showThankYou(_ note: Notification) {
        
        DispatchQueue.main.async {
            self.hidePurchaseUI()
            self.thankYouLabel.isHidden = false
        }
    }
    
    
    @objc func productListReceived(_ note: Notification) {
        
        DispatchQueue.main.async {
            self.storeProgress.stopAnimating()
            self.showPurchaseUI()
        }
    }
    
    @objc func storeFailure(_ note: Notification) {

        DispatchQueue.main.async {
            self.storeProgress.stopAnimating()
            self.cantMakePaymentsLabel.isHidden = false
            self.hidePurchaseUI()
        }
    }


    // MARK: - NSCollectionViewDelegate Functions

    func numberOfSections(in collectionView: UICollectionView) -> Int {

        // Only one section in this collection
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        // Just return the number of products we have
        if let sc: StoreController = self.storeController {
            return sc.availableProducts.count
        } else {
            return 0
        }
    }


    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // Create (or retrieve) a CollectionViewItem instance and configure it
        
        // Dequeue a generic UICollectionViewCell...
        let item: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "com.bps.tip.view.cvi", for: indexPath)
        
        // ...and make sure we actually have a TipViewCollectionViewCell
        guard let tcvc: TipViewCollectionViewCell = item as? TipViewCollectionViewCell else {
            return item
        }

        let index: Int = indexPath.row
        if index < self.productEmojis.count && self.storeController != nil {
            let product: SKProduct = self.storeController!.availableProducts[index]
            tcvc.iconLabel.text = self.productEmojis[index]
            tcvc.priceLabel.text = "\(product.localPrice ?? "0.00")"
            tcvc.product = product
            return tcvc
        }
                
        // Make the item generic on error
        tcvc.iconLabel.text = "?"
        tcvc.priceLabel.text = "0.00"
        return tcvc
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let tcvc: TipViewCollectionViewCell = collectionView.cellForItem(at: indexPath) as! TipViewCollectionViewCell
        
        if self.storeController != nil {
            tcvc.isSelected = true
            tcvc.setNeedsDisplay()
            
            if let product: SKProduct = tcvc.product {
                let payment: SKMutablePayment = SKMutablePayment(product: product)
                payment.quantity = 1
                
                if self.storeController != nil && self.storeController!.paymentQueue != nil {
                    self.storeController!.paymentQueue!.add(payment)
                    
                    // NOTE Outcomes handled asynchronously from this point
                }
            }
            
            tcvc.isSelected = false
            tcvc.setNeedsDisplay()
        }
    }
    
    
    func updateCollectionViewSize() {
        if let sc: StoreController = self.storeController {
            if let flowLayout: UICollectionViewFlowLayout = priceCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.itemSize = CGSize(width: self.priceCollectionView.frame.size.width / CGFloat(sc.availableProducts.count + 1), height: self.priceCollectionView.frame.size.height)
                flowLayout.minimumLineSpacing = 0.0
                flowLayout.minimumInteritemSpacing = 0.2
            }
        }
    }
    
    
    /*
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard (self.storeController != nil && !self.storeController!.availableProducts.isEmpty) else {
            return .zero
        }

        let numberOfPoducts = CGFloat(self.storeController!.availableProducts.count)
        return CGSize(width: self.priceCollectionView.frame.size.width / numberOfPoducts,
                      height: self.priceCollectionView.frame.size.height)
    }
    */
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}
