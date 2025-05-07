import Testing

/// A test runner for Swift Testing tests.
public struct SwiftTestingRunner {
  public init() {}

  /// Runs all Swift Testing tests (annotated with `@Test`) in the current executable.
  ///
  /// Returns 0 on pass, non-zero on failure.
  public func run() async -> CInt {
    // TODO(cbracken): https://github.com/flutter/flutter/issues/168858
    // Once swift-testing exposes a public API for a test runner, migrate to that.
    let exitCode: CInt = await Testing.__swiftPMEntryPoint(passing: nil)
    return exitCode
  }
}
