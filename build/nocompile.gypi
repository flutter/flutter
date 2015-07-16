# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into an target to create a unittest that
# invokes a set of no-compile tests.  A no-compile test is a test that asserts
# a particular construct will not compile.
#
# Also see:
#   http://dev.chromium.org/developers/testing/no-compile-tests
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my_module_nc_unittests',
#   'type': 'executable',
#   'sources': [
#     'nc_testset_1.nc',
#     'nc_testset_2.nc',
#   ],
#   'includes': ['path/to/this/gypi/file'],
# }
#
# The .nc files are C++ files that contain code we wish to assert will not
# compile.  Each individual test case in the file should be put in its own
# #ifdef section.  The expected output should be appended with a C++-style
# comment that has a python list of regular expressions.  This will likely
# be greater than 80-characters. Giving a solid expected output test is
# important so that random compile failures do not cause the test to pass.
#
# Example .nc file:
#
#   #if defined(TEST_NEEDS_SEMICOLON)  // [r"expected ',' or ';' at end of input"]
#
#   int a = 1
#
#   #elif defined(TEST_NEEDS_CAST)  // [r"invalid conversion from 'void*' to 'char*'"]
#
#   void* a = NULL;
#   char* b = a;
#
#   #endif
#
# If we needed disable TEST_NEEDS_SEMICOLON, then change the define to:
#
#   DISABLE_TEST_NEEDS_SEMICOLON
#   TEST_NEEDS_CAST
#
# The lines above are parsed by a regexp so avoid getting creative with the
# formatting or ifdef logic; it will likely just not work.
#
# Implementation notes:
# The .nc files are actually processed by a python script which executes the
# compiler and generates a .cc file that is empty on success, or will have a
# series of #error lines on failure, and a set of trivially passing gunit
# TEST() functions on success. This allows us to fail at the compile step when
# something goes wrong, and know during the unittest run that the test was at
# least processed when things go right.

{
  # TODO(awong): Disabled until http://crbug.com/105388 is resolved.
  'sources/': [['exclude', '\\.nc$']],
  'conditions': [
    [ 'OS!="win" and clang==1', {
      'rules': [
        {
          'variables': {
            'nocompile_driver': '<(DEPTH)/tools/nocompile_driver.py',
            'nc_result_path': ('<(INTERMEDIATE_DIR)/<(module_dir)/'
                               '<(RULE_INPUT_ROOT)_nc.cc'),
           },
          'rule_name': 'run_nocompile',
          'extension': 'nc',
          'inputs': [
            '<(nocompile_driver)',
          ],
          'outputs': [
            '<(nc_result_path)'
          ],
          'action': [
            'python',
            '<(nocompile_driver)',
            '4', # number of compilers to invoke in parallel.
            '<(RULE_INPUT_PATH)',
            '-Wall -Werror -Wfatal-errors -I<(DEPTH)',
            '<(nc_result_path)',
            ],
          'message': 'Generating no compile results for <(RULE_INPUT_PATH)',
          'process_outputs_as_sources': 1,
        },
      ],
    }, {
      'sources/': [['exclude', '\\.nc$']]
    }],  # 'OS!="win" and clang=="1"'
  ],
}

