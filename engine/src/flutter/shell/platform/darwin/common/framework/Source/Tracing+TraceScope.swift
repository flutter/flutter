// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

/// A class that represents a thread-local tracing scope.
///
/// A `TraceScope` is created by calling `Tracing.beginScope(_:)`.
/// It must be ended by calling `end()` or by using `defer { scope.end() }`.
///
/// If a `TraceScope` is deallocated without being ended, a runtime assertion
/// will fire in debug builds, and the scope will be ended automatically to
/// prevent timeline corruption.
@objc(FlutterTraceScope)
public final class TraceScope: NSObject {
  private let name: String
  private var isEnded = false

  internal init(name: String) {
    self.name = name
    Tracing.beginSection(name)
  }

  /// Ends the tracing scope.
  ///
  /// This method must be called exactly once. Calling it multiple times has no effect.
  @objc public func end() {
    guard !isEnded else { return }
    isEnded = true
    Tracing.endSection(name)
  }

  deinit {
    if !isEnded {
      assertionFailure("TraceScope '\(name)' was not ended. You must call 'scope.end()'.")
      end()
    }
  }
}

// MARK: - Swift Ergonomics

/// Swift-specific extensions to `Tracing` providing type-safe and
/// exception-safe wrappers.
extension Tracing {
  /// Executes the provided synchronous work block inside a tracing scope.
  ///
  /// This guarantees the scope is / ended even if the block throws or returns
  /// early.
  ///
  /// Basic usage:
  /// ```swift
  /// Tracing.withTrace("MyScope") {
  ///   // Perform work.
  /// }
  /// ```
  ///
  /// The traced block can optionally return a value:
  /// ```swift
  /// let value = Tracing.withTrace("MyScope") {
  ///   // Perform work.
  ///   return 42
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - name: The name of the tracing scope.
  ///   - work: The block of work to synchronously execute, optionally returning a value.
  /// - Returns: The value returned by the `work` block.
  @inlinable
  public static func withTrace<T>(_ name: String, _ work: () throws -> T) rethrows -> T {
    let scope = beginScope(name)
    defer { scope.end() }
    return try work()
  }

  /// Begins a manual tracing scope.
  ///
  /// The returned `TraceScope` must be ended by calling `end()` or by using `defer`.
  ///
  /// ```swift
  /// let scope = Tracing.beginScope("MyScope")
  /// defer { scope.end() }
  /// ```
  ///
  /// - Parameter name: The name of the tracing scope.
  /// - Returns: A `TraceScope` token that must be ended.
  public static func beginScope(_ name: String) -> TraceScope {
    return TraceScope(name: name)
  }
}
