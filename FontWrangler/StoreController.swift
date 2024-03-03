
//  StoreController.swift
//  FontWrangler
//
//  Created by Tony Smith on 03/04/2022.
//  Copyright © 2024 Tony Smith. All rights reserved.


import UIKit
import StoreKit


final class StoreController: NSObject,
                             SKProductsRequestDelegate,
                             SKPaymentTransactionObserver {
    
    // This class manages the App Store connection for taking tips
    
    
    // MARK: Private Properties
    
    private var productIdentifiers: [String] = []
    private var productRequest: SKProductsRequest? = nil
    
    
    // MARK: Public Properties
    
    var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }

    var availableProducts: [SKProduct] = []
    var paymentQueue: SKPaymentQueue? = nil
    
    
    // MARK: - Initialization Methods
    
    override init() {

        self.paymentQueue = SKPaymentQueue.default()
        self.productIdentifiers = [kTipTypes.tiny,
                                   kTipTypes.small,
                                   kTipTypes.medium,
                                   kTipTypes.large,
                                   kTipTypes.huge]
    }
    
    
    func initPaymentQueue() {

        // If we have an initialised payment queue, set
        // `self` as its payment transaction observer
        if self.paymentQueue != nil {
            self.paymentQueue!.add(self)
        }
    }
    
    
    func validateProductIdentifiers() {
        
        // Request a list of available products
        // NOTE List is set in ASC and defined by our
        //      Product ID array, `productIdentifiers`

        self.productRequest = SKProductsRequest.init(productIdentifiers: Set(self.productIdentifiers))
        if let pr: SKProductsRequest = self.productRequest {
            // Set the instance as the request delegate, and start a request for products
            pr.delegate = self
            pr.start()

            // This yields an async result: see `productsRequest(request, response)`
        } else {
            // Could not establish the request, so treat this as a failure
            // and notify the host view controller
            self.notifyParent(kPaymentNotifications.failed)
        }
    }

    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        // Async handler for Product list request

        self.availableProducts.removeAll()
        for item: String in self.productIdentifiers {
            for nitem: SKProduct in response.products {
                if nitem.productIdentifier == item {
                    self.availableProducts.append(nitem)
                    break
                }
            }
        }
 
        #if DEBUG
        // List valid and invalid Product IDs for debugging
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
        
        // Tell the host view controller the Product list has been updated
        notifyParent(kPaymentNotifications.updated)
    }
    
    
    func restorePurchasedProducts() {
        
        // Restore past purchases.
        // NOTE Tips don't really need this, so may remove

        self.paymentQueue!.restoreCompletedTransactions()
    }
    
    
    // MARK: - Payment Processing Handler
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        // This is called asynchronously (often not on the main thread) in response
        // to incoming messages from the App Store during purchases

        var purchaseState: String = ""
        var doFinishTransaction: Bool = false
        
        for transaction: SKPaymentTransaction in transactions {
            let userInfo: [AnyHashable: Any] = ["pid": transaction.payment.productIdentifier]
            switch transaction.transactionState {
                case .purchasing:
                    purchaseState = "purchase in flight"
                case .deferred:
                    self.notifyParent(kPaymentNotifications.inflight, userInfo)
                    purchaseState = "purchase deferred"
                case .purchased:
                    self.notifyParent(kPaymentNotifications.tip, userInfo)
                    purchaseState = "purchase succeeded"
                    doFinishTransaction = true
                case .restored:
                    self.notifyParent(kPaymentNotifications.restored)
                    purchaseState = "purchases restored"
                    doFinishTransaction = true
                case .failed:
                    fallthrough
                @unknown default:
                    // Trap cancelled purchases so we send the correct
                    // notification to the host view controller
                    if (transaction.error as? SKError)?.code == .paymentCancelled {
                        self.notifyParent(kPaymentNotifications.cancelled, userInfo)
                        purchaseState = "purchase cancelled"
                    } else {
                        self.notifyParent(kPaymentNotifications.failed, userInfo)
                        purchaseState = "purchase failed"

                        if let err = transaction.error {
                            purchaseState += " \(err.localizedDescription)"
                        } else {
                            purchaseState += " (reason unknown)"
                        }
                    }
                    
                    doFinishTransaction = true
            }
            
            if doFinishTransaction {
                queue.finishTransaction(transaction)
                doFinishTransaction = false
            }
            
            #if DEBUG
            print("Event: purchase \(purchaseState)")
            #endif
        }
    }
    
    
    // MARK: - Payment Event Handlers
    
    private func notifyParent(_ rawName: String, _ userInfo: [AnyHashable: Any]? = nil) {

        // Generic notification issuer. Receiver is the host view controller

        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: rawName),
                                        object: self,
                                        userInfo: userInfo)
    }
}


// MARK: - SK Product Extensions

extension SKProduct {

    // Add a `localPrice` property which provides the local price with
    // an appropriate currency label attached
    var localPrice: String? {
        let priceFormatter: NumberFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = self.priceLocale
        return priceFormatter.string(from: self.price)
    }
}
