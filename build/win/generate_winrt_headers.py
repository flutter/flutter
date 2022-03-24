#!/usr/bin/env python3
#
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
  """Cleans and creates the specified directory."""

  if os.path.exists(output_dir):
        shutil.rmtree(output_dir, ignore_errors=True)
  os.mkdir(output_dir)
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


def write_options_file(options_path, input_files, output_dir):
  """Writes a cppwinrt options file to the specified path. This encodes
  cppwinrt's command-line options into a file to be parsed, rather than passing
  a long command-line.
  """

  outfile = open(options_path, 'w')
  for input_file in input_files:
    outfile.write('-in "%s"\n' % input_file)
  outfile.write('-out "%s"\n' % output_dir)
  outfile.write('-verbose\n')
  outfile.close()


def generate_headers(options_file):
  """Run cppwinrt.exe with the specified options file to generate WinRT headers
  in the output directory. Logs stderr to the console.
  """

  args = [
      to_abs_path(r'..\..\third_party\cppwinrt\bin\cppwinrt.exe'),
      '@%s' % options_file
  ]
  process = subprocess.Popen(args, stderr=subprocess.PIPE)
  out, err = process.communicate()
  print(err)

  # On failure, emit the options file contents. On success, cppwinrt does so
  # itself.
  if process.returncode != 0:
    print('cppwinrt header generation failed. Options file was:')
    infile = open(options_file, 'r')
    print((infile.read()))
    infile.close()
  return process.returncode


def main(argv):
  generated_dir = to_abs_path(r'..\..\third_party\cppwinrt\generated')
  clean(generated_dir)

  abs_sdk_path = to_abs_path(r'..\..\%s' % SDK_PATH)
  input_files = get_inputs(abs_sdk_path, SDK_VERSION)
  options_file = r'%s\cppwinrt_options.txt' % generated_dir
  write_options_file(options_file, input_files, generated_dir)
  return generate_headers(options_file)


if __name__ == "__main__":
  sys.exit(main(sys.argv[1:]))
