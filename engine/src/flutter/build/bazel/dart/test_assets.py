#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Writes the manifests of a test's asset directory (flutter_test_assets, flutter_assets.bzl).

`flutter test` builds the package's asset bundle into build/unit_test_assets
(flutter_tools' commands/test.dart, asset.dart) and hands the directory to
flutter_tester as --flutter-assets-dir. For a package that declares no
assets or fonts -- packages/flutter -- the bundle is these three files and
the framework's compiled shaders (which the rule compiles with impellerc):

- AssetManifest.bin: the asset map in the standard message codec (an empty
  map is the type byte 13 and the size 0);
- FontManifest.json: the font families, an empty list;
- NativeAssetsManifest.json: no native assets.

Assets, fonts and NOTICES.Z (the packages' licenses) are the next step.
"""

import argparse
import json

# StandardMessageCodec: a map is type 13, then its size, then its entries.
_EMPTY_ASSET_MANIFEST = bytes([13, 0])

_EMPTY_NATIVE_ASSETS_MANIFEST = {'format-version': [1, 0, 0], 'native-assets': {}}


def main():
  parser = argparse.ArgumentParser(description=__doc__.split('\n', maxsplit=1)[0])
  parser.add_argument('--asset-manifest', required=True)
  parser.add_argument('--font-manifest', required=True)
  parser.add_argument('--native-assets-manifest', required=True)
  options = parser.parse_args()

  with open(options.asset_manifest, 'wb') as f:
    f.write(_EMPTY_ASSET_MANIFEST)
  with open(options.font_manifest, 'w', encoding='utf-8') as f:
    f.write('[]')
  with open(options.native_assets_manifest, 'w', encoding='utf-8') as f:
    json.dump(_EMPTY_NATIVE_ASSETS_MANIFEST, f, separators=(',', ':'))


if __name__ == '__main__':
  main()
