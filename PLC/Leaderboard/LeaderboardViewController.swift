//
//  SecondViewController.swift
//  PLC
//
//  Created by Chris on 6/25/18.
//  Copyright © 2018 Chris Chou. All rights reserved.
//

import UIKit

class LeaderboardViewController: UIViewController {
    
    //MARK:Properties
    var leaderboardPageViewController: LeaderboardPageViewController? {
        didSet {
            leaderboardPageViewController?.leaderboardDelegate = self as? LeaderboardPageViewControllerDelegate
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: Segue Functions
    func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let leaderboardPageViewController = segue.destination as? LeaderboardPageViewController {
            self.leaderboardPageViewController = leaderboardPageViewController
        }
    }
}

