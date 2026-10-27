#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Lays the Android embedding's Maven artifacts as a repository at another version (engine_maven_repository).

The build names the artifacts by the engine's git revision:
`zip_archives/download.flutter.io/io/flutter/flutter_embedding_debug/1.0.0-<revision>/flutter_embedding_debug-1.0.0-<revision>.jar`
(shell/platform/android's embedding_jars and abi_jars) and the poms beside
the build's other outputs as `flutter_embedding_debug.pom`,
`arm64_v8a_debug.pom` (pom_embedding, pom_libflutter), whose text names the
revision too. The tests' SDK facsimile says the engine is `bazel`
(bin/cache/engine.stamp), so the Gradle plugin asks for
`io.flutter:flutter_embedding_debug:1.0.0-bazel`: this writes
`<output>/download.flutter.io/io/flutter/<artifact>/1.0.0-<version>/<artifact>-1.0.0-<version>.<ext>`
for every jar and pom given, the revision replaced in the poms' text.
"""

import argparse
import os
import re
import shutil
import sys


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--output", required=True, help="The repository's directory.")
    parser.add_argument("--engine-version", required=True, help="The revision the build's artifacts name.")
    parser.add_argument("--version", required=True, help="What follows 1.0.0- in the repository.")
    parser.add_argument("files", nargs="*", help="The jars and poms.")
    args = parser.parse_args(argv)
    built = "1.0.0-" + args.engine_version
    wanted = "1.0.0-" + args.version
    versioned = re.compile(r"^(?P<artifact>[A-Za-z0-9_]+)-" + re.escape(built) + r"(?P<classifier>-[a-z]+)?\.(?P<ext>jar|pom)$")
    flat = re.compile(r"^(?P<artifact>[A-Za-z0-9_]+)\.(?P<ext>jar|pom)$")
    written = 0
    for path in args.files:
        name = os.path.basename(path)
        match = versioned.match(name) or flat.match(name)
        if not match:
            print(f"warning: {name}: not an artifact of the embedding; left out", file=sys.stderr)
            continue
        artifact = match.group("artifact")
        classifier = match.groupdict().get("classifier") or ""
        ext = match.group("ext")
        directory = os.path.join(args.output, "download.flutter.io", "io", "flutter", artifact, wanted)
        os.makedirs(directory, exist_ok=True)
        destination = os.path.join(directory, f"{artifact}-{wanted}{classifier}.{ext}")
        if ext == "pom":
            with open(path, encoding="utf-8") as f:
                text = f.read()
            with open(destination, "w", encoding="utf-8") as f:
                f.write(text.replace(built, wanted))
        else:
            shutil.copyfile(path, destination)
        written += 1
    if not written:
        raise SystemExit("no artifact written")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
