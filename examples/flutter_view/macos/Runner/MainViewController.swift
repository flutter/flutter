//
//  Main.swift
//  Runner
//
//  Created by Alex Wallen on 9/8/22.
//

import Foundation
import AppKit

class MainViewController: NSViewController, NativeViewControllerDelegate {

  static let ping: String = "ping"

  var nativeViewController: NativeViewController?

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    if segue.identifier == "NativeViewControllerSegue" {
      self.nativeViewController = segue.destinationController as? NativeViewController
      self.nativeViewController?.delegate = self
    }
  }

  func didTapIncrementButton() {

  }

}


