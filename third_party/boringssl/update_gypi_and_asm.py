# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can b
# found in the LICENSE file.

"""Enumerates the BoringSSL source in src/ and generates two gypi files:
  boringssl.gypi and boringssl_tests.gypi."""

import os
import subprocess
import sys


# OS_ARCH_COMBOS maps from OS and platform to the OpenSSL assembly "style" for
# that platform and the extension used by asm files.
OS_ARCH_COMBOS = [
    ('linux', 'arm', 'elf', [''], 'S'),
    ('linux', 'aarch64', 'linux64', [''], 'S'),
    ('linux', 'x86', 'elf', ['-fPIC'], 'S'),
    ('linux', 'x86_64', 'elf', [''], 'S'),
    ('mac', 'x86', 'macosx', ['-fPIC'], 'S'),
    ('mac', 'x86_64', 'macosx', [''], 'S'),
    ('win', 'x86', 'win32n', [''], 'asm'),
    ('win', 'x86_64', 'nasm', [''], 'asm'),
]

# NON_PERL_FILES enumerates assembly files that are not processed by the
# perlasm system.
NON_PERL_FILES = {
    ('linux', 'arm'): [
        'src/crypto/poly1305/poly1305_arm_asm.S',
        'src/crypto/chacha/chacha_vec_arm.S',
        'src/crypto/cpu-arm-asm.S',
    ],
}

FILE_HEADER = """# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is created by update_gypi_and_asm.py. Do not edit manually.

"""


def FindCMakeFiles(directory):
  """Returns list of all CMakeLists.txt files recursively in directory."""
  cmakefiles = []

  for (path, _, filenames) in os.walk(directory):
    for filename in filenames:
      if filename == 'CMakeLists.txt':
        cmakefiles.append(os.path.join(path, filename))

  return cmakefiles


def NoTests(dent, is_dir):
  """Filter function that can be passed to FindCFiles in order to remove test
  sources."""
  if is_dir:
    return dent != 'test'
  return 'test.' not in dent and not dent.startswith('example_')


def OnlyTests(dent, is_dir):
  """Filter function that can be passed to FindCFiles in order to remove
  non-test sources."""
  if is_dir:
    return True
  return '_test.' in dent or dent.startswith('example_')


def FindCFiles(directory, filter_func):
  """Recurses through directory and returns a list of paths to all the C source
  files that pass filter_func."""
  cfiles = []

  for (path, dirnames, filenames) in os.walk(directory):
    for filename in filenames:
      if filename.endswith('.c') and filter_func(filename, False):
        cfiles.append(os.path.join(path, filename))
        continue

    for (i, dirname) in enumerate(dirnames):
      if not filter_func(dirname, True):
        del dirnames[i]

  return cfiles


def ExtractPerlAsmFromCMakeFile(cmakefile):
  """Parses the contents of the CMakeLists.txt file passed as an argument and
  returns a list of all the perlasm() directives found in the file."""
  perlasms = []
  with open(cmakefile) as f:
    for line in f:
      line = line.strip()
      if not line.startswith('perlasm('):
        continue
      if not line.endswith(')'):
        raise ValueError('Bad perlasm line in %s' % cmakefile)
      # Remove "perlasm(" from start and ")" from end
      params = line[8:-1].split()
      if len(params) < 2:
        raise ValueError('Bad perlasm line in %s' % cmakefile)
      perlasms.append({
          'extra_args': params[2:],
          'input': os.path.join(os.path.dirname(cmakefile), params[1]),
          'output': os.path.join(os.path.dirname(cmakefile), params[0]),
      })

  return perlasms


def ReadPerlAsmOperations():
  """Returns a list of all perlasm() directives found in CMake config files in
  src/."""
  perlasms = []
  cmakefiles = FindCMakeFiles('src')

  for cmakefile in cmakefiles:
    perlasms.extend(ExtractPerlAsmFromCMakeFile(cmakefile))

  return perlasms


