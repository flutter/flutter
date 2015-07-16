#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import json
import os
import subprocess
import sys
import urllib2
from utils import commit
from utils import mojo_root_dir
from utils import system

import patch

# //base and its dependencies
base_deps = [
    "base",
    "testing",
    "third_party/ashmem",
    "third_party/libevent",
    "third_party/libxml", # via //base/test
    "third_party/modp_b64",
    "third_party/tcmalloc",
]

# //build and its dependencies
build_deps = [
    "build",
    "third_party/android_testrunner",
    "third_party/binutils",
    "third_party/pymock",
    "tools/android",
    "tools/clang",
    "tools/generate_library_loader",
    "tools/gritsettings",
    "tools/relocation_packer",
    "tools/valgrind",
]

# //sandbox/linux and its dependencies
sandbox_deps = [
    "sandbox/linux",
]

# things used from //mojo/public
mojo_sdk_deps = [
    "third_party/cython",
]

# These directories are snapshotted from chromium without modifications.
dirs_to_snapshot = base_deps + build_deps + sandbox_deps + mojo_sdk_deps

files_to_copy = [ "sandbox/sandbox_export.h" ]

# The contents of these files before the roll will be preserved after the roll,
# even though they live in directories rolled in from Chromium.
files_not_to_roll = [
    "build/config/ui.gni",
    "build/ls.py",
    "build/module_args/mojo.gni",
]

dirs = dirs_to_snapshot

def chromium_rev_number(src_commit):
  base_url = "https://cr-rev.appspot.com/_ah/api/crrev/v1/commit/"
  commit_info = json.load(urllib2.urlopen(base_url + src_commit))
  return commit_info["numberings"][0]["number"]

def rev(source_dir):
  for d in dirs:
    print "removing directory %s" % d
    try:
      system(["git", "rm", "-r", d], cwd=mojo_root_dir)
    except subprocess.CalledProcessError:
      print "Could not remove %s" % d
    print "cloning directory %s" % d
    files = system(["git", "ls-files", d], cwd=source_dir)
    for f in files.splitlines():
      dest_path = os.path.join(mojo_root_dir, f)
      system(["mkdir", "-p", os.path.dirname(dest_path)], cwd=source_dir)
      system(["cp", os.path.join(source_dir, f), dest_path], cwd=source_dir)
    system(["git", "add", d], cwd=mojo_root_dir)

  for f in files_to_copy:
    system(["cp", os.path.join(source_dir, f), os.path.join(mojo_root_dir, f)])

  system(["git", "add", "."], cwd=mojo_root_dir)
  src_commit = system(["git", "rev-parse", "HEAD"], cwd=source_dir).strip()
  src_rev = chromium_rev_number(src_commit)
  commit("Update from https://crrev.com/" + src_rev, cwd=mojo_root_dir)

def main():
  parser = argparse.ArgumentParser(description="Update the mojo repo's " +
      "snapshot of things imported from chromium.")
  parser.add_argument("chromium_dir", help="chromium source dir")
  args = parser.parse_args()
  pre_roll_commit = system(
      ["git", "rev-parse", "HEAD"], cwd=mojo_root_dir).strip()

  rev(args.chromium_dir)

  try:
    patch.patch_and_filter()
  except subprocess.CalledProcessError:
    print "ERROR: Roll failed due to a patch not applying"
    print "Fix the patch to apply, commit the result, and re-run this script"
    return 1

  print "Restoring files whose contents don't track Chromium"
  for f in files_not_to_roll:
    system(["git", "checkout", pre_roll_commit, "--", f], cwd=mojo_root_dir)
  if files_not_to_roll:
    commit("Restored pre-roll versions of files that don't get rolled")
  return 0

if __name__ == "__main__":
  sys.exit(main())
