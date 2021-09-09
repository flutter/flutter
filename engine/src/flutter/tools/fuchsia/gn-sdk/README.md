# flutter/tools/fuchsia/gn-sdk

This directory contains a few build rules imported from an August 2021 snapshot
of the Fuchsia GN SDK, with small (required) path adjustments.

The Dart Fuchsia tests require the Fuchsia _Core_ SDK, and the build rules in
the GN SDK require slight path modification to support building against the
Fuchsia Core SDK from a different location. Therefore, the Fuchsia Core SDK is
downloaded via `gclient sync` (versioned according to its fingerprint in DEPS),
and the modified build rules from Fuchsia GN SDK are, for now, copied to
and maintained in flutter/engine.

It is not yet clear if Fuchsia will want to provide SDK resources that support
GN build rules with Dart libraries and tests, but if that does happen, these
files should be replaced by the Fuchsia-provided build rules.

<!-- TODO(richkadel): Talk with Fuchsia SDK team about:
  1. Splitting the GN rules into a separate CIPD download (so SDK Dart libaries
     and reusable GN rules can both be downloaded into flutter)
  2. Ensuring the config.gni path to the SDK will work if the GN rules are not
     in the same directory as the other SDK artifacts (e.g., FIDL, C++, and
     Dart libraries)
  3. How to resolve third-party Dart dependencies in Fuchsia Dart meta.json
     files (i.e., including something like the `find_dart_libraries.py` script)
  4. Address issues found in the Flutter GN SDK build rules, including:
     * `cmc_merge` is adding `.cmx` extension redundantly (compared to
       fuchsia.git's version, which doesn't).
     * `prepare_package_inputs.py` list `unprocessed_binary_paths` can be empty
       for non-C++ packages (like Dart) but the code assumes the list is never
       empty, and crashes.
     * `prepare_package_inputs.py` list seems to require up front knowledge of
       all of the resources, at GN time, but for Dart, I seem to need to compile
       the libraries, so the compiler ("dart kernel") will generate a manifest
       of the compiled libraries that need to be added as resources. I had to
       add a separate JSON file of compile-time-generated list of additional
       resources to add to the package and its manifest.
     * Other `TODO(richkadel)` items in `flutter/tools/fuchsia`, mostly those
       in the `gn-sdk` subdirectory, but others (derived from fuchsia.git may
       add context.
-->


## Other GN SDK build rules to be considered

<!-- TODO(richkadel): revisit the following build rules and consider replacing
them with existing GN SDK rules.
-->

It may be wise to consider replacing a few other duplicated (but differently
built) build rules in `//flutter/tools/fuchsia` and `//build` with up-to-date
(via `gclient sync`) rules from the GN SDK. Some of the flutter versions of
these rules were originally imported from the fuchsia.git `//build` directory,
and tailored for flutter. The GN SDK build rules offer simplified versions of
these rules, pre-tailored for the Fuchsia SDK layout and out-of-tree use cases.

Known build files in this category, with the same file name and similar GN
templates, in both Flutter and Fuchsia GN SDK, include:

* fidl_library.gni
* gn_run_binary.py

Other Flutter GN SDK build rules that could replace flutter implemented logic
include:

* gn-sdk/build/fuchsia_sdk_pkg.gni could potentially replace some of the build
  logic in `//flutter/tools/fuchsia/sdk/sdk_targets.gni` and/or
  `//build/fuchsia/sdk.gni`
* gn-sdk/build/pm_tool.gni rules could potentially replace some flutter pm
  invocations

SDK build logic that might improve GN target implementations in flutter include:

* gn-sdk/build/test.gni
