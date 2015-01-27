# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'bindings_core_dart_output_dir': '<(SHARED_INTERMEDIATE_DIR)/blink/bindings/core/dart',

    'dart_class_id_files': [
      '<(SHARED_INTERMEDIATE_DIR)/blink/bindings/dart/DartWebkitClassIds.cpp',
      '<(SHARED_INTERMEDIATE_DIR)/blink/bindings/dart/DartWebkitClassIds.h',
    ],

    'conditions': [
      ['OS=="win" and buildtype=="Official"', {
        # On Windows Official release builds, we try to preserve symbol
        # space.
        'bindings_core_dart_generated_aggregate_files': [
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings.cpp',
        ],
      }, {
        'bindings_core_dart_generated_aggregate_files': [
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings01.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings02.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings03.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings04.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings05.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings06.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings07.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings08.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings09.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings10.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings11.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings12.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings13.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings14.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings15.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings16.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings17.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings18.cpp',
          '<(bindings_core_dart_output_dir)/DartGeneratedCoreBindings19.cpp',
        ],
      }],
    ],
  },
}
