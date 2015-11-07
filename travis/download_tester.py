#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import sys

def download(base_url, out_dir, name):
    url = '%s/%s' % (base_url, name)
    dst = os.path.join(out_dir, name)
    print 'Downloading', url
    subprocess.call([ 'curl', '-o', dst, url ])

def main():
    parser = argparse.ArgumentParser(description='Downloads test artifacts from Google storage')
    parser.add_argument('revision_file')
    parser.add_argument('out_dir')
    args = parser.parse_args()

    out_dir = args.out_dir
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    revision = None
    with open(args.revision_file, 'r') as f:
        revision = f.read()

    base_url = 'https://storage.googleapis.com/mojo/sky/shell/linux-x64/%s' % revision
    download(base_url, out_dir, 'sky_shell')
    download(base_url, out_dir, 'icudtl.dat')
    download(base_url, out_dir, 'sky_snapshot')

    subprocess.call([ 'chmod', 'a+x', os.path.join(out_dir, 'sky_shell' )])
    subprocess.call([ 'chmod', 'a+x', os.path.join(out_dir, 'sky_snapshot' )])

if __name__ == '__main__':
    sys.exit(main())
