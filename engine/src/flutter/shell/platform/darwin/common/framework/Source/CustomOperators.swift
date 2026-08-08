// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

infix operator ??= : AssignmentPrecedence

/// The dart -aware assignment operator.
///
/// If `lhs` is `nil`, assigns the result of evaluating `rhs` to `lhs` and returns the new value.
/// If `lhs` is non-`nil`, returns the existing unwrapped value of `lhs` without evaluating `rhs`.
@discardableResult
public func ??= <T>(lhs: inout T?, rhs: @autoclosure () -> T) -> T {
  if let value = lhs {
    return value
  }
  let newValue = rhs()
  lhs = newValue
  return newValue
}
