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
closure with `build_directory_aspect`.
"""

BuildDirectoryInfo = provider(
    doc = "Where a target's files sit in GN's build directory.",
    fields = {
        "entries": "A depset of (file, path) pairs, each file at its path under the build directory; " +
                   "a directory artifact's contents go under the path.",
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

def _build_directory_aspect_impl(target, ctx):
    transitive = []
    for attribute in _FOLLOWED_ATTRIBUTES:
        for dep in _targets_of(getattr(ctx.rule.attr, attribute, None)):
            if _CollectedInfo in dep:
                transitive.append(dep[_CollectedInfo].entries)
    if BuildDirectoryInfo in target:
        direct = target[BuildDirectoryInfo].entries
    elif ctx.rule.kind in ("cc_binary", "cc_shared_library"):
        # GN writes an executable or a shared library into the build root.
        direct = depset([(f, f.basename) for f in target[DefaultInfo].files.to_list()])
    else:
        direct = depset()
    return [_CollectedInfo(entries = depset(transitive = [direct] + transitive))]

_CollectedInfo = provider(
    doc = "BuildDirectoryInfo entries over a target's dependency closure.",
    fields = {"entries": "A depset of (file, path) pairs."},
)

build_directory_aspect = aspect(
    implementation = _build_directory_aspect_impl,
    doc = "Collects BuildDirectoryInfo over deps, srcs, data and an archive's files and trees, with executables " +
          "and shared libraries at the build root.",
    attr_aspects = _FOLLOWED_ATTRIBUTES,
)

def collected_build_directory_entries(target):
    """The (file, path) pairs collected over `target`'s closure by build_directory_aspect."""
    return target[_CollectedInfo].entries.to_list()
