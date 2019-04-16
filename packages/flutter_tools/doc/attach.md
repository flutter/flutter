# Flutter Attach

## Overview

A Flutter-command that attaches to applications that have been launched
without `flutter run`.

With an application already running, a HotRunner can be attached to it
with:
```
$ flutter attach --debug-port 12345
```

Alternatively, the attach command can start listening and scan for new
programs that become active:
```
$ flutter attach
```
As soon as a new observatory is detected the command attaches to it and
enables hot reloading.

To attach to a flutter mod running on a fuchsia device, `--module` must
also be provided.
