//
//  PlatformViewController.swift
//  Runner
//
//  Created by Alex Wallen on 9/5/22.
//

import Cocoa

class PlatformViewController: NSViewController {
    var count: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func increment(_ sender: Any) {
      self.count += 1
    }
}
