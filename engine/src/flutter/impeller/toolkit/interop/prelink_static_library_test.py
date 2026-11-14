#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Tests for prelink_static_library.py.

The end-to-end tests compile small objects with the clang in buildtools, run
the script on an archive of them, and check the symbols of the result.
"""

import importlib.util
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import unittest

INTEROP_DIR = os.path.dirname(os.path.abspath(__file__))
FLUTTER_DIR = os.path.normpath(os.path.join(INTEROP_DIR, '..', '..', '..'))
SCRIPT = os.path.join(INTEROP_DIR, 'prelink_static_library.py')

_spec = importlib.util.spec_from_file_location('prelink_static_library', SCRIPT)
prelink = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(prelink)


def clang_bin():
  host_os = {'darwin': 'mac', 'linux': 'linux', 'win32': 'windows'}[sys.platform]
  machine = platform.machine().lower()
  host_cpu = 'arm64' if machine in ('arm64', 'aarch64') else 'x64'
  return os.path.join(FLUTTER_DIR, 'buildtools', '%s-%s' % (host_os, host_cpu), 'clang', 'bin')


CLANG_BIN = clang_bin()


def llvm_tool(name):
  return os.path.join(CLANG_BIN, name + ('.exe' if sys.platform == 'win32' else ''))


def ar_member_header(name, size):
  return b'%-16s%-12s%-6s%-6s%-8s%-10d`\n' % (name, b'0', b'0', b'0', b'644', size)


def bsd_archive(members):
  """Returns a BSD archive that stores names with the #1/ extension."""
  data = b'!<arch>\n'
  data += ar_member_header(b'__.SYMDEF', 4) + b'\0\0\0\0'
  for name, body in members:
    padded_name = name.encode() + b'\0' * (4 - len(name) % 4)
    contents = padded_name + body
    data += ar_member_header(b'#1/%d' % len(padded_name), len(contents)) + contents
    if len(contents) % 2:
      data += b'\n'
  return data


def gnu_archive(members):
  """Returns a GNU archive with a symbol table and a long name table."""
  names = b''
  offsets = []
  for name, _ in members:
    offsets.append(len(names))
    names += name.encode() + b'/\n'
  data = b'!<arch>\n'
  data += ar_member_header(b'/', 4) + b'\0\0\0\0'
  data += ar_member_header(b'//', len(names)) + names
  if len(names) % 2:
    data += b'\n'
  for offset, (_, body) in zip(offsets, members):
    data += ar_member_header(b'/%d' % offset, len(body)) + body
    if len(body) % 2:
      data += b'\n'
  return data


class ImpellerExportsTest(unittest.TestCase):

  def write_header(self, text):
    handle, path = tempfile.mkstemp(suffix='.h')
    with os.fdopen(handle, 'w', encoding='utf-8') as f:
      f.write(text)
    self.addCleanup(os.remove, path)
    return path

  def test_parses_impeller_header(self):
    header = os.path.join(INTEROP_DIR, 'impeller.h')
    exports = prelink.impeller_exports(header)
    with open(header, encoding='utf-8') as f:
      declarations = sum(1 for line in f if line.lstrip().startswith('IMPELLER_EXPORT'))
    self.assertEqual(len(exports), declarations)
    self.assertEqual(len(exports), len(set(exports)))
    for name in exports:
      self.assertTrue(name.startswith('Impeller'), name)
    self.assertIn('ImpellerGetVersion', exports)
    self.assertIn('ImpellerSurfaceDrawDisplayList', exports)

  def test_parses_multiline_declarations(self):
    header = self.write_header(
        'IMPELLER_EXPORT\n'
        'uint32_t ImpellerOne(void);\n'
        '\n'
        'IMPELLER_EXPORT IMPELLER_NODISCARD ImpellerFoo IMPELLER_NULLABLE\n'
        'ImpellerTwoNew(const ImpellerRect* IMPELLER_NONNULL rect);\n'
        '\n'
        '// IMPELLER_EXPORT int NotAnExport(void);\n'
        '#define IMPELLER_EXPORT_HELPER(x) x\n'
    )
    self.assertEqual(prelink.impeller_exports(header), ['ImpellerOne', 'ImpellerTwoNew'])

  def test_rejects_duplicates(self):
    header = self.write_header(
        'IMPELLER_EXPORT void ImpellerA(void);\n'
        'IMPELLER_EXPORT void ImpellerA(void);\n'
    )
    with self.assertRaises(SystemExit):
      prelink.impeller_exports(header)

  def test_rejects_header_without_exports(self):
    header = self.write_header('void ImpellerA(void);\n')
    with self.assertRaises(SystemExit):
      prelink.impeller_exports(header)


