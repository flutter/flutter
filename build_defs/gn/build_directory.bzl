# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Where a target's files sit in GN's build directory.

GN writes every output into `engine/src/out/<build>/` at a path the target
names: a copy's `outputs` (`$root_gen_dir/dart-pkg/sky_engine/lib/async/
{{source_file_part}}`), an action's, an archive's `zip_archives/<output>`.
Bazel writes each under its package in bazel-bin instead, and `install`
(install.bzl) lays them out as GN does for the consumers that read the
build directory. A rule that knows where GN would put its files says so
with BuildDirectoryInfo; `install` collects it over a target's dependency
closure with `build_directory_aspect`, which also places an executable or
shared library at the build root as GN's link tools leave it: stripped, with
the binary as linked under exe.unstripped/ or lib.unstripped/.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@host_platform//:host.bzl", "HOST_CLANG")

BuildDirectoryInfo = provider(
    doc = "Where a target's files sit in GN's build directory.",
    fields = {
        "entries": "A depset of (file, path) pairs, each file at its path under the build directory; " +
                   "a directory artifact's contents go under the path.",
    },
)

GnBuildInfo = provider(
    doc = "Where the products of a wrapped GN build (gn_build) sit in GN's build directory. A product's " +
          "filegroup -- `output_group` over the build -- places its file there (build_directory_aspect).",
    fields = {
        "paths": "Product name (an output group) to its path under the GN build directory.",
    },
)

def build_directory_path(gn_output):
    """GN's path under the build directory for an output written as GN does.

    Args:
      gn_output: the output as GN names it: under `$root_out_dir/` (the
        build directory) or `$root_gen_dir/` (its gen/).

    Returns:
      The path under the build directory, or None for any other form.
    """
    if gn_output.startswith("$root_out_dir/"):
        return gn_output[len("$root_out_dir/"):]
    if gn_output.startswith("$root_gen_dir/"):
        return "gen/" + gn_output[len("$root_gen_dir/"):]
    return None

def expand_output_pattern(pattern, file, package = None):
    """A GN output pattern expanded for one source file.

    `{{source_file_part}}`, `{{source_name_part}}`, and, given the copy's
    package, `{{source_target_relative}}` for a file of that package (its
    path under the package, as GN's is under the BUILD file's directory).

    Args:
      pattern: GN's output, with or without source expansions.
      file: the source File.
      package: the copy's package, for `{{source_target_relative}}`.

    Returns:
      The pattern with the expansions replaced, or None when it holds one
      this does not know (or cannot say for the file).
    """
    name = file.basename
    stem = name[:-len(file.extension) - 1] if file.extension else name
    expanded = pattern.replace("{{source_file_part}}", name).replace("{{source_name_part}}", stem)
    if "{{source_target_relative}}" in expanded:
        prefix = package + "/" if package else None
        if not prefix or not file.short_path.startswith(prefix):
            return None
        expanded = expanded.replace("{{source_target_relative}}", file.short_path[len(prefix):])
    if "{{" in expanded:
        return None
    return expanded

def path_under_root(file, root, label = None):
    """A file's path under `root`, a directory of its repository.

    A directory copied or archived whole keeps its files' paths below it
    (copy_tree's, a zip_tree's): the prebuilt Dart SDK's `bin/dart` under
    `dart-sdk/`, the shader library's `impeller/blending.glsl`.

    Args:
      file: the File.
      root: the directory, relative to the root of the file's repository;
        empty for the repository's root itself.
      label: the caller's label, for the message when the file is not
        under `root`.

    Returns:
      The path, relative to `root`.
    """

    # short_path is relative to the main repository's root, with another
    # repository's files under `../<repository>/`.
    path = file.short_path
    if path.startswith("../"):
        path = path.split("/", 2)[2]
    if root:
        if not path.startswith(root + "/"):
            fail("%s: %s is not under %s" % (label, file.short_path, root))
        path = path[len(root) + 1:]
    return path

def copy_entries(outputs, files, package = None):
    """The BuildDirectoryInfo entries of a copy: its files at GN's `outputs`.

    A pattern output (`{{source_file_part}}`) places every file; literal
    outputs place the files one to one, in order. Outputs of a form this
    does not read (under a target's own gen dir written as such, an
    expansion other than the ones expand_output_pattern knows) place
    nothing, as before.

    Args:
      outputs: GN's `outputs`.
      files: the copy's files, in GN's `sources` order.
      package: the copy's package, for `{{source_target_relative}}`.

    Returns:
      A list of (file, path) pairs.
    """
    entries = []
    patterns = [o for o in outputs if "{{" in o]
    if patterns:
        for file in files:
            for pattern in patterns:
                path = build_directory_path(pattern)
                expanded = expand_output_pattern(path, file, package) if path else None
                if expanded:
                    entries.append((file, expanded))
        return entries
    paths = [build_directory_path(o) for o in outputs]
    if len(paths) != len(files) or None in paths:
        return entries
    for file, path in zip(files, paths):
        entries.append((file, path))
    return entries

def _targets_of(value):
    # A label, a list of labels, or a dict keyed by labels
    # (label_keyed_string_dict) or holding them (string_keyed_label_dict:
    # a zip_bundle's `files`, destination to target).
    if type(value) == "Target":
        return [value]
    if type(value) == "dict":
        return [v for v in value.keys() + value.values() if type(v) == "Target"]
    if type(value) == "list":
        return [v for v in value if type(v) == "Target"]
    return []

# The attributes the aspect follows: a rule's dependencies, sources and
# data, and an archive's `files` and `trees` (zip_bundle.bzl) -- ninja
# building GN's archive target writes its inputs' closure into the build
# directory too (the web SDK's tree beside flutter-web-sdk.zip).
_FOLLOWED_ATTRIBUTES = ["deps", "srcs", "data", "files", "trees"]

def _strip(ctx, binary, directory, flag):
    """`llvm-objcopy <flag>` of `binary` into `<directory>/<binary's name>` beside it.

    The copy keeps the binary's name, in a directory of its own: a script
    that names a file after its input (create_flutter_jar.py, the jar's
    lib/<abi>/ entries) sees the name GN's layout has.
    """
    package = ctx.label.package
    relative = binary.short_path[len(package) + 1:] if package else binary.short_path
    parent = relative[:-len(binary.basename)]
    stripped = ctx.actions.declare_file(parent + directory + "/" + binary.basename)
    objcopy = [f for f in ctx.files._objcopy if f.basename == "llvm-objcopy"]
    if len(objcopy) != 1:
        fail("%s: _objcopy should hold llvm-objcopy, holds %s" % (ctx.label, ctx.files._objcopy))
    args = ctx.actions.args()
    args.add(flag)
    args.add(binary)
    args.add(stripped)
    ctx.actions.run(
        executable = objcopy[0],
        arguments = [args],
        inputs = [binary],
        tools = ctx.files._objcopy,
        outputs = [stripped],
        mnemonic = "Strip",
        progress_message = "Stripping %{output}",
    )
    return stripped

def _binary_entries(target, ctx):
    # GN's link tools write an executable to exe.unstripped/ and
    # `llvm-objcopy --strip-all` it into the build root, always; a shared
    # library goes through lib.unstripped/ the same way under
    # stripped_symbols (the `stripped` flag; tools/gn's default, which only
    # the developer's --no-stripped configurations and Android turn off).
    # The binary in bazel-bin stays as linked -- the tests run it, as GN's
    # unstripped copy is there to be run under a debugger -- and what an
    # install or an archive ships is stripped here, by the same tool with
    # the same flag. The Android toolchain besides writes every shared
    # library `--strip-unneeded` into lib.stripped/ (build/toolchain/android,
    # postsolink), stripped_symbols or not: the copy the Android embedding's
    # jar packages.
    shared = ctx.rule.kind == "cc_shared_library" or getattr(ctx.rule.attr, "linkshared", False)
    android = ctx.target_platform_has_constraint(ctx.attr._android[platform_common.ConstraintValueInfo])
    apple = (
        ctx.target_platform_has_constraint(ctx.attr._macos[platform_common.ConstraintValueInfo]) or
        ctx.target_platform_has_constraint(ctx.attr._ios[platform_common.ConstraintValueInfo])
    )
    entries = []
    shipped = {}
    for binary in target[DefaultInfo].files.to_list():
        # GN's mac toolchain (build/toolchain/mac, iOS's too) links into the
        # build root as is and strips nothing: the frameworks' packaging
        # strips and writes dSYMs (the Apple products' phase, research/20 M4).
        if apple:
            entries.append((binary, binary.basename))
            continue
        if shared and android:
            entries.append((_strip(ctx, binary, "lib.stripped", "--strip-unneeded"), "lib.stripped/" + binary.basename))
        if shared and not ctx.attr._stripped[BuildSettingInfo].value:
            entries.append((binary, binary.basename))
            continue

        # `<name>.stripped` is cc_binary's own (its CcStrip action, the
        # toolchain's strip with -S: debug sections only); this is GN's
        # --strip-all copy, the file an archive or install ships, under
        # shipped/ in bazel-bin.
        stripped = _strip(ctx, binary, "shipped", "--strip-all")
        entries.append((stripped, binary.basename))
        entries.append((binary, ("lib.unstripped/" if shared else "exe.unstripped/") + binary.basename))
        shipped[binary] = stripped
    return entries, shipped

def _gn_build_product(ctx):
    """The build-directory path of a gn_build product's filegroup, or None for any other filegroup."""
    group = getattr(ctx.rule.attr, "output_group", "")
    srcs = getattr(ctx.rule.attr, "srcs", [])
    if not group or len(srcs) != 1 or GnBuildInfo not in srcs[0]:
        return None
    return srcs[0][GnBuildInfo].paths.get(group)

