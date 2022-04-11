
//  StoreController.swift
//  FontWrangler
//
//  Created by Tony Smith on 03/04/2022.
//  Copyright © 2022 Tony Smith. All rights reserved.


import UIKit
import StoreKit


class StoreController: NSObject,
                       SKProductsRequestDelegate,
                       SKPaymentTransactionObserver {
    
    // This class manages the App Store connection for taking tips
    
    
    // MARK: Private Properties
    
    private var productIdentifiers: [String] = []
    private var productRequest: SKProductsRequest? = nil
    private var paymentQueue: SKPaymentQueue? = nil
    private var nc: NotificationCenter = NotificationCenter.default
    
    // MARK: Public Properties
    
    var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }

    var availableProducts: NSMutableArray = NSMutableArray.init()
    
    
    // MARK: - Initialization Methods
    
    override init() {
        self.productIdentifiers = [kTipTypes.huge,
                                   kTipTypes.large,
                                   kTipTypes.medium,
                                   kTipTypes.small,
                                   kTipTypes.tiny]
        self.paymentQueue = SKPaymentQueue.default()
    }
    
    
    func initPaymentQueue() {
        
        if self.paymentQueue != nil {
            self.paymentQueue!.add(self)
        }
    }
    
    
    func validateProductIdentifiers() {
        
        self.productRequest = SKProductsRequest.init(productIdentifiers: Set(self.productIdentifiers))
        if let pr: SKProductsRequest = self.productRequest {
            pr.delegate = self
            pr.start()
        }
    }

    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        self.availableProducts = NSMutableArray.init(array: response.products)

        #if DEBUG
        // List invalid Product IDs for debugging
        if response.invalidProductIdentifiers.count > 0 {
            for invalidIdentifier in response.invalidProductIdentifiers {
                print("Invalid ID: \(invalidIdentifier)")
            }
        }
        #endif
        
        // Tell the parent TipViewController the product list
        // has been updated
        notifyParent(kPaymentNotifications.updated)
    }
    
    
    func restorePurchasedProducts() {
        
        // Restore past purchases.
        // NOTE Tips don't really need this, so may remove
        self.paymentQueue!.restoreCompletedTransactions()
    }
    
    
    // MARK: - Payment Processing
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        // This is called asynchronously (often not on the main thread) in response
        // to incoming messages from the App Store
        var state: String = ""
        var doFinishTransaction: Bool = false
        
        for i: Int in 0..<transactions.count {
            let transaction: SKPaymentTransaction = transactions[i]
            
            switch transaction.transactionState {
                case .purchasing:
                    state = "purchase in flight"
                case .purchased:
                    doFinishTransaction = true
                    state = "purchase succeeded"
                    self.notifyParent(kPaymentNotifications.tip)
                case .restored:
                    doFinishTransaction = true
                    state = "purchases restored"
                    self.notifyParent(kPaymentNotifications.restored)
                case .deferred:
                    state = "purchase deferred"
                default:
                    doFinishTransaction = true
                    state = "purchase failed"
                    if let err = transaction.error {
                        state += " \(err.localizedDescription)"
                    } else {
                        state += " (reason unknown)"
                    }
            }
            
            if doFinishTransaction {
                queue.finishTransaction(transaction)
                doFinishTransaction = false
            }
            
            #if DEBUG
            print("Event: purchase \(state)")
            #endif
        }
    }
    
    
    // MARK: - Payment Event Handlers
    
    private func notifyParent(_ rawName: String) {
        // Tell the View Controller
        self.nc.post(name: NSNotification.Name.init(rawValue: rawName), object: self)
    }
}