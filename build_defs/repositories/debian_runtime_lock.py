#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Writes debian_runtime.lock.bzl: the Debian packages a browser loads at run time, pinned.

The engine's build sysroot (@sysroot_linux_x64, Chromium's Debian bullseye
tarball) is for linking: its shared objects are stubs with the code
stripped out, so a program cannot load them. The tests that drive the pinned
Chrome and Firefox (lib/web_ui's, flutter_tools' web shard) want the same
libraries whole, from the build rather than the host, so this tool computes
which Debian packages they are and where to fetch them, pinned by sha256,
and `debian_runtime_sysroot` (debian_runtime.bzl) unpacks them into a
runtime sysroot the browsers' launchers put on LD_LIBRARY_PATH.

The build sysroot carries dpkg's metadata for its 640 packages
(`debian/<package>/DEBIAN/{control,md5sums}`), which answers both questions
offline: which package ships a shared object the browsers name (`NEEDED`
entries of their ELF files, read with objdump), and what each package
depends on (`Depends`), at the versions the build sysroot was made from, so
the runtime libraries match the headers the engine compiles against. The
closure leaves out the C library and the compiler runtime (libc6,
libgcc-s1: a program keeps the host's, whose dynamic loader must match its
libc) and architecture-independent data packages (icon themes, MIME
databases) -- but for the ones named with `--data-package`, taken as they
are: the fonts the browsers render with (DejaVu, and Liberation, the
metric-compatible stand-ins for Arial, Times and Courier that fontconfig's
own rules alias them to) and fontconfig's configuration, so that a
rendering depends on no font of the host. Each package's file comes from
snapshot.debian.org, Debian's
immutable archive, found through its API by name and version and downloaded
once here for its sha256.

    python3 debian_runtime_lock.py \\
        --sysroot engine/src/out/bazel-flutter-8/external/+synced_deps+sysroot_linux_x64 \\
        --binary engine/src/out/bazel-flutter-8/external/+browsers+chrome/chrome-linux64/chrome \\
        --binary engine/src/out/bazel-flutter-8/external/+browsers+chrome/chromedriver-linux64/chromedriver \\
        --binary engine/src/out/bazel-flutter-8/external/+browsers+firefox/firefox/firefox \\
        --binary engine/src/out/bazel-flutter-8/external/+browsers+firefox/firefox/libxul.so \\
        --package libgl1 ... (Mesa, which Firefox dlopens) \\
        --data-package fonts-dejavu-core --data-package fonts-liberation=1:1.07.4-11 \\
        --data-package fontconfig-config \\
        --output build_defs/repositories/debian_runtime.lock.bzl
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.request

SNAPSHOT = "https://snapshot.debian.org"

# Packages a program keeps the host's: the C library and the dynamic loader,
# and the compiler runtime beside them.
HOST_PACKAGES = {"libc6", "libgcc-s1"}


def read_control(path):
    """The fields of a dpkg control file, folded lines joined."""
    fields = {}
    key = None
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.startswith((" ", "\t")) and key:
                fields[key] += line
            elif ":" in line:
                key, _, value = line.partition(":")
                fields[key] = value.strip()
    return fields


def depends(control):
    """The package names of a Depends field, the first alternative of each."""
    names = []
    for clause in control.get("Depends", "").split(","):
        clause = clause.strip()
        if not clause:
            continue
        first = clause.split("|")[0].strip()
        names.append(re.split(r"[\s(:]", first)[0])
    return names


