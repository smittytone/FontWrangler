
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
    private var nc: NotificationCenter = NotificationCenter.default
    
    
    // MARK: Public Properties
    
    var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }

    var availableProducts: [SKProduct] = []
    var paymentQueue: SKPaymentQueue? = nil
    
    
    // MARK: - Initialization Methods
    
    override init() {
        self.productIdentifiers = [kTipTypes.tiny,
                                   kTipTypes.small,
                                   kTipTypes.medium,
                                   kTipTypes.large,
                                   kTipTypes.huge]
        self.paymentQueue = SKPaymentQueue.default()
    }
    
    
    func initPaymentQueue() {
        
        if self.paymentQueue != nil {
            self.paymentQueue!.add(self)
        }
    }
    
    
    func validateProductIdentifiers() {
        
        // Get a list of available products
        self.productRequest = SKProductsRequest.init(productIdentifiers: Set(self.productIdentifiers))
        if let pr: SKProductsRequest = self.productRequest {
            pr.delegate = self
            pr.start()
        }
    }

    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        self.availableProducts = []
        
        for item: String in self.productIdentifiers {
            for nitem: SKProduct in response.products {
                if nitem.productIdentifier == item {
                    self.availableProducts.append(nitem)
                    break
                }
            }
        }
 
        #if DEBUG
        // List invalid Product IDs for debugging
        if !response.invalidProductIdentifiers.isEmpty {
            print("Invalid Store Product IDs:")
            for invalidIdentifier in response.invalidProductIdentifiers {
                print("  \(invalidIdentifier)")
            }
        }
        
        if !response.products.isEmpty {
            print("Valid Store Product IDs:")
            for product in response.products {
                print("  \(product.productIdentifier)")
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
        
        for transaction in transactions {
            switch transaction.transactionState {
                case .purchasing:
                    state = "purchase in flight"
                case .deferred:
                    state = "purchase deferred"
                case .purchased:
                    doFinishTransaction = true
                    state = "purchase succeeded"
                    self.notifyParent(kPaymentNotifications.tip)
                case .restored:
                    doFinishTransaction = true
                    state = "purchases restored"
                    self.notifyParent(kPaymentNotifications.restored)
                case .failed:
                    fallthrough
                @unknown default:
                    doFinishTransaction = true
                    state = "purchase failed"
                    if let err = transaction.error {
                        state += " \(err.localizedDescription)"
                    } else {
                        state += " (reason unknown)"
                    }
                    
                    if (transaction.error as? SKError)?.code != .paymentCancelled {
                        self.notifyParent(kPaymentNotifications.failed)
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


extension SKProduct {
    var localPrice: String? {
        let priceFormatter: NumberFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = self.priceLocale
        return priceFormatter.string(from: self.price)
    }
}
