# Linux semantics testing

Tests that the Flutter Linux embedder exposes Flutter semantics correctly over
[AT-SPI](https://gitlab.gnome.org/GNOME/at-spi2-core), as seen by screen
readers such as Orca.

The app in `lib/` shows a page per widget, plus a page that sets semantics
properties directly with `Semantics` widgets, selected by the driver test. The
driver test in `test_driver/` runs on the host, and inspects the app over the
AT-SPI D-Bus interface.

For each page the test checks the AT-SPI role, name, states and actions of the
widget, then performs actions on it over AT-SPI and checks the results.

## Running

This requires a graphical session with the accessibility bus running:

```sh
flutter drive -d linux -t lib/main.dart
```

On CI this runs as the `linux_semantics_test` devicelab task, which starts a
D-Bus session bus if there isn't one:

```sh
cd dev/devicelab
../../bin/dart bin/test_runner.dart test -t linux_semantics_test
```

## Adding a page

1. Add the widget to `pages` in `lib/pages.dart`.
2. Add a group to `test_driver/main_test.dart` that checks the AT-SPI
   properties of the widget, and any interactions.
