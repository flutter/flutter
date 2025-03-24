## Best Practices

### Runtime assertions

Unopt builds use [FML_DCHECK](https://cs.opensource.google/flutter/engine/+/master:fml/logging.h;l=86?q=FML_DCHECK&ss=flutter%2Fengine) to enable assertion checks across the engine repository. Assertions on dependencies like Dart VM or Skia are not enabled because local and CI builds would be extremely slow.
Unopt builds are not published or consumed by the flutter/flutter CI to run integration tests or benchmarks.

### Sanitizers

[flutter/engine](https://github.com/flutter/engine) supports thread, address, memory, undefined behavior and leak sanitizers. Sanitizers are not enabled by default but they can be enabled on local builds following the [sanitizers with the flutter engine](../engine/Using-Sanitizers-with-the-Flutter-Engine.md) instructions.

### Builds with sanitizers, and tests with assertions enabled

[flutter/engine](https://github.com/flutter/engine) runs automated builds with sanitizers and testing with assertions. Testing with assertions is enabled in all the supported platforms and sanitizers are enabled only on the Linux platform.
Sanitizer builds:

* [Linux unopt](https://ci.chromium.org/p/flutter/builders/prod/Linux%20Unopt)

Tests with assertions enabled:

* [Linux unopt](https://ci.chromium.org/p/flutter/builders/prod/Linux%20Unopt)
* [Mac unopt](https://ci.chromium.org/p/flutter/builders/prod/Linux%20mac_unopt)
* [Windows unopt](https://ci.chromium.org/p/flutter/builders/prod/Windows%20Unopt)