class ArchiveMembersTest(unittest.TestCase):

  def read_members(self, data):
    handle, path = tempfile.mkstemp(suffix='.a')
    with os.fdopen(handle, 'wb') as f:
      f.write(data)
    self.addCleanup(os.remove, path)
    return list(prelink.archive_members(path))

  MEMBERS = [
      ('short.o', b'odd'),
      ('a_member_name_longer_than_sixteen_bytes.o', b'even'),
      ('png.filter_neon.o', b'x'),
  ]

  def test_bsd_archive(self):
    self.assertEqual(self.read_members(bsd_archive(self.MEMBERS)), self.MEMBERS)

  def test_gnu_archive(self):
    self.assertEqual(self.read_members(gnu_archive(self.MEMBERS)), self.MEMBERS)

  def test_rejects_non_archive(self):
    with self.assertRaises(SystemExit):
      self.read_members(b'\x7fELF')


class CoffDirectivesTest(unittest.TestCase):

  def test_directive_symbols(self):
    text = (
        '/DEFAULTLIB:libcmt /alternatename:foo=bar /INCLUDE:baz '
        '-export:"qux",DATA /FAILIFMISMATCH:_MSC_VER=1900'
    )
    found = [match.groups()[1:] for match in prelink.COFF_SYMBOL_DIRECTIVES.finditer(text)]
    self.assertEqual(
        found, [
            ('foo', 'bar', None, None),
            (None, None, 'baz', None),
            (None, None, None, '"qux"'),
        ]
    )


# Two translation units. `internal` and `kInternalData` are defined in one and
# used in the other. `Inline<int>` is an inline template instantiation, which is
# a COMDAT in both objects.
SOURCE_A = '''
int internal(int);
extern int kInternalData;
template <class T> T Inline(T x) { return x + 1; }
extern "C" int ImpellerTestExported(void) { return internal(Inline(1)) + kInternalData; }
'''
SOURCE_B = '''
int kInternalData = 3;
template <class T> T Inline(T x) { return x + 1; }
int internal(int x) { return Inline(x) * 2; }
'''
HEADER = 'IMPELLER_EXPORT int ImpellerTestExported(void);\n'


class PrelinkFailed(Exception):
  pass


