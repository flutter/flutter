#!/usr/bin/env python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import ast
import os
import sys

script_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, os.path.join(script_dir, os.pardir, "pylib"))

from mojom.generate.data
import mojom_cpp_generator

def ReadDict(file):
  with open(file, 'r') as f:
    s = f.read()
    dict = ast.literal_eval(s)
    return dict

dict = ReadDict(sys.argv[1])
module = mojom.generate.data.ModuleFromData(dict)
dir = None
if len(sys.argv) > 2:
  dir = sys.argv[2]
cpp = mojom_cpp_generator.Generator(module, ".", dir)
cpp.GenerateFiles([])
