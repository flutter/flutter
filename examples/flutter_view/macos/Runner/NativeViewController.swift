// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import AppKit

protocol NativeViewControllerDelegate: NSObjectProtocol {
    func didTapIncrementButton()
}

/**
The code behind a native view to be displayed in the `MainFlutterViewController`
as an embed segue. If any storyboard view inherits from this class definition,
it should contain a function to handle for `handleIncrement`
*/
class NativeViewController: NSViewController {

  var count: Int?

  var labelText: String {
    get {
      let count = self.count ?? 0
      return "Flutter button tapped \(count) time\(count == 1 ? "" : "s")"
    }
  }

  var delegate: NativeViewControllerDelegate?

  @IBOutlet weak var incrementLabel: NSTextField!

  @IBAction func handleIncrement(_ sender: Any) {
    self.delegate?.didTapIncrementButton()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setState(for: 0)
  }

  func didReceiveIncrement() {
    setState(for: (self.count ?? 0) + 1)
  }

  func setState(for count: Int) {
    self.count = count
    self.incrementLabel.stringValue = labelText
  }

}
