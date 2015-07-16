# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'conditions': [
    ['use_system_protobuf==0', {
      'conditions': [
        ['OS!="win"', {
          'variables': {
            'config_h_dir':
              '.',  # crafted for gcc/linux.
          },
        }, {  # else, OS=="win"
          'variables': {
            'config_h_dir':
              'vsprojects',  # crafted for msvc.
          },
          'target_defaults': {
            'msvs_disabled_warnings': [
              4018,  # signed/unsigned mismatch in comparison
              4244,  # implicit conversion, possible loss of data
              4355,  # 'this' used in base member initializer list
              4267,  # size_t to int truncation
              4291,  # no matching operator delete for a placement new
            ],
            'defines!': [
              'WIN32_LEAN_AND_MEAN',  # Protobuf defines this itself.
            ],
          },
        }],
        ['OS=="ios" and "<(GENERATOR)"=="xcode" and "<(GENERATOR_FLAVOR)"!="ninja"', {
          'variables': {
            'ninja_output_dir': 'ninja-protoc',
            'ninja_product_dir':
              '<(DEPTH)/xcodebuild/<(ninja_output_dir)/<(CONFIGURATION_NAME)',
            # Gyp to rerun
            're_run_targets': [
              'third_party/protobuf/protobuf.gyp',
            ],
          },
          'targets': [
            {
              # On iOS, generating protoc is done via two actions: (1) compiling
              # the executable with ninja, and (2) copying the executable into a
              # location that is shared with other projects. These actions are
              # separated into two targets in order to be able to specify that the
              # second action should not run until the first action finishes (since
              # the ordering of multiple actions in one target is defined only by
              # inputs and outputs, and it's impossible to set correct inputs for
              # the ninja build, so setting all the inputs and outputs isn't an
              # option). The first target is given here; the second target is the
              # normal protoc target under the condition that "OS==iOS".
              'target_name': 'compile_protoc',
              'type': 'none',
              'toolsets': ['host'],
              'includes': ['../../build/ios/mac_build.gypi'],
              'actions': [
                {
                  'action_name': 'compile protoc',
                  'inputs': [],
                  'outputs': [],
                  'action': [
                    '<@(ninja_cmd)',
                    'protoc',
                  ],
                  'message': 'Generating the C++ protocol buffers compiler',
                },
              ],
            },
          ],
        }],
      ],
      'targets': [
        # The "lite" lib is about 1/7th the size of the heavy lib,
        # but it doesn't support some of the more exotic features of
        # protobufs, like reflection.  To generate C++ code that can link
        # against the lite version of the library, add the option line:
        #
        #   option optimize_for = LITE_RUNTIME;
        #
        # to your .proto file.
        {
          'target_name': 'protobuf_lite',
          'type': '<(component)',
          'toolsets': ['host', 'target'],
          'includes': [
            'protobuf_lite.gypi',
          ],
          # Required for component builds. See http://crbug.com/172800.
          'defines': [
            'LIBPROTOBUF_EXPORTS',
            'PROTOBUF_USE_DLLS',
          ],
          'direct_dependent_settings': {
            'defines': [
              'PROTOBUF_USE_DLLS',
            ],
          },
        },
        # This is the full, heavy protobuf lib that's needed for c++ .protos
        # that don't specify the LITE_RUNTIME option.  The protocol
        # compiler itself (protoc) falls into that category.
        #
        # DO NOT LINK AGAINST THIS TARGET IN CHROME CODE  --agl
        {
          'target_name': 'protobuf_full_do_not_use',
          'type': 'static_library',
          'toolsets': ['host','target'],
          'includes': [
            'protobuf_lite.gypi',
          ],
          'sources': [
            'src/google/protobuf/descriptor.h',
            'src/google/protobuf/descriptor.pb.h',
            'src/google/protobuf/descriptor_database.h',
            'src/google/protobuf/dynamic_message.h',
            'src/google/protobuf/generated_enum_reflection.h',
            'src/google/protobuf/generated_message_reflection.h',
            'src/google/protobuf/message.h',
            'src/google/protobuf/reflection_ops.h',
            'src/google/protobuf/service.h',
            'src/google/protobuf/text_format.h',
            'src/google/protobuf/wire_format.h',
            'src/google/protobuf/io/gzip_stream.h',
            'src/google/protobuf/io/printer.h',
            'src/google/protobuf/io/tokenizer.h',
            'src/google/protobuf/io/zero_copy_stream_impl.h',
            'src/google/protobuf/compiler/code_generator.h',
            'src/google/protobuf/compiler/command_line_interface.h',
            'src/google/protobuf/compiler/importer.h',
            'src/google/protobuf/compiler/java/java_doc_comment.cc',
            'src/google/protobuf/compiler/java/java_doc_comment.h',
            'src/google/protobuf/compiler/parser.h',

            'src/google/protobuf/stubs/strutil.cc',
            'src/google/protobuf/stubs/strutil.h',
            'src/google/protobuf/stubs/substitute.cc',
            'src/google/protobuf/stubs/substitute.h',
            'src/google/protobuf/stubs/stl_util.h',
            'src/google/protobuf/stubs/stringprintf.cc',
            'src/google/protobuf/stubs/stringprintf.h',
            'src/google/protobuf/stubs/structurally_valid.cc',
            'src/google/protobuf/stubs/template_util.h',
            'src/google/protobuf/stubs/type_traits.h',

            'src/google/protobuf/descriptor.cc',
            'src/google/protobuf/descriptor.pb.cc',
            'src/google/protobuf/descriptor_database.cc',
            'src/google/protobuf/dynamic_message.cc',
            'src/google/protobuf/extension_set.cc',
            'src/google/protobuf/extension_set.h',
            'src/google/protobuf/extension_set_heavy.cc',
            'src/google/protobuf/generated_message_reflection.cc',
            'src/google/protobuf/message.cc',
            'src/google/protobuf/reflection_ops.cc',
            'src/google/protobuf/service.cc',
            'src/google/protobuf/text_format.cc',
            'src/google/protobuf/wire_format.cc',
            # This file pulls in zlib, but it's not actually used by protoc, so
            # instead of compiling zlib for the host, let's just exclude this.
            # 'src/src/google/protobuf/io/gzip_stream.cc',
            'src/google/protobuf/io/printer.cc',
            'src/google/protobuf/io/tokenizer.cc',
            'src/google/protobuf/io/zero_copy_stream_impl.cc',
            'src/google/protobuf/compiler/importer.cc',
            'src/google/protobuf/compiler/parser.cc',
          ],
        },
        {
          'target_name': 'protoc',
          'conditions': [
            ['OS!="ios" or "<(GENERATOR)"!="xcode" or "<(GENERATOR_FLAVOR)"=="ninja"', {
              'type': 'executable',
              'toolsets': ['host'],
              'sources': [
                'src/google/protobuf/compiler/code_generator.cc',
                'src/google/protobuf/compiler/command_line_interface.cc',
                'src/google/protobuf/compiler/plugin.cc',
                'src/google/protobuf/compiler/plugin.pb.cc',
                'src/google/protobuf/compiler/subprocess.cc',
                'src/google/protobuf/compiler/subprocess.h',
                'src/google/protobuf/compiler/zip_writer.cc',
                'src/google/protobuf/compiler/zip_writer.h',
                'src/google/protobuf/compiler/cpp/cpp_enum.cc',
                'src/google/protobuf/compiler/cpp/cpp_enum.h',
                'src/google/protobuf/compiler/cpp/cpp_enum_field.cc',
                'src/google/protobuf/compiler/cpp/cpp_enum_field.h',
                'src/google/protobuf/compiler/cpp/cpp_extension.cc',
                'src/google/protobuf/compiler/cpp/cpp_extension.h',
                'src/google/protobuf/compiler/cpp/cpp_field.cc',
                'src/google/protobuf/compiler/cpp/cpp_field.h',
                'src/google/protobuf/compiler/cpp/cpp_file.cc',
                'src/google/protobuf/compiler/cpp/cpp_file.h',
                'src/google/protobuf/compiler/cpp/cpp_generator.cc',
                'src/google/protobuf/compiler/cpp/cpp_helpers.cc',
                'src/google/protobuf/compiler/cpp/cpp_helpers.h',
                'src/google/protobuf/compiler/cpp/cpp_message.cc',
                'src/google/protobuf/compiler/cpp/cpp_message.h',
                'src/google/protobuf/compiler/cpp/cpp_message_field.cc',
                'src/google/protobuf/compiler/cpp/cpp_message_field.h',
                'src/google/protobuf/compiler/cpp/cpp_primitive_field.cc',
                'src/google/protobuf/compiler/cpp/cpp_primitive_field.h',
                'src/google/protobuf/compiler/cpp/cpp_service.cc',
                'src/google/protobuf/compiler/cpp/cpp_service.h',
                'src/google/protobuf/compiler/cpp/cpp_string_field.cc',
                'src/google/protobuf/compiler/cpp/cpp_string_field.h',
                'src/google/protobuf/compiler/java/java_enum.cc',
                'src/google/protobuf/compiler/java/java_enum.h',
                'src/google/protobuf/compiler/java/java_enum_field.cc',
                'src/google/protobuf/compiler/java/java_enum_field.h',
                'src/google/protobuf/compiler/java/java_extension.cc',
                'src/google/protobuf/compiler/java/java_extension.h',
                'src/google/protobuf/compiler/java/java_field.cc',
                'src/google/protobuf/compiler/java/java_field.h',
                'src/google/protobuf/compiler/java/java_file.cc',
                'src/google/protobuf/compiler/java/java_file.h',
                'src/google/protobuf/compiler/java/java_generator.cc',
                'src/google/protobuf/compiler/java/java_helpers.cc',
                'src/google/protobuf/compiler/java/java_helpers.h',
                'src/google/protobuf/compiler/java/java_message.cc',
                'src/google/protobuf/compiler/java/java_message.h',
                'src/google/protobuf/compiler/java/java_message_field.cc',
                'src/google/protobuf/compiler/java/java_message_field.h',
                'src/google/protobuf/compiler/java/java_primitive_field.cc',
                'src/google/protobuf/compiler/java/java_primitive_field.h',
                'src/google/protobuf/compiler/java/java_service.cc',
                'src/google/protobuf/compiler/java/java_service.h',
                'src/google/protobuf/compiler/java/java_string_field.cc',
                'src/google/protobuf/compiler/java/java_string_field.h',
                'src/google/protobuf/compiler/python/python_generator.cc',
                'src/google/protobuf/compiler/main.cc',
              ],
              'dependencies': [
                'protobuf_full_do_not_use',
              ],
              'include_dirs': [
                '<(config_h_dir)',
                'src/src',
              ],
            }, {  # else, OS=="ios" and "<(GENERATOR)"=="xcode" and "<(GENERATOR_FLAVOR)"!="ninja"
              'type': 'none',
              'toolsets': ['host'],
              'dependencies': [
                'compile_protoc',
              ],
              'actions': [
                {
                  'action_name': 'copy protoc',
                  'inputs': [
                    '<(ninja_product_dir)/protoc',
                  ],
                  'outputs': [
                    '<(PRODUCT_DIR)/protoc',
                  ],
                  'action': [
                    'cp',
                    '<(ninja_product_dir)/protoc',
                    '<(PRODUCT_DIR)/protoc',
                  ],
                },
              ],
            }],
          ],
        },
        {
          # Generate the python module needed by all protoc-generated Python code.
          'target_name': 'py_proto',
          'type': 'none',
          'copies': [
            {
              'destination': '<(PRODUCT_DIR)/pyproto/google/',
              'files': [
                # google/ module gets an empty __init__.py.
                '__init__.py',
              ],
            },
            {
              'destination': '<(PRODUCT_DIR)/pyproto/google/protobuf',
              'files': [
                'python/google/protobuf/__init__.py',
                'python/google/protobuf/descriptor.py',
                'python/google/protobuf/descriptor_database.py',
                'python/google/protobuf/descriptor_pool.py',
                'python/google/protobuf/message.py',
                'python/google/protobuf/message_factory.py',
                'python/google/protobuf/reflection.py',
                'python/google/protobuf/service.py',
                'python/google/protobuf/service_reflection.py',
                'python/google/protobuf/text_format.py',

                # TODO(ncarter): protoc's python generator treats
                # descriptor.proto specially, but it's not possible to trigger
                # the special treatment unless you run protoc from ./src/src
                # (the treatment is based on the path to the .proto file
                # matching a constant exactly). I'm not sure how to convince
                # gyp to execute a rule from a different directory.  Until this
                # is resolved, use a copy of descriptor_pb2.py that I manually
                # generated.
                'descriptor_pb2.py',
              ],
            },
            {
              'destination': '<(PRODUCT_DIR)/pyproto/google/protobuf/internal',
              'files': [
                'python/google/protobuf/internal/__init__.py',
                'python/google/protobuf/internal/api_implementation.py',
                'python/google/protobuf/internal/containers.py',
                'python/google/protobuf/internal/cpp_message.py',
                'python/google/protobuf/internal/decoder.py',
                'python/google/protobuf/internal/encoder.py',
                'python/google/protobuf/internal/enum_type_wrapper.py',
                'python/google/protobuf/internal/generator_test.py',
                'python/google/protobuf/internal/message_listener.py',
                'python/google/protobuf/internal/python_message.py',
                'python/google/protobuf/internal/type_checkers.py',
                'python/google/protobuf/internal/wire_format.py',
              ],
            },
          ],
      #   # We can't generate a proper descriptor_pb2.py -- see earlier comment.
      #   'rules': [
      #     {
      #       'rule_name': 'genproto',
      #       'extension': 'proto',
      #       'inputs': [
      #         '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)protoc<(EXECUTABLE_SUFFIX)',
      #       ],
      #       'variables': {
      #         # The protoc compiler requires a proto_path argument with the
      #           # directory containing the .proto file.
      #           'rule_input_relpath': 'src/google/protobuf',
      #         },
      #         'outputs': [
      #           '<(PRODUCT_DIR)/pyproto/google/protobuf/<(RULE_INPUT_ROOT)_pb2.py',
      #         ],
      #         'action': [
      #           '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)protoc<(EXECUTABLE_SUFFIX)',
      #           '-I./src',
      #           '-I.',
      #           '--python_out=<(PRODUCT_DIR)/pyproto/google/protobuf',
      #           'google/protobuf/descriptor.proto',
      #         ],
      #         'message': 'Generating Python code from <(RULE_INPUT_PATH)',
      #       },
      #     ],
      #     'dependencies': [
      #       'protoc#host',
      #     ],
      #     'sources': [
      #       'src/google/protobuf/descriptor.proto',
      #     ],
         },
      ],
    }, { # use_system_protobuf==1
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
    }],
  ],
}