def PerlAsm(output_filename, input_filename, perlasm_style, extra_args):
  """Runs the a perlasm script and puts the output into output_filename."""
  base_dir = os.path.dirname(output_filename)
  if not os.path.isdir(base_dir):
    os.makedirs(base_dir)
  output = subprocess.check_output(
      ['perl', input_filename, perlasm_style] + extra_args)
  with open(output_filename, 'w+') as out_file:
    out_file.write(output)


def ArchForAsmFilename(filename):
  """Returns the architectures that a given asm file should be compiled for
  based on substrings in the filename."""

  if 'x86_64' in filename or 'avx2' in filename:
    return ['x86_64']
  elif ('x86' in filename and 'x86_64' not in filename) or '586' in filename:
    return ['x86']
  elif 'armx' in filename:
    return ['arm', 'aarch64']
  elif 'armv8' in filename:
    return ['aarch64']
  elif 'arm' in filename:
    return ['arm']
  else:
    raise ValueError('Unknown arch for asm filename: ' + filename)


def WriteAsmFiles(perlasms):
  """Generates asm files from perlasm directives for each supported OS x
  platform combination."""
  asmfiles = {}

  for osarch in OS_ARCH_COMBOS:
    (osname, arch, perlasm_style, extra_args, asm_ext) = osarch
    key = (osname, arch)
    outDir = '%s-%s' % key

    for perlasm in perlasms:
      filename = os.path.basename(perlasm['input'])
      output = perlasm['output']
      if not output.startswith('src'):
        raise ValueError('output missing src: %s' % output)
      output = os.path.join(outDir, output[4:])
      output = output.replace('${ASM_EXT}', asm_ext)

      if arch in ArchForAsmFilename(filename):
        PerlAsm(output, perlasm['input'], perlasm_style,
                perlasm['extra_args'] + extra_args)
        asmfiles.setdefault(key, []).append(output)

  for (key, non_perl_asm_files) in NON_PERL_FILES.iteritems():
    asmfiles.setdefault(key, []).extend(non_perl_asm_files)

  return asmfiles


def PrintVariableSection(out, name, files):
  out.write('    \'%s\': [\n' % name)
  for f in sorted(files):
    out.write('      \'%s\',\n' % f)
  out.write('    ],\n')


def main():
  crypto_c_files = FindCFiles(os.path.join('src', 'crypto'), NoTests)
  ssl_c_files = FindCFiles(os.path.join('src', 'ssl'), NoTests)

  # Generate err_data.c
  with open('err_data.c', 'w+') as err_data:
    subprocess.check_call(['go', 'run', 'err_data_generate.go'],
                          cwd=os.path.join('src', 'crypto', 'err'),
                          stdout=err_data)
  crypto_c_files.append('err_data.c')

  with open('boringssl.gypi', 'w+') as gypi:
    gypi.write(FILE_HEADER + '{\n  \'variables\': {\n')

    PrintVariableSection(
        gypi, 'boringssl_lib_sources', crypto_c_files + ssl_c_files)

    perlasms = ReadPerlAsmOperations()

    for ((osname, arch), asm_files) in sorted(
        WriteAsmFiles(perlasms).iteritems()):
      PrintVariableSection(gypi, 'boringssl_%s_%s_sources' %
                           (osname, arch), asm_files)

    gypi.write('  }\n}\n')

  test_c_files = FindCFiles(os.path.join('src', 'crypto'), OnlyTests)
  test_c_files += FindCFiles(os.path.join('src', 'ssl'), OnlyTests)

  with open('boringssl_tests.gypi', 'w+') as test_gypi:
    test_gypi.write(FILE_HEADER + '{\n  \'targets\': [\n')

    test_names = []
    for test in sorted(test_c_files):
      test_name = 'boringssl_%s' % os.path.splitext(os.path.basename(test))[0]
      test_gypi.write("""    {
      'target_name': '%s',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        '%s',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },\n""" % (test_name, test))
      test_names.append(test_name)

    test_names.sort()

    test_gypi.write("""  ],
  'variables': {
    'boringssl_test_targets': [\n""")

    for test in test_names:
      test_gypi.write("""      '%s',\n""" % test)

    test_gypi.write('    ],\n  }\n}\n')

  return 0


if __name__ == '__main__':
  sys.exit(main())
