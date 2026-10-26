#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Compares a Bazel build's consumer-visible files with a GN build directory.

The Bazel side is either an installed directory -- `bazel run --config=<build>
//engine/src/flutter/ci/builders:<build> -- <directory>` lays a builder's
files out as GN's `engine/src/out/<build>/` is (build_defs/dist/install.bzl)
-- or the directory holding a `local_engine.json`, which maps the GN paths
the flutter tool reads to where Bazel built the files
(build_defs/dist/local_engine.bzl; `bazel build //engine/src/flutter:local_engine`
writes it beside its outputs). This tool walks the consumer-visible paths --
what the flutter tool reads from a `--local-engine`, the embedder's library
and header, the archives -- in both and reports, per path: whether it is on
both sides, and for a file whether the two are identical (modulo the version
hash in a generated LICENSE), expected to differ (a binary;
`--expect-different`), or different; a directory is every file under it; an
archive is compared entry by entry as artifact_diff.py does. Paths not given
on the command line default to the Linux host's (without the archives for a
manifest, which has none). Exit status 1 when a path is missing on either
side or a file differs unexpectedly.

    python3 install_diff.py --gn engine/src/out/host_debug_unopt \\
        --bazel engine/src/out/bazel-bin/engine/src/flutter \\
        --expect-different=flutter_tester --expect-different='*.so' ...
    python3 install_diff.py --gn engine/src/out/ci/host_debug --bazel <installed directory>
    python3 install_diff.py --web --gn engine/src/out/wasm_release --bazel <dir>
"""

import argparse
import fnmatch
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import artifact_diff  # pylint: disable=wrong-import-position

# The Linux host build directory as the flutter tool's artifacts.dart reads
# a local engine (flutter_tester, gen_snapshot, icudtl.dat, impellerc and
# libtessellator.so, font-subset, the GTK library with its flutter_linux/
# headers, dart-sdk/, flutter_patched_sdk/, gen/flutter/lib/snapshot/, the
# frontend server, the sky_engine package), plus the embedder's library and
# header, path_ops, and the archives.
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
    "gen/dart-pkg/sky_engine",
    "zip_archives",
]

# The web build directory (wasm_release, wasm_debug_unopt): the SDK tree the
# flutter tool's --local-web-sdk reads and the archive CI uploads, with the
# six modules' files -- .wasm, .js.symbols, the .wasm.map of an unoptimized
# build and the .js loaders -- expected to differ as builds under different
# toolchains' flags do (--web).
WEB_PATHS = ["flutter_web_sdk", "zip_archives/flutter-web-sdk.zip"]
WEB_EXPECTED_DIFFERENT = [
    "*.wasm",
    "*.js.symbols",
    "*.wasm.map",
    "canvaskit.js",
    "skwasm.js",
    "skwasm_heavy.js",
    "wimp.js",
]

# GN's bookkeeping and intermediates next to its outputs, which no consumer
# reads: depfiles, stamps, and the assembly bin_to_linkable writes under
# gen/flutter/lib/snapshot/out/<build>/.
DEFAULT_IGNORED = ["*.d", "*.stamp", "*.S"]

# The manifest a Bazel local engine writes beside its outputs.
LOCAL_ENGINE_MANIFEST = "local_engine.json"


def _manifest_resolver(directory):
    """Resolves GN paths through `directory`'s local_engine.json; None without one.

    An entry maps a GN path (`flutter_tester`, `gen/flutter/lib/snapshot`) to
    where Bazel built it, relative to the manifest's directory; a path
    resolves through the longest entry that is it or a parent of it, as the
    flutter tool's LocalEngineLayout does, and stays where it is under the
    directory when no entry covers it (and so reports as missing).
    """
    manifest = os.path.join(directory, LOCAL_ENGINE_MANIFEST)
    if not os.path.isfile(manifest):
        return None
    with open(manifest, encoding="utf-8") as f:
        entries = json.load(f)["entries"]
    base = os.path.realpath(directory)

    def resolve(path):
        parts = path.split("/")
        for n in range(len(parts), 0, -1):
            prefix = "/".join(parts[:n])
            if prefix in entries:
                return os.path.normpath(os.path.join(base, entries[prefix], *parts[n:]))
        return os.path.join(directory, path)

    return resolve


def _files_under(root, ignored):
    """The files under `root` (a file or a directory) by path relative to it; empty if absent.

    Symbolic links to directories are followed: a repository Bazel fetched
    (the prebuilt Dart SDK a manifest maps `dart-sdk` to) is one.
    """
    if os.path.isfile(root):
        return {"": root}
    found = {}
    for directory, _, files in os.walk(root, followlinks=True):
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
    parser.add_argument(
        "--bazel",
        required=True,
        help=f"The installed Bazel build directory, or the directory holding a {LOCAL_ENGINE_MANIFEST}.",
    )
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
        "--web",
        action="store_true",
        help="Compare a web build directory: the paths default to flutter_web_sdk/ and the SDK "
        "archive, and the modules' files are expected to differ.",
    )
    parser.add_argument(
        "paths", nargs="*", help="Paths under the build directory to compare (default: the Linux host's)."
    )
    args = parser.parse_args(argv)
    if args.web:
        args.expect_different = args.expect_different + WEB_EXPECTED_DIFFERENT
    resolve = _manifest_resolver(args.bazel)
    manifest = resolve is not None
    if not args.paths:
        args.paths = WEB_PATHS if args.web else DEFAULT_PATHS
        if manifest:
            args.paths = [path for path in args.paths if path != "zip_archives"]
    if not manifest:
        resolve = lambda path: os.path.join(args.bazel, path)  # pylint: disable=unnecessary-lambda-assignment

    def expected(path):
        return any(
            fnmatch.fnmatch(path, g) or fnmatch.fnmatch(os.path.basename(path), g)
            for g in args.expect_different
        )

    failures = 0
    totals = {"identical": 0, "expected": 0, "different": 0, "missing": 0}
    for path in args.paths:
        gn_root = os.path.join(args.gn, path)
        bazel_root = resolve(path)
        if not os.path.exists(gn_root) or not os.path.exists(bazel_root):
            side = "GN" if os.path.exists(gn_root) else "Bazel" if os.path.exists(bazel_root) else "neither"
            print(f"{path}: only in {side}")
            failures += 1
            totals["missing"] += 1
            continue
        gn_files = _files_under(gn_root, args.ignore)
        bazel_files = _files_under(bazel_root, args.ignore)
        beside = 0
        if manifest:
            # Bazel's output tree holds other outputs beside the mapped files
            # (a package's intermediates, a repository's BUILD file); the
            # consumer reads GN's paths, so only those are looked for.
            beside = len(set(bazel_files) - set(gn_files))
            bazel_files = {relative: f for relative, f in bazel_files.items() if relative in gn_files}
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
                # The sizes, so that two Bazel files that should differ and do
                # not (one module installed at every variant's place) show.
                expected_different.append(full)
                details.append(
                    f"  expected different: {full} (GN {os.path.getsize(gn_files[relative])} B, "
                    f"Bazel {os.path.getsize(bazel_files[relative])} B)"
                )
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
                f"{f', {beside} other files beside them' if beside else ''}"
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
