//
//  Main.swift
//  Runner
//
//  Created by Alex Wallen on 9/8/22.
//

import Foundation
import AppKit
import FlutterMacOS

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
      self.nativeViewController?.delegate = self
    }

    if segue.identifier == "FlutterViewControllerSegue" {
      self.flutterViewController = segue.destinationController as? FlutterViewController

      RegisterMethodChannel(registry: self.flutterViewController!)

      weak var weakSelf = self
      messageChannel?.setMessageHandler({ (message, reply) in
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

  func didTapIncrementButton() {

  }

}


