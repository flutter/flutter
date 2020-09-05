# Flutter Attach

## Overview

A Flutter-command that attaches to applications that have been launched
without `flutter run` and provides a HotRunner (enabling hot reload/restart).

## Usage

There are three ways for the attach command to discover a running app:

1. If the platform is Fuchsia the module name must be provided, e.g. `$
flutter attach --module=mod_name`. This can be called either before or after
the application is started, attach will poll the device if it cannot
immediately discover the port
1. On Android and iOS, just running `flutter attach` suffices. Flutter tools
will search for an already running Flutter app or module if available.
Otherwise, the tool will wait for the next Flutter app or module to launch
before attaching.
1. If the app or module is already running and the specific observatory port is
known, it can be explicitly provided to attach via the command-line, e.g.
`$ flutter attach --debug-port 12345`

## Source

See the [source](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/commands/attach.dart) for the attach command.
