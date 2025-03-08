import Foundation

@objc public class FlutterFoo: NSObject {
  @objc public var name: String

  @objc public init(name: String) {
    self.name = name
  }

  @objc public func hello() -> String {
    return "Hello, " + self.name
  }
}
