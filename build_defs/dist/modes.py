#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""The mode a file of the build ships with (zip_bundle.py, universal.py, install.bzl).

GN's archives and build directories carry each file's own mode: build/zip.py
stores what it finds, 0755 for what a linker wrote and for the scripts that
are executable in the source tree, 0644 for the rest. A Bazel build's files
have less of a mode of their own:

  * every output of an action is 0555 once the action is over, a licence
    and a library alike, and never writable;
  * a file of a repository Bazel fetched from CIPD has the mode the
    package's zip stores, 0600 or 0700: the owner's alone.

Archived as they are, the first leaves an SDK's data files executable and
read-only, and the second leaves a Dart SDK that no user but the one who
unpacked it can read.

shipped_mode() is the mode such a file ships with: 0755 or 0644, as in GN's
archives. A file with no execute bit is 0644. A file that is executable and
writable has a mode of its own -- a source file, or one a script laid out --
and its execute bit is kept (GN's archives keep it too: the fonts and icons
that are executable in the Dart SDK). A file that is executable and not
writable is an action's output, whose mode says nothing: it is 0755 if it is
a program, 0644 if not.

Run as a script, it gives the files an install laid out those modes:

    modes.py <directory> < <paths under it, one per line>

Each path is a file or a directory (walked); a directory becomes 0755.
"""

import os
import stat
import sys

# Mach-O's magic numbers, as the file has them (32- and 64-bit, either byte
# order), and the universal binary's (always big-endian; the second with
# 64-bit offsets).
_MACH_O_BIG = (b'\xfe\xed\xfa\xce', b'\xfe\xed\xfa\xcf')
_MACH_O_LITTLE = (b'\xce\xfa\xed\xfe', b'\xcf\xfa\xed\xfe')
_UNIVERSAL = b'\xca\xfe\xba\xbe'
_UNIVERSAL_64 = b'\xca\xfe\xba\xbf'

# What of an ELF or Mach-O file is a program: an executable, a shared
# library, a bundle -- not an object file, a core or a dSYM's DWARF file.
_ELF_TYPES = (2, 3)  # ET_EXEC, ET_DYN
_MACH_O_TYPES = (2, 6, 8)  # MH_EXECUTE, MH_DYLIB, MH_BUNDLE


def _is_mach_o_program(head):
  """Whether a Mach-O header (its first 16 bytes) is a program's."""
  magic = head[:4]
  if magic not in _MACH_O_BIG + _MACH_O_LITTLE or len(head) < 16:
    return False
  # filetype is the header's fourth word, in the header's byte order.
  order = 'little' if magic in _MACH_O_LITTLE else 'big'
  return int.from_bytes(head[12:16], order) in _MACH_O_TYPES


def is_program(path):
  """Whether the file is what a system runs or loads.

  An ELF or Mach-O executable or shared library, a universal binary of
  such, a Windows image, a WebAssembly module (the linker's output, 0755 in
  GN's archives like any other), or a script with a `#!` line.
  """
  with open(path, 'rb') as file:
    head = file.read(40)
    if head[:2] in (b'#!', b'MZ'):
      return True
    magic = head[:4]
    if magic == b'\x00asm':
      return True
    if magic == b'\x7fELF' and len(head) >= 18:
      # e_type follows the 16 bytes of e_ident, in the byte order e_ident[5]
      # names (1: little-endian).
      return int.from_bytes(head[16:18], 'little' if head[5] == 1 else 'big') in _ELF_TYPES
    if magic in (_UNIVERSAL, _UNIVERSAL_64) and len(head) >= 8:
      # The number of architectures follows. A Java class file starts with
      # the same four bytes, and has its version there: 45 at the least.
      if not 0 < int.from_bytes(head[4:8], 'big') < 20:
        return False
      # A universal file is what its architectures are (the DWARF file of a
      # universal binary's dSYM is universal too, and no program): the first
      # one's header says. Its offset is the third word of the first
      # architecture's entry, two words wide in the 64-bit format.
      width = 8 if magic == _UNIVERSAL_64 else 4
      if len(head) < 16 + width:
        return False
      file.seek(int.from_bytes(head[16:16 + width], 'big'))
      return _is_mach_o_program(file.read(16))
    return _is_mach_o_program(head)


def shipped_mode(path):
  """The mode the file ships with: 0o755 or 0o644 (see the module's docstring)."""
  mode = stat.S_IMODE(os.stat(path).st_mode)
  if not mode & 0o111:
    return 0o644
  if mode & 0o222:
    return 0o755
  return 0o755 if is_program(path) else 0o644


def set_shipped_modes(root, paths):
  """Gives each file at or under `paths` (relative to `root`) its shipped mode; directories 0755.

  Symlinks are left alone. A directory's own mode is set before its files
  are read, so a read-only tree is handled from the top.
  """
  for path in paths:
    full = os.path.join(root, path)
    if os.path.islink(full):
      continue
    if not os.path.isdir(full):
      os.chmod(full, shipped_mode(full))
      continue
    for directory, _, files in os.walk(full):
      os.chmod(directory, 0o755)
      for name in files:
        file = os.path.join(directory, name)
        if not os.path.islink(file):
          os.chmod(file, shipped_mode(file))


if __name__ == '__main__':
  if len(sys.argv) != 2:
    sys.exit('usage: modes.py <directory> < <paths under it, one per line>')
  set_shipped_modes(sys.argv[1], [line.rstrip('\n') for line in sys.stdin if line.strip()])
