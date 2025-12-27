# Flutter Engine

This project contains the engine for Flutter. GN is used as the build system
and there are many targets. The engine is built for the local ("host") platform
but also built for the the target platform (ex. iOS or Android).

The tool at `./bin/et` is used as a wrapper around GN and ninja to easily build
targets. The results are placed in "../out/\<config name\>". Build config names
describe the target platform, but also codify the optimization level and the
target architecture. For example, when developing on an arm64 mac,
`host_debug_unopt_arm64` is the most likely configuration for testing.

For testing there are numerous test runners. How they are run locally is
documented in `./testing/run_tests.py`.

This project lives as a subdirectory of the flutter github project at
https://github.com/flutter/flutter.

## Directories

- `./ci` - necessary data for continuous integration
- `./fml` - low-level cross-platform helper classes
- `./impeller` - a 2d renderer
- `./lib` - Contains the engine's Dart code (dart:ui).
- `./shell` - contains the embedders for each target platform
- `./third-party` - 3rd party dependencies which are copied here with depot
  tools.
- `./tools` - tools used for assisting engine development

## Style

- The Google C++ Style Guide is used for C++.
- C++ docstrings are in the Doxygen format.
- Prefer functions that are less than 30 lines long.
