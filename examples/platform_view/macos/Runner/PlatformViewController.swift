//
//  PlatformViewController.swift
//  Runner
//
//  Created by Alex Wallen on 9/5/22.
//

import Cocoa

class PlatformViewController: NSViewController {
    var count: Int = 0

    @IBOutlet weak var label: NSTextField!

    var labelText: String {
      get {
        return "Button tapped \(self.count) time\(self.count != 1 ? "s" : "")."
      }
    }

    override func viewDidLoad() {
      super.viewDidLoad()
      self.label.stringValue = labelText
    }

    public required init?(coder aDecoder: NSCoder) {
      self.count = 0
      super.init(coder: aDecoder)
    }

    init(withCount count: Int, onClose close: ((Int)->())?) {
      self.count = count
      super.init(nibName: nil, bundle: nil)
    }

    @IBAction func pop(_ sender: Any) {
      dismiss(self)
    }

    @IBAction func increment(_ sender: Any) {
      self.count += 1
      self.label.stringValue = labelText
    }
}
