# Flutter Native Driver

An experiment in adding platform-aware functionality to `flutter_driver`.

Project tracking: <https://github.com/orgs/flutter/projects/154>.

We'd like to be able to test, within `flutter/flutter` (and friends):

- Does a web-view load and render the expected content?
- Unexpected changes with the native OS, i.e. Android edge-to-edge
- Impeller rendering on Android using a real GPU (not swift_shader or Skia)
- Does an app correctly respond to application backgrounding and resume?
- Interact with native UI elements (not rendered by Flutter) and observe output
- Native text/keyboard input (IMEs, virtual keyboards, anything a11y related)

This project is tracking augmenting `flutter_driver` towards these goals.

If the project is not successful, the experiment will be turned-down and the
code removed or repurposed.

---

_Questions?_ Ask in the `#hackers-tests` channel on the Flutter Discord or
`@matanlurey` or `@johnmccutchan` on GitHub.
