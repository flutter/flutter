#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
This script invokes the go build tool.
Must be called as follows:
python go.py [--android] <go-tool> <build directory> <output file>
<src directory> <CGO_CFLAGS> <CGO_LDFLAGS> <go-binary options>
eg.
python go.py /usr/lib/google-golang/bin/go out/build out/a.out .. "-I."
"-L. -ltest" test -c test/test.go
"""

import argparse
import os
import shutil
import subprocess
import sys

NDK_PLATFORM = 'android-16'
NDK_TOOLCHAIN = 'arm-linux-androideabi-4.9'

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--android', action='store_true')
  parser.add_argument('go_tool')
  parser.add_argument('build_directory')
  parser.add_argument('output_file')
  parser.add_argument('src_root')
  parser.add_argument('out_root')
  parser.add_argument('cgo_cflags')
  parser.add_argument('cgo_ldflags')
  parser.add_argument('go_option', nargs='*')
  args = parser.parse_args()
  go_tool = os.path.abspath(args.go_tool)
  build_dir = args.build_directory
  out_file = os.path.abspath(args.output_file)
  # The src directory specified is relative. We need this as an absolute path.
  src_root = os.path.abspath(args.src_root)
  # GOPATH must be absolute, and point to one directory up from |src_Root|
  go_path = os.path.abspath(os.path.join(src_root, '..'))
  # GOPATH also includes any third_party/go libraries that have been imported
  go_path += ':' +  os.path.join(src_root, 'third_party', 'go')
  go_path += ':' +  os.path.abspath(os.path.join(args.out_root, 'gen', 'go'))
  if 'MOJO_GOPATH' in os.environ:
    go_path += ':' + os.environ['MOJO_GOPATH']
  go_options = args.go_option
  try:
    shutil.rmtree(build_dir, True)
    os.mkdir(build_dir)
  except Exception:
    pass
  old_directory = os.getcwd()
  os.chdir(build_dir)
  env = os.environ.copy()
  env['GOPATH'] = go_path
  env['GOROOT'] = os.path.dirname(os.path.dirname(go_tool))
  env['CGO_CFLAGS'] = args.cgo_cflags
  env['CGO_LDFLAGS'] = args.cgo_ldflags
  if args.android:
    env['CGO_ENABLED'] = '1'
    env['GOOS'] = 'android'
    env['GOARCH'] = 'arm'
    env['GOARM'] = '7'
    # The Android go tool prebuilt binary has a default path to the compiler,
    # which with high probability points to an invalid path, so we override the
    # CC env var that will be used by the go tool.
    if 'CC' not in env:
      ndk_path = os.path.join(src_root, 'third_party', 'android_tools', 'ndk')
      if sys.platform.startswith('linux'):
        arch = 'linux-x86_64'
      elif sys.platform == 'darwin':
        arch = 'darwin-x86_64'
      else:
        raise Exception('unsupported platform: ' + sys.platform)
      ndk_cc = os.path.join(ndk_path, 'toolchains', NDK_TOOLCHAIN,
          'prebuilt', arch, 'bin', 'arm-linux-androideabi-gcc')
      sysroot = os.path.join(ndk_path, 'platforms', NDK_PLATFORM, 'arch-arm')
      env['CC'] = '%s --sysroot %s' % (ndk_cc, sysroot)

  call_result = subprocess.call([go_tool] + go_options, env=env)
  if call_result != 0:
    return call_result
  out_files = sorted([ f for f in os.listdir('.') if os.path.isfile(f)])
  if (len(out_files) > 0):
    shutil.move(out_files[0], out_file)
  os.chdir(old_directory)
  try:
    shutil.rmtree(build_dir, True)
  except Exception:
    pass

if __name__ == '__main__':
  sys.exit(main())
