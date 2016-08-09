#!/usr/bin/env python
#
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Signs and zipaligns APK.

"""

import optparse
import shutil
import sys
import tempfile

from util import build_utils

def RenameInflateAndAddPageAlignment(
    rezip_apk_jar_path, in_zip_file, out_zip_file):
  rezip_apk_cmd = [
      'java',
      '-classpath',
      rezip_apk_jar_path,
      'RezipApk',
      'renamealign',
      in_zip_file,
      out_zip_file,
    ]
  build_utils.CheckOutput(rezip_apk_cmd)


def ReorderAndAlignApk(rezip_apk_jar_path, in_zip_file, out_zip_file):
  rezip_apk_cmd = [
      'java',
      '-classpath',
      rezip_apk_jar_path,
      'RezipApk',
      'reorder',
      in_zip_file,
      out_zip_file,
    ]
  build_utils.CheckOutput(rezip_apk_cmd)


def JarSigner(key_path, key_name, key_passwd, unsigned_path, signed_path):
  shutil.copy(unsigned_path, signed_path)
  sign_cmd = [
      'jarsigner',
      '-sigalg', 'MD5withRSA',
      '-digestalg', 'SHA1',
      '-keystore', key_path,
      '-storepass', key_passwd,
      signed_path,
      key_name,
    ]
  build_utils.CheckOutput(sign_cmd)


def AlignApk(zipalign_path, unaligned_path, final_path):
  align_cmd = [
      zipalign_path,
      '-f', '4',  # 4 bytes
      unaligned_path,
      final_path,
      ]
  build_utils.CheckOutput(align_cmd)


def main():
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)

  parser.add_option('--rezip-apk-jar-path',
                    help='Path to the RezipApk jar file.')
  parser.add_option('--zipalign-path', help='Path to the zipalign tool.')
  parser.add_option('--unsigned-apk-path', help='Path to input unsigned APK.')
  parser.add_option('--final-apk-path',
      help='Path to output signed and aligned APK.')
  parser.add_option('--key-path', help='Path to keystore for signing.')
  parser.add_option('--key-passwd', help='Keystore password')
  parser.add_option('--key-name', help='Keystore name')
  parser.add_option('--stamp', help='Path to touch on success.')
  parser.add_option('--load-library-from-zip', type='int',
      help='If non-zero, build the APK such that the library can be loaded ' +
           'directly from the zip file using the crazy linker. The library ' +
           'will be renamed, uncompressed and page aligned.')

  options, _ = parser.parse_args()

  FinalizeApk(options)

  if options.depfile:
    build_utils.WriteDepfile(
        options.depfile, build_utils.GetPythonDependencies())

  if options.stamp:
    build_utils.Touch(options.stamp)


def FinalizeApk(options):
  with tempfile.NamedTemporaryFile() as signed_apk_path_tmp, \
      tempfile.NamedTemporaryFile() as apk_to_sign_tmp:

    if options.load_library_from_zip:
      # We alter the name of the library so that the Android Package Manager
      # does not extract it into a separate file. This must be done before
      # signing, as the filename is part of the signed manifest. At the same
      # time we uncompress the library, which is necessary so that it can be
      # loaded directly from the APK.
      # Move the library to a page boundary by adding a page alignment file.
      apk_to_sign = apk_to_sign_tmp.name
      RenameInflateAndAddPageAlignment(
          options.rezip_apk_jar_path, options.unsigned_apk_path, apk_to_sign)
    else:
      apk_to_sign = options.unsigned_apk_path

    signed_apk_path = signed_apk_path_tmp.name
    JarSigner(options.key_path, options.key_name, options.key_passwd,
              apk_to_sign, signed_apk_path)

    if options.load_library_from_zip:
      # Reorder the contents of the APK. This re-establishes the canonical
      # order which means the library will be back at its page aligned location.
      # This step also aligns uncompressed items to 4 bytes.
      ReorderAndAlignApk(
          options.rezip_apk_jar_path, signed_apk_path, options.final_apk_path)
    else:
      # Align uncompressed items to 4 bytes
      AlignApk(options.zipalign_path, signed_apk_path, options.final_apk_path)


if __name__ == '__main__':
  sys.exit(main())
