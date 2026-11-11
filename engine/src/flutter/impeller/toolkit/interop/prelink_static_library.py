#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Prelinks the Impeller static library into a single object that only exports
the Impeller C API.

libimpeller.a bundles Skia, HarfBuzz, ICU, libc++ and more. Hidden visibility
does not stop those symbols from colliding with other copies of the same
libraries when an application links the archive statically, because hidden
symbols in an object file still have global binding. This script does a
relocatable link of every archive member into one object and then makes every
symbol that is not declared with IMPELLER_EXPORT in impeller.h local.

  * Mach-O: `ld -r -exported_symbols_list` turns the other symbols into
    non-external (static) symbols. ld64.lld does not support -r, so this uses
    the ld64 from the Xcode toolchain. That linker cannot read the bitcode of
    the engine's clang, so if the archive holds bitcode, a throwaway ld64.lld
    link with -object_path_lto first produces native LTO objects.
  * ELF: `ld.lld -r`, then `llvm-objcopy --keep-global-symbols` makes the other
    symbols local, and `--remove-section=.group` drops the COMDAT groups. If the
    groups were kept, the linker of the application could discard COMDATs of
    the same name (template instantiations) in other objects in favor of the
    now-local copies in this object.

  * COFF: there is no relocatable link, so `llvm-objcopy --redefine-syms`
    instead prefixes every other symbol that the archive defines with
    COFF_PREFIX.

If the archive holds LLVM bitcode (enable_lto), LTO runs as part of the
prelink.

