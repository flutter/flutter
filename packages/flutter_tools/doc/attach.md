# Flutter Attach

## Overview

A Flutter-command that attaches to applications that have been launched
without `flutter run` and provides a HotRunner (enabling hot reload/restart).

## Usage

There are four ways for the attach command to discover a running app:

1. If the app is already running and the observatory port is known, it can be
explicitly provided to attach via the command-line, e.g. `$ flutter attach
--debug-port 12345`
1. If the app is already running and the platform is iOS, attach can use mDNS
to lookup the observatory port via the application ID, with just `$ flutter
attach`
1. If the platform is Fuchsia the module name must be provided, e.g. `$
flutter attach --module=mod_name`. This can be called either before or after
the application is started, attach will poll the device if it cannot
immediately discover the port
1. On other platforms (i.e. Android), if the app is not yet running attach
will listen and wait for the app to be (manually) started with the default
command: `$ flutter attach`

## Source

See the [source](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/commands/attach.dart) for the attach command.
