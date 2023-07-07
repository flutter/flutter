## Dart Web Developer Service

The Dart Web Developer Service (DWDS) allows developer tools designed to work
with the native Dart VM to also work with Dart Web applications compiled with
[DDC](https://webdev.dartlang.org/tools/dartdevc), built / served with
[webdev](https://webdev.dartlang.org/tools/webdev), and run in Chrome.

`package:dwds` is integrated into `webdev serve` as well as `flutter run`.

At a basic level, DWDS proxies between:
* Developer tools that are written against the
  [Dart VM Service Protocol](https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md)
* Execution environments that expose the
  [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol)