def needed(binary):
    """The NEEDED sonames of an ELF file."""
    out = subprocess.run(["objdump", "-p", binary], check=True, capture_output=True, text=True).stdout
    return [line.split()[1] for line in out.splitlines() if line.strip().startswith("NEEDED")]


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--sysroot", required=True, help="The build sysroot's directory (its debian/ metadata).")
    parser.add_argument("--binary", action="append", default=[], help="An ELF file whose NEEDED libraries seed the closure; may repeat.")
    parser.add_argument("--package", action="append", default=[], help="A package to add to the roots; may repeat.")
    parser.add_argument(
        "--data-package",
        action="append",
        default=[],
        metavar="NAME[=VERSION]",
        help="An architecture-independent package to take as it is, without its dependencies (fonts, fontconfig's "
        "configuration); the version is the build sysroot's when the package is in it, else required; may repeat.",
    )
    parser.add_argument("--output", required=True, help="The .bzl file to write.")
    args = parser.parse_args(argv)

    # The packages: control fields and the shared objects each ships.
    controls = {}
    shipped = {}  # basename -> package
    debian = os.path.join(args.sysroot, "debian")
    for package in sorted(os.listdir(debian)):
        control_path = os.path.join(debian, package, "DEBIAN", "control")
        if not os.path.isfile(control_path):
            continue
        controls[package] = read_control(control_path)
        md5sums = os.path.join(debian, package, "DEBIAN", "md5sums")
        if os.path.isfile(md5sums):
            with open(md5sums, encoding="utf-8") as f:
                for line in f:
                    parts = line.split()
                    if len(parts) == 2 and "/lib/" in "/" + parts[1] and ".so" in parts[1]:
                        shipped[os.path.basename(parts[1])] = package

    def package_of(soname):
        if soname in shipped:
            return shipped[soname]
        for name, package in shipped.items():
            if name.startswith(soname + "."):
                return package
        return None

    roots = set(args.package)
    missing = []
    for binary in args.binary:
        for soname in needed(binary):
            package = package_of(soname)
            if package is None:
                missing.append((os.path.basename(binary), soname))
            else:
                roots.add(package)
    for binary, soname in missing:
        # A browser's own libraries (Firefox's libmozsandbox.so) and glibc's.
        print(f"note: {binary}: {soname} is not a sysroot package's", file=sys.stderr)

    closure = {}
    queue = sorted(roots)
    while queue:
        package = queue.pop(0)
        if package in closure or package in HOST_PACKAGES:
            continue
        control = controls.get(package)
        if control is None:
            print(f"warning: {package} is not in the sysroot's metadata; left out", file=sys.stderr)
            continue
        if control.get("Architecture") == "all":
            continue
        closure[package] = control
        queue.extend(depends(control))

    for data_package in args.data_package:
        package, _, version = data_package.partition("=")
        control = controls.get(package)
        if control is None:
            if not version:
                raise SystemExit(f"{package} is not in the sysroot's metadata; give its version as {package}=<version>")
            control = {"Version": version, "Architecture": "all"}
        closure[package] = control

    entries = {}
    for package, control in sorted(closure.items()):
        version = control["Version"]
        with urllib.request.urlopen(f"{SNAPSHOT}/mr/binary/{package}/{version}/binfiles?fileinfo=1") as response:
            info = json.load(response)
        candidates = [r["hash"] for r in info["result"] if r["architecture"] == control["Architecture"]]
        if not candidates:
            raise SystemExit(f"{package} {version}: no {control['Architecture']} file at {SNAPSHOT}")
        file_info = info["fileinfo"][candidates[0]][0]
        url = f"{SNAPSHOT}/archive/{file_info['archive_name']}/{file_info['first_seen']}{file_info['path']}/{file_info['name']}"
        with urllib.request.urlopen(url) as response:
            sha256 = hashlib.sha256(response.read()).hexdigest()
        entries[package] = (version, url, sha256)
        print(f"{package} {version} {sha256[:12]}", file=sys.stderr)

    with open(args.output, "w", encoding="utf-8") as out:
        out.write('# GENERATED by build_defs/repositories/debian_runtime_lock.py; do not edit.\n')
        out.write('"""The Debian packages the browsers the tests drive load at run time, pinned.\n\n')
        out.write("Each entry is the package's version in the engine's build sysroot, its file in\n")
        out.write("snapshot.debian.org's immutable archive, and the file's sha256 (debian_runtime.bzl).\n")
        out.write('"""\n\n')
        out.write("DEBIAN_RUNTIME_PACKAGES = {\n")
        for package, (version, url, sha256) in sorted(entries.items()):
            out.write(f'    "{package}": {{\n')
            out.write(f'        "sha256": "{sha256}",\n')
            out.write(f'        "url": "{url}",\n')
            out.write(f'        "version": "{version}",\n')
            out.write("    },\n")
        out.write("}\n")
    print(f"{len(entries)} packages -> {args.output}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
