# tools

[![Build Status](https://travis-ci.org/flutter/tools.svg)](https://travis-ci.org/flutter/tools)
[![Build status](https://ci.appveyor.com/api/projects/status/fpokp26jprqddfms/branch/master?svg=true)](https://ci.appveyor.com/project/devoncarew/tools/branch/master)
[![pub package](https://img.shields.io/pub/v/sky_tools.svg)](https://pub.dartlang.org/packages/sky_tools)

Tools for building Flutter applications.

## Installing

To install, run:

    pub global activate sky_tools

or, depend on this package in your pubspec:

```yaml
dev_dependencies:
  sky_tools: any
```

## Running sky_tools

Run `sky_tools` (or `pub global run sky_tools`) to see a list of available
commands:

- `init` to create a new project

Then, run a `sky_tools` command:

    sky_tools init --out my_sky_project

## Running sky_tools:sky_server

To serve the current directory using `sky_server`:

    pub run sky_tools:sky_server [-v] PORT

## Running sky_tools:build_sky_apk

```
usage: pub run sky_tools:build_sky_apk <options>

-h, --help
    --android-sdk
    --skyx
```

## Filing Issues

Please file reports on the
[GitHub Issue Tracker](https://github.com/flutter/tools/issues).
