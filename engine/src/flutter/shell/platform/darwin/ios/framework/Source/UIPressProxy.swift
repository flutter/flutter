// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

/// A event class that is a wrapper around a UIPress and a UIEvent to allow
/// overriding for testing purposes, since UIKit doesn't allow creation of
/// UIEvent or UIPress directly.
@available(iOS 13.4, *)
@objc(FlutterUIPressProxy)
public class UIPressProxy: NSObject {
  private var press: UIPress?
  private var event: UIEvent?

  /**
   * Initializes the proxy with the given press and event objects.
   * - Parameter press: The UIPress object to wrap.
   * - Parameter event: The UIEvent object to wrap.
   */
  @objc public init(press: UIPress, event: UIEvent) {
    self.press = press
    self.event = event
    super.init()  // Call superclass initializer
  }

  /**
   * Initializer for fake subclasses.
   * Subclasses using this MUST override the properties below as needed,
   * as the internal press/event objects will be nil.
   */
  @objc override public init() {
    self.press = nil
    self.event = nil
    super.init()
  }

  @objc required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented for UIPressProxy")
  }

  /// The phase of the press event.
  @objc public var phase: UIPress.Phase {
    guard let press = press else {
      fatalError("nil UIPress")
    }
    return press.phase
  }

  /// The key associated with the press event, if any.
  /// Note: In Swift, `UIPress.key` is optional.
  @objc public var key: UIKey? {
    return press?.key
  }

  /// The type of the event.
  @objc public var type: UIEvent.EventType {
    guard let event = event else {
      fatalError("nil UIEvent")
    }
    return event.type
  }

  /// The time at which the event occurred.
  /// NSTimeInterval is typealiased to TimeInterval in Swift.
  @objc public var timestamp: TimeInterval {
    guard let event = event else {
      fatalError("nil UIEvent")
    }
    return event.timestamp
  }
}