def _build_directory_aspect_impl(target, ctx):
    transitive = []
    for attribute in _FOLLOWED_ATTRIBUTES:
        for dep in _targets_of(getattr(ctx.rule.attr, attribute, None)):
            if _CollectedInfo in dep:
                transitive.append(dep[_CollectedInfo].entries)
    binary = None
    shipped = {}
    if BuildDirectoryInfo in target:
        direct = target[BuildDirectoryInfo].entries
    elif ctx.rule.kind == "filegroup" and _gn_build_product(ctx) != None:
        # A product of a wrapped GN build (gn_build's `:gen_snapshot`): at
        # its path in GN's build directory (clang_x64/gen_snapshot for a
        # cross build's host tool).
        direct = depset([(f, _gn_build_product(ctx)) for f in target[DefaultInfo].files.to_list()])
    elif ctx.rule.kind in ("cc_binary", "cc_shared_library"):
        # GN writes an executable or a shared library into the build root.
        binary, shipped = _binary_entries(target, ctx)
        direct = depset(binary)
    else:
        direct = depset()
    return [_CollectedInfo(
        entries = depset(transitive = [direct] + transitive),
        binary = binary,
        shipped = shipped,
    )]

_CollectedInfo = provider(
    doc = "BuildDirectoryInfo entries over a target's dependency closure.",
    fields = {
        "entries": "A depset of (file, path) pairs.",
        "binary": "For an executable or shared library: its own (file, path) pairs -- the stripped copy at the " +
                  "build root and the binary under exe.unstripped/ or lib.unstripped/ -- else None.",
        "shipped": "For a binary: its files mapped to the copies an archive or install ships.",
    },
)

