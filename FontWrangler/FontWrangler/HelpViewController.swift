
//  Created by Tony Smith on 02/04/2020.
//  Copyright © 2020 Tony Smith. All rights reserved.


import UIKit
import WebKit


class HelpViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    
    @IBOutlet weak var pageHeaderLabel: UILabel!
    
    private var vcs = [HelpPageViewController]()
    var index: Int = 0
    private var pvc: UIPageViewController? = nil
    
    
    // MARK: - Lifecycle Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.index = 0
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        for i in 0..<3 {
            let hpvc: HelpPageViewController = storyboard.instantiateViewController(withIdentifier: "help.page.view") as! HelpPageViewController
            hpvc.titleLabel?.text = "Page \(i)"
            hpvc.index = i
            vcs.append(hpvc)
        }
        
        self.pvc = UIPageViewController(transitionStyle: .scroll,
                                        navigationOrientation: .horizontal,
                                        options: nil)
        self.pvc?.delegate = self
        self.pvc?.dataSource = self
        var frame = self.view.frame
        frame.size.height -= 100
        frame.origin.y =  frame.origin.y + 40
        self.pvc?.view.frame = frame
        self.pvc?.view.backgroundColor = .clear
        self.pvc?.setViewControllers([vcs[0]],
                                     direction: .forward,
                                     animated: true,
                                     completion: nil)
        self.addChild(self.pvc!)
        self.view.addSubview(self.pvc!.view)
        self.pvc?.didMove(toParent: self)
        
        let proxy = UIPageControl.appearance()
        proxy.pageIndicatorTintColor = UIColor.label.withAlphaComponent(0.4)
        proxy.currentPageIndicatorTintColor = UIColor.label
    }
    

    @IBAction func doClose(_ sender: Any) {
            
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let hpvc: HelpPageViewController = viewController as! HelpPageViewController
        
        if hpvc.index == 0 {
            return nil
        }
        
        self.index = hpvc.index - 1
        return vcs[self.index]
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let hpvc: HelpPageViewController = viewController as! HelpPageViewController
        
        if hpvc.index == 2 {
            return nil
        }
        
        self.index = hpvc.index + 1
        return vcs[self.index]
    }
    
    
    func presentationCount(for: UIPageViewController) -> Int {
        
        return 3
    }
    
    func presentationIndex(for: UIPageViewController) -> Int {
        
        return self.index
    }
}
