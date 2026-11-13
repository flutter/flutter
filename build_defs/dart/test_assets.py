#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Writes the manifests of a test's asset directory (flutter_test_assets, flutter_assets.bzl).

`flutter test` builds the package's asset bundle into build/unit_test_assets
(flutter_tools' commands/test.dart, asset.dart) and hands the directory to
flutter_tester as --flutter-assets-dir. The bundle is these three files, the
package's assets (which the rule places by their keys) and the framework's
compiled shaders (which the rule compiles with impellerc):

- AssetManifest.bin: the asset map in the standard message codec -- each
  asset's key to its variants, `{'asset': <key>}` for the asset itself and
  `{'asset': <key>, 'dpr': <ratio>}` for each resolution variant found in a
  `<ratio>x/` directory beside it (asset.dart's _createAssetManifestBinary);
  an empty map is the type byte 13 and the size 0;
- FontManifest.json: the font families, an empty list (flutter_tester runs
  the tests with --disable-asset-fonts: the bundle's fonts are not loaded);
- NativeAssetsManifest.json: no native assets.

NOTICES.Z (the packages' licenses) is not written.
"""

import argparse
import json
import re
import struct

_EMPTY_NATIVE_ASSETS_MANIFEST = {'format-version': [1, 0, 0], 'native-assets': {}}

# A resolution variant's directory: `2.0x`, `3x` (asset.dart's
# _extractPixelRatioFromKeyRegExp, over the directory name).
_PIXEL_RATIO_DIRECTORY = re.compile(r'^(\d+(\.\d*)?)x$')


class _StandardMessageWriter:
  """The subset of the StandardMessageCodec the asset manifest uses: maps, lists, strings, doubles."""

  def __init__(self):
    self.data = bytearray()

  def _size(self, value):
    if value < 254:
      self.data.append(value)
    elif value <= 0xffff:
      self.data.append(254)
      self.data += struct.pack('<H', value)
    else:
      self.data.append(255)
      self.data += struct.pack('<I', value)

  def write(self, value):
    if isinstance(value, str):
      encoded = value.encode('utf-8')
      self.data.append(7)
      self._size(len(encoded))
      self.data += encoded
    elif isinstance(value, float):
      self.data.append(6)
      # Doubles are aligned to 8 bytes from the start of the message.
      while len(self.data) % 8:
        self.data.append(0)
      self.data += struct.pack('<d', value)
    elif isinstance(value, list):
      self.data.append(12)
      self._size(len(value))
      for item in value:
        self.write(item)
    elif isinstance(value, dict):
      self.data.append(13)
      self._size(len(value))
      for key, item in value.items():
        self.write(key)
        self.write(item)
    else:
      raise TypeError('not written by the asset manifest: %r' % (value,))


def asset_manifest(keys):
  """The asset map of `keys` as flutter_tools builds it: main assets to their variants."""
  present = set(keys)
  variants = {}
  for key in keys:
    directory, _, name = key.rpartition('/')
    parent, _, ratio_directory = directory.rpartition('/')
    match = _PIXEL_RATIO_DIRECTORY.match(ratio_directory)
    if match:
      main = '/'.join(part for part in (parent, name) if part)
      variants.setdefault(main, []).append({'asset': key, 'dpr': float(match.group(1))})
    else:
      variants.setdefault(key, [])
  manifest = {}
  for main in sorted(variants):
    entries = ([{'asset': main}] if main in present else []) + sorted(
        variants[main], key=lambda entry: entry['asset'])
    if entries:
      manifest[main] = entries
  return manifest


def main():
  parser = argparse.ArgumentParser(description=__doc__.split('\n', maxsplit=1)[0])
  parser.add_argument('--asset-manifest', required=True)
  parser.add_argument('--font-manifest', required=True)
  parser.add_argument('--native-assets-manifest', required=True)
  parser.add_argument(
      '--asset', action='append', default=[], help='the key of an asset of the package, in the directory')
  options = parser.parse_args()

  writer = _StandardMessageWriter()
  writer.write(asset_manifest(options.asset))
  with open(options.asset_manifest, 'wb') as f:
    f.write(bytes(writer.data))
  with open(options.font_manifest, 'w', encoding='utf-8') as f:
    f.write('[]')
  with open(options.native_assets_manifest, 'w', encoding='utf-8') as f:
    json.dump(_EMPTY_NATIVE_ASSETS_MANIFEST, f, separators=(',', ':'))


if __name__ == '__main__':
  main()
