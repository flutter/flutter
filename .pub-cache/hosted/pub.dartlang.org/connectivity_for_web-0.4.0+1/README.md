# connectivity_for_web

A web implementation of [connectivity](https://pub.dev/connectivity/connectivity). Currently this package uses an experimental API, with a fallback to dart:html, so not all features may be available to all browsers.

## Usage

### Import the package

This package is a non-endorsed implementation of `connectivity` for the web platform, so you need to modify your `pubspec.yaml` to use it:

```yaml
...
dependencies:
  ...
  connectivity: ^0.4.9
  connectivity_for_web: ^0.3.0
  ...
...
```

## Example

Find the example wiring in the [Google sign-in example application](https://github.com/ditman/plugins/blob/connectivity-web/packages/connectivity/connectivity/example/lib/main.dart).

## Limitations on the web platform

In order to retrieve information about the quality/speed of a browser's connection, the web implementation of the `connectivity` plugin uses the browser's [**NetworkInformation** Web API](https://developer.mozilla.org/en-US/docs/Web/API/NetworkInformation), which as of this writing (June 2020) is still "experimental", and not available in all browsers:

![Data on support for the netinfo feature across the major browsers from caniuse.com](https://caniuse.bitsofco.de/image/netinfo.png)

On desktop browsers, this API only returns a very broad set of connectivity statuses (One of `'slow-2g', '2g', '3g', or '4g'`), and may *not* provide a Stream of changes. Firefox still hasn't enabled this feature by default.

**Fallback to `navigator.onLine`**

For those browsers where the NetworkInformation Web API is not available, the plugin falls back to the [**NavigatorOnLine** Web API](https://developer.mozilla.org/en-US/docs/Web/API/NavigatorOnLine), which is more broadly supported: 

![Data on support for the online-status feature across the major browsers from caniuse.com](https://caniuse.bitsofco.de/image/online-status.png)


The NavigatorOnLine API is [provided by `dart:html`](https://api.dart.dev/stable/2.7.2/dart-html/Navigator/onLine.html), and only supports a boolean connectivity status (either online or offline), with no network speed information. In those cases the plugin will return either `wifi` (when the browser is online) or `none` (when it's not).

Other than the approximate "downlink" speed, where available, and due to security and privacy concerns, **no Web browser will provide** any specific information about the actual network your users' device is connected to, like **the SSID on a Wi-Fi, or the MAC address of their device.**

## Contributions and Testing

Tests are crucial to contributions to this package. All new contributions should be reasonably tested.

In order to run tests in this package, do:

```
cd test
flutter run -d chrome
```

All contributions to this package are welcome. Read the [Contributing to Flutter Plugins](https://github.com/flutter/plugins/blob/master/CONTRIBUTING.md) guide to get started.

## Issues and feedback

Please file an [issue](https://github.com/ditman/plugins/issues/new)
to send feedback or report a bug.

**Thank you!**
