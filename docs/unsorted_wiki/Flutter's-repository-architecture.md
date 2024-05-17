Flutter uses a deeply multi-repository architecture, which includes, among many others, the following:

* github.com/flutter/flutter
* github.com/flutter/engine
* github.com/flutter/packages
* github.com/dart-lang/sdk
* llvm.googlesource.com
* skia.googlesource.com
* swiftshader.googlesource.com
* android.googlesource.com
* fuchsia.googlesource.com
* boringssl.googlesource.com
* chromium.googlesource.com, which mirrors a large number of further repositories
* flutter.googlesource.com, which mirrors a large number of further repositories

There are, all told, hundreds of repositories involved in Flutter's development.

Generally, the boundaries between repositories represent integration points. For example, Dart is integrated into Flutter's engine, but is also used in other contexts. Dart therefore is in its own repository, separate from Flutter's engine. Flutter's engine is integrated into Flutter's tooling as a prebuilt binary, and therefore they are in separate repositories.

Our current architecture enables some important features, for example:

 - flutter/packages can be tested against different versions of Flutter with a clean integration point.
 - flutter/flutter has an unambiguous integration with the Engine, including on release branches.
 - flutter/flutter is entirely code covered by a single license. (This is why that repo does not need a license script the way flutter/engine does.)
 - flutter/flutter can be delivered to developers in a way that they can step through the code in a debugger without significant parts of the repo providing distractions.
 - flutter/flutter is easy for new contributors to hack on, providing an easy on-ramp to grow the community from where people can get more deeply involved, e.g. with the engine.
 - flutter/engine can select specific versions of dependencies (e.g. Skia) rather than having to merge in the actual dependency code.
 - flutter/engine binaries can be built in the same way for CI testing as for release.

Some repositories that were historically split have been merged or are planned to be merged. For example, we have merged our various packages and plugins into a single repository (flutter/packages); previously, they were each in individual packages, then eventually two (plugins and packages). Combining these makes sense as they share near-identical CI testing and development tooling. Another example is flutter/buildroot and flutter/engine, which we plan to merge in due course (previously the buildroot was separated for ease of integration with Fuchsia).