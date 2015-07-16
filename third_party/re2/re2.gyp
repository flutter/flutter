# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 're2',
      'type': 'static_library',
      'include_dirs': [
        '.',
        '<(DEPTH)',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          '.',
          '<(DEPTH)',
        ],
      },
      'dependencies': [
        '<(DEPTH)/base/third_party/dynamic_annotations/dynamic_annotations.gyp:dynamic_annotations',
      ],
      'sources': [
        're2/bitstate.cc',
        're2/compile.cc',
        're2/dfa.cc',
        're2/filtered_re2.cc',
        're2/filtered_re2.h',
        're2/mimics_pcre.cc',
        're2/nfa.cc',
        're2/onepass.cc',
        're2/parse.cc',
        're2/perl_groups.cc',
        're2/prefilter.cc',
        're2/prefilter.h',
        're2/prefilter_tree.cc',
        're2/prefilter_tree.h',
        're2/prog.cc',
        're2/prog.h',
        're2/re2.cc',
        're2/re2.h',
        're2/regexp.cc',
        're2/regexp.h',
        're2/set.cc',
        're2/set.h',
        're2/simplify.cc',
        're2/stringpiece.h',
        're2/tostring.cc',
        're2/unicode_casefold.cc',
        're2/unicode_casefold.h',
        're2/unicode_groups.cc',
        're2/unicode_groups.h',
        're2/variadic_function.h',
        're2/walker-inl.h',
        'util/arena.cc',
        'util/arena.h',
        'util/atomicops.h',
        'util/flags.h',
        'util/hash.cc',
        'util/logging.h',
        'util/mutex.h',
        'util/rune.cc',
        'util/sparse_array.h',
        'util/sparse_set.h',
        'util/stringpiece.cc',
        'util/stringprintf.cc',
        'util/strutil.cc',
        'util/utf.h',
        'util/util.h',
      ],
      'conditions': [
        ['OS=="win"', {
          'msvs_disabled_warnings': [ 4018, 4722, 4267 ],
        }]
      ]
    },
  ],
}
