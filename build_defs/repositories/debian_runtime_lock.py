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

What the build sysroot lacks altogether -- Xvfb, the X server felt starts
for Firefox, a program rather than a library -- comes from bullseye's own
Packages index as snapshot.debian.org had it at `--index`'s timestamp (the
month of the build sysroot's newest package), which gives such a package's
version, dependencies, file and sha256; a package the sysroot has keeps
the sysroot's version.

    python3 debian_runtime_lock.py \\
        --sysroot engine/src/out/bazel-flutter-8/external/+synced_deps+sysroot_linux_x64 \\
        --binary engine/src/out/bazel-flutter-8/external/+browsers+chrome/chrome-linux64/chrome \\
        --binary engine/src/out/bazel-flutter-8/external/+browsers+chrome/chromedriver-linux64/chromedriver \\
        --binary engine/src/out/bazel-flutter-8/external/+browsers+firefox/firefox/firefox \\
        --binary engine/src/out/bazel-flutter-8/external/+browsers+firefox/firefox/libxul.so \\
        --package libgl1 ... (Mesa, which Firefox dlopens) \\
        --index 20240901T000000Z --package xvfb --data-package xkb-data \\
        --package ninja-build --package pkg-config \\
        --data-package fonts-dejavu-core --data-package fonts-liberation \\
        --data-package fontconfig-config \\
        --output build_defs/repositories/debian_runtime.lock.bzl
"""

import argparse
import hashlib
import json
import lzma
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
    with open(path, encoding="utf-8") as f:
        return parse_stanza(f.read())


def parse_stanza(text):
    """The fields of one control stanza (a dpkg control file, a Packages index entry)."""
    fields = {}
    key = None
    for line in text.splitlines(keepends=True):
        if line.startswith((" ", "\t")) and key:
            fields[key] += line
        elif ":" in line:
            key, _, value = line.partition(":")
            fields[key] = value.strip()
    return fields


def read_index(timestamp, suite="bullseye", architecture="amd64"):
    """The binary packages of a Debian suite as snapshot.debian.org had its index at a timestamp: name to fields."""
    url = f"{SNAPSHOT}/archive/debian/{timestamp}/dists/{suite}/main/binary-{architecture}/Packages.xz"
    with urllib.request.urlopen(url) as response:
        text = lzma.decompress(response.read()).decode("utf-8")
    index = {}
    for stanza in text.split("\n\n"):
        fields = parse_stanza(stanza)
        if "Package" in fields:
            index[fields["Package"]] = fields
    return index


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
    parser.add_argument(
        "--index",
        metavar="TIMESTAMP",
        help="A snapshot.debian.org timestamp (20240901T000000Z) of bullseye's Packages index, for the packages the "
        "build sysroot lacks (Xvfb): their versions, dependencies and files come from the index.",
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

    # The packages outside the build sysroot, at bullseye's versions of the
    # index's day; a package the sysroot has keeps the sysroot's.
    index = read_index(args.index) if args.index else {}

    def control_of(package):
        if package in controls:
            return controls[package]
        if package in index:
            return index[package]
        return None

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
        control = control_of(package)
        if control is None:
            print(f"warning: {package} is in neither the sysroot's metadata nor the index; left out", file=sys.stderr)
            continue
        if control.get("Architecture") == "all":
            continue
        closure[package] = control
        queue.extend(depends(control))

    for data_package in args.data_package:
        package, _, version = data_package.partition("=")
        control = control_of(package)
        if control is None:
            if not version:
                raise SystemExit(f"{package} is in neither the sysroot's metadata nor the index; give its version as {package}=<version>")
            control = {"Version": version, "Architecture": "all"}
        elif version and version != control["Version"]:
            control = {"Version": version, "Architecture": "all"}
        closure[package] = control

    entries = {}
    for package, control in sorted(closure.items()):
        version = control["Version"]
        if "Filename" in control:
            # The index's entry: its file at the index's timestamp, its sha256 as the index says.
            url = f"{SNAPSHOT}/archive/debian/{args.index}/{control['Filename']}"
            sha256 = control["SHA256"]
        else:
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
        out.write("Each entry is the package's version in the engine's build sysroot (bullseye's of\n")
        out.write("the index's day for a package the sysroot lacks), its file in snapshot.debian.org's\n")
        out.write("immutable archive, and the file's sha256 (debian_runtime.bzl).\n")
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
