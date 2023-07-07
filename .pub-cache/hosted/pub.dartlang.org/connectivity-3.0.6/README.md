# connectivity

---

## Deprecation Notice

This plugin has been replaced by the [Flutter Community Plus
Plugins](https://plus.fluttercommunity.dev/) version,
[`connectivity_plus`](https://pub.dev/packages/connectivity_plus).
No further updates are planned to this plugin, and we encourage all users to
migrate to the Plus version.

Critical fixes (e.g., for any security incidents) will be provided through the
end of 2021, at which point this package will be marked as discontinued.

---

This plugin allows Flutter apps to discover network connectivity and configure
themselves accordingly. It can distinguish between cellular vs WiFi connection.
This plugin works for iOS and Android.

> Note that on Android, this does not guarantee connection to Internet. For instance,
the app might have wifi access but it might be a VPN or a hotel WiFi with no access.

## Usage

Sample usage to check current status:

```dart
import 'package:connectivity/connectivity.dart';

var connectivityResult = await (Connectivity().checkConnectivity());
if (connectivityResult == ConnectivityResult.mobile) {
  // I am connected to a mobile network.
} else if (connectivityResult == ConnectivityResult.wifi) {
  // I am connected to a wifi network.
}
```

> Note that you should not be using the current network status for deciding
whether you can reliably make a network connection. Always guard your app code
against timeouts and errors that might come from the network layer.

You can also listen for network state changes by subscribing to the stream
exposed by connectivity plugin:

```dart
import 'package:connectivity/connectivity.dart';

@override
initState() {
  super.initState();

  subscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    // Got a new connectivity status!
  })
}

// Be sure to cancel subscription after you are done
@override
dispose() {
  super.dispose();

  subscription.cancel();
}
```

Note that connectivity changes are no longer communicated to Android apps in the background starting with Android O. *You should always check for connectivity status when your app is resumed.* The broadcast is only useful when your application is in the foreground.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.dev/).

For help on editing plugin code, view the [documentation](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin).
