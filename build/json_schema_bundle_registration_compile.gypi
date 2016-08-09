# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    # When including this gypi, the following variables must be set:
    #   schema_files:
    #     An array of json or idl files that comprise the api model.
    #   impl_dir_:
    #     The root path of API implementations; also used for the
    #     output location. (N.B. Named as such to prevent gyp from
    #     expanding it as a relative path.)
    #   root_namespace:
    #     A Python string substituion pattern used to generate the C++
    #     namespace for each API. Use %(namespace)s to replace with the API
    #     namespace, like "toplevel::%(namespace)s_api".
    #
    # Functions and namespaces can be excluded by setting "nocompile" to true.
    'api_gen_dir': '<(DEPTH)/tools/json_schema_compiler',
    'api_gen': '<(api_gen_dir)/compiler.py',
    'generator_files': [
      '<(api_gen_dir)/cc_generator.py',
      '<(api_gen_dir)/code.py',
      '<(api_gen_dir)/compiler.py',
      '<(api_gen_dir)/cpp_bundle_generator.py',
      '<(api_gen_dir)/cpp_type_generator.py',
      '<(api_gen_dir)/cpp_util.py',
      '<(api_gen_dir)/h_generator.py',
      '<(api_gen_dir)/idl_schema.py',
      '<(api_gen_dir)/json_schema.py',
      '<(api_gen_dir)/model.py',
      '<(api_gen_dir)/util_cc_helper.py',
    ],
  },
  'actions': [
    {
      # GN version: json_schema_api.gni
      'action_name': 'genapi_bundle_registration',
      'inputs': [
        '<@(generator_files)',
        '<@(schema_files)',
        '<@(non_compiled_schema_files)',
      ],
      'outputs': [
        '<(SHARED_INTERMEDIATE_DIR)/<(impl_dir_)/generated_api_registration.h',
        '<(SHARED_INTERMEDIATE_DIR)/<(impl_dir_)/generated_api_registration.cc',
      ],
      'action': [
        'python',
        '<(api_gen)',
        '--root=<(DEPTH)',
        '--destdir=<(SHARED_INTERMEDIATE_DIR)',
        '--namespace=<(root_namespace)',
        '--generator=cpp-bundle-registration',
        '--impl-dir=<(impl_dir_)',
        '<@(schema_files)',
        '<@(non_compiled_schema_files)',
      ],
      'message': 'Generating C++ API bundle code for function registration',
      'process_outputs_as_sources': 1,
      # Avoid running MIDL compiler on IDL input files.
      'explicit_idl_action': 1,
    },
  ],
  'include_dirs': [
    '<(SHARED_INTERMEDIATE_DIR)',
    '<(DEPTH)',
  ],
  'direct_dependent_settings': {
    'include_dirs': [
      '<(SHARED_INTERMEDIATE_DIR)',
    ]
  },
  # This target exports a hard dependency because it generates header
  # files.
  'hard_dependency': 1,
}