The result is checked: the defined global symbols of the object must be
exactly the Impeller C API (plus prefixed symbols for COFF).
"""

import argparse
import os
import re
import shutil
import subprocess
import sys


def impeller_exports(header):
  with open(header, encoding='utf-8') as f:
    text = f.read()
  # Declarations look like:
  #   IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerFoo IMPELLER_NULLABLE
  #   ImpellerFooNew(...);
  names = []
  for match in re.finditer(r'^IMPELLER_EXPORT\b(.*?)\(', text, re.MULTILINE | re.DOTALL):
    identifiers = re.findall(r'[A-Za-z_]\w*', match.group(1))
    names.append(identifiers[-1])
  if not names:
    raise SystemExit('No IMPELLER_EXPORT declarations found in %s' % header)
  duplicates = sorted({n for n in names if names.count(n) > 1})
  if duplicates:
    raise SystemExit('Duplicate exports in %s: %s' % (header, ', '.join(duplicates)))
  return names


def tool(args, name):
  return os.path.join(args.clang_bin, name + ('.exe' if sys.platform == 'win32' else ''))


def run(args):
  result = subprocess.run(
      args,
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE,
      encoding='utf-8',
      errors='surrogateescape',
  )
  if result.returncode != 0:
    sys.stderr.write('Command failed: %s\n%s%s' % (' '.join(args), result.stdout, result.stderr))
    raise SystemExit(result.returncode)
  return result.stdout


def write_lines(path, lines):
  with open(path, 'w', encoding='utf-8', errors='surrogateescape', newline='\n') as f:
    f.write(''.join(line + '\n' for line in lines))


BITCODE_MAGICS = (b'BC\xc0\xde', b'\xde\xc0\x17\x0b')


def archive_members(path):
  """Yields (name, contents) for each member of a BSD or GNU archive."""
  with open(path, 'rb') as f:
    data = f.read()
  if data[:8] != b'!<arch>\n':
    raise SystemExit('%s is not an archive' % path)
  gnu_names = b''
  pos = 8
  while pos < len(data):
    header = data[pos:pos + 60]
    name = header[:16].decode().rstrip()
    size = int(header[48:58])
    pos += 60
    body = data[pos:pos + size]
    pos += size + (size & 1)
    if name.startswith('#1/'):
      length = int(name[3:])
      name = body[:length].rstrip(b'\0').decode()
      body = body[length:]
    elif name == '//':
      gnu_names = body
      continue
    elif name.startswith('/') and name[1:].isdigit():
      offset = int(name[1:])
      name = gnu_names[offset:gnu_names.index(b'/\n', offset)].decode()
    elif name.endswith('/'):
      name = name[:-1]
    if name in ('', '/', '/SYM64') or name.startswith('__.SYMDEF'):
      continue
    yield name, body


def prelink_macho(args, exports, work_dir, merged):
  if not args.ld:
    raise SystemExit('--ld is required for Mach-O')
  exports_list = os.path.join(work_dir, 'exports.macho.txt')
  write_lines(exports_list, ['_' + e for e in exports])

  native_dir = os.path.join(work_dir, 'native')
  os.makedirs(native_dir, exist_ok=True)
  for stale in os.listdir(native_dir):
    os.remove(os.path.join(native_dir, stale))
  natives = []
  has_bitcode = False
  for index, (name, body) in enumerate(archive_members(args.input)):
    if body[:4] in BITCODE_MAGICS:
      has_bitcode = True
      continue
    path = os.path.join(native_dir, '%05d_%s' % (index, os.path.basename(name)))
    with open(path, 'wb') as f:
      f.write(body)
    natives.append(path)

  inputs = natives
  if has_bitcode:
    # Run LTO the same way the shared library link does, and keep its object.
    # Symbols that native members reference stay defined in it.
    lto_dir = os.path.join(work_dir, 'lto')
    if os.path.isdir(lto_dir):
      shutil.rmtree(lto_dir)
    os.makedirs(lto_dir)
    command = [
        tool(args, 'clang++'),
        '-arch',
        args.arch,
        '-fuse-ld=lld',
        '-dynamiclib',
        '-nostdlib',
        '-Wl,-all_load',
        '-Wl,-exported_symbols_list,' + exports_list,
        '-Wl,-undefined,dynamic_lookup',
        '-Wl,-object_path_lto,' + lto_dir,
        args.input,
        '-o',
        os.path.join(work_dir, 'throwaway.dylib'),
    ]
    if args.sysroot:
      command[1:1] = ['-isysroot', args.sysroot]
    run(command)
    lto_objects = sorted(os.path.join(lto_dir, f) for f in os.listdir(lto_dir))
    if not lto_objects:
      raise SystemExit('LTO produced no objects in %s' % lto_dir)
    inputs = lto_objects + natives
  elif not natives:
    raise SystemExit('%s has no members' % args.input)

  run([
      args.ld,
      '-r',
      '-arch',
      args.arch,
      '-exported_symbols_list',
      exports_list,
      '-o',
      merged,
  ] + inputs)
  return ['_' + e for e in exports]


def prelink_elf(args, exports, work_dir, merged):
  exports_list = os.path.join(work_dir, 'exports.txt')
  write_lines(exports_list, exports)
  relocatable = os.path.join(work_dir, 'relocatable.o')
  run([
      tool(args, 'ld.lld'),
      '-r',
      '--whole-archive',
      args.input,
      '-o',
      relocatable,
  ])
  run([
      tool(args, 'llvm-objcopy'),
      '--keep-global-symbols=' + exports_list,
      '--remove-section=.group',
      relocatable,
      merged,
  ])
  return exports


COFF_PREFIX = 'impeller_internal.'


def coff_external_symbols(args, archive):
  """Returns ({defined external symbols}, {undefined symbols}) of a COFF archive."""
  output = run([tool(args, 'llvm-nm'), '--extern-only', '--format=posix', '--no-sort', archive])
  defined = set()
  undefined = set()
  for line in output.splitlines():
    # Skip member headers ("impeller.lib[foo.obj]:").
    if not line or line.endswith(']:'):
      continue
    fields = line.split(' ')
    if len(fields) < 2:
      continue
    name, kind = fields[0], fields[1]
    if kind == 'U':
      undefined.add(name)
    else:
      defined.add(name)
  return defined, undefined


# Linker directives that name a symbol.
COFF_SYMBOL_DIRECTIVES = re.compile(
    r'[/-](alternatename:([^\s=]+)=(\S+)|include:(\S+)|export:([^\s,=]+))', re.IGNORECASE
)


def coff_directive_symbols(args, archive):
  """Returns ({symbols named by /INCLUDE}, {symbols named by other directives})."""
  output = run([tool(args, 'llvm-readobj'), '--coff-directives', archive])
  included = set()
  others = set()
  for match in COFF_SYMBOL_DIRECTIVES.finditer(output):
    alternate, target, include, export = (n.strip('"') if n else n for n in match.groups()[1:])
    if include:
      included.add(include)
    others.update(n for n in (alternate, target, export) if n)
  return included, others


def prelink_coff(args, exports, work_dir):
  defined, _ = coff_external_symbols(args, args.input)
  missing = sorted(set(exports) - defined)
  if missing:
    raise SystemExit('%s does not define: %s' % (args.input, ', '.join(missing[:50])))

  # .drectve sections are not rewritten. Symbols that the MSVC STL headers
  # /INCLUDE (e.g. std::locale facet ids) must stay shared with the CRT anyway.
  included, directive_symbols = coff_directive_symbols(args, args.input)
  renamed = sorted(defined - set(exports) - included)
  # --redefine-syms files are whitespace separated, and '#' starts a comment.
  unrenameable = [n for n in renamed if '#' in n]
  if unrenameable:
    raise SystemExit('Cannot rename: %s' % ', '.join(unrenameable[:50]))
  stale = sorted(directive_symbols & set(renamed))
  if stale:
    raise SystemExit(
        'Linker directives in %s name internal symbols: %s' % (args.input, ', '.join(stale[:50]))
    )

  renames = []
  for name in renamed:
    renames.append('%s %s%s' % (name, COFF_PREFIX, name))
    renames.append('__imp_%s __imp_%s%s' % (name, COFF_PREFIX, name))
  renames_file = os.path.join(work_dir, 'renames.coff.txt')
  write_lines(renames_file, renames)

  renamed_archive = os.path.join(work_dir, 'impeller_renamed.lib')
  if os.path.exists(renamed_archive):
    os.remove(renamed_archive)
  run([
      tool(args, 'llvm-objcopy'),
      '--redefine-syms=' + renames_file,
      args.input,
      renamed_archive,
  ])

  defined, undefined = coff_external_symbols(args, renamed_archive)
  expected = set(exports)
  extra = sorted(n for n in defined - expected - included if not n.startswith(COFF_PREFIX))
  missing = sorted(expected - defined)
  dangling = sorted(undefined & set(renamed))
  if extra or missing or dangling:
    message = '%s does not export exactly the Impeller C API.\n' % renamed_archive
    if extra:
      message += 'Unexpected global symbols (%d): %s\n' % (len(extra), ', '.join(extra[:50]))
    if missing:
      message += 'Missing exports (%d): %s\n' % (len(missing), ', '.join(missing[:50]))
    if dangling:
      message += 'Unrenamed references (%d): %s\n' % (len(dangling), ', '.join(dangling[:50]))
    raise SystemExit(message)

  if os.path.exists(args.output):
    os.remove(args.output)
  shutil.move(renamed_archive, args.output)


def check_exports(args, merged, expected):
  output = run([
      tool(args, 'llvm-nm'),
      '--defined-only',
      '--extern-only',
      '--format=just-symbols',
      merged,
  ])
  defined = set(output.split())
  expected = set(expected)
  extra = sorted(defined - expected)
  missing = sorted(expected - defined)
  if extra or missing:
    message = '%s does not export exactly the Impeller C API.\n' % merged
    if extra:
      message += 'Unexpected global symbols (%d): %s\n' % (len(extra), ', '.join(extra[:50]))
    if missing:
      message += 'Missing exports (%d): %s\n' % (len(missing), ', '.join(missing[:50]))
    raise SystemExit(message)


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--format', required=True, choices=['macho', 'elf', 'coff'])
  parser.add_argument('--input', required=True, help='The archive to prelink.')
  parser.add_argument('--output', required=True, help='The archive to write.')
  parser.add_argument('--header', required=True, help='impeller.h')
  parser.add_argument('--clang-bin', required=True, help='The LLVM toolchain bin directory.')
  parser.add_argument('--work-dir', required=True)
  parser.add_argument('--arch', help='The Mach-O architecture, e.g. arm64.')
  parser.add_argument('--sysroot', help='The Apple SDK.')
  parser.add_argument('--ld', help='The Xcode toolchain ld, for Mach-O.')
  args = parser.parse_args()

  if args.format == 'macho' and not args.arch:
    parser.error('--arch is required for Mach-O')

  os.makedirs(args.work_dir, exist_ok=True)
  exports = impeller_exports(args.header)

  if args.format == 'coff':
    prelink_coff(args, exports, args.work_dir)
    return 0

  merged = os.path.join(args.work_dir, 'impeller.o')

  if args.format == 'macho':
    expected = prelink_macho(args, exports, args.work_dir, merged)
  else:
    expected = prelink_elf(args, exports, args.work_dir, merged)

  check_exports(args, merged, expected)

  if os.path.exists(args.output):
    os.remove(args.output)
  run([
      tool(args, 'llvm-ar'),
      '--format=' + ('darwin' if args.format == 'macho' else 'gnu'),
      'rcs',
      args.output,
      merged,
  ])
  return 0


if __name__ == '__main__':
  sys.exit(main())
