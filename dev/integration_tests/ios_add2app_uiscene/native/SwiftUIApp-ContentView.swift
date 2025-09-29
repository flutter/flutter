import Flutter
import SwiftUI

struct FlutterViewControllerRepresentable: UIViewControllerRepresentable {
  // Access the AppDelegate through the view environment.
  @Environment(AppDelegate.self) var appDelegate

  func makeUIViewController(context: Context) -> some UIViewController {
    return FlutterViewController(
      engine: appDelegate.flutterEngine,
      nibName: nil,
      bundle: nil
    )
  }

  func updateUIViewController(
    _ uiViewController: UIViewControllerType,
    context: Context
  ) {}
}

struct ContentView: View {
  var body: some View {
    FlutterViewControllerRepresentable()
  }
}
