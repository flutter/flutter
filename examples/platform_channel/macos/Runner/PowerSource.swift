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

  /// Returns the current power source capacity. Apple-defined power sources will return this value
  /// as a percentage.
  func getCurrentCapacity() -> Int {
    if !sources.isEmpty {
      let source = sources[0]
      let description = IOPSGetPowerSourceDescription(info, source).takeUnretainedValue() as! [String: AnyObject]
      if let level = description[kIOPSCurrentCapacityKey] as? Int {
        return level
      }
    }
    return -1
  }

  /// Returns whether the device is drawing battery power or connected to an external power source.
  func getPowerState() -> PowerState {
    if !sources.isEmpty {
      let source = sources[0]
      let description = IOPSGetPowerSourceDescription(info, source).takeUnretainedValue() as! [String: AnyObject]
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
