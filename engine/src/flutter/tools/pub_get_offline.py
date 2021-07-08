# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This python script uses `pub get --offline` to fill in
# .dart_tool/package_config.json files for Dart packages in the tree whose
# dependencies should be entirely resolved without requesting data from pub.dev.
# This allows us to be certain that the Dart code we are pulling for these
# packages is explicitly fetched by `gclient sync` rather than implicitly
# fetched by pub version solving, and pub fetching transitive dependencies.

import json
import os
import subprocess
import sys

ALL_PACKAGES = [
  os.path.join("src", "flutter", "ci"),
  os.path.join("src", "flutter", "flutter_frontend_server"),
  os.path.join("src", "flutter", "testing", "benchmark"),
  os.path.join("src", "flutter", "testing", "dart"),
  os.path.join("src", "flutter", "testing", "litetest"),
  os.path.join("src", "flutter", "testing", "scenario_app"),
  os.path.join("src", "flutter", "testing", "smoke_test_failure"),
  os.path.join("src", "flutter", "testing", "symbols"),
  os.path.join("src", "flutter", "tools", "android_lint"),
  os.path.join("src", "flutter", "tools", "clang_tidy"),
  os.path.join("src", "flutter", "tools", "const_finder"),
  os.path.join("src", "flutter", "tools", "githooks"),
  os.path.join("src", "flutter", "tools", "licenses"),
]


def FetchPackage(pub, package):
  try:
    subprocess.check_output(pub, cwd=package, stderr=subprocess.STDOUT)
  except subprocess.CalledProcessError as err:
    print("'%s' failed in '%s' with status %d:\n%s" %
          (' '.join(pub), package, err.returncode, err.output))
    return 1
  return 0


def CheckPackage(package):
  package_config = os.path.join(package, ".dart_tool", "package_config.json")
  pub_count = 0
  with open(package_config) as f:
    data_dict = json.load(f)
    packages_data = data_dict["packages"]
    for package_data in packages_data:
      package_uri = package_data["rootUri"]
      package_name = package_data["name"]
      if ".pub-cache" in package_uri and "pub.dartlang.org" in package_uri:
        print("Error: package '%s' was fetched from pub" % package_name)
        pub_count = pub_count + 1
  if pub_count > 0:
    print("Error: %d packages were fetched from pub for %s" % (pub_count, package))
    print("Please fix the pubspec.yaml for %s "
          "so that all dependencies are path dependencies" % package)
  return pub_count


def Main():
  leading = os.path.join("src", "third_party", "dart", "tools", "sdks", "dart-sdk", "bin")
  pub = "pub"
  if os.name == "nt":
    pub = "pub.bat"
  pubcmd = [os.path.abspath(os.path.join(leading, pub)), "get", "--offline"]

  pub_count = 0
  for package in ALL_PACKAGES:
    if FetchPackage(pubcmd, package) != 0:
      return 1
    pub_count = pub_count + CheckPackage(package)

  if pub_count > 0:
    return 1

  return 0


if __name__ == '__main__':
  sys.exit(Main())
