# Template Xcode project with a custom application bundle

This template is an empty Xcode project with a settable application bundle path
within the `xcscheme`. It is used when debugging a project on a physical iOS 17+
device via Xcode 15+ when `--use-application-binary` is used.

It is also used to run iOS apps on Apple silicon Macs using the Designed for
iPad destination. The generated launch action selects the Flutter build mode
and whether to attach LLDB. The original app's Xcode project and schemes are
not changed by this launcher.
