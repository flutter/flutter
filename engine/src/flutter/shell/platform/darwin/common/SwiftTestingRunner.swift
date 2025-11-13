// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Darwin
import Testing

// The C symbol of the swift-testing ABI.v0 test runner entrypoint lookup function.
//
// Testing.framework exports this C function which, when called, returns the Swift entrypoint
// function (Testing.ABI.v0.entryPoint) implementing the swift-testing test runner.
// See: https://github.com/swiftlang/swift-testing/blob/72afbb418542654781a6b7853479c7e70a862b6f/Sources/Testing/ABI/EntryPoints/ABIEntryPoint.swift#L65-L73
private let getEntryPointSymbol = "swt_abiv0_getEntryPoint"

// The C function signature for the ABI.v0 test runner entrypoint lookup function.
// See: https://github.com/swiftlang/swift-testing/blob/72afbb418542654781a6b7853479c7e70a862b6f/Sources/Testing/ABI/EntryPoints/ABIEntryPoint.swift#L65-L73
private typealias GetEntryPointFunc = @convention(c) () -> UnsafeRawPointer

// swift-testing dylib containing the test runner entrypoint lookup symbol.
private let testingDylib = "@rpath/Testing.framework/Testing"

// The Swift function signature for the swift-testing runner entrypoint function.
//
// This type is defined as Testing.ABI.v0.Entrypoint in swift-testing.
// See: https://github.com/swiftlang/swift-testing/blob/72afbb418542654781a6b7853479c7e70a862b6f/Sources/Testing/ABI/EntryPoints/ABIEntryPoint.swift#L15-L32
private typealias SwiftTestingEntryPointFunc = @convention(thin) @Sendable (
  _ configurationJSON: UnsafeRawBufferPointer?,
  _ recordHandler: @escaping @Sendable (_ recordJSON: UnsafeRawBufferPointer) -> Void
) async throws -> Bool

// Looks up and returns the swift-testing test runner entrypoint function.
//
// TODO(cbracken): https://github.com/flutter/flutter/issues/168858
// This is necessary because at present, Swift stable does not yet have a mechanism for
// declaring extern functions. Experimental support exists for the following:
//
// @_extern(c, "swt_abiv0_getEntryPoint")
// func getEntryPoint() -> UnsafeRawPointer
//
// When this lands in Swift stable, we should replace the dlsym lookup below with the stable
// equivalent of the above.
private func resolveSwiftTestingEntrypoint() -> SwiftTestingEntryPointFunc {
  // Load swift-testing dylib.
  guard let testingDylibHandle = dlopen(testingDylib, RTLD_NOW) else {
    let errorMessage = dlerror().map { String(cString: $0) } ?? "Unknown error."
    fatalError("Error opening Testing.framework: \(errorMessage)")
  }
  defer {
    dlclose(testingDylibHandle)
  }

  // Look up the C function that can be called to return the Swift entrypoint function.
  guard let swt_abiv0_getEntryPoint = dlsym(testingDylibHandle, getEntryPointSymbol) else {
    let errorMessage = dlerror().map { String(cString: $0) } ?? "Unknown error."
    fatalError("Error locating entrypoint symbol \(getEntryPointSymbol): \(errorMessage)")
  }
  let getEntryPoint = unsafeBitCast(swt_abiv0_getEntryPoint, to: GetEntryPointFunc.self)

  // Call the C function to get the Swift test runner entrypoint function.
  return unsafeBitCast(getEntryPoint(), to: SwiftTestingEntryPointFunc.self)
}

/// A test runner for Swift Testing tests.
public struct SwiftTestingRunner {
  public init() {}

  /// Runs all Swift Testing tests (annotated with `@Test`) in the current executable.
  ///
  /// Returns 0 on pass, non-zero on failure.
  public func run() async -> CInt {
    let testRunnerEntryPoint = resolveSwiftTestingEntrypoint()
    do {
      let result = try await testRunnerEntryPoint(nil) { _ in
        // unused: recordHandler callback.
      }
      return result ? EXIT_SUCCESS : EXIT_FAILURE
    } catch {
      fputs("Swift Testing entrypoint threw an error: \(error)\n", stderr)
      fflush(stderr)
      return EXIT_FAILURE
    }
  }
}
