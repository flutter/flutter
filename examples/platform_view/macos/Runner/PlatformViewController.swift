// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa

class PlatformViewController: NSViewController {
    var count: Int = 0

    var dispose: ((PlatformViewController)->())?

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
      self.dispose = nil
      super.init(coder: aDecoder)
    }

    init(withCount count: Int, onClose dispose: ((PlatformViewController)->())?) {
      self.count = count
      self.dispose = dispose
      super.init(nibName: nil, bundle: nil)
    }

    @IBAction func pop(_ sender: Any) {
      self.dispose?(self)
      dismiss(self)
    }

    @IBAction func increment(_ sender: Any) {
      self.count += 1
      self.label.stringValue = labelText
    }
}
