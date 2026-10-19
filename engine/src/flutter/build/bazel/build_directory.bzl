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

def expand_output_pattern(pattern, file):
    """A GN output pattern expanded for one source file: `{{source_file_part}}` and `{{source_name_part}}`.

    Args:
      pattern: GN's output, with or without source expansions.
      file: the source File.

    Returns:
      The pattern with the expansions replaced, or None when it holds one
      this does not know.
    """
    name = file.basename
    stem = name[:-len(file.extension) - 1] if file.extension else name
    expanded = pattern.replace("{{source_file_part}}", name).replace("{{source_name_part}}", stem)
    if "{{" in expanded:
        return None
    return expanded

def copy_entries(outputs, files):
    """The BuildDirectoryInfo entries of a copy: its files at GN's `outputs`.

    A pattern output (`{{source_file_part}}`) places every file; literal
    outputs place the files one to one, in order. Outputs of a form this
    does not read (under a target's own gen dir written as such, an
    expansion other than the two above) place nothing, as before.

    Args:
      outputs: GN's `outputs`.
      files: the copy's files, in GN's `sources` order.

    Returns:
      A list of (file, path) pairs.
    """
    entries = []
    patterns = [o for o in outputs if "{{" in o]
    if patterns:
        for file in files:
            for pattern in patterns:
                path = build_directory_path(pattern)
                expanded = expand_output_pattern(path, file) if path else None
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
    if type(value) == "Target":
        return [value]
    if type(value) == "dict":
        return value.keys()
    if type(value) == "list":
        return [v for v in value if type(v) == "Target"]
    return []

def _build_directory_aspect_impl(target, ctx):
    transitive = []
    for attribute in ("deps", "srcs", "data"):
        for dep in _targets_of(getattr(ctx.rule.attr, attribute, None)):
            if _CollectedInfo in dep:
                transitive.append(dep[_CollectedInfo].entries)
    direct = target[BuildDirectoryInfo].entries if BuildDirectoryInfo in target else depset()
    return [_CollectedInfo(entries = depset(transitive = [direct] + transitive))]

_CollectedInfo = provider(
    doc = "BuildDirectoryInfo entries over a target's dependency closure.",
    fields = {"entries": "A depset of (file, path) pairs."},
)

build_directory_aspect = aspect(
    implementation = _build_directory_aspect_impl,
    doc = "Collects BuildDirectoryInfo over deps, srcs and data.",
    attr_aspects = ["deps", "srcs", "data"],
)

def collected_build_directory_entries(target):
    """The (file, path) pairs collected over `target`'s closure by build_directory_aspect."""
    return target[_CollectedInfo].entries.to_list()
