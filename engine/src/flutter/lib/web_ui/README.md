# Flutter Web Engine

This directory contains the source code for the Web Engine. The easiest way to
hack on the Web Engine is using the `felt` tool. See dev/README.md for details.

## Rolling CanvasKit

CanvasKit is versioned separately from Skia and rolled manually. Flutter
consumes a pre-built CanvasKit provided by the Skia team, currently hosted on
unpkg.com. When a new version of CanvasKit is available (check
https://www.npmjs.com/package/canvaskit-wasm or consult the Skia team
directly), follow these steps to roll to the new version:

- Make sure you have `depot_tools` installed (if you are regularly hacking on
  the engine code, you probably do).
- If not already authenticated with CIPD, run `cipd auth-login` and follow
  instructions (this step requires sufficient privileges; contact
  #hackers-infra-🌡 on Flutter's Discord server).
- Edit `dev/canvaskit_lock.yaml` and update the value of `canvaskit_version`
  to the new version.
- Run `dart dev/canvaskit_roller.dart` and make sure it completes successfully.
  The script uploads the new version of CanvasKit to the
  `flutter/web/canvaskit_bundle` CIPD package, and writes the CIPD package
  instance ID to the DEPS file.
- Send a pull request containing the above file changes. If the new version
  contains breaking changes, the PR must also contain corresponding fixes.

If you have questions, contact the Flutter Web team on Flutter Discord on the
#hackers-web-🌍 channel.
