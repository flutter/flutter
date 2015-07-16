# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'xmlfiles': [
      'src/src/mapi/glapi/gen/EXT_draw_buffers2.xml',
      'src/src/mapi/glapi/gen/NV_texture_barrier.xml',
      'src/src/mapi/glapi/gen/NV_primitive_restart.xml',
      'src/src/mapi/glapi/gen/ARB_base_instance.xml',
      'src/src/mapi/glapi/gen/EXT_packed_depth_stencil.xml',
      'src/src/mapi/glapi/gen/ARB_sync.xml',
      'src/src/mapi/glapi/gen/ARB_draw_buffers.xml',
      'src/src/mapi/glapi/gen/ARB_geometry_shader4.xml',
      'src/src/mapi/glapi/gen/ARB_draw_buffers_blend.xml',
      'src/src/mapi/glapi/gen/GL3x.xml',
      'src/src/mapi/glapi/gen/ARB_blend_func_extended.xml',
      'src/src/mapi/glapi/gen/EXT_gpu_shader4.xml',
      'src/src/mapi/glapi/gen/ARB_robustness.xml',
      'src/src/mapi/glapi/gen/ARB_ES2_compatibility.xml',
      'src/src/mapi/glapi/gen/ARB_map_buffer_range.xml',
      'src/src/mapi/glapi/gen/OES_single_precision.xml',
      'src/src/mapi/glapi/gen/ARB_debug_output.xml',
      'src/src/mapi/glapi/gen/ARB_draw_instanced.xml',
      'src/src/mapi/glapi/gen/ARB_copy_buffer.xml',
      'src/src/mapi/glapi/gen/glX_API.xml',
      'src/src/mapi/glapi/gen/ARB_framebuffer_object.xml',
      'src/src/mapi/glapi/gen/OES_EGL_image.xml',
      'src/src/mapi/glapi/gen/gl_and_es_API.xml',
      'src/src/mapi/glapi/gen/ARB_color_buffer_float.xml',
      'src/src/mapi/glapi/gen/ARB_instanced_arrays.xml',
      'src/src/mapi/glapi/gen/APPLE_object_purgeable.xml',
      'src/src/mapi/glapi/gen/APPLE_vertex_array_object.xml',
      'src/src/mapi/glapi/gen/ARB_texture_rgb10_a2ui.xml',
      'src/src/mapi/glapi/gen/ARB_sampler_objects.xml',
      'src/src/mapi/glapi/gen/OES_fixed_point.xml',
      'src/src/mapi/glapi/gen/EXT_provoking_vertex.xml',
      'src/src/mapi/glapi/gen/ARB_texture_float.xml',
      'src/src/mapi/glapi/gen/EXT_texture_integer.xml',
      'src/src/mapi/glapi/gen/es_EXT.xml',
      'src/src/mapi/glapi/gen/gl_and_glX_API.xml',
      'src/src/mapi/glapi/gen/EXT_transform_feedback.xml',
      'src/src/mapi/glapi/gen/ARB_texture_buffer_object.xml',
      'src/src/mapi/glapi/gen/EXT_framebuffer_object.xml',
      'src/src/mapi/glapi/gen/ARB_uniform_buffer_object.xml',
      'src/src/mapi/glapi/gen/ARB_texture_rg.xml',
      'src/src/mapi/glapi/gen/ARB_vertex_type_2_10_10_10_rev.xml',
      'src/src/mapi/glapi/gen/ARB_seamless_cube_map.xml',
      'src/src/mapi/glapi/gen/EXT_texture_array.xml',
      'src/src/mapi/glapi/gen/ARB_vertex_array_object.xml',
      'src/src/mapi/glapi/gen/ARB_invalidate_subdata.xml',
      'src/src/mapi/glapi/gen/ARB_draw_elements_base_vertex.xml',
      'src/src/mapi/glapi/gen/AMD_draw_buffers_blend.xml',
      'src/src/mapi/glapi/gen/ARB_get_program_binary.xml',
      'src/src/mapi/glapi/gen/gl_API.xml',
      'src/src/mapi/glapi/gen/ARB_depth_clamp.xml',
      'src/src/mapi/glapi/gen/ARB_texture_storage.xml',
      'src/src/mapi/glapi/gen/ARB_depth_buffer_float.xml',
      'src/src/mapi/glapi/gen/EXT_separate_shader_objects.xml',
      'src/src/mapi/glapi/gen/ARB_texture_compression_rgtc.xml',
      'src/src/mapi/glapi/gen/NV_conditional_render.xml',
      'src/src/mesa/main/APIspec.xml',
    ],
  },

  'targets': [
    # The targets below generate all of the sources Mesa generates
    # during its build process. Mesa's XML processors like gl_XML.py
    # rely heavily on Python's libxml2 bindings. Specifically, the
    # processors require validation against the DTD for default values
    # for attributes, and none of Python's built-in XML parsers support
    # validation. It's infeasible to use any third-party XML parser for
    # Python which relies on native code due to the large number of
    # host platforms Chromium must build on, and pure Python validators
    # are in short supply.

    # The main target is generate_mesa_sources, which must be run
    # manually on a host platform with libxml2's Python bindings
    # installed. (Most Linux distributions should fulfill this
    # requirement.)
    {
      'target_name': 'mesa_builtin_compiler',
      'type': 'executable',
      'include_dirs': [
        'src/src/gallium/auxiliary',
        'src/src/gallium/include',
        'src/src/glsl',
        'src/src/glsl/glcpp',
        'src/src/mapi',
        'src/src/mapi/glapi',
        'src/src/mesa',
        'src/src/mesa/main',
        '<(generated_src_dir)/mesa/',
        '<(generated_src_dir)/mesa/main',
        '<(generated_src_dir)/mesa/program',
        '<(generated_src_dir)/mesa/glapi',
      ],
      'dependencies': [
        'generate_main_mesa_sources',
        'mesa_headers',
        'mesa_libglslcommon', # implicit dependency on generate_main_mesa_sources
      ],
      'variables': {
        'clang_warning_flags': [
          '-Wno-tautological-constant-out-of-range-compare',
        ],
        'clang_warning_flags_unset': [
          # Don't warn about string->bool used in asserts.
          '-Wstring-conversion',
        ],
      },
      'sources': [
        'src/src/mesa/program/hash_table.c',
        'src/src/mesa/program/symbol_table.c',
        'src/src/glsl/standalone_scaffolding.cpp',
        'src/src/glsl/main.cpp',
        'src/src/glsl/builtin_stubs.cpp',
      ],
    },
    {
      'target_name': 'generate_mesa_sources',
      'type': 'none',
      'dependencies': [
        'mesa_builtin_compiler',
      ],
      'actions': [
        {
          'action_name': 'generateBuiltins',
          'inputs': [
            '<(PRODUCT_DIR)/mesa_builtin_compiler',
            'src/src/glsl/builtins/tools/generate_builtins.py'
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/builtin_function.cpp',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/builtin_function.cpp',
            'src/src/glsl/builtins/tools/generate_builtins.py',
            '<(PRODUCT_DIR)/mesa_builtin_compiler',
          ],
          'message': "Generating Mesa builtins ...",
        }
      ],
    },
    {
      'target_name': 'generate_main_mesa_sources',
      'type': 'none',
      'actions': [
        {
          'action_name': 'glsl_parser_cc',
          'inputs': [
            'src/src/glsl/glsl_parser.yy',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glsl_parser.cc',
            '<(generated_src_dir)/mesa/glsl_parser.h',
          ],
          'action': [
            'bison',
            '-y',
            '-v',
            '-o',
            '<(generated_src_dir)/mesa/glsl_parser.cc',
            '-p',
            '_mesa_glsl_',
            '--defines=<(generated_src_dir)/mesa/glsl_parser.h',
            'src/src/glsl/glsl_parser.yy'
          ],
          'message': "Generating glsl parser ...",
        },
        {
          'action_name': 'lex_yy_c',
          'inputs': [
            'src/src/mesa/program/program_lexer.l',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/lex.yy.c',
          ],
          'action': [
            'flex',
            '--never-interactive',
            '--outfile=<(generated_src_dir)/mesa/lex.yy.c',
            'src/src/mesa/program/program_lexer.l'
          ],
          'message': "Generating lex.yy.c ...",
        },
        {
          'action_name': 'glsl_lexer_cc',
          'inputs': [
            'src/src/glsl/glsl_lexer.ll',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glsl_lexer.cc',
          ],
          'action': [
            'flex',
            '--nounistd',
            '--outfile=<(generated_src_dir)/mesa/glsl_lexer.cc',
            'src/src/glsl/glsl_lexer.ll',
          ],
          'message': "Generating glsl lexer ...",
        },
        {
          'action_name': 'glcpp_lex_c',
          'inputs': [
            'src/src/glsl/glcpp/glcpp-lex.l',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glcpp-lex.c',
          ],
          'action': [
            'flex',
            '--nounistd',
            '--outfile=<(generated_src_dir)/mesa/glcpp-lex.c',
            'src/src/glsl/glcpp/glcpp-lex.l',
          ],
          'message': "Generating glcpp-lex.c ...",
        },
        {
          'action_name': 'glcpp_parse_c',
          'inputs': [
            'src/src/glsl/glcpp/glcpp-parse.y',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glcpp-parse.c',
            '<(generated_src_dir)/mesa/glcpp-parse.h',
          ],
          'action': [
            'bison',
            '-y',
            '-v',
            '-d',
            '-p',
            'glcpp_parser_',
            '-o',
            '<(generated_src_dir)/mesa/glcpp-parse.c',
            '--defines=<(generated_src_dir)/mesa/glcpp-parse.h',
            'src/src/glsl/glcpp/glcpp-parse.y',
          ],
          'message': "Generating glcpp parser ...",
        },
        {
          'action_name': 'program_parse_tab_c',
          'inputs': [
            'src/src/mesa/program/program_parse.y',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/program/program_parse.tab.c',
          ],
          'action': [
            'bison',
            '-y',
            '-v',
            '-d',
            '-p',
            '_mesa_program_',
            '--output=<(generated_src_dir)/mesa/program/program_parse.tab.c',
            'src/src/mesa/program/program_parse.y',
          ],
          'message': "Generating program_parse.y ...",
        },
        {
          'action_name': 'glapi_mapi_tmp_h',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/mapi/mapi_abi.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glapi_mapi_tmp.h',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/glapi_mapi_tmp.h',
            'src/src/mapi/mapi/mapi_abi.py',
            '--printer',
            'glapi',
            '--mode',
            'lib',
            'src/src/mapi/glapi/gen/gl_and_es_API.xml',
          ],
          'message': "Generating glapi_mapi_tmp.h ...",
        },
        {
          'action_name': 'glapi_mapi_tmp_shared_h',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/mapi/mapi_abi.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glapi_mapi_tmp_shared.h',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/glapi_mapi_tmp_shared.h',
            'src/src/mapi/mapi/mapi_abi.py',
            '--printer',
            'shared-glapi',
            '--mode',
            'lib',
            'src/src/mapi/glapi/gen/gl_and_es_API.xml',
          ],
          'message': "Generating glapi_mapi_tmp_shared.h ...",
        },
        {
          'action_name': 'glprocs_h',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/gl_procs.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glprocs.h',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/glprocs.h',
            'src/src/mapi/glapi/gen/gl_procs.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
          ],
          'message': "Generating glprocs.h ...",
        },
        {
          'action_name': 'glapitemp_h',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/gl_apitemp.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glapi/glapitemp.h',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/glapi/glapitemp.h',
            'src/src/mapi/glapi/gen/gl_apitemp.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
          ],
          'message': "Generating glapitemp.h ...",
        },
        {
          'action_name': 'glapitable_h',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/gl_table.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glapi/glapitable.h',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/glapi/glapitable.h',
            'src/src/mapi/glapi/gen/gl_table.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
          ],
          'message': "Generating glapitable.h ...",
        },
        {
          'action_name': 'glapi_gentable_c',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/gl_gentable.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glapi_gentable.c',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/glapi_gentable.c',
            'src/src/mapi/glapi/gen/gl_gentable.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
          ],
          'message': "Generating glapi_gentable.c ...",
        },
        {
          'action_name': 'glapi_x86_64_S',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/gl_x86-64_asm.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/glapi_x86-64.S',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/glapi_x86-64.S',
            'src/src/mapi/glapi/gen/gl_x86-64_asm.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
          ],
          'message': "Generating glapi_x86-64.S ...",
        },
        {
          'action_name': 'enums_c',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/gl_enums.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/enums.c',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/enums.c',
            'src/src/mapi/glapi/gen/gl_enums.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_and_es_API.xml',
          ],
          'message': "Generating enums.c ...",
        },
        {
          'action_name': 'dispatch_h',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/gl_table.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/main/dispatch.h',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/main/dispatch.h',
            'src/src/mapi/glapi/gen/gl_table.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
            '-m',
            'remap_table',
          ],
          'message': "Generating dispatch.h ...",
        },
        {
          'action_name': 'remap_helper_h',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/remap_helper.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/main/remap_helper.h',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/main/remap_helper.h',
            'src/src/mapi/glapi/gen/remap_helper.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
          ],
          'message': "Generating remap_helper.h ...",
        },
        {
          'action_name': 'indirect_c',
          'inputs': [
            '<@(xmlfiles)',
            'src/src/mapi/glapi/gen/glX_proto_send.py',
            'redirectoutput.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/indirect.c',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/indirect.c',
            'src/src/mapi/glapi/gen/glX_proto_send.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
            '-m',
            'proto',
          ],
          'message': "Generating indirect.c ...",
        },
        {
          'action_name': 'indirect_h',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/glX_proto_send.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/indirect.h',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/indirect.h',
            'src/src/mapi/glapi/gen/glX_proto_send.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
            '-m',
            'init_h',
          ],
          'message': "Generating indirect.h ...",
        },
        {
          'action_name': 'indirect_init_c',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/glX_proto_send.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/indirect_init.c',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/indirect_init.c',
            'src/src/mapi/glapi/gen/glX_proto_send.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
            '-m',
            'init_c',
          ],
          'message': "Generating indirect_init.c ...",
        },
        {
          'action_name': 'indirect_size_h',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/glX_proto_size.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/indirect_size.h',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/indirect_size.h',
            'src/src/mapi/glapi/gen/glX_proto_size.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
            '-m',
            'size_h',
            '--only-set',
            '-h',
            '_INDIRECT_SIZE_H_',
          ],
          'message': "Generating indirect_size.h ...",
        },
        {
          'action_name': 'indirect_size_c',
          'inputs': [
            '<@(xmlfiles)',
            'redirectoutput.py',
            'src/src/mapi/glapi/gen/glX_proto_size.py',
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/indirect_size.c',
          ],
          'action': [
            'python',
            'redirectoutput.py',
            '<(generated_src_dir)/mesa/indirect_size.c',
            'src/src/mapi/glapi/gen/glX_proto_size.py',
            '-f',
            'src/src/mapi/glapi/gen/gl_API.xml',
            '-m',
            'size_c',
            '--only-set',
          ],
          'message': "Generating indirect_size.c ...",
        },
        {
          'action_name': 'git_sha1_h',
          'inputs': [
          ],
          'outputs': [
            '<(generated_src_dir)/mesa/git_sha1.h',
          ],
          'action': [
            'python',
            'generate_git_sha1.py',
            '<(generated_src_dir)/mesa/git_sha1.h',
          ],
          'message': "Generating Mesa sources ...",
        },
      ],
    },
  ],
}
