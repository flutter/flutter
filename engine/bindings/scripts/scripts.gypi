# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'bindings_scripts_dir': '.',
    'bindings_scripts_output_dir': '<(SHARED_INTERMEDIATE_DIR)/sky/bindings/scripts',
    'jinja_module_files': [
      # jinja2/__init__.py contains version string, so sufficient for package
      '<(DEPTH)/third_party/jinja2/__init__.py',
      '<(DEPTH)/third_party/markupsafe/__init__.py',  # jinja2 dep
    ],
    'idl_lexer_parser_files': [
      # PLY (Python Lex-Yacc)
      '<(DEPTH)/third_party/ply/lex.py',
      '<(DEPTH)/third_party/ply/yacc.py',
      # Web IDL lexer/parser (base parser)
      '<(DEPTH)/tools/idl_parser/idl_lexer.py',
      '<(DEPTH)/tools/idl_parser/idl_node.py',
      '<(DEPTH)/tools/idl_parser/idl_parser.py',
      # Blink IDL lexer/parser/constructor
      'blink_idl_lexer.py',
      'blink_idl_parser.py',
    ],
    'idl_compiler_files': [
      'idl_compiler.py',
      # Blink IDL front end (ex-lexer/parser)
      'idl_definitions.py',
      'idl_reader.py',
      'idl_types.py',
      'idl_validator.py',
      'interface_dependency_resolver.py',
      # V8 code generator
      'code_generator_v8.py',
      'v8_attributes.py',
      'v8_callback_interface.py',
      'v8_dictionary.py',
      'v8_globals.py',
      'v8_interface.py',
      'v8_methods.py',
      'v8_types.py',
      'v8_utilities.py',
    ],
    'idl_cache_files': [
      '<(bindings_scripts_output_dir)/lextab.py',
      '<(bindings_scripts_output_dir)/parsetab.pickle',
      '<(bindings_scripts_output_dir)/cached_jinja_templates.stamp',
    ],

    'conditions': [
        # These scripts can skip writing generated files if they are identical
        # to the already existing files, which avoids further build steps, like
        # recompilation. However, a dependency (earlier build step) having a
        # newer timestamp than an output (later build step) confuses some build
        # systems, so only use this on ninja, which explicitly supports this use
        # case (gyp turns all actions into ninja restat rules).
        ['"<(GENERATOR)"=="ninja"', {
          'write_file_only_if_changed': '1',
        }, {
          'write_file_only_if_changed': '0',
        }],
    ],
  },
}