build_directory_aspect = aspect(
    implementation = _build_directory_aspect_impl,
    doc = "Collects BuildDirectoryInfo over deps, srcs, data and an archive's files and trees, with executables " +
          "and shared libraries at the build root, stripped as GN's link tools strip them.",
    attr_aspects = _FOLLOWED_ATTRIBUTES,
    attrs = {
        "_stripped": attr.label(default = "//engine/src/flutter/build/bazel:stripped"),
        "_android": attr.label(default = "@platforms//os:android"),
        "_macos": attr.label(default = "@platforms//os:macos"),
        "_ios": attr.label(default = "@platforms//os:ios"),
        # The host's llvm-objcopy (@host_platform), whichever host builds.
        "_objcopy": attr.label(
            default = HOST_CLANG + "//:objcopy_files",
            allow_files = True,
            cfg = "exec",
        ),
    },
)

def collected_build_directory_entries(target):
    """The (file, path) pairs collected over `target`'s closure by build_directory_aspect."""
    return target[_CollectedInfo].entries.to_list()

def binary_entries(target):
    """An executable's or shared library's own (file, path) pairs, or None for any other target.

    The pairs are what GN's link tool leaves: the stripped binary at the
    build root and the one linked under exe.unstripped/ or lib.unstripped/
    (a shared library under `stripped` only; otherwise just the library).

    Args:
      target: a target the aspect ran on.

    Returns:
      A list of (file, path) pairs, or None.
    """
    if _CollectedInfo not in target:
        return None
    return target[_CollectedInfo].binary

def shipped_file(target, file):
    """The copy of `file` of `target` that an archive or install ships: the stripped one for a binary, else `file`."""
    if _CollectedInfo not in target:
        return file
    return target[_CollectedInfo].shipped.get(file, file)
