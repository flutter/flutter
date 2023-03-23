// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import IOKit.ps

enum PowerState {
  case ac
  case battery
  case unknown
}

/// A convenience wrapper for an IOKit power source.
class PowerSource {
  let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
  lazy var sources = IOPSCopyPowerSourcesList(info).takeRetainedValue() as Array

  func hasBattery() -> Bool {
    return !sources.isEmpty
  }

  /// Returns the current power source capacity. Apple-defined power sources will return this value
  /// as a percentage.
  func getCurrentCapacity() -> Int {
    if let source = sources.first {
      let description =
        IOPSGetPowerSourceDescription(info, source).takeUnretainedValue() as! [String: AnyObject]
      if let level = description[kIOPSCurrentCapacityKey] as? Int {
        return level
      }
    }
    return -1
  }

  /// Returns whether the device is drawing battery power or connected to an external power source.
  func getPowerState() -> PowerState {
    if let source = sources.first {
      let description =
        IOPSGetPowerSourceDescription(info, source).takeUnretainedValue() as! [String: AnyObject]
      if let state = description[kIOPSPowerSourceStateKey] as? String {
        switch state {
        case kIOPSACPowerValue:
          return .ac
        case kIOPSBatteryPowerValue:
          return .battery
        default:
          return .unknown
        }
      }
    }
    return .unknown
  }
}

protocol PowerSourceStateChangeDelegate: AnyObject {
  func onPowerSourceStateChanged()
}

/// A listener for system power source state change events. Notifies the delegate on each event.
class PowerSourceStateChangeHandler {
  private var runLoopSource: CFRunLoopSource?
  weak var delegate: PowerSourceStateChangeDelegate?

  init() {
    let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    self.runLoopSource = IOPSNotificationCreateRunLoopSource(
      { (context: UnsafeMutableRawPointer?) in
        let weakSelf = Unmanaged<PowerSourceStateChangeHandler>.fromOpaque(
          UnsafeRawPointer(context!)
        ).takeUnretainedValue()
        weakSelf.delegate?.onPowerSourceStateChanged()
      }, context
    ).takeRetainedValue()
    CFRunLoopAddSource(CFRunLoopGetCurrent(), self.runLoopSource, .defaultMode)
  }

  deinit {
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), self.runLoopSource, .defaultMode)
  }
}
