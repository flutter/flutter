#!/usr/bin/env python3
# Copyright 2013 The Chromium Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Install Debian sysroots for building chromium.
"""
# The sysroot is needed to ensure that binaries that get built will run on
# the oldest stable version of Debian that we currently support.
# This script can be run manually but is more often run as part of gclient
# hooks. When run from hooks this script is a no-op on non-linux platforms.
# The sysroot image could be constructed from scratch based on the current state
# of the Debian archive but for consistency we use a pre-built root image (we
# don't want upstream changes to Debian to effect the chromium build until we
# choose to pull them in). The images will normally need to be rebuilt every
# time chrome's build dependencies are changed but should also be updated
# periodically to include upstream security fixes from Debian.
# This script looks at sysroots.json next to it to find the name of a .tar.xz
# to download and the location to extract it to. The extracted sysroot could for
# example be in build/linux/debian_bullseye_amd64-sysroot/.
import glob
import hashlib
import json
import optparse
import os
import shutil
import subprocess
import sys
from urllib.request import urlopen
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.dirname(os.path.dirname(os.path.dirname(SCRIPT_DIR)))
VALID_ARCHS = ("amd64", "i386", "armhf", "arm64", "mipsel", "mips64el",
               "ppc64el", "riscv64")
ARCH_TRANSLATIONS = {
    "x64": "amd64",
    "x86": "i386",
    "arm": "armhf",
    "mips": "mipsel",
    "mips64": "mips64el",
    "ppc64le": "ppc64el",
}
DEFAULT_TARGET_PLATFORMS = {
    "amd64": "bullseye",
    "i386": "bullseye",
    "armhf": "bullseye",
    "arm64": "bullseye",
    "mipsel": "bullseye",
    "mips64el": "bullseye",
    "ppc64el": "bullseye",
    "riscv64": "trixie",
}
DEFAULT_SYSROOTS_PATH = os.path.join(os.path.relpath(SCRIPT_DIR, SRC_DIR),
                                     "sysroots.json")
class Error(Exception):
    pass
def GetSha256(filename):
    sha1 = hashlib.sha256()
    with open(filename, "rb") as f:
        while True:
            # Read in 1mb chunks, so it doesn't all have to be loaded into
            # memory.
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            sha1.update(chunk)
    return sha1.hexdigest()
def main(args):
    parser = optparse.OptionParser("usage: %prog [OPTIONS]",
                                   description=__doc__)
    parser.add_option("--sysroots-json-path",
                      help="The location of sysroots.json file")
    parser.add_option("--arch",
                      help="Sysroot architecture: %s" % ", ".join(VALID_ARCHS))
    parser.add_option(
        "--all",
        action="store_true",
        help="Install all sysroot images (useful when updating the"
        " images)",
    )
    options, _ = parser.parse_args(args)
    if options.sysroots_json_path:
        sysroots_json_path = options.sysroots_json_path
    else:
        sysroots_json_path = DEFAULT_SYSROOTS_PATH
    if options.arch:
        arch = ARCH_TRANSLATIONS.get(options.arch, options.arch)
        InstallSysroot(sysroots_json_path, DEFAULT_TARGET_PLATFORMS[arch],
                       arch)
    elif options.all:
        for arch in VALID_ARCHS:
            InstallSysroot(sysroots_json_path, DEFAULT_TARGET_PLATFORMS[arch],
                           arch)
    else:
        print("You much specify one of the options.")
        return 1
    return 0
def GetSysrootDict(sysroots_json_path, target_platform, target_arch):
    if target_arch not in VALID_ARCHS:
        raise Error("Unknown architecture: %s" % target_arch)
    sysroots_file = os.path.join(SRC_DIR, sysroots_json_path)
    sysroots = json.load(open(sysroots_file))
    sysroot_key = "%s_%s" % (target_platform, target_arch)
    if sysroot_key not in sysroots:
        raise Error("No sysroot for: %s %s" % (target_platform, target_arch))
    return sysroots[sysroot_key]
def InstallSysroot(sysroots_json_path, target_platform, target_arch):
    sysroot_dict = GetSysrootDict(sysroots_json_path, target_platform,
                                  target_arch)
    tarball_filename = sysroot_dict["Tarball"]
    tarball_sha256sum = sysroot_dict["Sha256Sum"]
    url_prefix = sysroot_dict["URL"]
    # TODO(thestig) Consider putting this elsewhere to avoid having to recreate
    # it on every build.
    linux_dir = os.path.dirname(SCRIPT_DIR)
    sysroot = os.path.join(linux_dir, sysroot_dict["SysrootDir"])
    url = "%s/%s" % (url_prefix, tarball_sha256sum)
    stamp = os.path.join(sysroot, ".stamp")
    # This file is created by first class GCS deps. If this file exists,
    # clear the entire directory and download with this script instead
    if os.path.exists(stamp) and not glob.glob(
            os.path.join(sysroot, ".*_is_first_class_gcs")):
        with open(stamp) as s:
            if s.read() == url:
                return
    print("Installing Debian %s %s root image: %s" %
          (target_platform, target_arch, sysroot))
    if os.path.isdir(sysroot):
        shutil.rmtree(sysroot)
    os.mkdir(sysroot)
    tarball = os.path.join(sysroot, tarball_filename)
    print("Downloading %s" % url)
    sys.stdout.flush()
    sys.stderr.flush()
    for _ in range(3):
        try:
            response = urlopen(url)
            with open(tarball, "wb") as f:
                f.write(response.read())
            break
        except Exception:  # Ignore exceptions.
            pass
    else:
        raise Error("Failed to download %s" % url)
    sha256sum = GetSha256(tarball)
    if sha256sum != tarball_sha256sum:
        raise Error("Tarball sha256sum is wrong."
                    "Expected %s, actual: %s" % (tarball_sha256sum, sha256sum))
    subprocess.check_call(["tar", "mxf", tarball, "-C", sysroot])
    os.remove(tarball)
    with open(stamp, "w") as s:
        s.write(url)
if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Error as e:
        sys.stderr.write(str(e) + "\n")
        sys.exit(1)
