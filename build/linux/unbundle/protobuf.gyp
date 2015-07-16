# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'protobuf_lite',
      'type': 'none',
      'direct_dependent_settings': {
        'cflags': [
          # Use full protobuf, because vanilla protobuf doesn't have
          # our custom patch to retain unknown fields in lite mode.
          '<!@(pkg-config --cflags protobuf)',
        ],
        'defines': [
          'USE_SYSTEM_PROTOBUF',

          # This macro must be defined to suppress the use
          # of dynamic_cast<>, which requires RTTI.
          'GOOGLE_PROTOBUF_NO_RTTI',
          'GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER',
        ],
      },
      'link_settings': {
        # Use full protobuf, because vanilla protobuf doesn't have
        # our custom patch to retain unknown fields in lite mode.
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other protobuf)',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l protobuf)',
        ],
      },
      'variables': {
        'headers_root_path': 'src',
        'header_filenames': [
          # This list can easily be updated using the command below:
          # find third_party/protobuf/src -iname '*.h' -printf "'%p',\n" | \
          # sed -e 's|third_party/protobuf/src/||' | sort -u
          'google/protobuf/compiler/code_generator.h',
          'google/protobuf/compiler/command_line_interface.h',
          'google/protobuf/compiler/cpp/cpp_enum_field.h',
          'google/protobuf/compiler/cpp/cpp_enum.h',
          'google/protobuf/compiler/cpp/cpp_extension.h',
          'google/protobuf/compiler/cpp/cpp_field.h',
          'google/protobuf/compiler/cpp/cpp_file.h',
          'google/protobuf/compiler/cpp/cpp_generator.h',
          'google/protobuf/compiler/cpp/cpp_helpers.h',
          'google/protobuf/compiler/cpp/cpp_message_field.h',
          'google/protobuf/compiler/cpp/cpp_message.h',
          'google/protobuf/compiler/cpp/cpp_options.h',
          'google/protobuf/compiler/cpp/cpp_primitive_field.h',
          'google/protobuf/compiler/cpp/cpp_service.h',
          'google/protobuf/compiler/cpp/cpp_string_field.h',
          'google/protobuf/compiler/cpp/cpp_unittest.h',
          'google/protobuf/compiler/importer.h',
          'google/protobuf/compiler/java/java_doc_comment.h',
          'google/protobuf/compiler/java/java_enum_field.h',
          'google/protobuf/compiler/java/java_enum.h',
          'google/protobuf/compiler/java/java_extension.h',
          'google/protobuf/compiler/java/java_field.h',
          'google/protobuf/compiler/java/java_file.h',
          'google/protobuf/compiler/java/java_generator.h',
          'google/protobuf/compiler/java/java_helpers.h',
          'google/protobuf/compiler/java/java_message_field.h',
          'google/protobuf/compiler/java/java_message.h',
          'google/protobuf/compiler/java/java_primitive_field.h',
          'google/protobuf/compiler/java/java_service.h',
          'google/protobuf/compiler/java/java_string_field.h',
          'google/protobuf/compiler/mock_code_generator.h',
          'google/protobuf/compiler/package_info.h',
          'google/protobuf/compiler/parser.h',
          'google/protobuf/compiler/plugin.h',
          'google/protobuf/compiler/plugin.pb.h',
          'google/protobuf/compiler/python/python_generator.h',
          'google/protobuf/compiler/subprocess.h',
          'google/protobuf/compiler/zip_writer.h',
          'google/protobuf/descriptor_database.h',
          'google/protobuf/descriptor.h',
          'google/protobuf/descriptor.pb.h',
          'google/protobuf/dynamic_message.h',
          'google/protobuf/extension_set.h',
          'google/protobuf/generated_enum_reflection.h',
          'google/protobuf/generated_message_reflection.h',
          'google/protobuf/generated_message_util.h',
          'google/protobuf/io/coded_stream.h',
          'google/protobuf/io/coded_stream_inl.h',
          'google/protobuf/io/gzip_stream.h',
          'google/protobuf/io/package_info.h',
          'google/protobuf/io/printer.h',
          'google/protobuf/io/tokenizer.h',
          'google/protobuf/io/zero_copy_stream.h',
          'google/protobuf/io/zero_copy_stream_impl.h',
          'google/protobuf/io/zero_copy_stream_impl_lite.h',
          'google/protobuf/message.h',
          'google/protobuf/message_lite.h',
          'google/protobuf/package_info.h',
          'google/protobuf/reflection_ops.h',
          'google/protobuf/repeated_field.h',
          'google/protobuf/service.h',
          'google/protobuf/stubs/atomicops.h',
          'google/protobuf/stubs/atomicops_internals_arm64_gcc.h',
          'google/protobuf/stubs/atomicops_internals_arm_gcc.h',
          'google/protobuf/stubs/atomicops_internals_arm_qnx.h',
          'google/protobuf/stubs/atomicops_internals_atomicword_compat.h',
          'google/protobuf/stubs/atomicops_internals_macosx.h',
          'google/protobuf/stubs/atomicops_internals_mips_gcc.h',
          'google/protobuf/stubs/atomicops_internals_pnacl.h',
          'google/protobuf/stubs/atomicops_internals_tsan.h',
          'google/protobuf/stubs/atomicops_internals_x86_gcc.h',
          'google/protobuf/stubs/atomicops_internals_x86_msvc.h',
          'google/protobuf/stubs/common.h',
          'google/protobuf/stubs/hash.h',
          'google/protobuf/stubs/map-util.h',
          'google/protobuf/stubs/once.h',
          'google/protobuf/stubs/platform_macros.h',
          'google/protobuf/stubs/stl_util.h',
          'google/protobuf/stubs/stringprintf.h',
          'google/protobuf/stubs/strutil.h',
          'google/protobuf/stubs/substitute.h',
          'google/protobuf/stubs/template_util.h',
          'google/protobuf/stubs/type_traits.h',
          'google/protobuf/testing/file.h',
          'google/protobuf/testing/googletest.h',
          'google/protobuf/test_util.h',
          'google/protobuf/test_util_lite.h',
          'google/protobuf/text_format.h',
          'google/protobuf/unknown_field_set.h',
          'google/protobuf/wire_format.h',
          'google/protobuf/wire_format_lite.h',
          'google/protobuf/wire_format_lite_inl.h',
        ],
      },
      'includes': [
        '../../build/shim_headers.gypi',
      ],
    },
    {
      'target_name': 'protoc',
      'type': 'none',
      'toolsets': ['host', 'target'],
    },
    {
      'target_name': 'py_proto',
      'type': 'none',
    },
  ],
}
