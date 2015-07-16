#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import hashlib
import os
import sys

def main():
  """Command line utility to embed file in a C executable."""
  parser = argparse.ArgumentParser(
      description='Generate a source file to embed the content of a file')

  parser.add_argument('source')
  parser.add_argument('out_dir')
  parser.add_argument('namespace')
  parser.add_argument('variable')

  opts = parser.parse_args()

  if not os.path.exists(opts.out_dir):
    os.makedirs(opts.out_dir)

  header = os.path.join(opts.out_dir, '%s.h' % opts.variable)
  c_file = os.path.join(opts.out_dir, '%s.cc' % opts.variable)
  namespaces = opts.namespace.split('::')

  data = None
  with open(opts.source, "rb") as f:
    data = f.read()

  with open(header, "w") as f:
    f.write('// Generated file. Do not modify.\n')
    f.write('\n')
    f.write('#include "mojo/tools/embed/data.h"\n')
    f.write('\n')
    for n in namespaces:
      f.write('namespace %s {\n' % n)
    f.write('extern const mojo::embed::Data %s;\n' % opts.variable);
    for n in reversed(namespaces):
      f.write('}  // namespace %s\n' % n)

  sha1hash = hashlib.sha1(data).hexdigest()
  values = ["0x%02x" % ord(c) for c in data]
  lines = []
  chunk_size = 16
  for i in range(0, len(values), chunk_size):
    lines.append("  " + ", ".join(values[i: i + chunk_size]))

  with open(c_file, "w") as f:
    f.write('// Generated file. Do not modify.\n')
    f.write('\n')
    f.write('#include "mojo/tools/embed/data.h"\n')
    f.write('\n')
    for n in namespaces:
      f.write('namespace %s {\n' % n)
    f.write('namespace {\n')
    f.write("const char data[%d] = {\n" % len(data))
    f.write(",\n".join(lines))
    f.write("\n};\n")
    f.write('}  // namespace\n')
    f.write('\n')
    f.write('extern const mojo::embed::Data %s;\n' % opts.variable);
    f.write('const mojo::embed::Data %s = {\n' % opts.variable);
    f.write('  "%s",\n' % sha1hash)
    f.write('  data,\n')
    f.write('  sizeof(data)\n')
    f.write('};\n');
    f.write('\n')
    for n in reversed(namespaces):
      f.write('}  // namespace %s\n' % n)

if __name__ == '__main__':
  main()
