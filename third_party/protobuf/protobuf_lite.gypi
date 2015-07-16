# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'sources': [
    'src/google/protobuf/stubs/atomicops.h',
    'src/google/protobuf/stubs/atomicops_internals_arm_gcc.h',
    'src/google/protobuf/stubs/atomicops_internals_atomicword_compat.h',
    'src/google/protobuf/stubs/atomicops_internals_macosx.h',
    'src/google/protobuf/stubs/atomicops_internals_mips_gcc.h',
    'src/google/protobuf/stubs/atomicops_internals_x86_gcc.cc',
    'src/google/protobuf/stubs/atomicops_internals_x86_gcc.h',
    'src/google/protobuf/stubs/atomicops_internals_x86_msvc.cc',
    'src/google/protobuf/stubs/atomicops_internals_x86_msvc.h',
    'src/google/protobuf/stubs/common.h',
    'src/google/protobuf/stubs/once.h',
    'src/google/protobuf/stubs/platform_macros.h',
    'src/google/protobuf/extension_set.h',
    'src/google/protobuf/generated_message_util.h',
    'src/google/protobuf/message_lite.h',
    'src/google/protobuf/repeated_field.h',
    'src/google/protobuf/unknown_field_set.cc',
    'src/google/protobuf/unknown_field_set.h',
    'src/google/protobuf/wire_format_lite.h',
    'src/google/protobuf/wire_format_lite_inl.h',
    'src/google/protobuf/io/coded_stream.h',
    'src/google/protobuf/io/zero_copy_stream.h',
    'src/google/protobuf/io/zero_copy_stream_impl_lite.h',

    'src/google/protobuf/stubs/common.cc',
    'src/google/protobuf/stubs/once.cc',
    'src/google/protobuf/stubs/hash.h',
    'src/google/protobuf/stubs/map-util.h',
    'src/google/protobuf/extension_set.cc',
    'src/google/protobuf/generated_message_util.cc',
    'src/google/protobuf/message_lite.cc',
    'src/google/protobuf/repeated_field.cc',
    'src/google/protobuf/wire_format_lite.cc',
    'src/google/protobuf/io/coded_stream.cc',
    'src/google/protobuf/io/coded_stream_inl.h',
    'src/google/protobuf/io/zero_copy_stream.cc',
    'src/google/protobuf/io/zero_copy_stream_impl_lite.cc',
    '<(config_h_dir)/config.h',
  ],
  'include_dirs': [
    '<(config_h_dir)',
    'src',
  ],
  # This macro must be defined to suppress the use of dynamic_cast<>,
  # which requires RTTI.
  'defines': [
    'GOOGLE_PROTOBUF_NO_RTTI',
    'GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER',
  ],
  'direct_dependent_settings': {
    'include_dirs': [
      '<(config_h_dir)',
      'src',
    ],
    'defines': [
      'GOOGLE_PROTOBUF_NO_RTTI',
      'GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER',
    ],
    # TODO(jschuh): http://crbug.com/167187 size_t -> int.
    'msvs_disabled_warnings': [ 4267 ],
  },
}
