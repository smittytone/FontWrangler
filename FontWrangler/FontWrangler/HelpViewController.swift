
//  HelpViewController.swift
//  Fontismo
//
//  Created by Tony Smith on 02/04/2020.
//  Copyright © 2023 Tony Smith. All rights reserved.


import UIKit


class HelpViewController: UIViewController,
                          UIPageViewControllerDelegate,
                          UIPageViewControllerDataSource {
    
    
    // MARK: - Object properties

    private var pageViewControllers = [HelpPageViewController]()
    private var pvc: UIPageViewController? = nil

    var pageIndex: Int = 0
    
    
    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.pageIndex = 0

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        for i in 0..<kHelpPageCount {
            let hpvc: HelpPageViewController = storyboard.instantiateViewController(withIdentifier: "help.page.view") as! HelpPageViewController
            hpvc.index = i
            pageViewControllers.append(hpvc)
        }

        // Instantiate the Page View Controller
        self.pvc = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal,
                                        options: nil)
        self.pvc?.delegate = self
        self.pvc?.dataSource = self
        var frame = self.view.frame
        frame.size.height -= 40
        frame.origin.y =  frame.origin.y + 40
        self.pvc?.view.frame = frame
        self.pvc?.view.backgroundColor = .clear
        self.pvc?.setViewControllers([pageViewControllers[0]],
                                     direction: .forward,
                                     animated: true,
                                     completion: nil)
        self.addChild(self.pvc!)
        self.view.addSubview(self.pvc!.view)
        self.pvc?.didMove(toParent: self)

        // Use the proxy to set the Page View Controller's
        // Page Control colours to work with Dark Mode
        let proxy = UIPageControl.appearance()
        proxy.pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.4)
        proxy.currentPageIndicatorTintColor = UIColor.label
    }
    
    
    @IBAction func doClose(_ sender: Any) {
            
        // Close the Help panel

        // FROM 1.1.1
        // Halt the web pages if open
        for pvc in self.pageViewControllers {
            if let wv = pvc.pageWebView {
                wv.stopLoading()
            }
        }

        self.dismiss(animated: true, completion: nil)
    }
    

    // MARK: - Page View Controller Data Source Functions

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let hpvc: HelpPageViewController = viewController as! HelpPageViewController
        
        if hpvc.index == 0 {
            // Return nil to indicate we can't go any further
            return nil
        }
        
        self.pageIndex = hpvc.index - 1
        return pageViewControllers[self.pageIndex]
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let hpvc: HelpPageViewController = viewController as! HelpPageViewController
        
        if hpvc.index == kHelpPageCount - 1 {
            // Return nil to indicate we can't go any further
            return nil
        }
        
        self.pageIndex = hpvc.index + 1
        return pageViewControllers[self.pageIndex]
    }
    
    
    func presentationCount(for: UIPageViewController) -> Int {
        
        // NOTE This has to be set absolutely - the view controller has not been populated
        //      when this is first called
        return kHelpPageCount
    }

    
    func presentationIndex(for: UIPageViewController) -> Int {
        
        return self.pageIndex
    }

    
}
