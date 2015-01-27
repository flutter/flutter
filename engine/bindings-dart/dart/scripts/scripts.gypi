# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'bindings_dart_scripts_dir': '.',
    'bindings_dart_scripts_output_dir': '<(SHARED_INTERMEDIATE_DIR)/blink/bindings/dart/scripts',
    'dart_dir': '../../../../../../dart',

    'dart_idl_compiler_files': [
      'dart_types.py',
      'dart_attributes.py',
      'code_generator_dart.py',
      'dart_compiler.py',
      'dart_interface.py',
      'dart_utilities.py',
      'idl_files.py',
      'dart_tests.py',
      'test/main.py',
      'test/__init__.py',
      'dart_methods.py',
      '__init__.py',
      'compiler.py',
      'dart_callback_interface.py',
    ],
  },
}
