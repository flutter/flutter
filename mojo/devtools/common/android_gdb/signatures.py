# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import itertools


def get_signature(file_object, elffile_module):
  """Computes a unique signature of a library file.

  We only hash the .text section of the library in order to make the hash
  resistant to stripping (we want the same hash for the same library with debug
  symbols kept or stripped).
  """
  try:
      elf = elffile_module.ELFFile(file_object)
      text_section = elf.get_section_by_name('.text')
  except elffile_module.common.ELFError:
      return None
  file_object.seek(text_section['sh_offset'])
  data = file_object.read(min(4096, text_section['sh_size']))
  def combine((i, c)):
    return i ^ ord(c)
  result = 16 * [0]
  for i in xrange(0, len(data), len(result)):
    result = map(combine,
                 itertools.izip_longest(result,
                                        data[i:i + len(result)],
                                        fillvalue='\0'))
  return ''.join(["%02x" % x for x in result])
