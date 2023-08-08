// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import AppKit
import FlutterMacOS

/**
The code behind a storyboard view which splits a flutter view and a macOS view.
*/
class MainViewController: NSViewController, NativeViewControllerDelegate {
  static let emptyString: String = ""
  static let ping: String = "ping"
  static let channel: String = "increment"

  var nativeViewController: NativeViewController?
  var flutterViewController: FlutterViewController?
  var messageChannel: FlutterBasicMessageChannel?

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    if segue.identifier == "NativeViewControllerSegue" {
      self.nativeViewController = segue.destinationController as? NativeViewController

      // Since`MainViewController` owns the platform channel, but not the
      // UI elements that trigger an action, those UI elements need a reference
      // to this controller to send messages on the platform channel.
      self.nativeViewController?.delegate = self
    }

    if segue.identifier == "FlutterViewControllerSegue" {
      self.flutterViewController = segue.destinationController as? FlutterViewController

      RegisterMethodChannel(registry: self.flutterViewController!)

      weak var weakSelf = self
      messageChannel?.setMessageHandler({ (message, reply) in

        // Dispatch an event, incrementing the counter in this case, when *any*
        // message is received.

        // Depending on the order of initialization, the nativeViewController
        // might not be initialized until this point.
        weakSelf?.nativeViewController?.didReceiveIncrement()
        reply(MainViewController.emptyString)
      })
    }
  }

  func RegisterMethodChannel(registry: FlutterPluginRegistry) {
    let registrar = registry.registrar(forPlugin: "")
    messageChannel = FlutterBasicMessageChannel(
      name: MainViewController.channel,
      binaryMessenger: registrar.messenger,
      codec: FlutterStringCodec.sharedInstance())
  }

  // Call in any instance where `ping` is to be sent through the `increment`
  // channel.

  func didTapIncrementButton() {
    self.messageChannel?.sendMessage(MainViewController.ping)
  }

}
