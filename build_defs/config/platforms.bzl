# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A platform and its runtime modes: one output directory per mode, as GN has one build directory per mode.

GN builds every runtime mode in a build directory of its own (out/host_debug,
out/host_profile, out/android_release_arm64: tools/gn --runtime-mode), so
the modes never clobber each other. Bazel names a configuration's directory
(bazel-out/<name>-<compilation mode>/) after the target platform
(--experimental_platform_in_output_dir, .bazelrc) and the compilation mode,
and the engine's runtime mode is a Starlark flag
(//engine/src/flutter/common:runtime_mode), which enters the name only
through a transition's hash -- so --config=android_profile_arm64 and
--config=android_release_arm64 wrote the same bazel-out/android_arm64-opt/
and rebuilt each other's work (NEED_DECISION Q27).

The fix is Bazel's platform flags: `runtime_mode_platforms(name = "android_arm64",
...)` declares the platform and four children, `android_arm64_debug`,
`_profile`, `_release` and `_jit_release`, each inheriting its constraints
and carrying `--//engine/src/flutter/common:runtime_mode=<mode>` as a
platform flag. A build for `android_arm64_profile` lands in
bazel-out/android_arm64_profile-opt/, apart from the release build's, and
its mode comes with the platform. The builders' configurations
(ci/builders/configs.bazelrc, generated) name the mode's platform -- a host
build too, `linux_x64_<mode>`, where it named no platform before -- and
keep the flag on the command line as well: a platform's flags apply to the
configurations that select the platform, and the tools a build runs
(gen_snapshot in the Dart wrap, the frontend server) are built in the
execution configuration, whose platform is the host's modeless one, so the
mode reaches them from the command line as it did before (GN builds its
host tools in the same runtime mode). in_configuration (configuration.bzl)
moves between the modes of one platform by name: `runtime_mode_platform`.
"""

# GN's flutter_runtime_mode values, and the flag that carries one.
RUNTIME_MODES = ["debug", "profile", "release", "jit_release"]

RUNTIME_MODE_FLAG = "//engine/src/flutter/common:runtime_mode"

def runtime_mode_platforms(name, constraint_values = [], parents = [], flags = [], visibility = None, **kwargs):
    """A platform and a child per runtime mode, `<name>_<mode>`, carrying the mode as a platform flag.

    Args:
      name: the platform's name; the children are `<name>_debug`, `<name>_profile`,
        `<name>_release` and `<name>_jit_release`.
      constraint_values: the platform's constraints (platform()'s).
      parents: the platform's parents (platform()'s).
      flags: the platform's own flags (platform()'s: the web platform's
        Impeller backends), which the children carry along with the mode's.
      visibility: the platforms' visibility.
      **kwargs: platform()'s other attributes (exec_properties, ...), for the
        platform and its children alike.
    """
    native.platform(
        name = name,
        constraint_values = constraint_values,
        parents = parents,
        flags = flags,
        visibility = visibility,
        **kwargs
    )
    for mode in RUNTIME_MODES:
        native.platform(
            name = runtime_mode_platform_name(name, mode),
            parents = [":" + name],
            flags = flags + ["--%s=%s" % (RUNTIME_MODE_FLAG, mode)],
            visibility = visibility,
            **kwargs
        )

def runtime_mode_platform_name(base, mode):
    """The name of `base`'s platform for `mode`: `<base>_<mode>`."""
    return base + "_" + mode

def runtime_mode_platform_base(name):
    """The platform a mode's platform is a child of.

    Args:
      name: a platform's name.

    Returns:
      `android_arm64` for `android_arm64_profile`; `name` itself when it is no
      mode's.
    """
    for mode in RUNTIME_MODES:
        suffix = "_" + mode
        if name.endswith(suffix):
            return name[:-len(suffix)]
    return name
