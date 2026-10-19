#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Compares an installed Bazel build directory with a GN build directory.

`bazel run //engine/src/flutter:install -- <directory>` lays a build's files
out as GN's `engine/src/out/<build>/` is (build/bazel/install.bzl). This tool
walks the consumer-visible paths of such a directory -- what the flutter
tool reads from a `--local-engine`, the embedder's library and header, the
archives -- in both and reports, per path: whether it is on both sides, and
for a file whether the two are identical (modulo the version hash in a
generated LICENSE), expected to differ (a binary; `--expect-different`), or
different; a directory is every file under it; an archive is compared entry
by entry as artifact_diff.py does. Paths not given on the command line
default to the Linux host's. Exit status 1 when a path is missing on either
side or a file differs unexpectedly.

    python3 install_diff.py --gn engine/src/out/host_debug_unopt \\
        --bazel engine/src/out/host_debug_unopt_bazel \\
        --expect-different=flutter_tester --expect-different='*.so' ...
"""

import argparse
import fnmatch
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import artifact_diff  # pylint: disable=wrong-import-position

# The Linux host build directory as the flutter tool's artifacts.dart reads
# a local engine (flutter_tester, gen_snapshot, icudtl.dat, impellerc and
# libtessellator.so, font-subset, the GTK library with its flutter_linux/
# headers, dart-sdk/, flutter_patched_sdk/, gen/flutter/lib/snapshot/, the
# frontend server), plus the embedder's library and header, path_ops, and
# the archives.
DEFAULT_PATHS = [
    "flutter_tester",
    "gen_snapshot",
    "icudtl.dat",
    "impellerc",
    "libtessellator.so",
    "libpath_ops.so",
    "font-subset",
    "libflutter_linux_gtk.so",
    "flutter_linux",
    "libflutter_engine.so",
    "flutter_embedder.h",
    "dart-sdk",
    "flutter_patched_sdk",
    "gen/flutter/lib/snapshot",
    "gen/frontend_server_aot.dart.snapshot",
    "zip_archives",
]

# GN's bookkeeping and intermediates next to its outputs, which no consumer
# reads: depfiles, stamps, and the assembly bin_to_linkable writes under
# gen/flutter/lib/snapshot/out/<build>/.
DEFAULT_IGNORED = ["*.d", "*.stamp", "*.S"]


def _files_under(root, ignored):
    """The files under `root` (a file or a directory) by path relative to it; empty if absent."""
    if os.path.isfile(root):
        return {"": root}
    found = {}
    for directory, _, files in os.walk(root):
        for name in files:
            path = os.path.join(directory, name)
            relative = os.path.relpath(path, root)
            if any(fnmatch.fnmatch(relative, g) or fnmatch.fnmatch(name, g) for g in ignored):
                continue
            found[relative] = path
    return found


def _same(gn_path, bazel_path):
    with open(gn_path, "rb") as gn, open(bazel_path, "rb") as bazel:
        gn_content, bazel_content = gn.read(), bazel.read()
    name = os.path.basename(gn_path)
    return artifact_diff._normalized(name, gn_content) == artifact_diff._normalized(  # pylint: disable=protected-access
        name, bazel_content
    )


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--gn", required=True, help="GN's build directory.")
    parser.add_argument("--bazel", required=True, help="The installed Bazel build directory.")
    parser.add_argument(
        "--expect-different",
        action="append",
        default=[],
        metavar="GLOB",
        help="Files (by path under the build directory, or base name) and archive entries whose "
        "content is expected to differ (binaries); may repeat.",
    )
    parser.add_argument(
        "--ignore",
        action="append",
        default=list(DEFAULT_IGNORED),
        metavar="GLOB",
        help=f"Files under a directory to leave out (default: {', '.join(DEFAULT_IGNORED)}); may repeat.",
    )
    parser.add_argument(
        "paths", nargs="*", default=DEFAULT_PATHS, help="Paths under the build directory to compare."
    )
    args = parser.parse_args(argv)

    def expected(path):
        return any(
            fnmatch.fnmatch(path, g) or fnmatch.fnmatch(os.path.basename(path), g)
            for g in args.expect_different
        )

    failures = 0
    totals = {"identical": 0, "expected": 0, "different": 0, "missing": 0}
    for path in args.paths:
        gn_root = os.path.join(args.gn, path)
        bazel_root = os.path.join(args.bazel, path)
        if not os.path.exists(gn_root) or not os.path.exists(bazel_root):
            side = "GN" if os.path.exists(gn_root) else "Bazel" if os.path.exists(bazel_root) else "neither"
            print(f"{path}: only in {side}")
            failures += 1
            totals["missing"] += 1
            continue
        gn_files = _files_under(gn_root, args.ignore)
        bazel_files = _files_under(bazel_root, args.ignore)
        identical, expected_different, different, details = [], [], [], []
        for relative in sorted(set(gn_files) | set(bazel_files)):
            full = os.path.join(path, relative) if relative else path
            if relative not in gn_files or relative not in bazel_files:
                details.append(f"  only in {'GN' if relative in gn_files else 'Bazel'}: {full}")
                continue
            if full.endswith(".zip"):
                ok, lines = artifact_diff.compare_archive(
                    full, gn_files[relative], bazel_files[relative], args.expect_different
                )
                details.extend("  " + line for line in lines)
                (identical if ok else different).append(full)
            elif _same(gn_files[relative], bazel_files[relative]):
                identical.append(full)
            elif expected(full):
                expected_different.append(full)
            else:
                different.append(full)
                details.append(f"  different: {full}")
        missing = [d for d in details if d.startswith("  only in")]
        ok = not different and not missing
        if os.path.isfile(gn_root):
            verdict = "identical" if identical else "expected different" if expected_different else "DIFFERENT"
            print(f"{path}: {verdict}")
        else:
            print(
                f"{path}: {'ok' if ok else 'DIFFERS'}; {len(bazel_files)} files"
                f"{'' if len(gn_files) == len(bazel_files) else f' (GN {len(gn_files)})'}, "
                f"{len(identical)} identical, {len(expected_different)} expected different, "
                f"{len(different)} different, {len(missing)} missing"
            )
        for line in details:
            print(line)
        if not ok:
            failures += 1
        totals["identical"] += len(identical)
        totals["expected"] += len(expected_different)
        totals["different"] += len(different)
        totals["missing"] += len(missing)
    print(
        f"{len(args.paths)} paths, {len(args.paths) - failures} ok: "
        f"{totals['identical']} files identical, {totals['expected']} expected different, "
        f"{totals['different']} different, {totals['missing']} missing"
    )
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
