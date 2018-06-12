import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, PlatformViewControllerDelegate
{
	override func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
	) -> Bool
	{
		GeneratedPluginRegistrant.register(with: self)

		let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
		let channel = FlutterMethodChannel.init(name: "splodium.com/splodium", binaryMessenger: controller)

		channel.setMethodCallHandler({
			(call: FlutterMethodCall, result: FlutterResult) -> Void in
			if ("switchView" == call.method)
			{
//				flutterResult = result

				let platformViewController = controller.storyboard?.instantiateViewController(withIdentifier: "PlatformView") as! PlatformViewController
// objc  platformViewController.counter = ((NSNumber*)call.arguments).intValue;
				platformViewController.delegate = self

				let navigationController = UINavigationController(rootViewController: platformViewController)
				navigationController.navigationBar.topItem?.title = "Platform View"
				controller.present(navigationController, animated: true, completion: nil)
      	}
//    else
//    {
//       result(FlutterMethodNotImplemented);
//    }
	});

		return super.application(application, didFinishLaunchingWithOptions: launchOptions)
	}

	func didUpdateCounter(counter: Int)
	{
	}
}
