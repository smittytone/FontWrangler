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
    private var clickedCell: TipViewCollectionViewCell? = nil
    private var productIcons: [String] = ["🍬", "☕️", "🍩", "🥧", "🍱"]


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
        hideProductList()
        
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
            //self.cantMakePaymentsLabel.isHidden = false
            self.showWarning()
            return
        }
        
        // We're good to go, so prep the store-related notifications
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
        
        nc.addObserver(self,
                       selector: #selector(storeCancel),
                       name: NSNotification.Name.init(rawValue: kPaymentNotifications.cancelled),
                       object: nil)

        nc.addObserver(self,
                       selector: #selector(clearHighlight),
                       name: NSNotification.Name.init(rawValue: kPaymentNotifications.inflight),
                       object: nil)
        
        // Get available products
        self.storeController!.validateProductIdentifiers()
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        // Update the collection view on rotation

        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _  in
            self?.updateCollectionViewSize()
            self?.priceCollectionView.layoutIfNeeded()
            self?.priceCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    
    private func hideProductList() {

        // Hide the Products collection view

        self.priceCollectionView.isHidden = true
    }


    private func showProductList() {
        
        // Reload and preseent the Products collection view
        
        self.priceCollectionView.reloadData()
        updateCollectionViewSize()
        self.priceCollectionView.isHidden = false
    }

    
    // MARK: - Action Functions
    
    @IBAction @objc func doDone(_ sender: Any) {
        
        // User has clicked 'Done', so just close the sheet
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func productListReceived(_ note: Notification) {
        
        // Async notification received when we get a list of products from the store:
        // Show the Products

        DispatchQueue.main.async {
            self.onAsyncReturn()

            if let sc = self.storeController {
                if !sc.availableProducts.isEmpty {
                    self.showProductList()
                    return
                }
            }

            // Fall through to error: hide the Product list
            // and show a warning
            self.hideProductList()
            //self.cantMakePaymentsLabel.isHidden = false
            self.showWarning()
        }
    }


    @objc func storeFailure(_ note: Notification) {

        // Async notification received if something went wrong with the purchase:
        // Clear the selection and post the warnning text

        DispatchQueue.main.async {
            self.onAsyncReturn()
            self.hideProductList()
            //self.cantMakePaymentsLabel.isHidden = false
            self.self.showWarning()
        }
    }
    
    
    @objc func storeCancel(_ note: Notification) {

        // Async notification received if the user cancelled the purchase:
        // Just clear the selection

        DispatchQueue.main.async {
            self.onAsyncReturn()
        }
    }


    @objc func clearHighlight(_ note: Notification) {

        // Async notification received if the user cancelled the purchase:
        // Just clear the selection

        DispatchQueue.main.async {
            self.clearCellHighlight()
        }
    }


    @objc func showThankYou(_ note: Notification) {

        // Async notification received if the user successfully made a purchase:
        // Clear the selection, hide the products, and post the thanks text

        DispatchQueue.main.async {
            self.onAsyncReturn()
            self.hideProductList()
            //self.thankYouLabel.isHidden = false
            self.showThanks()
        }
    }


    func onAsyncReturn() {

        // Generic operations to be perfomed on async return from store operations

        self.storeProgress.stopAnimating()
        self.clearCellHighlight()
    }


    func clearCellHighlight() {

        // If there's a reference to a cell, set when it's selected,
        // then clear the highlight and the stored reference

        if let tvcv: TipViewCollectionViewCell = self.clickedCell {
            tvcv.isClicked = false
            tvcv.setNeedsDisplay()
            self.clickedCell = nil
        }
    }


    // MARK: - NSCollectionViewDelegate Functions

    func numberOfSections(in collectionView: UICollectionView) -> Int {

        // Only one section in this collection

        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        // Just return the number of products we have, or zero

        return self.storeController != nil ? self.storeController!.availableProducts.count : 0
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
        if index < self.productIcons.count && self.storeController != nil {
            let product: SKProduct = self.storeController!.availableProducts[index]
            tcvc.iconLabel.text = self.productIcons[index]
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

        // A Product has been tapped, so highlight its cell and save a reference

        let tcvc: TipViewCollectionViewCell = collectionView.cellForItem(at: indexPath) as! TipViewCollectionViewCell
        if let product: SKProduct = tcvc.product {
            if self.storeController != nil && self.storeController!.paymentQueue != nil {
                // Fire off the payment request
                let payment: SKMutablePayment = SKMutablePayment(product: product)
                payment.quantity = 1
                self.storeController!.paymentQueue!.add(payment)

                // Mark the cell as selected
                tcvc.isClicked = true
                tcvc.setNeedsDisplay()
                clickedCell = tcvc

                // NOTE Outcomes handled asynchronously from this point
                return
            }
        }

        // Fall through to error: hide the Products and show the warning
        self.hideProductList()
        //self.cantMakePaymentsLabel.isHidden = false
        self.showWarning()
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


    private func showWarning() {

        self.showAlert("Sorry", "You can’t make purchases at this time. Please try again later")
    }


    private func showThanks() {

        self.showAlert("Thank You!", "Your donation is very gratefully received", true)
    }


    private func showAlert(_ title: String, _ message: String, _ doExit: Bool = false) {

        // Generic alert display function which ensures
        // the alert is actioned on the main thread

        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: title,
                                               message: message,
                                               preferredStyle: .alert)

            // Set the exit closure: it just closes the view controller
            let outHandler: ((UIAlertAction) -> Void) = { action in
                self.doDone(self)
            }

            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                          style: .default,
                                          handler: (!doExit ? nil : outHandler)))
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


    
}
