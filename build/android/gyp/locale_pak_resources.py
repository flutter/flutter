#!/usr/bin/env python
#
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""Creates a resources.zip for locale .pak files.

Places the locale.pak files into appropriate resource configs
(e.g. en-GB.pak -> res/raw-en/en_gb.lpak). Also generates a locale_paks
TypedArray so that resource files can be enumerated at runtime.
"""

import collections
import optparse
import os
import sys
import zipfile

from util import build_utils


# This should stay in sync with:
# base/android/java/src/org/chromium/base/LocaleUtils.java
_CHROME_TO_ANDROID_LOCALE_MAP = {
    'he': 'iw',
    'id': 'in',
    'fil': 'tl',
}


def ToResourceFileName(name):
  """Returns the resource-compatible file name for the given file."""
  # Resources file names must consist of [a-z0-9_.].
  # Changes extension to .lpak so that compression can be toggled separately for
  # locale pak files vs other pak files.
  return name.replace('-', '_').replace('.pak', '.lpak').lower()


def CreateLocalePaksXml(names):
  """Creates the contents for the locale-paks.xml files."""
  VALUES_FILE_TEMPLATE = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
  <array name="locale_paks">%s
  </array>
</resources>
'''
  VALUES_ITEM_TEMPLATE = '''
    <item>@raw/%s</item>'''

  res_names = (os.path.splitext(name)[0] for name in names)
  items = ''.join((VALUES_ITEM_TEMPLATE % name for name in res_names))
  return VALUES_FILE_TEMPLATE % items


def ComputeMappings(sources):
  """Computes the mappings of sources -> resources.

  Returns a tuple of:
    - mappings: List of (src, dest) paths
    - lang_to_locale_map: Map of language -> list of resource names
      e.g. "en" -> ["en_gb.lpak"]
  """
  lang_to_locale_map = collections.defaultdict(list)
  mappings = []
  for src_path in sources:
    basename = os.path.basename(src_path)
    name = os.path.splitext(basename)[0]
    res_name = ToResourceFileName(basename)
    if name == 'en-US':
      dest_dir = 'raw'
    else:
      # Chrome's uses different region mapping logic from Android, so include
      # all regions for each language.
      android_locale = _CHROME_TO_ANDROID_LOCALE_MAP.get(name, name)
      lang = android_locale[0:2]
      dest_dir = 'raw-' + lang
      lang_to_locale_map[lang].append(res_name)
    mappings.append((src_path, os.path.join(dest_dir, res_name)))
  return mappings, lang_to_locale_map


def main():
  parser = optparse.OptionParser()
  build_utils.AddDepfileOption(parser)
  parser.add_option('--locale-paks', help='List of files for res/raw-LOCALE')
  parser.add_option('--resources-zip', help='Path to output resources.zip')
  parser.add_option('--print-languages',
      action='store_true',
      help='Print out the list of languages that cover the given locale paks '
           '(using Android\'s language codes)')

  options, _ = parser.parse_args()
  build_utils.CheckOptions(options, parser,
                           required=['locale_paks'])

  sources = build_utils.ParseGypList(options.locale_paks)

  if options.depfile:
    deps = sources + build_utils.GetPythonDependencies()
    build_utils.WriteDepfile(options.depfile, deps)

  mappings, lang_to_locale_map = ComputeMappings(sources)
  if options.print_languages:
    print '\n'.join(sorted(lang_to_locale_map))

  if options.resources_zip:
    with zipfile.ZipFile(options.resources_zip, 'w', zipfile.ZIP_STORED) as out:
      for mapping in mappings:
        out.write(mapping[0], mapping[1])

      # Create TypedArray resources so ResourceExtractor can enumerate files.
      def WriteValuesFile(lang, names):
        dest_dir = 'values'
        if lang:
          dest_dir += '-' + lang
        # Always extract en-US.lpak since it's the fallback.
        xml = CreateLocalePaksXml(names + ['en_us.lpak'])
        out.writestr(os.path.join(dest_dir, 'locale-paks.xml'), xml)

      for lang, names in lang_to_locale_map.iteritems():
        WriteValuesFile(lang, names)
      WriteValuesFile(None, [])


if __name__ == '__main__':
  sys.exit(main())
