# Flutter Conductor

Command-line tool for managing a release of the Flutter SDK.

## Requirements

Some basic requirements to conduct a release are:

- a Linux or macOS computer set up for Flutter development. The conductor does
  not support Windows.
- git
- Mirrors on GitHub of the Flutter
  [framework](https://github.com/flutter/flutter) and
  [engine](https://github.com/flutter/engine) repositories.

## Usage

The main entrypoint for the conductor is [bin/conductor](bin/conductor). For
brevity, the rest of this document will assume that this entrypoint is on the
shell path.

All available commands can be seen via:

`conductor help`

Releases are initialized with the `start` sub-command, like:

```
conductor start \
  --candidate-branch=flutter-2.2-candidate.10 \
  --release-channel=beta \
  --framework-mirror=git@github.com:flutter-contributor/flutter.git \
  --engine-mirror=git@github.com:flutter-contributor/engine.git \
  --engine-cherrypicks=72114dafe28c8700f1d5d629c6ae9d34172ba395 \
  --framework-cherrypicks=a3e66b396746f6581b2b7efd1b0d0f0074215128,d8d853436206e86f416236b930e97779b143a100 \
  --dart-revision=4511eb2a779a612d9d6b2012123575013e0aef12
```

For more details on these command line arguments, see `conductor help start`.
This command will write to disk a state file that will persist until the release
is completed. To see the current status of the release (at any time), issue the
command:

`conductor status`

Once initializing the release, the conductor tool will issue instructions for
manual steps that must be executed by the user. At any time these instructions
can be seen via `conductor status`. Once these manual steps have been completed,
you can proceed to the next step by using the command:

`conductor next`

Upon successful completion of the release, the following command will remove the
persistent state file:

`conductor clean`
