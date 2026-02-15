// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit

@testable import InternalFlutterSwift

/// UIPressProxy subclass for use to create fake UIPress events in tests.
@available(iOS 13.4, *)
@objc
public class FakeUIPressProxy: UIPressProxy {
  private let dataPhase: UIPress.Phase
  private let dataKey: UIKey  // Store the copied key
  private let dataType: UIEvent.EventType
  private let dataTimestamp: TimeInterval

  @objc override public var phase: UIPress.Phase {
    return dataPhase
  }

  @objc override public var key: UIKey? {
    return dataKey
  }

  @objc override public var type: UIEvent.EventType {
    return dataType
  }

  @objc override public var timestamp: TimeInterval {
    return dataTimestamp
  }

  @objc public init(
    phase: UIPress.Phase,
    key: UIKey,
    type: UIEvent.EventType,
    timestamp: TimeInterval
  ) {
    self.dataPhase = phase
    // Create independent UIKey copy tied to proxy lifetime.
    guard let copiedKey = key.copy() as? UIKey else {
      fatalError("Failed to copy UIKey in FakeUIPressProxy initializer")
    }
    self.dataKey = copiedKey
    self.dataType = type
    self.dataTimestamp = timestamp
    super.init()
  }

  @objc required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented for FakeUIPressProxy")
  }

}
