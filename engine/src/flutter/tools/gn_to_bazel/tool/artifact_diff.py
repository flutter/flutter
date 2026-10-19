# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Compares the archives a Bazel build and a GN build of the same configuration produce.

GN writes the archives CI uploads under `<out>/zip_archives/` (the zip_bundle
template); the converted zip_bundle rules write theirs under
`bazel-bin/engine/src/flutter/<package>/zip_archives/`. This tool pairs the
two by the archive's path under zip_archives/ and reports, per archive: the
entries each side has that the other lacks, whether the entries come in the
same order, and which common entries differ -- after normalizing the
generated `LICENSE.<target>.md` (its engine version hash) -- so that a
difference is a build difference, not noise.

    cd engine/src
    ninja -C out/host_debug_unopt flutter/build/archives:artifacts ...
    bazel build //engine/src/flutter/build/archives:all ...
    python3 flutter/tools/gn_to_bazel/tool/artifact_diff.py \\
        --gn=out/host_debug_unopt --bazel=out/bazel-bin/engine/src/flutter

Entries whose content is expected to differ -- binaries, which the two
builds compile under flags that agree only up to the known parity classes --
are listed with `--expect-different=NAME` (a glob over the entry path);
they count as "expected" rather than "different". The exit status is 1 when
an archive is missing on either side, has an entry the other lacks, or has
an unexpected difference; entry order is reported, not counted (zip.py walks
a directory in the filesystem's order, which GN does not promise).
"""

import argparse
import fnmatch
import os
import re
import sys
import zipfile

_VERSION_HASH = re.compile(rb"[0-9a-f]{40}")


def _archives(root):
    """The zip files under `<root>/**/zip_archives/`, by their path under zip_archives/."""
    found = {}
    # The root may be a convenience symlink (bazel-bin); below it the
    # archives sit in real directories, and the symlinks are the runfiles
    # forests of every test and binary, which lead back into the checkout.
    for directory, subdirectories, files in os.walk(os.path.realpath(root)):
        subdirectories[:] = [d for d in subdirectories if not d.endswith(".runfiles")]
        if "zip_archives" not in directory.split(os.sep):
            continue
        parts = directory.split(os.sep)
        below = os.sep.join(parts[parts.index("zip_archives") + 1 :])
        for name in files:
            if name.endswith(".zip"):
                found[os.path.join(below, name) if below else name] = os.path.join(directory, name)
    return found


def _entries(path):
    with zipfile.ZipFile(path) as archive:
        return [(info.filename, archive.read(info.filename)) for info in archive.infolist()]


def _normalized(name, content):
    if os.path.basename(name).startswith("LICENSE.") and name.endswith(".md"):
        return _VERSION_HASH.sub(b"<version>", content)
    return content


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--gn", required=True, help="GN's build directory (holds zip_archives/).")
    parser.add_argument(
        "--bazel",
        required=True,
        help="A directory of Bazel's output tree to search for zip_archives/ directories "
        "(engine/src/out/bazel-bin/engine/src/flutter).",
    )
    parser.add_argument(
        "--expect-different",
        action="append",
        default=[],
        metavar="GLOB",
        help="Entries (by path in the archive, or base name) whose content is expected to differ "
        "(binaries); may repeat.",
    )
    parser.add_argument(
        "--only",
        action="append",
        default=[],
        metavar="GLOB",
        help="Compare only archives whose path under zip_archives/ matches; may repeat.",
    )
    args = parser.parse_args(argv)

    gn = _archives(args.gn)
    bazel = _archives(args.bazel)
    names = sorted(set(gn) | set(bazel))
    if args.only:
        names = [n for n in names if any(fnmatch.fnmatch(n, g) for g in args.only)]
    if not names:
        print("no archives found", file=sys.stderr)
        return 2

    failures = 0
    for name in names:
        if name not in gn or name not in bazel:
            print(f"{name}: only in {'GN' if name in gn else 'Bazel'}")
            failures += 1
            continue
        ok, lines = compare_archive(name, gn[name], bazel[name], args.expect_different)
        print("\n".join(lines))
        if not ok:
            failures += 1
    return 1 if failures else 0


def compare_archive(name, gn_path, bazel_path, expect_different):
    """Compares two archives entry by entry.

    Returns whether they agree (the same entries, every common entry
    identical or expected to differ) and the lines of the report, the first a
    summary under `name` and the rest the entries that disagree.
    """
    gn_entries = _entries(gn_path)
    bazel_entries = _entries(bazel_path)
    gn_names = [n for n, _ in gn_entries]
    bazel_names = [n for n, _ in bazel_entries]
    gn_set, bazel_set = set(gn_names), set(bazel_names)
    gn_by_name = dict(gn_entries)
    identical, expected, different = [], [], []
    for entry, content in bazel_entries:
        if entry not in gn_by_name:
            continue
        if _normalized(entry, content) == _normalized(entry, gn_by_name[entry]):
            identical.append(entry)
        elif any(
            fnmatch.fnmatch(entry, g) or fnmatch.fnmatch(os.path.basename(entry), g)
            for g in expect_different
        ):
            expected.append(entry)
        else:
            different.append(entry)
    order = "same order" if gn_names == bazel_names else "different order"
    ok = not different and gn_set == bazel_set
    lines = [
        f"{name}: {'ok' if ok else 'DIFFERS'}; {len(bazel_names)} entries"
        f"{'' if gn_set == bazel_set else f' (GN {len(gn_names)})'}, "
        f"{len(identical)} identical, {len(expected)} expected different, "
        f"{len(different)} different; {order}"
    ]
    lines.extend(f"  only in Bazel: {entry}" for entry in sorted(bazel_set - gn_set))
    lines.extend(f"  only in GN: {entry}" for entry in sorted(gn_set - bazel_set))
    lines.extend(f"  different: {entry}" for entry in different)
    return ok, lines


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
