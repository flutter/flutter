#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import subprocess
import sys
import yaml
import zipfile
import os
import argparse
import copy

SNAPSHOT_KEY = 'snapshot_blob.bin'
DENSITIES = ['drawable-xxhdpi']
THEMES = ['white', 'black', 'grey600']
SIZES = [24]

class MaterialAsset(object):
    def __init__(self, descriptor):
        self.name = descriptor['name']
        self.size = descriptor['size']
        self.theme = descriptor['theme']
        self.density = descriptor['density']

    @property
    def key(self):
        category, subtype = self.name.split('/', 1)
        return os.path.join(category, self.density, 'ic_%(subtype)s_%(theme)s_%(size)sdp.png' % {
            'subtype': subtype, 'theme': self.theme, 'size': self.size,
        })

def generate_values(asset_descriptor, key, default):
    if key in asset_descriptor:
        return [asset_descriptor[key]]
    return default

def generate_material_assets(asset_descriptor):
    current_asset_descriptor = copy.deepcopy(asset_descriptor)
    for density in generate_values(asset_descriptor, 'density', DENSITIES):
        current_asset_descriptor['density'] = density
        for theme in generate_values(asset_descriptor, 'theme', THEMES):
            current_asset_descriptor['theme'] = theme
            for size in generate_values(asset_descriptor, 'size', SIZES):
                current_asset_descriptor['size'] = size
                yield MaterialAsset(current_asset_descriptor)

def load_manifest(manifest):
    with open(manifest) as manifest_file:
        return yaml.load(manifest_file)

def parse_material_assets(manifest_descriptor):
    for asset_descriptor in manifest_descriptor['material-design-icons']:
        for asset in generate_material_assets(asset_descriptor):
            yield asset

def main():
    parser = argparse.ArgumentParser(description='Taco')
    parser.add_argument('manifest', type=str)
    parser.add_argument('--asset-base', type=str)
    parser.add_argument('--snapshot', type=str)
    parser.add_argument('-o', '--output-file', type=str)
    args = parser.parse_args()

    manifest_descriptor = load_manifest(args.manifest)
    material_assets = list(parse_material_assets( manifest_descriptor))

    with zipfile.ZipFile(args.output_file, 'w', zipfile.ZIP_DEFLATED) as archive:
        if args.snapshot is not None:
            archive.write(args.snapshot, SNAPSHOT_KEY)
        for asset in material_assets:
            archive.write(os.path.join(args.asset_base, asset.key), asset.key, zipfile.ZIP_STORED)

if __name__ == '__main__':
    sys.exit(main())
