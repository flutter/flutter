#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import shutil

def remove_empty_dirs(root_dir):
    for root, dirs, _ in os.walk(root_dir):
         for name in dirs:
             fname = os.path.join(root, name)
             if not os.listdir(fname):
                 os.removedirs(fname)

def main():
    parser = argparse.ArgumentParser(
        description='Clean Sky package for distribution')
    parser.add_argument('package_dir', type=str)
    parser.add_argument('--touch', type=str)
    args = parser.parse_args()

    remove_empty_dirs(args.package_dir)

    material_design_icons = os.path.join(args.package_dir, 'lib/assets/material-design-icons')
    if os.path.exists(material_design_icons):
        shutil.rmtree(material_design_icons)

    with open(args.touch, 'w') as f:
        pass


if __name__ == '__main__':
    main()
