#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script returns the flags that should be passed to clang.

import os
import sys

THIS_DIR = os.path.abspath(os.path.dirname(__file__))
SRC_DIR = os.path.join(THIS_DIR, '..', '..', '..')
CLANG_LIB_PATH = os.path.normpath(os.path.join(
    SRC_DIR, 'third_party', 'llvm-build', 'Release+Asserts', 'lib'))

FLAGS = '-Xclang -add-plugin -Xclang blink-gc-plugin'
PREFIX= ' -Xclang -plugin-arg-blink-gc-plugin -Xclang '
for arg in sys.argv[1:]:
  if arg == 'enable-oilpan=1':
    FLAGS += PREFIX + 'enable-oilpan'
  elif arg == 'dump-graph=1':
    FLAGS += PREFIX + 'dump-graph'
  elif arg == 'warn-raw-ptr=1':
    FLAGS += PREFIX + 'warn-raw-ptr'
  elif arg == 'warn-unneeded-finalizer=1':
    FLAGS += PREFIX + 'warn-unneeded-finalizer'
  elif arg.startswith('custom_clang_lib_path='):
    CLANG_LIB_PATH = arg[len('custom_clang_lib_path='):]

if not sys.platform in ['win32', 'cygwin']:
  LIBSUFFIX = 'dylib' if sys.platform == 'darwin' else 'so'
  FLAGS = ('-Xclang -load -Xclang "%s/libBlinkGCPlugin.%s" ' + FLAGS) % \
           (CLANG_LIB_PATH, LIBSUFFIX)

print FLAGS
