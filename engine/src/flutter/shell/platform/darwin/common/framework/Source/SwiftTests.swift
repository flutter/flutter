import Foundation
import Testing

@main
struct TestApp {
  static func main() async {
    let exitCode: CInt = await Testing.__swiftPMEntryPoint(passing: nil)
    exit(exitCode)
  }
}