class EndToEndTest(unittest.TestCase):

  @classmethod
  def setUpClass(cls):
    # Every engine checkout has the buildtools clang. Fail instead of skipping,
    # so that a wrong path can't silently disable these tests.
    if not os.path.exists(llvm_tool('clang++')):
      raise FileNotFoundError('The buildtools clang is not at %s' % CLANG_BIN)

  def setUp(self):
    self.work_dir = tempfile.mkdtemp()
    self.addCleanup(shutil.rmtree, self.work_dir)
    self.header = self.path('impeller.h')
    with open(self.header, 'w', encoding='utf-8') as f:
      f.write(HEADER)

  def path(self, name):
    return os.path.join(self.work_dir, name)

  def build_archive(self, target, ar_format, extra_flags=()):
    objects = []
    for name, source in (('a', SOURCE_A), ('b', SOURCE_B)):
      source_path = self.path(name + '.cc')
      with open(source_path, 'w', encoding='utf-8') as f:
        f.write(source)
      object_path = self.path(name + '.o')
      subprocess.check_call([
          llvm_tool('clang++'),
          '--target=' + target,
          '-O0',
          '-c',
          source_path,
          '-o',
          object_path,
      ] + list(extra_flags))
      objects.append(object_path)
    archive = self.path('libinput.a')
    subprocess.check_call([llvm_tool('llvm-ar'), '--format=' + ar_format, 'rcs', archive] + objects)
    return archive

  def prelink(self, archive, fmt, extra_args=()):
    output = self.path('liboutput.a')
    result = subprocess.run([
        sys.executable,
        SCRIPT,
        '--format',
        fmt,
        '--input',
        archive,
        '--output',
        output,
        '--header',
        self.header,
        '--clang-bin',
        CLANG_BIN,
        '--work-dir',
        self.path('work'),
    ] + list(extra_args),
                            stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT,
                            encoding='utf-8')
    if result.returncode != 0:
      raise PrelinkFailed(result.stdout)
    return output

  def symbols(self, archive, *flags):
    output = subprocess.check_output([llvm_tool('llvm-nm'), '--format=just-symbols'] + list(flags) +
                                     [archive],
                                     encoding='utf-8')
    return {line for line in output.split() if not line.endswith(':')}

  def test_elf(self):
    archive = self.build_archive('x86_64-linux-gnu', 'gnu')
    output = self.prelink(archive, 'elf')

    self.assertEqual(
        self.symbols(output, '--defined-only', '--extern-only'), {'ImpellerTestExported'}
    )
    self.assertEqual(self.symbols(output, '--undefined-only'), set())
    defined = self.symbols(output, '--defined-only')
    self.assertIn('_Z8internali', defined)
    self.assertIn('kInternalData', defined)

    headers = subprocess.check_output([llvm_tool('llvm-objdump'), '--section-headers', output],
                                      encoding='utf-8')
    self.assertNotIn('.group', headers)

  def test_elf_rejects_missing_export(self):
    with open(self.header, 'a', encoding='utf-8') as f:
      f.write('IMPELLER_EXPORT int ImpellerTestMissing(void);\n')
    archive = self.build_archive('x86_64-linux-gnu', 'gnu')
    with self.assertRaisesRegex(PrelinkFailed, 'Missing exports.*ImpellerTestMissing'):
      self.prelink(archive, 'elf')

  def test_coff(self):
    archive = self.build_archive('x86_64-pc-windows-msvc', 'coff')
    output = self.prelink(archive, 'coff')

    prefix = prelink.COFF_PREFIX
    defined = self.symbols(output, '--defined-only', '--extern-only')
    self.assertIn('ImpellerTestExported', defined)
    self.assertIn(prefix + '?internal@@YAHH@Z', defined)
    self.assertIn(prefix + '?kInternalData@@3HA', defined)
    for name in defined - {'ImpellerTestExported'}:
      self.assertTrue(name.startswith(prefix), name)
    # References from the other object were renamed too.
    undefined = self.symbols(output, '--undefined-only')
    self.assertIn(prefix + '?internal@@YAHH@Z', undefined)
    self.assertNotIn('?internal@@YAHH@Z', undefined)

  def macho(self, extra_flags):
    archive = self.build_archive('arm64-apple-macos12', 'darwin', extra_flags)
    ld = subprocess.check_output(['xcrun', '--find', 'ld'], encoding='utf-8').strip()
    sysroot = subprocess.check_output(['xcrun', '--show-sdk-path'], encoding='utf-8').strip()
    output = self.prelink(archive, 'macho', ['--arch', 'arm64', '--ld', ld, '--sysroot', sysroot])

    self.assertEqual(
        self.symbols(output, '--defined-only', '--extern-only'), {'_ImpellerTestExported'}
    )
    self.assertEqual(self.symbols(output, '--undefined-only'), set())

  @unittest.skipUnless(sys.platform == 'darwin', 'Requires the Xcode linker.')
  def test_macho(self):
    self.macho([])

  @unittest.skipUnless(sys.platform == 'darwin', 'Requires the Xcode linker.')
  def test_macho_bitcode(self):
    self.macho(['-flto'])


if __name__ == '__main__':
  unittest.main()
