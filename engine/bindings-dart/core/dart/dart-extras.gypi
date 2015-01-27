{
  'variables': {
    'global_dart_output_dir': '<(SHARED_INTERMEDIATE_DIR)/blink/bindings/dart',
    'dart_dir': '../../../../../../dart',
    'dart_lib_dir': '<(dart_dir)/sdk/lib',
    'resources_dir': 'resources',
    'build_dir': '../../../build',
    'core_dir': '../../../core',
    'modules_dir': '../../../modules',
    'core_gyp_dir': '<(core_dir)',
    'scripts_dir': '../../dart/gyp/scripts',

    'bindings_core_dart_stamp_file': '<(SHARED_INTERMEDIATE_DIR)/blink/bindings/core/dart/core.stamp',

    # Share with Source/core/core.gyp somehow.
    # Note: that SVG exclusions are not applicable for Dartium.
    'bindings_idl_files': [
      '<@(core_idl_files)',
      '<@(core_dependency_idl_files)',
      '<@(modules_idl_files)',
      '<@(modules_dependency_idl_files)',
      '<(modules_dir)/geolocation/NavigatorGeolocation.idl',
       # Add some interfaces which are missing for JS, but necessary for Dart.
      '<(core_dir)/svg/SVGFilterPrimitiveStandardAttributes.idl',
      '<(core_dir)/svg/SVGFitToViewBox.idl',
      '<(core_dir)/svg/SVGTests.idl',
    ],

    'bindings_idl_files!': [
      # Custom bindings in bindings/core/v8/custom exist for these.
      '<(core_dir)/dom/EventListener.idl',

      '<(core_dir)/page/AbstractView.idl',

      # FIXME: I don't know why these are excluded, either.
      # Someone (me?) should figure it out and add appropriate comments.
      '<(core_dir)/css/CSSUnknownRule.idl',
    ],

    'enable_dart_native_extensions%': '<(enable_dart_native_extensions)',
    'additional_webcore_include_dirs': [
      '.',
      'custom',
      '<(dart_dir)runtime',
      '<(dart_dir)runtime/include',
      '<(SHARED_INTERMEDIATE_DIR)/blink/bindings/dart',
    ],
  },
  'targets': [
    {
      'target_name': 'dart_debug_hooks_source',
      'type': 'none',
      'actions': [
        {
          'action_name': 'generateDartDebugHooksSource',
          'inputs': [
            'DartDebugHooks.js',
          ],
          'outputs': [
            '<(SHARED_INTERMEDIATE_DIR)/blink/DartDebugHooksSource.h',
          ],
          'action': [
            'python',
            '<(build_dir)/scripts/xxd.py',
            'DartDebugHooksSource_js',
            '<@(_inputs)',
            '<@(_outputs)'
          ],
          'message': 'Generating DartDebugHooksSource.h from DartDebugHooks.js',
        },
      ]
    },
    {
      'target_name': 'gen_dart_blink',
      'type': 'none',
      'actions': [
        {
          'action_name': 'generateDartBlinkLibrary',
          'inputs': [
            # Only includes main IDL files from core and modules (exclude
            # dependencies and testing, for which bindings are not included in
            # aggregate bindings).
            '<@(core_idl_files)',
            '<@(modules_idl_files)',
            '<(bindings_core_dart_stamp_file)',
            '<(bindings_modules_dart_stamp_file)',
            '<@(dart_code_generator_template_files)',
            '<@(dart_idl_compiler_files)',
            '<@(idl_compiler_files)',
          ],
          'outputs': [
            '<(global_dart_output_dir)/_blink_dartium.dart',
          ],
          'action': [
            'python',
            '-S',  # skip 'import site' to speed up startup
            '../../dart/scripts/compiler.py',
            '--generate-dart-blink',
            '<(bindings_core_dart_output_dir)',
            '<(core_idl_files_list)',
            '--generate-dart-blink',
            '<(bindings_modules_dart_output_dir)',
            '<(modules_idl_files_list)',
            '--output-directory',
            '<(global_dart_output_dir)',
          ],
          'message': 'Generating dart:_blink library',
        },
      ]
    },
    {
      'target_name': 'dart_snapshot',
      'type': 'none',
      'hard_dependency': 1,
      'dependencies': [
        '<(dart_dir)/runtime/dart-runtime.gyp:gen_snapshot#host',
        'gen_dart_blink',
      ],
      'variables': {
        'idls_list_temp_file': '<|(idls_list_temp_file.tmp <@(bindings_idl_files))',
        'output_path': '<(SHARED_INTERMEDIATE_DIR)/blink/bindings/dart',
        'dart_html_lib_dir': '<(dart_dir)/tools/dom',
        'dart_html_lib_deps': '<!(python <@(scripts_dir)/dart_html_lib_deps.py <(dart_html_lib_dir))',
      },
      'sources': [
        # '<!@(cat <(idls_list_temp_file))',
      ],
      'actions': [
        # FIXME: We need an action to generate:
        # - Dart*.[h|cpp]
        # - blink_DartResolver.cpp
        {
          'action_name': 'generate_dart_class_ids',
          'inputs': [
            # Only includes main IDL files from core and modules (exclude
            # dependencies and testing, for which bindings are not included in
            # aggregate bindings).
            '<@(core_idl_files)',
            '<@(modules_idl_files)',
            '<(bindings_core_dart_stamp_file)',
            '<(bindings_modules_dart_stamp_file)',
            '<@(dart_code_generator_template_files)',
            '<@(dart_idl_compiler_files)',
            '<@(idl_compiler_files)',
          ],
          'outputs': [
            '<@(dart_class_id_files)',
          ],
          'action': [
            'python',
            '-S',  # skip 'import site' to speed up startup
            '../../dart/scripts/compiler.py',
            '--generate-globals',
            '<(bindings_core_dart_output_dir)',
            '<(core_idl_files_list)',
            '--generate-globals',
            '<(bindings_modules_dart_output_dir)',
            '<(modules_idl_files_list)',
            '--output-directory',
            '<(global_dart_output_dir)',
          ],
          'message': 'Generating Dart class id table',
        },
        {
          'action_name': 'build_dart_snapshot',
          'variables': {
            'output_path': '<(SHARED_INTERMEDIATE_DIR)/blink/bindings/dart',
            'pure_libs': [
              '<(global_dart_output_dir)/_blink_dartium.dart',
              '<(dart_lib_dir)/html/html_common/html_common.dart',
              '<(dart_lib_dir)/js/dartium/js_dartium.dart',
              '<(dart_lib_dir)/html/dartium/html_dartium.dart',
              '<(dart_lib_dir)/indexed_db/dartium/indexed_db_dartium.dart',
              '<(dart_lib_dir)/svg/dartium/svg_dartium.dart',
              '<(dart_lib_dir)/web_audio/dartium/web_audio_dartium.dart',
              '<(dart_lib_dir)/web_gl/dartium/web_gl_dartium.dart',
              '<(dart_lib_dir)/web_sql/dartium/web_sql_dartium.dart',
            ],
          },
          'inputs': [
            '<@(scripts_dir)/build_dart_snapshot.py',
            '<(resources_dir)/DartSnapshot.bytes.template',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)gen_snapshot<(EXECUTABLE_SUFFIX)',
            # FIXME: libs below can consist of more than a single file. Ideally, we should
            # track that somehow.
            # FIXME: We need blink_dartium.dart here.
            '<@(pure_libs)',
            '<@(dart_html_lib_deps)',
          ],
          'outputs': [
            '<(output_path)/DartSnapshot.bytes',
          ],
          'action': [
            'python',
            '<@(scripts_dir)/build_dart_snapshot.py',
            '<(dart_dir)',
            '<(resources_dir)/DartSnapshot.bytes.template',
            '<(output_path)',
            '<(PRODUCT_DIR)/<(EXECUTABLE_PREFIX)gen_snapshot<(EXECUTABLE_SUFFIX)',
            '<@(pure_libs)',
          ],
        },
      ],
    },
  ],
}
