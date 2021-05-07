#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import shutil
import subprocess
import sys

from xml.dom import minidom

# The SDK version downloaded from CIPD.
# TODO(cbracken): pass this as an argument to this script.
SDK_VERSION = '10.0.19041.0'
SDK_PATH = r'third_party\windows_sdk\Windows Kits\10'

def clean(output_dir):
  if os.path.exists(output_dir):
        shutil.rmtree(output_dir, ignore_errors=True)
  return


def to_abs_path(relative_path):
  """Returns a canonical path for the specified path relative to the script
  directory.
  """

  script_dir = os.path.dirname(os.path.realpath(__file__))
  return os.path.realpath(os.path.join(script_dir, relative_path))


def get_inputs(sdk_path, sdk_version):
  """Parses the SDK's Platform.xml file and generates the set of .winmd files
  to pass as input to cppwinrt.
  """

  platform_xml = r'%s\Platforms\UAP\%s\Platform.xml' % (sdk_path, sdk_version)
  reference_dir = r'%s\References\%s' % (sdk_path, sdk_version)

  inputs = []
  doc = minidom.parse(platform_xml)
  for contract in doc.getElementsByTagName('ApiContract'):
    name = contract.getAttribute('name')
    version = contract.getAttribute('version')
    winmd_path = os.path.join(reference_dir, name, version, '%s.winmd' % name)
    inputs.append(winmd_path)
  return inputs


def generate_headers(input_files, output_dir):
  """Run cppwinrt.exe on the installed Windows SDK version and generate
  cppwinrt headers in the output directory.
  """

  args = [to_abs_path(r'..\..\third_party\cppwinrt\bin\cppwinrt.exe')]
  for winmd_path in input_files:
    args += ['-in', winmd_path]
  args += ['-out', output_dir]
  subprocess.check_output(args)
  return 0


def main(argv):
  generated_dir = to_abs_path(r'..\..\third_party\cppwinrt\generated')
  clean(generated_dir)

  abs_sdk_path = to_abs_path(r'..\..\%s' % SDK_PATH)
  input_files = get_inputs(abs_sdk_path, SDK_VERSION)
  return generate_headers(input_files, generated_dir)


if __name__ == "__main__":
  sys.exit(main(sys.argv[1:]))
