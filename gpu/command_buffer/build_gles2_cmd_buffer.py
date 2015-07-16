#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""code generator for GLES2 command buffers."""

import itertools
import os
import os.path
import sys
import re
import platform
from optparse import OptionParser
from subprocess import call

_SIZE_OF_UINT32 = 4
_SIZE_OF_COMMAND_HEADER = 4
_FIRST_SPECIFIC_COMMAND_ID = 256

_LICENSE = """// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

"""

_DO_NOT_EDIT_WARNING = """// This file is auto-generated from
// gpu/command_buffer/build_gles2_cmd_buffer.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

"""

# This string is copied directly out of the gl2.h file from GLES2.0
#
# Edits:
#
# *) Any argument that is a resourceID has been changed to GLid<Type>.
#    (not pointer arguments) and if it's allowed to be zero it's GLidZero<Type>
#    If it's allowed to not exist it's GLidBind<Type>
#
# *) All GLenums have been changed to GLenumTypeOfEnum
#
_GL_TYPES = {
  'GLenum': 'unsigned int',
  'GLboolean': 'unsigned char',
  'GLbitfield': 'unsigned int',
  'GLbyte': 'signed char',
  'GLshort': 'short',
  'GLint': 'int',
  'GLsizei': 'int',
  'GLubyte': 'unsigned char',
  'GLushort': 'unsigned short',
  'GLuint': 'unsigned int',
  'GLfloat': 'float',
  'GLclampf': 'float',
  'GLvoid': 'void',
  'GLfixed': 'int',
  'GLclampx': 'int'
}

_GL_TYPES_32 = {
  'GLintptr': 'long int',
  'GLsizeiptr': 'long int'
}

_GL_TYPES_64 = {
  'GLintptr': 'long long int',
  'GLsizeiptr': 'long long int'
}

# Capabilites selected with glEnable
_CAPABILITY_FLAGS = [
  {'name': 'blend'},
  {'name': 'cull_face'},
  {'name': 'depth_test', 'state_flag': 'framebuffer_state_.clear_state_dirty'},
  {'name': 'dither', 'default': True},
  {'name': 'polygon_offset_fill'},
  {'name': 'sample_alpha_to_coverage'},
  {'name': 'sample_coverage'},
  {'name': 'scissor_test'},
  {'name': 'stencil_test',
   'state_flag': 'framebuffer_state_.clear_state_dirty'},
  {'name': 'rasterizer_discard', 'es3': True},
  {'name': 'primitive_restart_fixed_index', 'es3': True},
]

_STATES = {
  'ClearColor': {
    'type': 'Normal',
    'func': 'ClearColor',
    'enum': 'GL_COLOR_CLEAR_VALUE',
    'states': [
      {'name': 'color_clear_red', 'type': 'GLfloat', 'default': '0.0f'},
      {'name': 'color_clear_green', 'type': 'GLfloat', 'default': '0.0f'},
      {'name': 'color_clear_blue', 'type': 'GLfloat', 'default': '0.0f'},
      {'name': 'color_clear_alpha', 'type': 'GLfloat', 'default': '0.0f'},
    ],
  },
  'ClearDepthf': {
    'type': 'Normal',
    'func': 'ClearDepth',
    'enum': 'GL_DEPTH_CLEAR_VALUE',
    'states': [
      {'name': 'depth_clear', 'type': 'GLclampf', 'default': '1.0f'},
    ],
  },
  'ColorMask': {
    'type': 'Normal',
    'func': 'ColorMask',
    'enum': 'GL_COLOR_WRITEMASK',
    'states': [
      {
        'name': 'color_mask_red',
        'type': 'GLboolean',
        'default': 'true',
        'cached': True
      },
      {
        'name': 'color_mask_green',
        'type': 'GLboolean',
        'default': 'true',
        'cached': True
      },
      {
        'name': 'color_mask_blue',
        'type': 'GLboolean',
        'default': 'true',
        'cached': True
      },
      {
        'name': 'color_mask_alpha',
        'type': 'GLboolean',
        'default': 'true',
        'cached': True
      },
    ],
    'state_flag': 'framebuffer_state_.clear_state_dirty',
  },
  'ClearStencil': {
    'type': 'Normal',
    'func': 'ClearStencil',
    'enum': 'GL_STENCIL_CLEAR_VALUE',
    'states': [
      {'name': 'stencil_clear', 'type': 'GLint', 'default': '0'},
    ],
  },
  'BlendColor': {
    'type': 'Normal',
    'func': 'BlendColor',
    'enum': 'GL_BLEND_COLOR',
    'states': [
      {'name': 'blend_color_red', 'type': 'GLfloat', 'default': '0.0f'},
      {'name': 'blend_color_green', 'type': 'GLfloat', 'default': '0.0f'},
      {'name': 'blend_color_blue', 'type': 'GLfloat', 'default': '0.0f'},
      {'name': 'blend_color_alpha', 'type': 'GLfloat', 'default': '0.0f'},
    ],
  },
  'BlendEquation': {
    'type': 'SrcDst',
    'func': 'BlendEquationSeparate',
    'states': [
      {
        'name': 'blend_equation_rgb',
        'type': 'GLenum',
        'enum': 'GL_BLEND_EQUATION_RGB',
        'default': 'GL_FUNC_ADD',
      },
      {
        'name': 'blend_equation_alpha',
        'type': 'GLenum',
        'enum': 'GL_BLEND_EQUATION_ALPHA',
        'default': 'GL_FUNC_ADD',
      },
    ],
  },
  'BlendFunc': {
    'type': 'SrcDst',
    'func': 'BlendFuncSeparate',
    'states': [
      {
        'name': 'blend_source_rgb',
        'type': 'GLenum',
        'enum': 'GL_BLEND_SRC_RGB',
        'default': 'GL_ONE',
      },
      {
        'name': 'blend_dest_rgb',
        'type': 'GLenum',
        'enum': 'GL_BLEND_DST_RGB',
        'default': 'GL_ZERO',
      },
      {
        'name': 'blend_source_alpha',
        'type': 'GLenum',
        'enum': 'GL_BLEND_SRC_ALPHA',
        'default': 'GL_ONE',
      },
      {
        'name': 'blend_dest_alpha',
        'type': 'GLenum',
        'enum': 'GL_BLEND_DST_ALPHA',
        'default': 'GL_ZERO',
      },
    ],
  },
  'PolygonOffset': {
    'type': 'Normal',
    'func': 'PolygonOffset',
    'states': [
      {
        'name': 'polygon_offset_factor',
        'type': 'GLfloat',
        'enum': 'GL_POLYGON_OFFSET_FACTOR',
        'default': '0.0f',
      },
      {
        'name': 'polygon_offset_units',
        'type': 'GLfloat',
        'enum': 'GL_POLYGON_OFFSET_UNITS',
        'default': '0.0f',
      },
    ],
  },
  'CullFace':  {
    'type': 'Normal',
    'func': 'CullFace',
    'enum': 'GL_CULL_FACE_MODE',
    'states': [
      {
        'name': 'cull_mode',
        'type': 'GLenum',
        'default': 'GL_BACK',
      },
    ],
  },
  'FrontFace': {
    'type': 'Normal',
    'func': 'FrontFace',
    'enum': 'GL_FRONT_FACE',
    'states': [{'name': 'front_face', 'type': 'GLenum', 'default': 'GL_CCW'}],
  },
  'DepthFunc': {
    'type': 'Normal',
    'func': 'DepthFunc',
    'enum': 'GL_DEPTH_FUNC',
    'states': [{'name': 'depth_func', 'type': 'GLenum', 'default': 'GL_LESS'}],
  },
  'DepthRange': {
    'type': 'Normal',
    'func': 'DepthRange',
    'enum': 'GL_DEPTH_RANGE',
    'states': [
      {'name': 'z_near', 'type': 'GLclampf', 'default': '0.0f'},
      {'name': 'z_far', 'type': 'GLclampf', 'default': '1.0f'},
    ],
  },
  'SampleCoverage': {
    'type': 'Normal',
    'func': 'SampleCoverage',
    'states': [
      {
        'name': 'sample_coverage_value',
        'type': 'GLclampf',
        'enum': 'GL_SAMPLE_COVERAGE_VALUE',
        'default': '1.0f',
      },
      {
        'name': 'sample_coverage_invert',
        'type': 'GLboolean',
        'enum': 'GL_SAMPLE_COVERAGE_INVERT',
        'default': 'false',
      },
    ],
  },
  'StencilMask': {
    'type': 'FrontBack',
    'func': 'StencilMaskSeparate',
    'state_flag': 'framebuffer_state_.clear_state_dirty',
    'states': [
      {
        'name': 'stencil_front_writemask',
        'type': 'GLuint',
        'enum': 'GL_STENCIL_WRITEMASK',
        'default': '0xFFFFFFFFU',
        'cached': True,
      },
      {
        'name': 'stencil_back_writemask',
        'type': 'GLuint',
        'enum': 'GL_STENCIL_BACK_WRITEMASK',
        'default': '0xFFFFFFFFU',
        'cached': True,
      },
    ],
  },
  'StencilOp': {
    'type': 'FrontBack',
    'func': 'StencilOpSeparate',
    'states': [
      {
        'name': 'stencil_front_fail_op',
        'type': 'GLenum',
        'enum': 'GL_STENCIL_FAIL',
        'default': 'GL_KEEP',
      },
      {
        'name': 'stencil_front_z_fail_op',
        'type': 'GLenum',
        'enum': 'GL_STENCIL_PASS_DEPTH_FAIL',
        'default': 'GL_KEEP',
      },
      {
        'name': 'stencil_front_z_pass_op',
        'type': 'GLenum',
        'enum': 'GL_STENCIL_PASS_DEPTH_PASS',
        'default': 'GL_KEEP',
      },
      {
        'name': 'stencil_back_fail_op',
        'type': 'GLenum',
        'enum': 'GL_STENCIL_BACK_FAIL',
        'default': 'GL_KEEP',
      },
      {
        'name': 'stencil_back_z_fail_op',
        'type': 'GLenum',
        'enum': 'GL_STENCIL_BACK_PASS_DEPTH_FAIL',
        'default': 'GL_KEEP',
      },
      {
        'name': 'stencil_back_z_pass_op',
        'type': 'GLenum',
        'enum': 'GL_STENCIL_BACK_PASS_DEPTH_PASS',
        'default': 'GL_KEEP',
      },
    ],
  },
  'StencilFunc': {
    'type': 'FrontBack',
    'func': 'StencilFuncSeparate',
    'states': [
      {
        'name': 'stencil_front_func',
        'type': 'GLenum',
        'enum': 'GL_STENCIL_FUNC',
        'default': 'GL_ALWAYS',
      },
      {
        'name': 'stencil_front_ref',
        'type': 'GLint',
        'enum': 'GL_STENCIL_REF',
        'default': '0',
      },
      {
        'name': 'stencil_front_mask',
        'type': 'GLuint',
        'enum': 'GL_STENCIL_VALUE_MASK',
        'default': '0xFFFFFFFFU',
      },
      {
        'name': 'stencil_back_func',
        'type': 'GLenum',
        'enum': 'GL_STENCIL_BACK_FUNC',
        'default': 'GL_ALWAYS',
      },
      {
        'name': 'stencil_back_ref',
        'type': 'GLint',
        'enum': 'GL_STENCIL_BACK_REF',
        'default': '0',
      },
      {
        'name': 'stencil_back_mask',
        'type': 'GLuint',
        'enum': 'GL_STENCIL_BACK_VALUE_MASK',
        'default': '0xFFFFFFFFU',
      },
    ],
  },
  'Hint': {
    'type': 'NamedParameter',
    'func': 'Hint',
    'states': [
      {
        'name': 'hint_generate_mipmap',
        'type': 'GLenum',
        'enum': 'GL_GENERATE_MIPMAP_HINT',
        'default': 'GL_DONT_CARE'
      },
      {
        'name': 'hint_fragment_shader_derivative',
        'type': 'GLenum',
        'enum': 'GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES',
        'default': 'GL_DONT_CARE',
        'extension_flag': 'oes_standard_derivatives'
      }
    ],
  },
  'PixelStore': {
    'type': 'NamedParameter',
    'func': 'PixelStorei',
    'states': [
      {
        'name': 'pack_alignment',
        'type': 'GLint',
        'enum': 'GL_PACK_ALIGNMENT',
        'default': '4'
      },
      {
        'name': 'unpack_alignment',
        'type': 'GLint',
        'enum': 'GL_UNPACK_ALIGNMENT',
        'default': '4'
      }
    ],
  },
  # TODO: Consider implemenenting these states
  # GL_ACTIVE_TEXTURE
  'LineWidth': {
    'type': 'Normal',
    'func': 'LineWidth',
    'enum': 'GL_LINE_WIDTH',
    'states': [
      {
        'name': 'line_width',
        'type': 'GLfloat',
        'default': '1.0f',
        'range_checks': [{'check': "<= 0.0f", 'test_value': "0.0f"}],
        'nan_check': True,
      }],
  },
  'DepthMask': {
    'type': 'Normal',
    'func': 'DepthMask',
    'enum': 'GL_DEPTH_WRITEMASK',
    'states': [
      {
        'name': 'depth_mask',
        'type': 'GLboolean',
        'default': 'true',
        'cached': True
      },
    ],
    'state_flag': 'framebuffer_state_.clear_state_dirty',
  },
  'Scissor': {
    'type': 'Normal',
    'func': 'Scissor',
    'enum': 'GL_SCISSOR_BOX',
    'states': [
      # NOTE: These defaults reset at GLES2DecoderImpl::Initialization.
      {
        'name': 'scissor_x',
        'type': 'GLint',
        'default': '0',
        'expected': 'kViewportX',
      },
      {
        'name': 'scissor_y',
        'type': 'GLint',
        'default': '0',
        'expected': 'kViewportY',
      },
      {
        'name': 'scissor_width',
        'type': 'GLsizei',
        'default': '1',
        'expected': 'kViewportWidth',
      },
      {
        'name': 'scissor_height',
        'type': 'GLsizei',
        'default': '1',
        'expected': 'kViewportHeight',
      },
    ],
  },
  'Viewport': {
    'type': 'Normal',
    'func': 'Viewport',
    'enum': 'GL_VIEWPORT',
    'states': [
      # NOTE: These defaults reset at GLES2DecoderImpl::Initialization.
      {
        'name': 'viewport_x',
        'type': 'GLint',
        'default': '0',
        'expected': 'kViewportX',
      },
      {
        'name': 'viewport_y',
        'type': 'GLint',
        'default': '0',
        'expected': 'kViewportY',
      },
      {
        'name': 'viewport_width',
        'type': 'GLsizei',
        'default': '1',
        'expected': 'kViewportWidth',
      },
      {
        'name': 'viewport_height',
        'type': 'GLsizei',
        'default': '1',
        'expected': 'kViewportHeight',
      },
    ],
  },
  'MatrixValuesCHROMIUM': {
    'type': 'NamedParameter',
    'func': 'MatrixLoadfEXT',
    'states': [
      { 'enum': 'GL_PATH_MODELVIEW_MATRIX_CHROMIUM',
        'enum_set': 'GL_PATH_MODELVIEW_CHROMIUM',
        'name': 'modelview_matrix',
        'type': 'GLfloat',
        'default': [
          '1.0f', '0.0f','0.0f','0.0f',
          '0.0f', '1.0f','0.0f','0.0f',
          '0.0f', '0.0f','1.0f','0.0f',
          '0.0f', '0.0f','0.0f','1.0f',
        ],
        'extension_flag': 'chromium_path_rendering',
      },
      { 'enum': 'GL_PATH_PROJECTION_MATRIX_CHROMIUM',
        'enum_set': 'GL_PATH_PROJECTION_CHROMIUM',
        'name': 'projection_matrix',
        'type': 'GLfloat',
        'default': [
          '1.0f', '0.0f','0.0f','0.0f',
          '0.0f', '1.0f','0.0f','0.0f',
          '0.0f', '0.0f','1.0f','0.0f',
          '0.0f', '0.0f','0.0f','1.0f',
        ],
        'extension_flag': 'chromium_path_rendering',
      },
    ],
  },
}

# Named type info object represents a named type that is used in OpenGL call
# arguments.  Each named type defines a set of valid OpenGL call arguments.  The
# named types are used in 'cmd_buffer_functions.txt'.
# type: The actual GL type of the named type.
# valid: The list of values that are valid for both the client and the service.
# valid_es3: The list of values that are valid in OpenGL ES 3, but not ES 2.
# invalid: Examples of invalid values for the type. At least these values
#          should be tested to be invalid.
# deprecated_es3: The list of values that are valid in OpenGL ES 2, but
#                 deprecated in ES 3.
# is_complete: The list of valid values of type are final and will not be
#              modified during runtime.
_NAMED_TYPE_INFO = {
  'BlitFilter': {
    'type': 'GLenum',
    'valid': [
      'GL_NEAREST',
      'GL_LINEAR',
    ],
    'invalid': [
      'GL_LINEAR_MIPMAP_LINEAR',
    ],
  },
  'FrameBufferTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_FRAMEBUFFER',
    ],
    'invalid': [
      'GL_DRAW_FRAMEBUFFER' ,
      'GL_READ_FRAMEBUFFER' ,
    ],
  },
  'RenderBufferTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_RENDERBUFFER',
    ],
    'invalid': [
      'GL_FRAMEBUFFER',
    ],
  },
  'BufferTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_ARRAY_BUFFER',
      'GL_ELEMENT_ARRAY_BUFFER',
    ],
    'valid_es3': [
      'GL_COPY_READ_BUFFER',
      'GL_COPY_WRITE_BUFFER',
      'GL_PIXEL_PACK_BUFFER',
      'GL_PIXEL_UNPACK_BUFFER',
      'GL_TRANSFORM_FEEDBACK_BUFFER',
      'GL_UNIFORM_BUFFER',
    ],
    'invalid': [
      'GL_RENDERBUFFER',
    ],
  },
  'IndexedBufferTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_TRANSFORM_FEEDBACK_BUFFER',
      'GL_UNIFORM_BUFFER',
    ],
    'invalid': [
      'GL_RENDERBUFFER',
    ],
  },
  'MapBufferAccess': {
    'type': 'GLenum',
    'valid': [
      'GL_MAP_READ_BIT',
      'GL_MAP_WRITE_BIT',
      'GL_MAP_INVALIDATE_RANGE_BIT',
      'GL_MAP_INVALIDATE_BUFFER_BIT',
      'GL_MAP_FLUSH_EXPLICIT_BIT',
      'GL_MAP_UNSYNCHRONIZED_BIT',
    ],
    'invalid': [
      'GL_SYNC_FLUSH_COMMANDS_BIT',
    ],
  },
  'Bufferiv': {
    'type': 'GLenum',
    'valid': [
      'GL_COLOR',
      'GL_STENCIL',
    ],
    'invalid': [
      'GL_RENDERBUFFER',
    ],
  },
  'Bufferuiv': {
    'type': 'GLenum',
    'valid': [
      'GL_COLOR',
    ],
    'invalid': [
      'GL_RENDERBUFFER',
    ],
  },
  'Bufferfv': {
    'type': 'GLenum',
    'valid': [
      'GL_COLOR',
      'GL_DEPTH',
    ],
    'invalid': [
      'GL_RENDERBUFFER',
    ],
  },
  'Bufferfi': {
    'type': 'GLenum',
    'valid': [
      'GL_DEPTH_STENCIL',
    ],
    'invalid': [
      'GL_RENDERBUFFER',
    ],
  },
  'BufferUsage': {
    'type': 'GLenum',
    'valid': [
      'GL_STREAM_DRAW',
      'GL_STATIC_DRAW',
      'GL_DYNAMIC_DRAW',
    ],
    'invalid': [
      'GL_STATIC_READ',
    ],
  },
  'CompressedTextureFormat': {
    'type': 'GLenum',
    'valid': [
    ],
  },
  'GLState': {
    'type': 'GLenum',
    'valid': [
      # NOTE: State an Capability entries added later.
      'GL_ACTIVE_TEXTURE',
      'GL_ALIASED_LINE_WIDTH_RANGE',
      'GL_ALIASED_POINT_SIZE_RANGE',
      'GL_ALPHA_BITS',
      'GL_ARRAY_BUFFER_BINDING',
      'GL_BLUE_BITS',
      'GL_COMPRESSED_TEXTURE_FORMATS',
      'GL_CURRENT_PROGRAM',
      'GL_DEPTH_BITS',
      'GL_DEPTH_RANGE',
      'GL_ELEMENT_ARRAY_BUFFER_BINDING',
      'GL_FRAMEBUFFER_BINDING',
      'GL_GENERATE_MIPMAP_HINT',
      'GL_GREEN_BITS',
      'GL_IMPLEMENTATION_COLOR_READ_FORMAT',
      'GL_IMPLEMENTATION_COLOR_READ_TYPE',
      'GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS',
      'GL_MAX_CUBE_MAP_TEXTURE_SIZE',
      'GL_MAX_FRAGMENT_UNIFORM_VECTORS',
      'GL_MAX_RENDERBUFFER_SIZE',
      'GL_MAX_TEXTURE_IMAGE_UNITS',
      'GL_MAX_TEXTURE_SIZE',
      'GL_MAX_VARYING_VECTORS',
      'GL_MAX_VERTEX_ATTRIBS',
      'GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS',
      'GL_MAX_VERTEX_UNIFORM_VECTORS',
      'GL_MAX_VIEWPORT_DIMS',
      'GL_NUM_COMPRESSED_TEXTURE_FORMATS',
      'GL_NUM_SHADER_BINARY_FORMATS',
      'GL_PACK_ALIGNMENT',
      'GL_RED_BITS',
      'GL_RENDERBUFFER_BINDING',
      'GL_SAMPLE_BUFFERS',
      'GL_SAMPLE_COVERAGE_INVERT',
      'GL_SAMPLE_COVERAGE_VALUE',
      'GL_SAMPLES',
      'GL_SCISSOR_BOX',
      'GL_SHADER_BINARY_FORMATS',
      'GL_SHADER_COMPILER',
      'GL_SUBPIXEL_BITS',
      'GL_STENCIL_BITS',
      'GL_TEXTURE_BINDING_2D',
      'GL_TEXTURE_BINDING_CUBE_MAP',
      'GL_UNPACK_ALIGNMENT',
      'GL_UNPACK_FLIP_Y_CHROMIUM',
      'GL_UNPACK_PREMULTIPLY_ALPHA_CHROMIUM',
      'GL_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM',
      'GL_BIND_GENERATES_RESOURCE_CHROMIUM',
      # we can add this because we emulate it if the driver does not support it.
      'GL_VERTEX_ARRAY_BINDING_OES',
      'GL_VIEWPORT',
    ],
    'valid_es3': [
      'GL_COPY_READ_BUFFER_BINDING',
      'GL_COPY_WRITE_BUFFER_BINDING',
      'GL_DRAW_BUFFER0',
      'GL_DRAW_BUFFER1',
      'GL_DRAW_BUFFER2',
      'GL_DRAW_BUFFER3',
      'GL_DRAW_BUFFER4',
      'GL_DRAW_BUFFER5',
      'GL_DRAW_BUFFER6',
      'GL_DRAW_BUFFER7',
      'GL_DRAW_BUFFER8',
      'GL_DRAW_BUFFER9',
      'GL_DRAW_BUFFER10',
      'GL_DRAW_BUFFER11',
      'GL_DRAW_BUFFER12',
      'GL_DRAW_BUFFER13',
      'GL_DRAW_BUFFER14',
      'GL_DRAW_BUFFER15',
      'GL_DRAW_FRAMEBUFFER_BINDING',
      'GL_FRAGMENT_SHADER_DERIVATIVE_HINT',
      'GL_MAJOR_VERSION',
      'GL_MAX_3D_TEXTURE_SIZE',
      'GL_MAX_ARRAY_TEXTURE_LAYERS',
      'GL_MAX_COLOR_ATTACHMENTS',
      'GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS',
      'GL_MAX_COMBINED_UNIFORM_BLOCKS',
      'GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS',
      'GL_MAX_DRAW_BUFFERS',
      'GL_MAX_ELEMENT_INDEX',
      'GL_MAX_ELEMENTS_INDICES',
      'GL_MAX_ELEMENTS_VERTICES',
      'GL_MAX_FRAGMENT_INPUT_COMPONENTS',
      'GL_MAX_FRAGMENT_UNIFORM_BLOCKS',
      'GL_MAX_FRAGMENT_UNIFORM_COMPONENTS',
      'GL_MAX_PROGRAM_TEXEL_OFFSET',
      'GL_MAX_SAMPLES',
      'GL_MAX_SERVER_WAIT_TIMEOUT',
      'GL_MAX_TEXTURE_LOD_BIAS',
      'GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS',
      'GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS',
      'GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS',
      'GL_MAX_UNIFORM_BLOCK_SIZE',
      'GL_MAX_UNIFORM_BUFFER_BINDINGS',
      'GL_MAX_VARYING_COMPONENTS',
      'GL_MAX_VERTEX_OUTPUT_COMPONENTS',
      'GL_MAX_VERTEX_UNIFORM_BLOCKS',
      'GL_MAX_VERTEX_UNIFORM_COMPONENTS',
      'GL_MIN_PROGRAM_TEXEL_OFFSET',
      'GL_MINOR_VERSION',
      'GL_NUM_EXTENSIONS',
      'GL_NUM_PROGRAM_BINARY_FORMATS',
      'GL_PACK_ROW_LENGTH',
      'GL_PACK_SKIP_PIXELS',
      'GL_PACK_SKIP_ROWS',
      'GL_PIXEL_PACK_BUFFER_BINDING',
      'GL_PIXEL_UNPACK_BUFFER_BINDING',
      'GL_PROGRAM_BINARY_FORMATS',
      'GL_READ_BUFFER',
      'GL_READ_FRAMEBUFFER_BINDING',
      'GL_SAMPLER_BINDING',
      'GL_TEXTURE_BINDING_2D_ARRAY',
      'GL_TEXTURE_BINDING_3D',
      'GL_TRANSFORM_FEEDBACK_BINDING',
      'GL_TRANSFORM_FEEDBACK_ACTIVE',
      'GL_TRANSFORM_FEEDBACK_BUFFER_BINDING',
      'GL_TRANSFORM_FEEDBACK_PAUSED',
      'GL_TRANSFORM_FEEDBACK_BUFFER_SIZE',
      'GL_TRANSFORM_FEEDBACK_BUFFER_START',
      'GL_UNIFORM_BUFFER_BINDING',
      'GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT',
      'GL_UNIFORM_BUFFER_SIZE',
      'GL_UNIFORM_BUFFER_START',
      'GL_UNPACK_IMAGE_HEIGHT',
      'GL_UNPACK_ROW_LENGTH',
      'GL_UNPACK_SKIP_IMAGES',
      'GL_UNPACK_SKIP_PIXELS',
      'GL_UNPACK_SKIP_ROWS',
      # GL_VERTEX_ARRAY_BINDING is the same as GL_VERTEX_ARRAY_BINDING_OES
      # 'GL_VERTEX_ARRAY_BINDING',
    ],
    'invalid': [
      'GL_FOG_HINT',
    ],
  },
  'IndexedGLState': {
    'type': 'GLenum',
    'valid': [
      'GL_TRANSFORM_FEEDBACK_BUFFER_BINDING',
      'GL_TRANSFORM_FEEDBACK_BUFFER_SIZE',
      'GL_TRANSFORM_FEEDBACK_BUFFER_START',
      'GL_UNIFORM_BUFFER_BINDING',
      'GL_UNIFORM_BUFFER_SIZE',
      'GL_UNIFORM_BUFFER_START',
    ],
    'invalid': [
      'GL_FOG_HINT',
    ],
  },
  'GetTexParamTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_TEXTURE_2D',
      'GL_TEXTURE_CUBE_MAP',
    ],
    'invalid': [
      'GL_PROXY_TEXTURE_CUBE_MAP',
    ]
  },
  'TextureTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_TEXTURE_2D',
      'GL_TEXTURE_CUBE_MAP_POSITIVE_X',
      'GL_TEXTURE_CUBE_MAP_NEGATIVE_X',
      'GL_TEXTURE_CUBE_MAP_POSITIVE_Y',
      'GL_TEXTURE_CUBE_MAP_NEGATIVE_Y',
      'GL_TEXTURE_CUBE_MAP_POSITIVE_Z',
      'GL_TEXTURE_CUBE_MAP_NEGATIVE_Z',
    ],
    'invalid': [
      'GL_PROXY_TEXTURE_CUBE_MAP',
    ]
  },
  'Texture3DTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_TEXTURE_3D',
      'GL_TEXTURE_2D_ARRAY',
    ],
    'invalid': [
      'GL_TEXTURE_2D',
    ]
  },
  'TextureBindTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_TEXTURE_2D',
      'GL_TEXTURE_CUBE_MAP',
    ],
    'valid_es3': [
      'GL_TEXTURE_3D',
      'GL_TEXTURE_2D_ARRAY',
    ],
    'invalid': [
      'GL_TEXTURE_1D',
      'GL_TEXTURE_3D',
    ],
  },
  'TransformFeedbackBindTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_TRANSFORM_FEEDBACK',
    ],
    'invalid': [
      'GL_TEXTURE_2D',
    ],
  },
  'TransformFeedbackPrimitiveMode': {
    'type': 'GLenum',
    'valid': [
      'GL_POINTS',
      'GL_LINES',
      'GL_TRIANGLES',
    ],
    'invalid': [
      'GL_LINE_LOOP',
    ],
  },
  'ShaderType': {
    'type': 'GLenum',
    'valid': [
      'GL_VERTEX_SHADER',
      'GL_FRAGMENT_SHADER',
    ],
    'invalid': [
      'GL_GEOMETRY_SHADER',
    ],
  },
  'FaceType': {
    'type': 'GLenum',
    'valid': [
      'GL_FRONT',
      'GL_BACK',
      'GL_FRONT_AND_BACK',
    ],
  },
  'FaceMode': {
    'type': 'GLenum',
    'valid': [
      'GL_CW',
      'GL_CCW',
    ],
  },
  'CmpFunction': {
    'type': 'GLenum',
    'valid': [
      'GL_NEVER',
      'GL_LESS',
      'GL_EQUAL',
      'GL_LEQUAL',
      'GL_GREATER',
      'GL_NOTEQUAL',
      'GL_GEQUAL',
      'GL_ALWAYS',
    ],
  },
  'Equation': {
    'type': 'GLenum',
    'valid': [
      'GL_FUNC_ADD',
      'GL_FUNC_SUBTRACT',
      'GL_FUNC_REVERSE_SUBTRACT',
    ],
    'invalid': [
      'GL_MIN',
      'GL_MAX',
    ],
  },
  'SrcBlendFactor': {
    'type': 'GLenum',
    'valid': [
      'GL_ZERO',
      'GL_ONE',
      'GL_SRC_COLOR',
      'GL_ONE_MINUS_SRC_COLOR',
      'GL_DST_COLOR',
      'GL_ONE_MINUS_DST_COLOR',
      'GL_SRC_ALPHA',
      'GL_ONE_MINUS_SRC_ALPHA',
      'GL_DST_ALPHA',
      'GL_ONE_MINUS_DST_ALPHA',
      'GL_CONSTANT_COLOR',
      'GL_ONE_MINUS_CONSTANT_COLOR',
      'GL_CONSTANT_ALPHA',
      'GL_ONE_MINUS_CONSTANT_ALPHA',
      'GL_SRC_ALPHA_SATURATE',
    ],
  },
  'DstBlendFactor': {
    'type': 'GLenum',
    'valid': [
      'GL_ZERO',
      'GL_ONE',
      'GL_SRC_COLOR',
      'GL_ONE_MINUS_SRC_COLOR',
      'GL_DST_COLOR',
      'GL_ONE_MINUS_DST_COLOR',
      'GL_SRC_ALPHA',
      'GL_ONE_MINUS_SRC_ALPHA',
      'GL_DST_ALPHA',
      'GL_ONE_MINUS_DST_ALPHA',
      'GL_CONSTANT_COLOR',
      'GL_ONE_MINUS_CONSTANT_COLOR',
      'GL_CONSTANT_ALPHA',
      'GL_ONE_MINUS_CONSTANT_ALPHA',
    ],
  },
  'Capability': {
    'type': 'GLenum',
    'valid': ["GL_%s" % cap['name'].upper() for cap in _CAPABILITY_FLAGS
        if 'es3' not in cap or cap['es3'] != True],
    'valid_es3': ["GL_%s" % cap['name'].upper() for cap in _CAPABILITY_FLAGS
        if 'es3' in cap and cap['es3'] == True],
    'invalid': [
      'GL_CLIP_PLANE0',
      'GL_POINT_SPRITE',
    ],
  },
  'DrawMode': {
    'type': 'GLenum',
    'valid': [
      'GL_POINTS',
      'GL_LINE_STRIP',
      'GL_LINE_LOOP',
      'GL_LINES',
      'GL_TRIANGLE_STRIP',
      'GL_TRIANGLE_FAN',
      'GL_TRIANGLES',
    ],
    'invalid': [
      'GL_QUADS',
      'GL_POLYGON',
    ],
  },
  'IndexType': {
    'type': 'GLenum',
    'valid': [
      'GL_UNSIGNED_BYTE',
      'GL_UNSIGNED_SHORT',
    ],
    'invalid': [
      'GL_UNSIGNED_INT',
      'GL_INT',
    ],
  },
  'GetMaxIndexType': {
    'type': 'GLenum',
    'valid': [
      'GL_UNSIGNED_BYTE',
      'GL_UNSIGNED_SHORT',
      'GL_UNSIGNED_INT',
    ],
    'invalid': [
      'GL_INT',
    ],
  },
  'Attachment': {
    'type': 'GLenum',
    'valid': [
      'GL_COLOR_ATTACHMENT0',
      'GL_DEPTH_ATTACHMENT',
      'GL_STENCIL_ATTACHMENT',
    ],
  },
  'BackbufferAttachment': {
    'type': 'GLenum',
    'valid': [
      'GL_COLOR_EXT',
      'GL_DEPTH_EXT',
      'GL_STENCIL_EXT',
    ],
  },
  'BufferParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_BUFFER_SIZE',
      'GL_BUFFER_USAGE',
    ],
    'invalid': [
      'GL_PIXEL_PACK_BUFFER',
    ],
  },
  'BufferMode': {
    'type': 'GLenum',
    'valid': [
      'GL_INTERLEAVED_ATTRIBS',
      'GL_SEPARATE_ATTRIBS',
    ],
    'invalid': [
      'GL_PIXEL_PACK_BUFFER',
    ],
  },
  'FrameBufferParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE',
      'GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME',
      'GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL',
      'GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE',
    ],
  },
  'MatrixMode': {
    'type': 'GLenum',
    'valid': [
      'GL_PATH_PROJECTION_CHROMIUM',
      'GL_PATH_MODELVIEW_CHROMIUM',
    ],
  },
  'ProgramParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_DELETE_STATUS',
      'GL_LINK_STATUS',
      'GL_VALIDATE_STATUS',
      'GL_INFO_LOG_LENGTH',
      'GL_ATTACHED_SHADERS',
      'GL_ACTIVE_ATTRIBUTES',
      'GL_ACTIVE_ATTRIBUTE_MAX_LENGTH',
      'GL_ACTIVE_UNIFORMS',
      'GL_ACTIVE_UNIFORM_MAX_LENGTH',
    ],
  },
  'QueryObjectParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_QUERY_RESULT_EXT',
      'GL_QUERY_RESULT_AVAILABLE_EXT',
    ],
  },
  'QueryParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_CURRENT_QUERY_EXT',
    ],
  },
  'QueryTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_ANY_SAMPLES_PASSED_EXT',
      'GL_ANY_SAMPLES_PASSED_CONSERVATIVE_EXT',
      'GL_COMMANDS_ISSUED_CHROMIUM',
      'GL_LATENCY_QUERY_CHROMIUM',
      'GL_ASYNC_PIXEL_UNPACK_COMPLETED_CHROMIUM',
      'GL_ASYNC_PIXEL_PACK_COMPLETED_CHROMIUM',
      'GL_COMMANDS_COMPLETED_CHROMIUM',
    ],
  },
  'RenderBufferParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_RENDERBUFFER_RED_SIZE',
      'GL_RENDERBUFFER_GREEN_SIZE',
      'GL_RENDERBUFFER_BLUE_SIZE',
      'GL_RENDERBUFFER_ALPHA_SIZE',
      'GL_RENDERBUFFER_DEPTH_SIZE',
      'GL_RENDERBUFFER_STENCIL_SIZE',
      'GL_RENDERBUFFER_WIDTH',
      'GL_RENDERBUFFER_HEIGHT',
      'GL_RENDERBUFFER_INTERNAL_FORMAT',
    ],
  },
  'SamplerParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_TEXTURE_MAG_FILTER',
      'GL_TEXTURE_MIN_FILTER',
      'GL_TEXTURE_MIN_LOD',
      'GL_TEXTURE_MAX_LOD',
      'GL_TEXTURE_WRAP_S',
      'GL_TEXTURE_WRAP_T',
      'GL_TEXTURE_WRAP_R',
      'GL_TEXTURE_COMPARE_MODE',
      'GL_TEXTURE_COMPARE_FUNC',
    ],
    'invalid': [
      'GL_GENERATE_MIPMAP',
    ],
  },
  'ShaderParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_SHADER_TYPE',
      'GL_DELETE_STATUS',
      'GL_COMPILE_STATUS',
      'GL_INFO_LOG_LENGTH',
      'GL_SHADER_SOURCE_LENGTH',
      'GL_TRANSLATED_SHADER_SOURCE_LENGTH_ANGLE',
    ],
  },
  'ShaderPrecision': {
    'type': 'GLenum',
    'valid': [
      'GL_LOW_FLOAT',
      'GL_MEDIUM_FLOAT',
      'GL_HIGH_FLOAT',
      'GL_LOW_INT',
      'GL_MEDIUM_INT',
      'GL_HIGH_INT',
    ],
  },
  'StringType': {
    'type': 'GLenum',
    'valid': [
      'GL_VENDOR',
      'GL_RENDERER',
      'GL_VERSION',
      'GL_SHADING_LANGUAGE_VERSION',
      'GL_EXTENSIONS',
    ],
  },
  'TextureParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_TEXTURE_MAG_FILTER',
      'GL_TEXTURE_MIN_FILTER',
      'GL_TEXTURE_POOL_CHROMIUM',
      'GL_TEXTURE_WRAP_S',
      'GL_TEXTURE_WRAP_T',
    ],
    'invalid': [
      'GL_GENERATE_MIPMAP',
    ],
  },
  'TexturePool': {
    'type': 'GLenum',
    'valid': [
      'GL_TEXTURE_POOL_MANAGED_CHROMIUM',
      'GL_TEXTURE_POOL_UNMANAGED_CHROMIUM',
    ],
  },
  'TextureWrapMode': {
    'type': 'GLenum',
    'valid': [
      'GL_CLAMP_TO_EDGE',
      'GL_MIRRORED_REPEAT',
      'GL_REPEAT',
    ],
  },
  'TextureMinFilterMode': {
    'type': 'GLenum',
    'valid': [
      'GL_NEAREST',
      'GL_LINEAR',
      'GL_NEAREST_MIPMAP_NEAREST',
      'GL_LINEAR_MIPMAP_NEAREST',
      'GL_NEAREST_MIPMAP_LINEAR',
      'GL_LINEAR_MIPMAP_LINEAR',
    ],
  },
  'TextureMagFilterMode': {
    'type': 'GLenum',
    'valid': [
      'GL_NEAREST',
      'GL_LINEAR',
    ],
  },
  'TextureUsage': {
    'type': 'GLenum',
    'valid': [
      'GL_NONE',
      'GL_FRAMEBUFFER_ATTACHMENT_ANGLE',
    ],
  },
  'VertexAttribute': {
    'type': 'GLenum',
    'valid': [
      # some enum that the decoder actually passes through to GL needs
      # to be the first listed here since it's used in unit tests.
      'GL_VERTEX_ATTRIB_ARRAY_NORMALIZED',
      'GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING',
      'GL_VERTEX_ATTRIB_ARRAY_ENABLED',
      'GL_VERTEX_ATTRIB_ARRAY_SIZE',
      'GL_VERTEX_ATTRIB_ARRAY_STRIDE',
      'GL_VERTEX_ATTRIB_ARRAY_TYPE',
      'GL_CURRENT_VERTEX_ATTRIB',
    ],
  },
  'VertexPointer': {
    'type': 'GLenum',
    'valid': [
      'GL_VERTEX_ATTRIB_ARRAY_POINTER',
    ],
  },
  'HintTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_GENERATE_MIPMAP_HINT',
    ],
    'invalid': [
      'GL_PERSPECTIVE_CORRECTION_HINT',
    ],
  },
  'HintMode': {
    'type': 'GLenum',
    'valid': [
      'GL_FASTEST',
      'GL_NICEST',
      'GL_DONT_CARE',
    ],
  },
  'PixelStore': {
    'type': 'GLenum',
    'valid': [
      'GL_PACK_ALIGNMENT',
      'GL_UNPACK_ALIGNMENT',
      'GL_UNPACK_FLIP_Y_CHROMIUM',
      'GL_UNPACK_PREMULTIPLY_ALPHA_CHROMIUM',
      'GL_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM',
    ],
    'invalid': [
      'GL_PACK_SWAP_BYTES',
      'GL_UNPACK_SWAP_BYTES',
    ],
  },
  'PixelStoreAlignment': {
    'type': 'GLint',
    'valid': [
      '1',
      '2',
      '4',
      '8',
    ],
    'invalid': [
      '3',
      '9',
    ],
  },
  'ReadPixelFormat': {
    'type': 'GLenum',
    'valid': [
      'GL_ALPHA',
      'GL_RGB',
      'GL_RGBA',
    ],
  },
  'PixelType': {
    'type': 'GLenum',
    'valid': [
      'GL_UNSIGNED_BYTE',
      'GL_UNSIGNED_SHORT_5_6_5',
      'GL_UNSIGNED_SHORT_4_4_4_4',
      'GL_UNSIGNED_SHORT_5_5_5_1',
    ],
    'valid_es3': [
      'GL_BYTE',
      'GL_UNSIGNED_SHORT',
      'GL_SHORT',
      'GL_UNSIGNED_INT',
      'GL_INT',
      'GL_HALF_FLOAT',
      'GL_FLOAT',
      'GL_UNSIGNED_INT_2_10_10_10_REV',
      'GL_UNSIGNED_INT_10F_11F_11F_REV',
      'GL_UNSIGNED_INT_5_9_9_9_REV',
      'GL_UNSIGNED_INT_24_8',
      'GL_FLOAT_32_UNSIGNED_INT_24_8_REV',
    ],
    'invalid': [
      'GL_UNSIGNED_BYTE_3_3_2',
    ],
  },
  'ReadPixelType': {
    'type': 'GLenum',
    'valid': [
      'GL_UNSIGNED_BYTE',
      'GL_UNSIGNED_SHORT_5_6_5',
      'GL_UNSIGNED_SHORT_4_4_4_4',
      'GL_UNSIGNED_SHORT_5_5_5_1',
    ],
    'invalid': [
      'GL_SHORT',
      'GL_INT',
    ],
  },
  'RenderBufferFormat': {
    'type': 'GLenum',
    'valid': [
      'GL_RGBA4',
      'GL_RGB565',
      'GL_RGB5_A1',
      'GL_DEPTH_COMPONENT16',
      'GL_STENCIL_INDEX8',
    ],
  },
  'ShaderBinaryFormat': {
    'type': 'GLenum',
    'valid': [
    ],
  },
  'StencilOp': {
    'type': 'GLenum',
    'valid': [
      'GL_KEEP',
      'GL_ZERO',
      'GL_REPLACE',
      'GL_INCR',
      'GL_INCR_WRAP',
      'GL_DECR',
      'GL_DECR_WRAP',
      'GL_INVERT',
    ],
  },
  'TextureFormat': {
    'type': 'GLenum',
    'valid': [
      'GL_ALPHA',
      'GL_LUMINANCE',
      'GL_LUMINANCE_ALPHA',
      'GL_RGB',
      'GL_RGBA',
    ],
    'valid_es3': [
      'GL_RED',
      'GL_RED_INTEGER',
      'GL_RG',
      'GL_RG_INTEGER',
      'GL_RGB_INTEGER',
      'GL_RGBA_INTEGER',
      'GL_DEPTH_COMPONENT',
      'GL_DEPTH_STENCIL',
    ],
    'invalid': [
      'GL_BGRA',
      'GL_BGR',
    ],
  },
  'TextureInternalFormat': {
    'type': 'GLenum',
    'valid': [
      'GL_ALPHA',
      'GL_LUMINANCE',
      'GL_LUMINANCE_ALPHA',
      'GL_RGB',
      'GL_RGBA',
    ],
    'valid_es3': [
      'GL_R8',
      'GL_R8_SNORM',
      'GL_R16F',
      'GL_R32F',
      'GL_R8UI',
      'GL_R8I',
      'GL_R16UI',
      'GL_R16I',
      'GL_R32UI',
      'GL_R32I',
      'GL_RG8',
      'GL_RG8_SNORM',
      'GL_RG16F',
      'GL_RG32F',
      'GL_RG8UI',
      'GL_RG8I',
      'GL_RG16UI',
      'GL_RG16I',
      'GL_RG32UI',
      'GL_RG32I',
      'GL_RGB8',
      'GL_SRGB8',
      'GL_RGB565',
      'GL_RGB8_SNORM',
      'GL_R11F_G11F_B10F',
      'GL_RGB9_E5',
      'GL_RGB16F',
      'GL_RGB32F',
      'GL_RGB8UI',
      'GL_RGB8I',
      'GL_RGB16UI',
      'GL_RGB16I',
      'GL_RGB32UI',
      'GL_RGB32I',
      'GL_RGBA8',
      'GL_SRGB8_ALPHA8',
      'GL_RGBA8_SNORM',
      'GL_RGB5_A1',
      'GL_RGBA4',
      'GL_RGB10_A2',
      'GL_RGBA16F',
      'GL_RGBA32F',
      'GL_RGBA8UI',
      'GL_RGBA8I',
      'GL_RGB10_A2UI',
      'GL_RGBA16UI',
      'GL_RGBA16I',
      'GL_RGBA32UI',
      'GL_RGBA32I',
      # The DEPTH/STENCIL formats are not supported in CopyTexImage2D.
      # We will reject them dynamically in GPU command buffer.
      'GL_DEPTH_COMPONENT16',
      'GL_DEPTH_COMPONENT24',
      'GL_DEPTH_COMPONENT32F',
      'GL_DEPTH24_STENCIL8',
      'GL_DEPTH32F_STENCIL8',
    ],
    'invalid': [
      'GL_BGRA',
      'GL_BGR',
    ],
  },
  'TextureInternalFormatStorage': {
    'type': 'GLenum',
    'valid': [
      'GL_RGB565',
      'GL_RGBA4',
      'GL_RGB5_A1',
      'GL_ALPHA8_EXT',
      'GL_LUMINANCE8_EXT',
      'GL_LUMINANCE8_ALPHA8_EXT',
      'GL_RGB8_OES',
      'GL_RGBA8_OES',
    ],
    'valid_es3': [
      'GL_R8',
      'GL_R8_SNORM',
      'GL_R16F',
      'GL_R32F',
      'GL_R8UI',
      'GL_R8I',
      'GL_R16UI',
      'GL_R16I',
      'GL_R32UI',
      'GL_R32I',
      'GL_RG8',
      'GL_RG8_SNORM',
      'GL_RG16F',
      'GL_RG32F',
      'GL_RG8UI',
      'GL_RG8I',
      'GL_RG16UI',
      'GL_RG16I',
      'GL_RG32UI',
      'GL_RG32I',
      'GL_SRGB8',
      'GL_RGB8_SNORM',
      'GL_R11F_G11F_B10F',
      'GL_RGB9_E5',
      'GL_RGB16F',
      'GL_RGB32F',
      'GL_RGB8UI',
      'GL_RGB8I',
      'GL_RGB16UI',
      'GL_RGB16I',
      'GL_RGB32UI',
      'GL_RGB32I',
      'GL_SRGB8_ALPHA8',
      'GL_RGBA8_SNORM',
      'GL_RGB10_A2',
      'GL_RGBA16F',
      'GL_RGBA32F',
      'GL_RGBA8UI',
      'GL_RGBA8I',
      'GL_RGB10_A2UI',
      'GL_RGBA16UI',
      'GL_RGBA16I',
      'GL_RGBA32UI',
      'GL_RGBA32I',
      'GL_DEPTH_COMPONENT16',
      'GL_DEPTH_COMPONENT24',
      'GL_DEPTH_COMPONENT32F',
      'GL_DEPTH24_STENCIL8',
      'GL_DEPTH32F_STENCIL8',
      'GL_COMPRESSED_R11_EAC',
      'GL_COMPRESSED_SIGNED_R11_EAC',
      'GL_COMPRESSED_RG11_EAC',
      'GL_COMPRESSED_SIGNED_RG11_EAC',
      'GL_COMPRESSED_RGB8_ETC2',
      'GL_COMPRESSED_SRGB8_ETC2',
      'GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2',
      'GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2',
      'GL_COMPRESSED_RGBA8_ETC2_EAC',
      'GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC',
    ],
    'deprecated_es3': [
      'GL_ALPHA8_EXT',
      'GL_LUMINANCE8_EXT',
      'GL_LUMINANCE8_ALPHA8_EXT',
      'GL_ALPHA16F_EXT',
      'GL_LUMINANCE16F_EXT',
      'GL_LUMINANCE_ALPHA16F_EXT',
      'GL_ALPHA32F_EXT',
      'GL_LUMINANCE32F_EXT',
      'GL_LUMINANCE_ALPHA32F_EXT',
    ],
  },
  'ImageInternalFormat': {
    'type': 'GLenum',
    'valid': [
      'GL_RGB',
      'GL_RGBA',
    ],
  },
  'ImageUsage': {
    'type': 'GLenum',
    'valid': [
      'GL_MAP_CHROMIUM',
      'GL_SCANOUT_CHROMIUM'
    ],
  },
  'ValueBufferTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_SUBSCRIBED_VALUES_BUFFER_CHROMIUM',
    ],
  },
  'SubscriptionTarget': {
    'type': 'GLenum',
    'valid': [
      'GL_MOUSE_POSITION_CHROMIUM',
    ],
  },
  'UniformParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_UNIFORM_SIZE',
      'GL_UNIFORM_TYPE',
      'GL_UNIFORM_NAME_LENGTH',
      'GL_UNIFORM_BLOCK_INDEX',
      'GL_UNIFORM_OFFSET',
      'GL_UNIFORM_ARRAY_STRIDE',
      'GL_UNIFORM_MATRIX_STRIDE',
      'GL_UNIFORM_IS_ROW_MAJOR',
    ],
    'invalid': [
      'GL_UNIFORM_BLOCK_NAME_LENGTH',
    ],
  },
  'UniformBlockParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_UNIFORM_BLOCK_BINDING',
      'GL_UNIFORM_BLOCK_DATA_SIZE',
      'GL_UNIFORM_BLOCK_NAME_LENGTH',
      'GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS',
      'GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES',
      'GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER',
      'GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER',
    ],
    'invalid': [
      'GL_NEAREST',
    ],
  },
  'VertexAttribType': {
    'type': 'GLenum',
    'valid': [
      'GL_BYTE',
      'GL_UNSIGNED_BYTE',
      'GL_SHORT',
      'GL_UNSIGNED_SHORT',
    #  'GL_FIXED',  // This is not available on Desktop GL.
      'GL_FLOAT',
    ],
    'invalid': [
      'GL_DOUBLE',
    ],
  },
  'VertexAttribIType': {
    'type': 'GLenum',
    'valid': [
      'GL_BYTE',
      'GL_UNSIGNED_BYTE',
      'GL_SHORT',
      'GL_UNSIGNED_SHORT',
      'GL_INT',
      'GL_UNSIGNED_INT',
    ],
    'invalid': [
      'GL_FLOAT',
      'GL_DOUBLE',
    ],
  },
  'TextureBorder': {
    'type': 'GLint',
    'is_complete': True,
    'valid': [
      '0',
    ],
    'invalid': [
      '1',
    ],
  },
  'VertexAttribSize': {
    'type': 'GLint',
    'valid': [
      '1',
      '2',
      '3',
      '4',
    ],
    'invalid': [
      '0',
      '5',
    ],
  },
  'ZeroOnly': {
    'type': 'GLint',
    'is_complete': True,
    'valid': [
      '0',
    ],
    'invalid': [
      '1',
    ],
  },
  'FalseOnly': {
    'type': 'GLboolean',
    'is_complete': True,
    'valid': [
      'false',
    ],
    'invalid': [
      'true',
    ],
  },
  'ResetStatus': {
    'type': 'GLenum',
    'valid': [
      'GL_GUILTY_CONTEXT_RESET_ARB',
      'GL_INNOCENT_CONTEXT_RESET_ARB',
      'GL_UNKNOWN_CONTEXT_RESET_ARB',
    ],
  },
  'SyncCondition': {
    'type': 'GLenum',
    'is_complete': True,
    'valid': [
      'GL_SYNC_GPU_COMMANDS_COMPLETE',
    ],
    'invalid': [
      '0',
    ],
  },
  'SyncFlags': {
    'type': 'GLbitfield',
    'is_complete': True,
    'valid': [
      '0',
    ],
    'invalid': [
      '1',
    ],
  },
  'SyncFlushFlags': {
    'type': 'GLbitfield',
    'valid': [
      'GL_SYNC_FLUSH_COMMANDS_BIT',
      '0',
    ],
    'invalid': [
      '0xFFFFFFFF',
    ],
  },
  'SyncParameter': {
    'type': 'GLenum',
    'valid': [
      'GL_SYNC_STATUS',  # This needs to be the 1st; all others are cached.
      'GL_OBJECT_TYPE',
      'GL_SYNC_CONDITION',
      'GL_SYNC_FLAGS',
    ],
    'invalid': [
      'GL_SYNC_FENCE',
    ],
  },
}

# This table specifies the different pepper interfaces that are supported for
# GL commands. 'dev' is true if it's a dev interface.
_PEPPER_INTERFACES = [
  {'name': '', 'dev': False},
  {'name': 'InstancedArrays', 'dev': False},
  {'name': 'FramebufferBlit', 'dev': False},
  {'name': 'FramebufferMultisample', 'dev': False},
  {'name': 'ChromiumEnableFeature', 'dev': False},
  {'name': 'ChromiumMapSub', 'dev': False},
  {'name': 'Query', 'dev': False},
  {'name': 'VertexArrayObject', 'dev': False},
  {'name': 'DrawBuffers', 'dev': True},
]

# A function info object specifies the type and other special data for the
# command that will be generated. A base function info object is generated by
# parsing the "cmd_buffer_functions.txt", one for each function in the
# file. These function info objects can be augmented and their values can be
# overridden by adding an object to the table below.
#
# Must match function names specified in "cmd_buffer_functions.txt".
#
# cmd_comment:  A comment added to the cmd format.
# type:         defines which handler will be used to generate code.
# decoder_func: defines which function to call in the decoder to execute the
#               corresponding GL command. If not specified the GL command will
#               be called directly.
# gl_test_func: GL function that is expected to be called when testing.
# cmd_args:     The arguments to use for the command. This overrides generating
#               them based on the GL function arguments.
# gen_cmd:      Whether or not this function geneates a command. Default = True.
# data_transfer_methods: Array of methods that are used for transfering the
#               pointer data.  Possible values: 'immediate', 'shm', 'bucket'.
#               The default is 'immediate' if the command has one pointer
#               argument, otherwise 'shm'. One command is generated for each
#               transfer method. Affects only commands which are not of type
#               'HandWritten', 'GETn' or 'GLcharN'.
#               Note: the command arguments that affect this are the final args,
#               taking cmd_args override into consideration.
# impl_func:    Whether or not to generate the GLES2Implementation part of this
#               command.
# impl_decl:    Whether or not to generate the GLES2Implementation declaration
#               for this command.
# needs_size:   If True a data_size field is added to the command.
# count:        The number of units per element. For PUTn or PUT types.
# use_count_func: If True the actual data count needs to be computed; the count
#               argument specifies the maximum count.
# unit_test:    If False no service side unit test will be generated.
# client_test:  If False no client side unit test will be generated.
# expectation:  If False the unit test will have no expected calls.
# gen_func:     Name of function that generates GL resource for corresponding
#               bind function.
# states:       array of states that get set by this function corresponding to
#               the given arguments
# state_flag:   name of flag that is set to true when function is called.
# no_gl:        no GL function is called.
# valid_args:   A dictionary of argument indices to args to use in unit tests
#               when they can not be automatically determined.
# pepper_interface: The pepper interface that is used for this extension
# pepper_name:  The name of the function as exposed to pepper.
# pepper_args:  A string representing the argument list (what would appear in
#               C/C++ between the parentheses for the function declaration)
#               that the Pepper API expects for this function. Use this only if
#               the stable Pepper API differs from the GLES2 argument list.
# invalid_test: False if no invalid test needed.
# shadowed:     True = the value is shadowed so no glGetXXX call will be made.
# first_element_only: For PUT types, True if only the first element of an
#               array is used and we end up calling the single value
#               corresponding function. eg. TexParameteriv -> TexParameteri
# extension:    Function is an extension to GL and should not be exposed to
#               pepper unless pepper_interface is defined.
# extension_flag: Function is an extension and should be enabled only when
#               the corresponding feature info flag is enabled. Implies
#               'extension': True.
# not_shared:   For GENn types, True if objects can't be shared between contexts
# unsafe:       True = no validation is implemented on the service side and the
#               command is only available with --enable-unsafe-es3-apis.
# id_mapping:   A list of resource type names whose client side IDs need to be
#               mapped to service side IDs.  This is only used for unsafe APIs.

_FUNCTION_INFO = {
  'ActiveTexture': {
    'decoder_func': 'DoActiveTexture',
    'unit_test': False,
    'impl_func': False,
    'client_test': False,
  },
  'AttachShader': {'decoder_func': 'DoAttachShader'},
  'BindAttribLocation': {
    'type': 'GLchar',
    'data_transfer_methods': ['bucket'],
    'needs_size': True,
  },
  'BindBuffer': {
    'type': 'Bind',
    'decoder_func': 'DoBindBuffer',
    'gen_func': 'GenBuffersARB',
  },
  'BindBufferBase': {
    'type': 'Bind',
    'id_mapping': [ 'Buffer' ],
    'gen_func': 'GenBuffersARB',
    'unsafe': True,
  },
  'BindBufferRange': {
    'type': 'Bind',
    'id_mapping': [ 'Buffer' ],
    'gen_func': 'GenBuffersARB',
    'valid_args': {
      '3': '4',
      '4': '4'
    },
    'unsafe': True,
  },
  'BindFramebuffer': {
    'type': 'Bind',
    'decoder_func': 'DoBindFramebuffer',
    'gl_test_func': 'glBindFramebufferEXT',
    'gen_func': 'GenFramebuffersEXT',
    'trace_level': 1,
  },
  'BindRenderbuffer': {
    'type': 'Bind',
    'decoder_func': 'DoBindRenderbuffer',
    'gl_test_func': 'glBindRenderbufferEXT',
    'gen_func': 'GenRenderbuffersEXT',
  },
  'BindSampler': {
    'type': 'Bind',
    'id_mapping': [ 'Sampler' ],
    'unsafe': True,
  },
  'BindTexture': {
    'type': 'Bind',
    'decoder_func': 'DoBindTexture',
    'gen_func': 'GenTextures',
    # TODO(gman): remove this once client side caching works.
    'client_test': False,
    'trace_level': 1,
  },
  'BindTransformFeedback': {
    'type': 'Bind',
    'id_mapping': [ 'TransformFeedback' ],
    'unsafe': True,
  },
  'BlitFramebufferCHROMIUM': {
    'decoder_func': 'DoBlitFramebufferCHROMIUM',
    'unit_test': False,
    'extension_flag': 'chromium_framebuffer_multisample',
    'pepper_interface': 'FramebufferBlit',
    'pepper_name': 'BlitFramebufferEXT',
    'defer_reads': True,
    'defer_draws': True,
    'trace_level': 1,
  },
  'BufferData': {
    'type': 'Manual',
    'data_transfer_methods': ['shm'],
    'client_test': False,
  },
  'BufferSubData': {
    'type': 'Data',
    'client_test': False,
    'decoder_func': 'DoBufferSubData',
    'data_transfer_methods': ['shm'],
  },
  'CheckFramebufferStatus': {
    'type': 'Is',
    'decoder_func': 'DoCheckFramebufferStatus',
    'gl_test_func': 'glCheckFramebufferStatusEXT',
    'error_value': 'GL_FRAMEBUFFER_UNSUPPORTED',
    'result': ['GLenum'],
  },
  'Clear': {
    'decoder_func': 'DoClear',
    'defer_draws': True,
    'trace_level': 1,
  },
  'ClearBufferiv': {
    'type': 'PUT',
    'use_count_func': True,
    'count': 4,
    'unsafe': True,
  },
  'ClearBufferuiv': {
    'type': 'PUT',
    'count': 4,
    'unsafe': True,
  },
  'ClearBufferfv': {
    'type': 'PUT',
    'use_count_func': True,
    'count': 4,
    'unsafe': True,
  },
  'ClearBufferfi': {
    'unsafe': True,
  },
  'ClearColor': {
    'type': 'StateSet',
    'state': 'ClearColor',
  },
  'ClearDepthf': {
    'type': 'StateSet',
    'state': 'ClearDepthf',
    'decoder_func': 'glClearDepth',
    'gl_test_func': 'glClearDepth',
    'valid_args': {
      '0': '0.5f'
    },
  },
  'ClientWaitSync': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args': 'GLuint sync, GLbitfieldSyncFlushFlags flags, '
                'GLuint timeout_0, GLuint timeout_1, GLenum* result',
    'unsafe': True,
    'result': ['GLenum'],
  },
  'ColorMask': {
    'type': 'StateSet',
    'state': 'ColorMask',
    'no_gl': True,
    'expectation': False,
  },
  'ConsumeTextureCHROMIUM': {
    'decoder_func': 'DoConsumeTextureCHROMIUM',
    'impl_func': False,
    'type': 'PUT',
    'count': 64,  # GL_MAILBOX_SIZE_CHROMIUM
    'unit_test': False,
    'client_test': False,
    'extension': "CHROMIUM_texture_mailbox",
    'chromium': True,
    'trace_level': 1,
  },
  'CopyBufferSubData': {
    'unsafe': True,
  },
  'CreateAndConsumeTextureCHROMIUM': {
    'decoder_func': 'DoCreateAndConsumeTextureCHROMIUM',
    'impl_func': False,
    'type': 'HandWritten',
    'data_transfer_methods': ['immediate'],
    'unit_test': False,
    'client_test': False,
    'extension': "CHROMIUM_texture_mailbox",
    'chromium': True,
  },
  'GenValuebuffersCHROMIUM': {
    'type': 'GENn',
    'gl_test_func': 'glGenValuebuffersCHROMIUM',
    'resource_type': 'Valuebuffer',
    'resource_types': 'Valuebuffers',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'DeleteValuebuffersCHROMIUM': {
    'type': 'DELn',
    'gl_test_func': 'glDeleteValuebuffersCHROMIUM',
    'resource_type': 'Valuebuffer',
    'resource_types': 'Valuebuffers',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'IsValuebufferCHROMIUM': {
    'type': 'Is',
    'decoder_func': 'DoIsValuebufferCHROMIUM',
    'expectation': False,
    'extension': True,
    'chromium': True,
  },
  'BindValuebufferCHROMIUM': {
    'type': 'Bind',
    'decoder_func': 'DoBindValueBufferCHROMIUM',
    'gen_func': 'GenValueBuffersCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'SubscribeValueCHROMIUM': {
    'decoder_func': 'DoSubscribeValueCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'PopulateSubscribedValuesCHROMIUM': {
    'decoder_func': 'DoPopulateSubscribedValuesCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'UniformValuebufferCHROMIUM': {
    'decoder_func': 'DoUniformValueBufferCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'ClearStencil': {
    'type': 'StateSet',
    'state': 'ClearStencil',
  },
  'EnableFeatureCHROMIUM': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'decoder_func': 'DoEnableFeatureCHROMIUM',
    'expectation': False,
    'cmd_args': 'GLuint bucket_id, GLint* result',
    'result': ['GLint'],
    'extension': True,
    'chromium': True,
    'pepper_interface': 'ChromiumEnableFeature',
  },
  'CompileShader': {'decoder_func': 'DoCompileShader', 'unit_test': False},
  'CompressedTexImage2D': {
    'type': 'Manual',
    'data_transfer_methods': ['bucket', 'shm'],
  },
  'CompressedTexSubImage2D': {
    'type': 'Data',
    'data_transfer_methods': ['bucket', 'shm'],
    'decoder_func': 'DoCompressedTexSubImage2D',
  },
  'CopyTexImage2D': {
    'decoder_func': 'DoCopyTexImage2D',
    'unit_test': False,
    'defer_reads': True,
  },
  'CopyTexSubImage2D': {
    'decoder_func': 'DoCopyTexSubImage2D',
    'defer_reads': True,
  },
  'CopyTexSubImage3D': {
    'defer_reads': True,
    'unsafe': True,
  },
  'CreateImageCHROMIUM': {
    'type': 'Manual',
    'cmd_args':
        'ClientBuffer buffer, GLsizei width, GLsizei height, '
        'GLenum internalformat',
    'result': ['GLuint'],
    'client_test': False,
    'gen_cmd': False,
    'expectation': False,
    'extension': True,
    'chromium': True,
  },
  'DestroyImageCHROMIUM': {
    'type': 'Manual',
    'client_test': False,
    'gen_cmd': False,
    'extension': True,
    'chromium': True,
  },
  'CreateGpuMemoryBufferImageCHROMIUM': {
    'type': 'Manual',
    'cmd_args':
        'GLsizei width, GLsizei height, GLenum internalformat, GLenum usage',
    'result': ['GLuint'],
    'client_test': False,
    'gen_cmd': False,
    'expectation': False,
    'extension': True,
    'chromium': True,
  },
  'CreateProgram': {
    'type': 'Create',
    'client_test': False,
  },
  'CreateShader': {
    'type': 'Create',
    'client_test': False,
  },
  'BlendColor': {
    'type': 'StateSet',
    'state': 'BlendColor',
  },
  'BlendEquation': {
    'type': 'StateSetRGBAlpha',
    'state': 'BlendEquation',
    'valid_args': {
      '0': 'GL_FUNC_SUBTRACT'
    },
  },
  'BlendEquationSeparate': {
    'type': 'StateSet',
    'state': 'BlendEquation',
    'valid_args': {
      '0': 'GL_FUNC_SUBTRACT'
    },
  },
  'BlendFunc': {
    'type': 'StateSetRGBAlpha',
    'state': 'BlendFunc',
  },
  'BlendFuncSeparate': {
    'type': 'StateSet',
    'state': 'BlendFunc',
  },
  'BlendBarrierKHR': {
    'gl_test_func': 'glBlendBarrierKHR',
    'extension': True,
    'extension_flag': 'blend_equation_advanced',
    'client_test': False,
  },
  'SampleCoverage': {'decoder_func': 'DoSampleCoverage'},
  'StencilFunc': {
    'type': 'StateSetFrontBack',
    'state': 'StencilFunc',
  },
  'StencilFuncSeparate': {
    'type': 'StateSetFrontBackSeparate',
    'state': 'StencilFunc',
  },
  'StencilOp': {
    'type': 'StateSetFrontBack',
    'state': 'StencilOp',
    'valid_args': {
      '1': 'GL_INCR'
    },
  },
  'StencilOpSeparate': {
    'type': 'StateSetFrontBackSeparate',
    'state': 'StencilOp',
    'valid_args': {
      '1': 'GL_INCR'
    },
  },
  'Hint': {
    'type': 'StateSetNamedParameter',
    'state': 'Hint',
  },
  'CullFace': {'type': 'StateSet', 'state': 'CullFace'},
  'FrontFace': {'type': 'StateSet', 'state': 'FrontFace'},
  'DepthFunc': {'type': 'StateSet', 'state': 'DepthFunc'},
  'LineWidth': {
    'type': 'StateSet',
    'state': 'LineWidth',
    'valid_args': {
      '0': '0.5f'
    },
  },
  'PolygonOffset': {
    'type': 'StateSet',
    'state': 'PolygonOffset',
  },
  'DeleteBuffers': {
    'type': 'DELn',
    'gl_test_func': 'glDeleteBuffersARB',
    'resource_type': 'Buffer',
    'resource_types': 'Buffers',
  },
  'DeleteFramebuffers': {
    'type': 'DELn',
    'gl_test_func': 'glDeleteFramebuffersEXT',
    'resource_type': 'Framebuffer',
    'resource_types': 'Framebuffers',
  },
  'DeleteProgram': { 'type': 'Delete' },
  'DeleteRenderbuffers': {
    'type': 'DELn',
    'gl_test_func': 'glDeleteRenderbuffersEXT',
    'resource_type': 'Renderbuffer',
    'resource_types': 'Renderbuffers',
  },
  'DeleteSamplers': {
    'type': 'DELn',
    'resource_type': 'Sampler',
    'resource_types': 'Samplers',
    'unsafe': True,
  },
  'DeleteShader': { 'type': 'Delete' },
  'DeleteSync': {
    'type': 'Delete',
    'cmd_args': 'GLuint sync',
    'resource_type': 'Sync',
    'unsafe': True,
  },
  'DeleteTextures': {
    'type': 'DELn',
    'resource_type': 'Texture',
    'resource_types': 'Textures',
  },
  'DeleteTransformFeedbacks': {
    'type': 'DELn',
    'resource_type': 'TransformFeedback',
    'resource_types': 'TransformFeedbacks',
    'unsafe': True,
  },
  'DepthRangef': {
    'decoder_func': 'DoDepthRangef',
    'gl_test_func': 'glDepthRange',
  },
  'DepthMask': {
    'type': 'StateSet',
    'state': 'DepthMask',
    'no_gl': True,
    'expectation': False,
  },
  'DetachShader': {'decoder_func': 'DoDetachShader'},
  'Disable': {
    'decoder_func': 'DoDisable',
    'impl_func': False,
    'client_test': False,
  },
  'DisableVertexAttribArray': {
    'decoder_func': 'DoDisableVertexAttribArray',
    'impl_decl': False,
  },
  'DrawArrays': {
    'type': 'Manual',
    'cmd_args': 'GLenumDrawMode mode, GLint first, GLsizei count',
    'defer_draws': True,
    'trace_level': 2,
  },
  'DrawElements': {
    'type': 'Manual',
    'cmd_args': 'GLenumDrawMode mode, GLsizei count, '
                'GLenumIndexType type, GLuint index_offset',
    'client_test': False,
    'defer_draws': True,
    'trace_level': 2,
  },
  'DrawRangeElements': {
    'type': 'Manual',
    'gen_cmd': 'False',
    'unsafe': True,
  },
  'Enable': {
    'decoder_func': 'DoEnable',
    'impl_func': False,
    'client_test': False,
  },
  'EnableVertexAttribArray': {
    'decoder_func': 'DoEnableVertexAttribArray',
    'impl_decl': False,
  },
  'FenceSync': {
    'type': 'Create',
    'client_test': False,
    'unsafe': True,
  },
  'Finish': {
    'impl_func': False,
    'client_test': False,
    'decoder_func': 'DoFinish',
    'defer_reads': True,
  },
  'Flush': {
    'impl_func': False,
    'decoder_func': 'DoFlush',
  },
  'FramebufferRenderbuffer': {
    'decoder_func': 'DoFramebufferRenderbuffer',
    'gl_test_func': 'glFramebufferRenderbufferEXT',
  },
  'FramebufferTexture2D': {
    'decoder_func': 'DoFramebufferTexture2D',
    'gl_test_func': 'glFramebufferTexture2DEXT',
    'trace_level': 1,
  },
  'FramebufferTexture2DMultisampleEXT': {
    'decoder_func': 'DoFramebufferTexture2DMultisample',
    'gl_test_func': 'glFramebufferTexture2DMultisampleEXT',
    'expectation': False,
    'unit_test': False,
    'extension_flag': 'multisampled_render_to_texture',
    'trace_level': 1,
  },
  'FramebufferTextureLayer': {
    'decoder_func': 'DoFramebufferTextureLayer',
    'unsafe': True,
  },
  'GenerateMipmap': {
    'decoder_func': 'DoGenerateMipmap',
    'gl_test_func': 'glGenerateMipmapEXT',
  },
  'GenBuffers': {
    'type': 'GENn',
    'gl_test_func': 'glGenBuffersARB',
    'resource_type': 'Buffer',
    'resource_types': 'Buffers',
  },
  'GenMailboxCHROMIUM': {
    'type': 'HandWritten',
    'impl_func': False,
    'extension': "CHROMIUM_texture_mailbox",
    'chromium': True,
  },
  'GenFramebuffers': {
    'type': 'GENn',
    'gl_test_func': 'glGenFramebuffersEXT',
    'resource_type': 'Framebuffer',
    'resource_types': 'Framebuffers',
  },
  'GenRenderbuffers': {
    'type': 'GENn', 'gl_test_func': 'glGenRenderbuffersEXT',
    'resource_type': 'Renderbuffer',
    'resource_types': 'Renderbuffers',
  },
  'GenSamplers': {
    'type': 'GENn',
    'gl_test_func': 'glGenSamplers',
    'resource_type': 'Sampler',
    'resource_types': 'Samplers',
    'unsafe': True,
  },
  'GenTextures': {
    'type': 'GENn',
    'gl_test_func': 'glGenTextures',
    'resource_type': 'Texture',
    'resource_types': 'Textures',
  },
  'GenTransformFeedbacks': {
    'type': 'GENn',
    'gl_test_func': 'glGenTransformFeedbacks',
    'resource_type': 'TransformFeedback',
    'resource_types': 'TransformFeedbacks',
    'unsafe': True,
  },
  'GetActiveAttrib': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
        'GLidProgram program, GLuint index, uint32_t name_bucket_id, '
        'void* result',
    'result': [
      'int32_t success',
      'int32_t size',
      'uint32_t type',
    ],
  },
  'GetActiveUniform': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
        'GLidProgram program, GLuint index, uint32_t name_bucket_id, '
        'void* result',
    'result': [
      'int32_t success',
      'int32_t size',
      'uint32_t type',
    ],
  },
  'GetActiveUniformBlockiv': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'result': ['SizedResult<GLint>'],
    'unsafe': True,
  },
  'GetActiveUniformBlockName': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
        'GLidProgram program, GLuint index, uint32_t name_bucket_id, '
        'void* result',
    'result': ['int32_t'],
    'unsafe': True,
  },
  'GetActiveUniformsiv': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
        'GLidProgram program, uint32_t indices_bucket_id, GLenum pname, '
        'GLint* params',
    'result': ['SizedResult<GLint>'],
    'unsafe': True,
  },
  'GetAttachedShaders': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args': 'GLidProgram program, void* result, uint32_t result_size',
    'result': ['SizedResult<GLuint>'],
  },
  'GetAttribLocation': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
        'GLidProgram program, uint32_t name_bucket_id, GLint* location',
    'result': ['GLint'],
    'error_return': -1,
  },
  'GetFragDataLocation': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
        'GLidProgram program, uint32_t name_bucket_id, GLint* location',
    'result': ['GLint'],
    'error_return': -1,
    'unsafe': True,
  },
  'GetBooleanv': {
    'type': 'GETn',
    'result': ['SizedResult<GLboolean>'],
    'decoder_func': 'DoGetBooleanv',
    'gl_test_func': 'glGetBooleanv',
  },
  'GetBufferParameteriv': {
    'type': 'GETn',
    'result': ['SizedResult<GLint>'],
    'decoder_func': 'DoGetBufferParameteriv',
    'expectation': False,
    'shadowed': True,
  },
  'GetError': {
    'type': 'Is',
    'decoder_func': 'GetErrorState()->GetGLError',
    'impl_func': False,
    'result': ['GLenum'],
    'client_test': False,
  },
  'GetFloatv': {
    'type': 'GETn',
    'result': ['SizedResult<GLfloat>'],
    'decoder_func': 'DoGetFloatv',
    'gl_test_func': 'glGetFloatv',
  },
  'GetFramebufferAttachmentParameteriv': {
    'type': 'GETn',
    'decoder_func': 'DoGetFramebufferAttachmentParameteriv',
    'gl_test_func': 'glGetFramebufferAttachmentParameterivEXT',
    'result': ['SizedResult<GLint>'],
  },
  'GetInteger64v': {
    'type': 'GETn',
    'result': ['SizedResult<GLint64>'],
    'client_test': False,
    'decoder_func': 'DoGetInteger64v',
    'unsafe': True
  },
  'GetIntegerv': {
    'type': 'GETn',
    'result': ['SizedResult<GLint>'],
    'decoder_func': 'DoGetIntegerv',
    'client_test': False,
  },
  'GetInteger64i_v': {
    'type': 'GETn',
    'result': ['SizedResult<GLint64>'],
    'client_test': False,
    'unsafe': True
  },
  'GetIntegeri_v': {
    'type': 'GETn',
    'result': ['SizedResult<GLint>'],
    'client_test': False,
    'unsafe': True
  },
  'GetInternalformativ': {
    'type': 'GETn',
    'result': ['SizedResult<GLint>'],
    'unsafe': True,
  },
  'GetMaxValueInBufferCHROMIUM': {
    'type': 'Is',
    'decoder_func': 'DoGetMaxValueInBufferCHROMIUM',
    'result': ['GLuint'],
    'unit_test': False,
    'client_test': False,
    'extension': True,
    'chromium': True,
    'impl_func': False,
  },
  'GetProgramiv': {
    'type': 'GETn',
    'decoder_func': 'DoGetProgramiv',
    'result': ['SizedResult<GLint>'],
    'expectation': False,
  },
  'GetProgramInfoCHROMIUM': {
    'type': 'Custom',
    'expectation': False,
    'impl_func': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
    'cmd_args': 'GLidProgram program, uint32_t bucket_id',
    'result': [
      'uint32_t link_status',
      'uint32_t num_attribs',
      'uint32_t num_uniforms',
    ],
  },
  'GetProgramInfoLog': {
    'type': 'STRn',
    'expectation': False,
  },
  'GetRenderbufferParameteriv': {
    'type': 'GETn',
    'decoder_func': 'DoGetRenderbufferParameteriv',
    'gl_test_func': 'glGetRenderbufferParameterivEXT',
    'result': ['SizedResult<GLint>'],
  },
  'GetSamplerParameterfv': {
    'type': 'GETn',
    'result': ['SizedResult<GLfloat>'],
    'id_mapping': [ 'Sampler' ],
    'unsafe': True,
  },
  'GetSamplerParameteriv': {
    'type': 'GETn',
    'result': ['SizedResult<GLint>'],
    'id_mapping': [ 'Sampler' ],
    'unsafe': True,
  },
  'GetShaderiv': {
    'type': 'GETn',
    'decoder_func': 'DoGetShaderiv',
    'result': ['SizedResult<GLint>'],
  },
  'GetShaderInfoLog': {
    'type': 'STRn',
    'get_len_func': 'glGetShaderiv',
    'get_len_enum': 'GL_INFO_LOG_LENGTH',
    'unit_test': False,
  },
  'GetShaderPrecisionFormat': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
      'GLenumShaderType shadertype, GLenumShaderPrecision precisiontype, '
      'void* result',
    'result': [
      'int32_t success',
      'int32_t min_range',
      'int32_t max_range',
      'int32_t precision',
    ],
  },
  'GetShaderSource': {
    'type': 'STRn',
    'get_len_func': 'DoGetShaderiv',
    'get_len_enum': 'GL_SHADER_SOURCE_LENGTH',
    'unit_test': False,
    'client_test': False,
  },
  'GetString': {
    'type': 'Custom',
    'client_test': False,
    'cmd_args': 'GLenumStringType name, uint32_t bucket_id',
  },
  'GetSynciv': {
    'type': 'GETn',
    'cmd_args': 'GLuint sync, GLenumSyncParameter pname, void* values',
    'result': ['SizedResult<GLint>'],
    'id_mapping': ['Sync'],
    'unsafe': True,
  },
  'GetTexParameterfv': {
    'type': 'GETn',
    'decoder_func': 'DoGetTexParameterfv',
    'result': ['SizedResult<GLfloat>']
  },
  'GetTexParameteriv': {
    'type': 'GETn',
    'decoder_func': 'DoGetTexParameteriv',
    'result': ['SizedResult<GLint>']
  },
  'GetTranslatedShaderSourceANGLE': {
    'type': 'STRn',
    'get_len_func': 'DoGetShaderiv',
    'get_len_enum': 'GL_TRANSLATED_SHADER_SOURCE_LENGTH_ANGLE',
    'unit_test': False,
    'extension': True,
  },
  'GetUniformBlockIndex': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
        'GLidProgram program, uint32_t name_bucket_id, GLuint* index',
    'result': ['GLuint'],
    'error_return': 'GL_INVALID_INDEX',
    'unsafe': True,
  },
  'GetUniformBlocksCHROMIUM': {
    'type': 'Custom',
    'expectation': False,
    'impl_func': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
    'cmd_args': 'GLidProgram program, uint32_t bucket_id',
    'result': ['uint32_t'],
    'unsafe': True,
  },
  'GetUniformsES3CHROMIUM': {
    'type': 'Custom',
    'expectation': False,
    'impl_func': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
    'cmd_args': 'GLidProgram program, uint32_t bucket_id',
    'result': ['uint32_t'],
    'unsafe': True,
  },
  'GetTransformFeedbackVarying': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
        'GLidProgram program, GLuint index, uint32_t name_bucket_id, '
        'void* result',
    'result': [
      'int32_t success',
      'int32_t size',
      'uint32_t type',
    ],
    'unsafe': True,
  },
  'GetTransformFeedbackVaryingsCHROMIUM': {
    'type': 'Custom',
    'expectation': False,
    'impl_func': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
    'cmd_args': 'GLidProgram program, uint32_t bucket_id',
    'result': ['uint32_t'],
    'unsafe': True,
  },
  'GetUniformfv': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'result': ['SizedResult<GLfloat>'],
  },
  'GetUniformiv': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'result': ['SizedResult<GLint>'],
  },
  'GetUniformIndices': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'result': ['SizedResult<GLuint>'],
    'cmd_args': 'GLidProgram program, uint32_t names_bucket_id, '
                'GLuint* indices',
    'unsafe': True,
  },
  'GetUniformLocation': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args':
        'GLidProgram program, uint32_t name_bucket_id, GLint* location',
    'result': ['GLint'],
    'error_return': -1, # http://www.opengl.org/sdk/docs/man/xhtml/glGetUniformLocation.xml
  },
  'GetVertexAttribfv': {
    'type': 'GETn',
    'result': ['SizedResult<GLfloat>'],
    'impl_decl': False,
    'decoder_func': 'DoGetVertexAttribfv',
    'expectation': False,
    'client_test': False,
  },
  'GetVertexAttribiv': {
    'type': 'GETn',
    'result': ['SizedResult<GLint>'],
    'impl_decl': False,
    'decoder_func': 'DoGetVertexAttribiv',
    'expectation': False,
    'client_test': False,
  },
  'GetVertexAttribPointerv': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'result': ['SizedResult<GLuint>'],
    'client_test': False,
  },
  'InvalidateFramebuffer': {
    'type': 'PUTn',
    'count': 1,
    'client_test': False,
    'unit_test': False,
    'unsafe': True,
  },
  'InvalidateSubFramebuffer': {
    'type': 'PUTn',
    'count': 1,
    'client_test': False,
    'unit_test': False,
    'unsafe': True,
  },
  'IsBuffer': {
    'type': 'Is',
    'decoder_func': 'DoIsBuffer',
    'expectation': False,
  },
  'IsEnabled': {
    'type': 'Is',
    'decoder_func': 'DoIsEnabled',
    'client_test': False,
    'impl_func': False,
    'expectation': False,
  },
  'IsFramebuffer': {
    'type': 'Is',
    'decoder_func': 'DoIsFramebuffer',
    'expectation': False,
  },
  'IsProgram': {
    'type': 'Is',
    'decoder_func': 'DoIsProgram',
    'expectation': False,
  },
  'IsRenderbuffer': {
    'type': 'Is',
    'decoder_func': 'DoIsRenderbuffer',
    'expectation': False,
  },
  'IsShader': {
    'type': 'Is',
    'decoder_func': 'DoIsShader',
    'expectation': False,
  },
  'IsSampler': {
    'type': 'Is',
    'id_mapping': [ 'Sampler' ],
    'expectation': False,
    'unsafe': True,
  },
  'IsSync': {
    'type': 'Is',
    'id_mapping': [ 'Sync' ],
    'cmd_args': 'GLuint sync',
    'expectation': False,
    'unsafe': True,
  },
  'IsTexture': {
    'type': 'Is',
    'decoder_func': 'DoIsTexture',
    'expectation': False,
  },
  'IsTransformFeedback': {
    'type': 'Is',
    'id_mapping': [ 'TransformFeedback' ],
    'expectation': False,
    'unsafe': True,
  },
  'LinkProgram': {
    'decoder_func': 'DoLinkProgram',
    'impl_func':  False,
  },
  'MapBufferCHROMIUM': {
    'gen_cmd': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
  },
  'MapBufferSubDataCHROMIUM': {
    'gen_cmd': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
    'pepper_interface': 'ChromiumMapSub',
  },
  'MapTexSubImage2DCHROMIUM': {
    'gen_cmd': False,
    'extension': "CHROMIUM_sub_image",
    'chromium': True,
    'client_test': False,
    'pepper_interface': 'ChromiumMapSub',
  },
  'MapBufferRange': {
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'cmd_args': 'GLenumBufferTarget target, GLintptrNotNegative offset, '
                'GLsizeiptr size, GLbitfieldMapBufferAccess access, '
                'uint32_t data_shm_id, uint32_t data_shm_offset, '
                'uint32_t result_shm_id, uint32_t result_shm_offset',
    'unsafe': True,
    'result': ['uint32_t'],
  },
  'PauseTransformFeedback': {
    'unsafe': True,
  },
  'PixelStorei': {'type': 'Manual'},
  'PostSubBufferCHROMIUM': {
      'type': 'Custom',
      'impl_func': False,
      'unit_test': False,
      'client_test': False,
      'extension': True,
      'chromium': True,
  },
  'ProduceTextureCHROMIUM': {
    'decoder_func': 'DoProduceTextureCHROMIUM',
    'impl_func': False,
    'type': 'PUT',
    'count': 64,  # GL_MAILBOX_SIZE_CHROMIUM
    'unit_test': False,
    'client_test': False,
    'extension': "CHROMIUM_texture_mailbox",
    'chromium': True,
    'trace_level': 1,
  },
  'ProduceTextureDirectCHROMIUM': {
    'decoder_func': 'DoProduceTextureDirectCHROMIUM',
    'impl_func': False,
    'type': 'PUT',
    'count': 64,  # GL_MAILBOX_SIZE_CHROMIUM
    'unit_test': False,
    'client_test': False,
    'extension': "CHROMIUM_texture_mailbox",
    'chromium': True,
    'trace_level': 1,
  },
  'RenderbufferStorage': {
    'decoder_func': 'DoRenderbufferStorage',
    'gl_test_func': 'glRenderbufferStorageEXT',
    'expectation': False,
  },
  'RenderbufferStorageMultisampleCHROMIUM': {
    'cmd_comment':
        '// GL_CHROMIUM_framebuffer_multisample\n',
    'decoder_func': 'DoRenderbufferStorageMultisampleCHROMIUM',
    'gl_test_func': 'glRenderbufferStorageMultisampleCHROMIUM',
    'expectation': False,
    'unit_test': False,
    'extension_flag': 'chromium_framebuffer_multisample',
    'pepper_interface': 'FramebufferMultisample',
    'pepper_name': 'RenderbufferStorageMultisampleEXT',
  },
  'RenderbufferStorageMultisampleEXT': {
    'cmd_comment':
        '// GL_EXT_multisampled_render_to_texture\n',
    'decoder_func': 'DoRenderbufferStorageMultisampleEXT',
    'gl_test_func': 'glRenderbufferStorageMultisampleEXT',
    'expectation': False,
    'unit_test': False,
    'extension_flag': 'multisampled_render_to_texture',
  },
  'ReadBuffer': {
    'unsafe': True,
  },
  'ReadPixels': {
    'cmd_comment':
        '// ReadPixels has the result separated from the pixel buffer so that\n'
        '// it is easier to specify the result going to some specific place\n'
        '// that exactly fits the rectangle of pixels.\n',
    'type': 'Custom',
    'data_transfer_methods': ['shm'],
    'impl_func': False,
    'client_test': False,
    'cmd_args':
        'GLint x, GLint y, GLsizei width, GLsizei height, '
        'GLenumReadPixelFormat format, GLenumReadPixelType type, '
        'uint32_t pixels_shm_id, uint32_t pixels_shm_offset, '
        'uint32_t result_shm_id, uint32_t result_shm_offset, '
        'GLboolean async',
    'result': ['uint32_t'],
    'defer_reads': True,
  },
  'ReleaseShaderCompiler': {
    'decoder_func': 'DoReleaseShaderCompiler',
    'unit_test': False,
  },
  'ResumeTransformFeedback': {
    'unsafe': True,
  },
  'SamplerParameterf': {
    'valid_args': {
      '2': 'GL_NEAREST'
    },
    'id_mapping': [ 'Sampler' ],
    'unsafe': True,
  },
  'SamplerParameterfv': {
    'type': 'PUT',
    'data_value': 'GL_NEAREST',
    'count': 1,
    'gl_test_func': 'glSamplerParameterf',
    'decoder_func': 'DoSamplerParameterfv',
    'first_element_only': True,
    'id_mapping': [ 'Sampler' ],
    'unsafe': True,
  },
  'SamplerParameteri': {
    'valid_args': {
      '2': 'GL_NEAREST'
    },
    'id_mapping': [ 'Sampler' ],
    'unsafe': True,
  },
  'SamplerParameteriv': {
    'type': 'PUT',
    'data_value': 'GL_NEAREST',
    'count': 1,
    'gl_test_func': 'glSamplerParameteri',
    'decoder_func': 'DoSamplerParameteriv',
    'first_element_only': True,
    'unsafe': True,
  },
  'ShaderBinary': {
    'type': 'Custom',
    'client_test': False,
  },
  'ShaderSource': {
    'type': 'PUTSTR',
    'decoder_func': 'DoShaderSource',
    'expectation': False,
    'data_transfer_methods': ['bucket'],
    'cmd_args':
        'GLuint shader, const char** str',
    'pepper_args':
        'GLuint shader, GLsizei count, const char** str, const GLint* length',
  },
  'StencilMask': {
    'type': 'StateSetFrontBack',
    'state': 'StencilMask',
    'no_gl': True,
    'expectation': False,
  },
  'StencilMaskSeparate': {
    'type': 'StateSetFrontBackSeparate',
    'state': 'StencilMask',
    'no_gl': True,
    'expectation': False,
  },
  'SwapBuffers': {
    'impl_func': False,
    'decoder_func': 'DoSwapBuffers',
    'unit_test': False,
    'client_test': False,
    'extension': True,
    'trace_level': 1,
  },
  'SwapInterval': {
    'impl_func': False,
    'decoder_func': 'DoSwapInterval',
    'unit_test': False,
    'client_test': False,
    'extension': True,
    'trace_level': 1,
  },
  'TexImage2D': {
    'type': 'Manual',
    'data_transfer_methods': ['shm'],
    'client_test': False,
  },
  'TexImage3D': {
    'type': 'Manual',
    'data_transfer_methods': ['shm'],
    'client_test': False,
    'unsafe': True,
  },
  'TexParameterf': {
    'decoder_func': 'DoTexParameterf',
    'valid_args': {
      '2': 'GL_NEAREST'
    },
  },
  'TexParameteri': {
    'decoder_func': 'DoTexParameteri',
    'valid_args': {
      '2': 'GL_NEAREST'
    },
  },
  'TexParameterfv': {
    'type': 'PUT',
    'data_value': 'GL_NEAREST',
    'count': 1,
    'decoder_func': 'DoTexParameterfv',
    'gl_test_func': 'glTexParameterf',
    'first_element_only': True,
  },
  'TexParameteriv': {
    'type': 'PUT',
    'data_value': 'GL_NEAREST',
    'count': 1,
    'decoder_func': 'DoTexParameteriv',
    'gl_test_func': 'glTexParameteri',
    'first_element_only': True,
  },
  'TexStorage3D': {
    'unsafe': True,
  },
  'TexSubImage2D': {
    'type': 'Manual',
    'data_transfer_methods': ['shm'],
    'client_test': False,
    'cmd_args': 'GLenumTextureTarget target, GLint level, '
                'GLint xoffset, GLint yoffset, '
                'GLsizei width, GLsizei height, '
                'GLenumTextureFormat format, GLenumPixelType type, '
                'const void* pixels, GLboolean internal'
  },
  'TexSubImage3D': {
    'type': 'Manual',
    'data_transfer_methods': ['shm'],
    'client_test': False,
    'cmd_args': 'GLenumTextureTarget target, GLint level, '
                'GLint xoffset, GLint yoffset, GLint zoffset, '
                'GLsizei width, GLsizei height, GLsizei depth, '
                'GLenumTextureFormat format, GLenumPixelType type, '
                'const void* pixels, GLboolean internal',
    'unsafe': True,
  },
  'TransformFeedbackVaryings': {
    'type': 'PUTSTR',
    'data_transfer_methods': ['bucket'],
    'decoder_func': 'DoTransformFeedbackVaryings',
    'cmd_args':
        'GLuint program, const char** varyings, GLenum buffermode',
    'unsafe': True,
  },
  'Uniform1f': {'type': 'PUTXn', 'count': 1},
  'Uniform1fv': {
    'type': 'PUTn',
    'count': 1,
    'decoder_func': 'DoUniform1fv',
  },
  'Uniform1i': {'decoder_func': 'DoUniform1i', 'unit_test': False},
  'Uniform1iv': {
    'type': 'PUTn',
    'count': 1,
    'decoder_func': 'DoUniform1iv',
    'unit_test': False,
  },
  'Uniform1ui': {
    'type': 'PUTXn',
    'count': 1,
    'unsafe': True,
  },
  'Uniform1uiv': {
    'type': 'PUTn',
    'count': 1,
    'unsafe': True,
  },
  'Uniform2i': {'type': 'PUTXn', 'count': 2},
  'Uniform2f': {'type': 'PUTXn', 'count': 2},
  'Uniform2fv': {
    'type': 'PUTn',
    'count': 2,
    'decoder_func': 'DoUniform2fv',
  },
  'Uniform2iv': {
    'type': 'PUTn',
    'count': 2,
    'decoder_func': 'DoUniform2iv',
  },
  'Uniform2ui': {
    'type': 'PUTXn',
    'count': 2,
    'unsafe': True,
  },
  'Uniform2uiv': {
    'type': 'PUTn',
    'count': 2,
    'unsafe': True,
  },
  'Uniform3i': {'type': 'PUTXn', 'count': 3},
  'Uniform3f': {'type': 'PUTXn', 'count': 3},
  'Uniform3fv': {
    'type': 'PUTn',
    'count': 3,
    'decoder_func': 'DoUniform3fv',
  },
  'Uniform3iv': {
    'type': 'PUTn',
    'count': 3,
    'decoder_func': 'DoUniform3iv',
  },
  'Uniform3ui': {
    'type': 'PUTXn',
    'count': 3,
    'unsafe': True,
  },
  'Uniform3uiv': {
    'type': 'PUTn',
    'count': 3,
    'unsafe': True,
  },
  'Uniform4i': {'type': 'PUTXn', 'count': 4},
  'Uniform4f': {'type': 'PUTXn', 'count': 4},
  'Uniform4fv': {
    'type': 'PUTn',
    'count': 4,
    'decoder_func': 'DoUniform4fv',
  },
  'Uniform4iv': {
    'type': 'PUTn',
    'count': 4,
    'decoder_func': 'DoUniform4iv',
  },
  'Uniform4ui': {
    'type': 'PUTXn',
    'count': 4,
    'unsafe': True,
  },
  'Uniform4uiv': {
    'type': 'PUTn',
    'count': 4,
    'unsafe': True,
  },
  'UniformMatrix2fv': {
    'type': 'PUTn',
    'count': 4,
    'decoder_func': 'DoUniformMatrix2fv',
  },
  'UniformMatrix2x3fv': {
    'type': 'PUTn',
    'count': 6,
    'unsafe': True,
  },
  'UniformMatrix2x4fv': {
    'type': 'PUTn',
    'count': 8,
    'unsafe': True,
  },
  'UniformMatrix3fv': {
    'type': 'PUTn',
    'count': 9,
    'decoder_func': 'DoUniformMatrix3fv',
  },
  'UniformMatrix3x2fv': {
    'type': 'PUTn',
    'count': 6,
    'unsafe': True,
  },
  'UniformMatrix3x4fv': {
    'type': 'PUTn',
    'count': 12,
    'unsafe': True,
  },
  'UniformMatrix4fv': {
    'type': 'PUTn',
    'count': 16,
    'decoder_func': 'DoUniformMatrix4fv',
  },
  'UniformMatrix4x2fv': {
    'type': 'PUTn',
    'count': 8,
    'unsafe': True,
  },
  'UniformMatrix4x3fv': {
    'type': 'PUTn',
    'count': 12,
    'unsafe': True,
  },
  'UniformBlockBinding': {
    'type': 'Custom',
    'impl_func': False,
    'unsafe': True,
  },
  'UnmapBufferCHROMIUM': {
    'gen_cmd': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
  },
  'UnmapBufferSubDataCHROMIUM': {
    'gen_cmd': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
    'pepper_interface': 'ChromiumMapSub',
  },
  'UnmapBuffer': {
    'type': 'Custom',
    'unsafe': True,
  },
  'UnmapTexSubImage2DCHROMIUM': {
    'gen_cmd': False,
    'extension': "CHROMIUM_sub_image",
    'chromium': True,
    'client_test': False,
    'pepper_interface': 'ChromiumMapSub',
  },
  'UseProgram': {
    'type': 'Bind',
    'decoder_func': 'DoUseProgram',
  },
  'ValidateProgram': {'decoder_func': 'DoValidateProgram'},
  'VertexAttrib1f': {'decoder_func': 'DoVertexAttrib1f'},
  'VertexAttrib1fv': {
    'type': 'PUT',
    'count': 1,
    'decoder_func': 'DoVertexAttrib1fv',
  },
  'VertexAttrib2f': {'decoder_func': 'DoVertexAttrib2f'},
  'VertexAttrib2fv': {
    'type': 'PUT',
    'count': 2,
    'decoder_func': 'DoVertexAttrib2fv',
  },
  'VertexAttrib3f': {'decoder_func': 'DoVertexAttrib3f'},
  'VertexAttrib3fv': {
    'type': 'PUT',
    'count': 3,
    'decoder_func': 'DoVertexAttrib3fv',
  },
  'VertexAttrib4f': {'decoder_func': 'DoVertexAttrib4f'},
  'VertexAttrib4fv': {
    'type': 'PUT',
    'count': 4,
    'decoder_func': 'DoVertexAttrib4fv',
  },
  'VertexAttribI4i': {
    'unsafe': True,
  },
  'VertexAttribI4iv': {
    'type': 'PUT',
    'count': 4,
    'unsafe': True,
  },
  'VertexAttribI4ui': {
    'unsafe': True,
  },
  'VertexAttribI4uiv': {
    'type': 'PUT',
    'count': 4,
    'unsafe': True,
  },
  'VertexAttribIPointer': {
    'type': 'Manual',
    'cmd_args': 'GLuint indx, GLintVertexAttribSize size, '
                'GLenumVertexAttribIType type, GLsizei stride, '
                'GLuint offset',
    'client_test': False,
    'unsafe': True,
  },
  'VertexAttribPointer': {
    'type': 'Manual',
    'cmd_args': 'GLuint indx, GLintVertexAttribSize size, '
                'GLenumVertexAttribType type, GLboolean normalized, '
                'GLsizei stride, GLuint offset',
    'client_test': False,
  },
  'WaitSync': {
    'type': 'Custom',
    'cmd_args': 'GLuint sync, GLbitfieldSyncFlushFlags flags, '
                'GLuint timeout_0, GLuint timeout_1',
    'impl_func': False,
    'client_test': False,
    'unsafe': True,
  },
  'Scissor': {
    'type': 'StateSet',
    'state': 'Scissor',
  },
  'Viewport': {
    'decoder_func': 'DoViewport',
  },
  'ResizeCHROMIUM': {
    'type': 'Custom',
    'impl_func': False,
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'GetRequestableExtensionsCHROMIUM': {
    'type': 'Custom',
    'impl_func': False,
    'cmd_args': 'uint32_t bucket_id',
    'extension': True,
    'chromium': True,
  },
  'RequestExtensionCHROMIUM': {
    'type': 'Custom',
    'impl_func': False,
    'client_test': False,
    'cmd_args': 'uint32_t bucket_id',
    'extension': True,
    'chromium': True,
  },
  'RateLimitOffscreenContextCHROMIUM': {
    'gen_cmd': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
  },
  'CreateStreamTextureCHROMIUM':  {
    'type': 'HandWritten',
    'impl_func': False,
    'gen_cmd': False,
    'extension': True,
    'chromium': True,
  },
  'TexImageIOSurface2DCHROMIUM': {
    'decoder_func': 'DoTexImageIOSurface2DCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'CopyTextureCHROMIUM': {
    'decoder_func': 'DoCopyTextureCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'CopySubTextureCHROMIUM': {
    'decoder_func': 'DoCopySubTextureCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'TexStorage2DEXT': {
    'unit_test': False,
    'extension': True,
    'decoder_func': 'DoTexStorage2DEXT',
  },
  'DrawArraysInstancedANGLE': {
    'type': 'Manual',
    'cmd_args': 'GLenumDrawMode mode, GLint first, GLsizei count, '
                'GLsizei primcount',
    'extension': True,
    'unit_test': False,
    'pepper_interface': 'InstancedArrays',
    'defer_draws': True,
  },
  'DrawBuffersEXT': {
    'type': 'PUTn',
    'decoder_func': 'DoDrawBuffersEXT',
    'count': 1,
    'client_test': False,
    'unit_test': False,
    # could use 'extension_flag': 'ext_draw_buffers' but currently expected to
    # work without.
    'extension': True,
    'pepper_interface': 'DrawBuffers',
  },
  'DrawElementsInstancedANGLE': {
    'type': 'Manual',
    'cmd_args': 'GLenumDrawMode mode, GLsizei count, '
                'GLenumIndexType type, GLuint index_offset, GLsizei primcount',
    'extension': True,
    'unit_test': False,
    'client_test': False,
    'pepper_interface': 'InstancedArrays',
    'defer_draws': True,
  },
  'VertexAttribDivisorANGLE': {
    'type': 'Manual',
    'cmd_args': 'GLuint index, GLuint divisor',
    'extension': True,
    'unit_test': False,
    'pepper_interface': 'InstancedArrays',
  },
  'GenQueriesEXT': {
    'type': 'GENn',
    'gl_test_func': 'glGenQueriesARB',
    'resource_type': 'Query',
    'resource_types': 'Queries',
    'unit_test': False,
    'pepper_interface': 'Query',
    'not_shared': 'True',
    'extension': "occlusion_query_EXT",
  },
  'DeleteQueriesEXT': {
    'type': 'DELn',
    'gl_test_func': 'glDeleteQueriesARB',
    'resource_type': 'Query',
    'resource_types': 'Queries',
    'unit_test': False,
    'pepper_interface': 'Query',
    'extension': "occlusion_query_EXT",
  },
  'IsQueryEXT': {
    'gen_cmd': False,
    'client_test': False,
    'pepper_interface': 'Query',
    'extension': "occlusion_query_EXT",
  },
  'BeginQueryEXT': {
    'type': 'Manual',
    'cmd_args': 'GLenumQueryTarget target, GLidQuery id, void* sync_data',
    'data_transfer_methods': ['shm'],
    'gl_test_func': 'glBeginQuery',
    'pepper_interface': 'Query',
    'extension': "occlusion_query_EXT",
  },
  'BeginTransformFeedback': {
    'unsafe': True,
  },
  'EndQueryEXT': {
    'type': 'Manual',
    'cmd_args': 'GLenumQueryTarget target, GLuint submit_count',
    'gl_test_func': 'glEndnQuery',
    'client_test': False,
    'pepper_interface': 'Query',
    'extension': "occlusion_query_EXT",
  },
  'EndTransformFeedback': {
    'unsafe': True,
  },
  'GetQueryivEXT': {
    'gen_cmd': False,
    'client_test': False,
    'gl_test_func': 'glGetQueryiv',
    'pepper_interface': 'Query',
    'extension': "occlusion_query_EXT",
  },
  'GetQueryObjectuivEXT': {
    'gen_cmd': False,
    'client_test': False,
    'gl_test_func': 'glGetQueryObjectuiv',
    'pepper_interface': 'Query',
    'extension': "occlusion_query_EXT",
  },
  'BindUniformLocationCHROMIUM': {
    'type': 'GLchar',
    'extension': True,
    'data_transfer_methods': ['bucket'],
    'needs_size': True,
    'gl_test_func': 'DoBindUniformLocationCHROMIUM',
  },
  'InsertEventMarkerEXT': {
    'type': 'GLcharN',
    'decoder_func': 'DoInsertEventMarkerEXT',
    'expectation': False,
    'extension': True,
  },
  'PushGroupMarkerEXT': {
    'type': 'GLcharN',
    'decoder_func': 'DoPushGroupMarkerEXT',
    'expectation': False,
    'extension': True,
  },
  'PopGroupMarkerEXT': {
    'decoder_func': 'DoPopGroupMarkerEXT',
    'expectation': False,
    'extension': True,
    'impl_func': False,
  },

  'GenVertexArraysOES': {
    'type': 'GENn',
    'extension': True,
    'gl_test_func': 'glGenVertexArraysOES',
    'resource_type': 'VertexArray',
    'resource_types': 'VertexArrays',
    'unit_test': False,
    'pepper_interface': 'VertexArrayObject',
  },
  'BindVertexArrayOES': {
    'type': 'Bind',
    'extension': True,
    'gl_test_func': 'glBindVertexArrayOES',
    'decoder_func': 'DoBindVertexArrayOES',
    'gen_func': 'GenVertexArraysOES',
    'unit_test': False,
    'client_test': False,
    'pepper_interface': 'VertexArrayObject',
  },
  'DeleteVertexArraysOES': {
    'type': 'DELn',
    'extension': True,
    'gl_test_func': 'glDeleteVertexArraysOES',
    'resource_type': 'VertexArray',
    'resource_types': 'VertexArrays',
    'unit_test': False,
    'pepper_interface': 'VertexArrayObject',
  },
  'IsVertexArrayOES': {
    'type': 'Is',
    'extension': True,
    'gl_test_func': 'glIsVertexArrayOES',
    'decoder_func': 'DoIsVertexArrayOES',
    'expectation': False,
    'unit_test': False,
    'pepper_interface': 'VertexArrayObject',
  },
  'BindTexImage2DCHROMIUM': {
    'decoder_func': 'DoBindTexImage2DCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'ReleaseTexImage2DCHROMIUM': {
    'decoder_func': 'DoReleaseTexImage2DCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'ShallowFinishCHROMIUM': {
    'impl_func': False,
    'gen_cmd': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
  },
  'ShallowFlushCHROMIUM': {
    'impl_func': False,
    'gen_cmd': False,
    'extension': "CHROMIUM_miscellaneous",
    'chromium': True,
    'client_test': False,
  },
  'OrderingBarrierCHROMIUM': {
    'impl_func': False,
    'gen_cmd': False,
    'extension': True,
    'chromium': True,
    'client_test': False,
  },
  'TraceBeginCHROMIUM': {
    'type': 'Custom',
    'impl_func': False,
    'client_test': False,
    'cmd_args': 'GLuint category_bucket_id, GLuint name_bucket_id',
    'extension': True,
    'chromium': True,
  },
  'TraceEndCHROMIUM': {
    'impl_func': False,
    'client_test': False,
    'decoder_func': 'DoTraceEndCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'AsyncTexImage2DCHROMIUM': {
    'type': 'Manual',
    'data_transfer_methods': ['shm'],
    'client_test': False,
    'cmd_args': 'GLenumTextureTarget target, GLint level, '
        'GLintTextureInternalFormat internalformat, '
        'GLsizei width, GLsizei height, '
        'GLintTextureBorder border, '
        'GLenumTextureFormat format, GLenumPixelType type, '
        'const void* pixels, '
        'uint32_t async_upload_token, '
        'void* sync_data',
    'extension': True,
    'chromium': True,
  },
  'AsyncTexSubImage2DCHROMIUM': {
    'type': 'Manual',
    'data_transfer_methods': ['shm'],
    'client_test': False,
    'cmd_args': 'GLenumTextureTarget target, GLint level, '
        'GLint xoffset, GLint yoffset, '
        'GLsizei width, GLsizei height, '
        'GLenumTextureFormat format, GLenumPixelType type, '
        'const void* data, '
        'uint32_t async_upload_token, '
        'void* sync_data',
    'extension': True,
    'chromium': True,
  },
  'WaitAsyncTexImage2DCHROMIUM': {
    'type': 'Manual',
    'client_test': False,
    'extension': True,
    'chromium': True,
  },
  'WaitAllAsyncTexImage2DCHROMIUM': {
    'type': 'Manual',
    'client_test': False,
    'extension': True,
    'chromium': True,
  },
  'DiscardFramebufferEXT': {
    'type': 'PUTn',
    'count': 1,
    'decoder_func': 'DoDiscardFramebufferEXT',
    'unit_test': False,
    'client_test': False,
    'extension_flag': 'ext_discard_framebuffer',
  },
  'LoseContextCHROMIUM': {
    'decoder_func': 'DoLoseContextCHROMIUM',
    'unit_test': False,
    'extension': True,
    'chromium': True,
  },
  'InsertSyncPointCHROMIUM': {
    'type': 'HandWritten',
    'impl_func': False,
    'extension': "CHROMIUM_sync_point",
    'chromium': True,
  },
  'WaitSyncPointCHROMIUM': {
    'type': 'Custom',
    'impl_func': True,
    'extension': "CHROMIUM_sync_point",
    'chromium': True,
    'trace_level': 1,
  },
  'DiscardBackbufferCHROMIUM': {
    'type': 'Custom',
    'impl_func': True,
    'extension': True,
    'chromium': True,
  },
  'ScheduleOverlayPlaneCHROMIUM': {
      'type': 'Custom',
      'impl_func': True,
      'unit_test': False,
      'client_test': False,
      'extension': True,
      'chromium': True,
  },
  'MatrixLoadfCHROMIUM': {
    'type': 'PUT',
    'count': 16,
    'data_type': 'GLfloat',
    'decoder_func': 'DoMatrixLoadfCHROMIUM',
    'gl_test_func': 'glMatrixLoadfEXT',
    'chromium': True,
    'extension': True,
    'extension_flag': 'chromium_path_rendering',
  },
  'MatrixLoadIdentityCHROMIUM': {
    'decoder_func': 'DoMatrixLoadIdentityCHROMIUM',
    'gl_test_func': 'glMatrixLoadIdentityEXT',
    'chromium': True,
    'extension': True,
    'extension_flag': 'chromium_path_rendering',
  },
}


def Grouper(n, iterable, fillvalue=None):
  """Collect data into fixed-length chunks or blocks"""
  args = [iter(iterable)] * n
  return itertools.izip_longest(fillvalue=fillvalue, *args)


def SplitWords(input_string):
  """Transforms a input_string into a list of lower-case components.

  Args:
    input_string: the input string.

  Returns:
    a list of lower-case words.
  """
  if input_string.find('_') > -1:
    # 'some_TEXT_' -> 'some text'
    return input_string.replace('_', ' ').strip().lower().split()
  else:
    if re.search('[A-Z]', input_string) and re.search('[a-z]', input_string):
      # mixed case.
      # look for capitalization to cut input_strings
      # 'SomeText' -> 'Some Text'
      input_string = re.sub('([A-Z])', r' \1', input_string).strip()
      # 'Vector3' -> 'Vector 3'
      input_string = re.sub('([^0-9])([0-9])', r'\1 \2', input_string)
    return input_string.lower().split()


def Lower(words):
  """Makes a lower-case identifier from words.

  Args:
    words: a list of lower-case words.

  Returns:
    the lower-case identifier.
  """
  return '_'.join(words)


def ToUnderscore(input_string):
  """converts CamelCase to camel_case."""
  words = SplitWords(input_string)
  return Lower(words)

def CachedStateName(item):
  if item.get('cached', False):
    return 'cached_' + item['name']
  return item['name']

def ToGLExtensionString(extension_flag):
  """Returns GL-type extension string of a extension flag."""
  if extension_flag == "oes_compressed_etc1_rgb8_texture":
    return "OES_compressed_ETC1_RGB8_texture" # Fixup inconsitency with rgb8,
                                              # unfortunate.
  uppercase_words = [ 'img', 'ext', 'arb', 'chromium', 'oes', 'amd', 'bgra8888',
                      'egl', 'atc', 'etc1', 'angle']
  parts = extension_flag.split('_')
  return "_".join(
    [part.upper() if part in uppercase_words else part for part in parts])

def ToCamelCase(input_string):
  """converts ABC_underscore_case to ABCUnderscoreCase."""
  return ''.join(w[0].upper() + w[1:] for w in input_string.split('_'))

def GetGLGetTypeConversion(result_type, value_type, value):
  """Makes a gl compatible type conversion string for accessing state variables.

   Useful when accessing state variables through glGetXXX calls.
   glGet documetation (for example, the manual pages):
   [...] If glGetIntegerv is called, [...] most floating-point values are
   rounded to the nearest integer value. [...]

  Args:
   result_type: the gl type to be obtained
   value_type: the GL type of the state variable
   value: the name of the state variable

  Returns:
   String that converts the state variable to desired GL type according to GL
   rules.
  """

  if result_type == 'GLint':
    if value_type == 'GLfloat':
      return 'static_cast<GLint>(round(%s))' % value
  return 'static_cast<%s>(%s)' % (result_type, value)

class CWriter(object):
  """Writes to a file formatting it for Google's style guidelines."""

  def __init__(self, filename):
    self.filename = filename
    self.content = []

  def Write(self, string):
    """Writes a string to a file spliting if it's > 80 characters."""
    lines = string.splitlines()
    num_lines = len(lines)
    for ii in range(0, num_lines):
      self.content.append(lines[ii])
      if ii < (num_lines - 1) or string[-1] == '\n':
        self.content.append('\n')

  def Close(self):
    """Close the file."""
    content = "".join(self.content)
    write_file = True
    if os.path.exists(self.filename):
      old_file = open(self.filename, "rb");
      old_content = old_file.read()
      old_file.close();
      if content == old_content:
        write_file = False
    if write_file:
      file = open(self.filename, "wb")
      file.write(content)
      file.close()


class CHeaderWriter(CWriter):
  """Writes a C Header file."""

  _non_alnum_re = re.compile(r'[^a-zA-Z0-9]')

  def __init__(self, filename, file_comment = None):
    CWriter.__init__(self, filename)

    base = os.path.abspath(filename)
    while os.path.basename(base) != 'src':
      new_base = os.path.dirname(base)
      assert new_base != base  # Prevent infinite loop.
      base = new_base

    hpath = os.path.relpath(filename, base)
    self.guard = self._non_alnum_re.sub('_', hpath).upper() + '_'

    self.Write(_LICENSE)
    self.Write(_DO_NOT_EDIT_WARNING)
    if not file_comment == None:
      self.Write(file_comment)
    self.Write("#ifndef %s\n" % self.guard)
    self.Write("#define %s\n\n" % self.guard)

  def Close(self):
    self.Write("#endif  // %s\n\n" % self.guard)
    CWriter.Close(self)

class TypeHandler(object):
  """This class emits code for a particular type of function."""

  _remove_expected_call_re = re.compile(r'  EXPECT_CALL.*?;\n', re.S)

  def __init__(self):
    pass

  def InitFunction(self, func):
    """Add or adjust anything type specific for this function."""
    if func.GetInfo('needs_size') and not func.name.endswith('Bucket'):
      func.AddCmdArg(DataSizeArgument('data_size'))

  def NeedsDataTransferFunction(self, func):
    """Overriden from TypeHandler."""
    return func.num_pointer_args >= 1

  def WriteStruct(self, func, file):
    """Writes a structure that matches the arguments to a function."""
    comment = func.GetInfo('cmd_comment')
    if not comment == None:
      file.Write(comment)
    file.Write("struct %s {\n" % func.name)
    file.Write("  typedef %s ValueType;\n" % func.name)
    file.Write("  static const CommandId kCmdId = k%s;\n" % func.name)
    func.WriteCmdArgFlag(file)
    func.WriteCmdFlag(file)
    file.Write("\n")
    result = func.GetInfo('result')
    if not result == None:
      if len(result) == 1:
        file.Write("  typedef %s Result;\n\n" % result[0])
      else:
        file.Write("  struct Result {\n")
        for line in result:
          file.Write("    %s;\n" % line)
        file.Write("  };\n\n")

    func.WriteCmdComputeSize(file)
    func.WriteCmdSetHeader(file)
    func.WriteCmdInit(file)
    func.WriteCmdSet(file)

    file.Write("  gpu::CommandHeader header;\n")
    args = func.GetCmdArgs()
    for arg in args:
      file.Write("  %s %s;\n" % (arg.cmd_type, arg.name))

    consts = func.GetCmdConstants()
    for const in consts:
      file.Write("  static const %s %s = %s;\n" %
                 (const.cmd_type, const.name, const.GetConstantValue()))

    file.Write("};\n")
    file.Write("\n")

    size = len(args) * _SIZE_OF_UINT32 + _SIZE_OF_COMMAND_HEADER
    file.Write("static_assert(sizeof(%s) == %d,\n" % (func.name, size))
    file.Write("              \"size of %s should be %d\");\n" %
               (func.name, size))
    file.Write("static_assert(offsetof(%s, header) == 0,\n" % func.name)
    file.Write("              \"offset of %s header should be 0\");\n" %
               func.name)
    offset = _SIZE_OF_COMMAND_HEADER
    for arg in args:
      file.Write("static_assert(offsetof(%s, %s) == %d,\n" %
                 (func.name, arg.name, offset))
      file.Write("              \"offset of %s %s should be %d\");\n" %
                 (func.name, arg.name, offset))
      offset += _SIZE_OF_UINT32
    if not result == None and len(result) > 1:
      offset = 0;
      for line in result:
        parts = line.split()
        name = parts[-1]
        check = """
static_assert(offsetof(%(cmd_name)s::Result, %(field_name)s) == %(offset)d,
              "offset of %(cmd_name)s Result %(field_name)s should be "
              "%(offset)d");
"""
        file.Write((check.strip() + "\n") % {
              'cmd_name': func.name,
              'field_name': name,
              'offset': offset,
            })
        offset += _SIZE_OF_UINT32
    file.Write("\n")

  def WriteHandlerImplementation(self, func, file):
    """Writes the handler implementation for this command."""
    if func.IsUnsafe() and func.GetInfo('id_mapping'):
      code_no_gen = """  if (!group_->Get%(type)sServiceId(
        %(var)s, &%(service_var)s)) {
    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, "%(func)s", "invalid %(var)s id");
    return error::kNoError;
  }
"""
      code_gen = """  if (!group_->Get%(type)sServiceId(
        %(var)s, &%(service_var)s)) {
    if (!group_->bind_generates_resource()) {
      LOCAL_SET_GL_ERROR(
          GL_INVALID_OPERATION, "%(func)s", "invalid %(var)s id");
      return error::kNoError;
    }
    GLuint client_id = %(var)s;
    gl%(gen_func)s(1, &%(service_var)s);
    Create%(type)s(client_id, %(service_var)s);
  }
"""
      gen_func = func.GetInfo('gen_func')
      for id_type in func.GetInfo('id_mapping'):
        service_var = id_type.lower()
        if id_type == 'Sync':
          service_var = "service_%s" % service_var
          file.Write("  GLsync %s = 0;\n" % service_var)
        if gen_func and id_type in gen_func:
          file.Write(code_gen % { 'type': id_type,
                                  'var': id_type.lower(),
                                  'service_var': service_var,
                                  'func': func.GetGLFunctionName(),
                                  'gen_func': gen_func })
        else:
          file.Write(code_no_gen % { 'type': id_type,
                                     'var': id_type.lower(),
                                     'service_var': service_var,
                                     'func': func.GetGLFunctionName() })
    args = []
    for arg in func.GetOriginalArgs():
      if arg.type == "GLsync":
        args.append("service_%s" % arg.name)
      elif arg.name.endswith("size") and arg.type == "GLsizei":
        args.append("num_%s" % func.GetLastOriginalArg().name)
      elif arg.name == "length":
        args.append("nullptr")
      else:
        args.append(arg.name)
    file.Write("  %s(%s);\n" %
               (func.GetGLFunctionName(), ", ".join(args)))

  def WriteCmdSizeTest(self, func, file):
    """Writes the size test for a command."""
    file.Write("  EXPECT_EQ(sizeof(cmd), cmd.header.size * 4u);\n")

  def WriteFormatTest(self, func, file):
    """Writes a format test for a command."""
    file.Write("TEST_F(GLES2FormatTest, %s) {\n" % func.name)
    file.Write("  cmds::%s& cmd = *GetBufferAs<cmds::%s>();\n" %
               (func.name, func.name))
    file.Write("  void* next_cmd = cmd.Set(\n")
    file.Write("      &cmd")
    args = func.GetCmdArgs()
    for value, arg in enumerate(args):
      file.Write(",\n      static_cast<%s>(%d)" % (arg.type, value + 11))
    file.Write(");\n")
    file.Write("  EXPECT_EQ(static_cast<uint32_t>(cmds::%s::kCmdId),\n" %
               func.name)
    file.Write("            cmd.header.command);\n")
    func.type_handler.WriteCmdSizeTest(func, file)
    for value, arg in enumerate(args):
      file.Write("  EXPECT_EQ(static_cast<%s>(%d), cmd.%s);\n" %
                 (arg.type, value + 11, arg.name))
    file.Write("  CheckBytesWrittenMatchesExpectedSize(\n")
    file.Write("      next_cmd, sizeof(cmd));\n")
    file.Write("}\n")
    file.Write("\n")

  def WriteImmediateFormatTest(self, func, file):
    """Writes a format test for an immediate version of a command."""
    pass

  def WriteBucketFormatTest(self, func, file):
    """Writes a format test for a bucket version of a command."""
    pass

  def WriteGetDataSizeCode(self, func, file):
    """Writes the code to set data_size used in validation"""
    pass

  def WriteImmediateCmdSizeTest(self, func, file):
    """Writes a size test for an immediate version of a command."""
    file.Write("  // TODO(gman): Compute correct size.\n")
    file.Write("  EXPECT_EQ(sizeof(cmd), cmd.header.size * 4u);\n")

  def __WriteIdMapping(self, func, file):
    """Writes client side / service side ID mapping."""
    if not func.IsUnsafe() or not func.GetInfo('id_mapping'):
      return
    for id_type in func.GetInfo('id_mapping'):
      file.Write("  group_->Get%sServiceId(%s, &%s);\n" %
                 (id_type, id_type.lower(), id_type.lower()))

  def WriteImmediateHandlerImplementation (self, func, file):
    """Writes the handler impl for the immediate version of a command."""
    self.__WriteIdMapping(func, file)
    file.Write("  %s(%s);\n" %
               (func.GetGLFunctionName(), func.MakeOriginalArgString("")))

  def WriteBucketHandlerImplementation (self, func, file):
    """Writes the handler impl for the bucket version of a command."""
    self.__WriteIdMapping(func, file)
    file.Write("  %s(%s);\n" %
               (func.GetGLFunctionName(), func.MakeOriginalArgString("")))

  def WriteServiceHandlerFunctionHeader(self, func, file):
    """Writes function header for service implementation handlers."""
    file.Write("""error::Error GLES2DecoderImpl::Handle%(name)s(
        uint32_t immediate_data_size, const void* cmd_data) {
      """ % {'name': func.name})
    if func.IsUnsafe():
      file.Write("""if (!unsafe_es3_apis_enabled())
          return error::kUnknownCommand;
        """)
    file.Write("""const gles2::cmds::%(name)s& c =
          *static_cast<const gles2::cmds::%(name)s*>(cmd_data);
      (void)c;
      """ % {'name': func.name})

  def WriteServiceImplementation(self, func, file):
    """Writes the service implementation for a command."""
    self.WriteServiceHandlerFunctionHeader(func, file)
    self.WriteHandlerExtensionCheck(func, file)
    self.WriteHandlerDeferReadWrite(func, file);
    if len(func.GetOriginalArgs()) > 0:
      last_arg = func.GetLastOriginalArg()
      all_but_last_arg = func.GetOriginalArgs()[:-1]
      for arg in all_but_last_arg:
        arg.WriteGetCode(file)
      self.WriteGetDataSizeCode(func, file)
      last_arg.WriteGetCode(file)
    func.WriteHandlerValidation(file)
    func.WriteHandlerImplementation(file)
    file.Write("  return error::kNoError;\n")
    file.Write("}\n")
    file.Write("\n")

  def WriteImmediateServiceImplementation(self, func, file):
    """Writes the service implementation for an immediate version of command."""
    self.WriteServiceHandlerFunctionHeader(func, file)
    self.WriteHandlerExtensionCheck(func, file)
    self.WriteHandlerDeferReadWrite(func, file);
    for arg in func.GetOriginalArgs():
      if arg.IsPointer():
        self.WriteGetDataSizeCode(func, file)
      arg.WriteGetCode(file)
    func.WriteHandlerValidation(file)
    func.WriteHandlerImplementation(file)
    file.Write("  return error::kNoError;\n")
    file.Write("}\n")
    file.Write("\n")

  def WriteBucketServiceImplementation(self, func, file):
    """Writes the service implementation for a bucket version of command."""
    self.WriteServiceHandlerFunctionHeader(func, file)
    self.WriteHandlerExtensionCheck(func, file)
    self.WriteHandlerDeferReadWrite(func, file);
    for arg in func.GetCmdArgs():
      arg.WriteGetCode(file)
    func.WriteHandlerValidation(file)
    func.WriteHandlerImplementation(file)
    file.Write("  return error::kNoError;\n")
    file.Write("}\n")
    file.Write("\n")

  def WriteHandlerExtensionCheck(self, func, file):
    if func.GetInfo('extension_flag'):
      file.Write("  if (!features().%s) {\n" % func.GetInfo('extension_flag'))
      file.Write("    LOCAL_SET_GL_ERROR(GL_INVALID_OPERATION, \"gl%s\","
                 " \"function not available\");\n" % func.original_name)
      file.Write("    return error::kNoError;")
      file.Write("  }\n\n")

  def WriteHandlerDeferReadWrite(self, func, file):
    """Writes the code to handle deferring reads or writes."""
    defer_draws = func.GetInfo('defer_draws')
    defer_reads = func.GetInfo('defer_reads')
    if defer_draws or defer_reads:
      file.Write("  error::Error error;\n")
    if defer_draws:
      file.Write("  error = WillAccessBoundFramebufferForDraw();\n")
      file.Write("  if (error != error::kNoError)\n")
      file.Write("    return error;\n")
    if defer_reads:
      file.Write("  error = WillAccessBoundFramebufferForRead();\n")
      file.Write("  if (error != error::kNoError)\n")
      file.Write("    return error;\n")

  def WriteValidUnitTest(self, func, file, test, *extras):
    """Writes a valid unit test for the service implementation."""
    if func.GetInfo('expectation') == False:
      test = self._remove_expected_call_re.sub('', test)
    name = func.name
    arg_strings = [
      arg.GetValidArg(func) \
      for arg in func.GetOriginalArgs() if not arg.IsConstant()
    ]
    gl_arg_strings = [
      arg.GetValidGLArg(func) \
      for arg in func.GetOriginalArgs()
    ]
    gl_func_name = func.GetGLTestFunctionName()
    vars = {
      'name':name,
      'gl_func_name': gl_func_name,
      'args': ", ".join(arg_strings),
      'gl_args': ", ".join(gl_arg_strings),
    }
    for extra in extras:
      vars.update(extra)
    old_test = ""
    while (old_test != test):
      old_test = test
      test = test % vars
    file.Write(test % vars)

  def WriteInvalidUnitTest(self, func, file, test, *extras):
    """Writes an invalid unit test for the service implementation."""
    if func.IsUnsafe():
      return
    for invalid_arg_index, invalid_arg in enumerate(func.GetOriginalArgs()):
      # Service implementation does not test constants, as they are not part of
      # the call in the service side.
      if invalid_arg.IsConstant():
        continue

      num_invalid_values = invalid_arg.GetNumInvalidValues(func)
      for value_index in range(0, num_invalid_values):
        arg_strings = []
        parse_result = "kNoError"
        gl_error = None
        for arg in func.GetOriginalArgs():
          if arg.IsConstant():
            continue
          if invalid_arg is arg:
            (arg_string, parse_result, gl_error) = arg.GetInvalidArg(
                value_index)
          else:
            arg_string = arg.GetValidArg(func)
          arg_strings.append(arg_string)
        gl_arg_strings = []
        for arg in func.GetOriginalArgs():
          gl_arg_strings.append("_")
        gl_func_name = func.GetGLTestFunctionName()
        gl_error_test = ''
        if not gl_error == None:
          gl_error_test = '\n  EXPECT_EQ(%s, GetGLError());' % gl_error

        vars = {
          'name': func.name,
          'arg_index': invalid_arg_index,
          'value_index': value_index,
          'gl_func_name': gl_func_name,
          'args': ", ".join(arg_strings),
          'all_but_last_args': ", ".join(arg_strings[:-1]),
          'gl_args': ", ".join(gl_arg_strings),
          'parse_result': parse_result,
          'gl_error_test': gl_error_test,
        }
        for extra in extras:
          vars.update(extra)
        file.Write(test % vars)

  def WriteServiceUnitTest(self, func, file, *extras):
    """Writes the service unit test for a command."""

    if func.name == 'Enable':
      valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  SetupExpectationsForEnableDisable(%(gl_args)s, true);
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);"""
    elif func.name == 'Disable':
      valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  SetupExpectationsForEnableDisable(%(gl_args)s, false);
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);"""
    else:
      valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}
"""
    else:
      valid_test += """
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}
"""
    self.WriteValidUnitTest(func, file, valid_test, *extras)

    if not func.IsUnsafe():
      invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs%(arg_index)d_%(value_index)d) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s)).Times(0);
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::%(parse_result)s, ExecuteCmd(cmd));%(gl_error_test)s
}
"""
      self.WriteInvalidUnitTest(func, file, invalid_test, *extras)

  def WriteImmediateServiceUnitTest(self, func, file, *extras):
    """Writes the service unit test for an immediate command."""
    file.Write("// TODO(gman): %s\n" % func.name)

  def WriteImmediateValidationCode(self, func, file):
    """Writes the validation code for an immediate version of a command."""
    pass

  def WriteBucketServiceUnitTest(self, func, file, *extras):
    """Writes the service unit test for a bucket command."""
    file.Write("// TODO(gman): %s\n" % func.name)

  def WriteBucketValidationCode(self, func, file):
    """Writes the validation code for a bucket version of a command."""
    file.Write("// TODO(gman): %s\n" % func.name)

  def WriteGLES2ImplementationDeclaration(self, func, file):
    """Writes the GLES2 Implemention declaration."""
    impl_decl = func.GetInfo('impl_decl')
    if impl_decl == None or impl_decl == True:
      file.Write("%s %s(%s) override;\n" %
                 (func.return_type, func.original_name,
                  func.MakeTypedOriginalArgString("")))
      file.Write("\n")

  def WriteGLES2CLibImplementation(self, func, file):
    file.Write("%s GLES2%s(%s) {\n" %
               (func.return_type, func.name,
                func.MakeTypedOriginalArgString("")))
    result_string = "return "
    if func.return_type == "void":
      result_string = ""
    file.Write("  %sgles2::GetGLContext()->%s(%s);\n" %
               (result_string, func.original_name,
                func.MakeOriginalArgString("")))
    file.Write("}\n")

  def WriteGLES2Header(self, func, file):
    """Writes a re-write macro for GLES"""
    file.Write("#define gl%s GLES2_GET_FUN(%s)\n" %(func.name, func.name))

  def WriteClientGLCallLog(self, func, file):
    """Writes a logging macro for the client side code."""
    comma = ""
    if len(func.GetOriginalArgs()):
      comma = " << "
    file.Write(
        '  GPU_CLIENT_LOG("[" << GetLogPrefix() << "] gl%s("%s%s << ")");\n' %
        (func.original_name, comma, func.MakeLogArgString()))

  def WriteClientGLReturnLog(self, func, file):
    """Writes the return value logging code."""
    if func.return_type != "void":
      file.Write('  GPU_CLIENT_LOG("return:" << result)\n')

  def WriteGLES2ImplementationHeader(self, func, file):
    """Writes the GLES2 Implemention."""
    self.WriteGLES2ImplementationDeclaration(func, file)

  def WriteGLES2TraceImplementationHeader(self, func, file):
    """Writes the GLES2 Trace Implemention header."""
    file.Write("%s %s(%s) override;\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))

  def WriteGLES2TraceImplementation(self, func, file):
    """Writes the GLES2 Trace Implemention."""
    file.Write("%s GLES2TraceImplementation::%s(%s) {\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))
    result_string = "return "
    if func.return_type == "void":
      result_string = ""
    file.Write('  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "GLES2Trace::%s");\n' %
               func.name)
    file.Write("  %sgl_->%s(%s);\n" %
               (result_string, func.name, func.MakeOriginalArgString("")))
    file.Write("}\n")
    file.Write("\n")

  def WriteGLES2Implementation(self, func, file):
    """Writes the GLES2 Implemention."""
    impl_func = func.GetInfo('impl_func')
    impl_decl = func.GetInfo('impl_decl')
    gen_cmd = func.GetInfo('gen_cmd')
    if (func.can_auto_generate and
        (impl_func == None or impl_func == True) and
        (impl_decl == None or impl_decl == True) and
        (gen_cmd == None or gen_cmd == True)):
      file.Write("%s GLES2Implementation::%s(%s) {\n" %
                 (func.return_type, func.original_name,
                  func.MakeTypedOriginalArgString("")))
      file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
      self.WriteClientGLCallLog(func, file)
      func.WriteDestinationInitalizationValidation(file)
      for arg in func.GetOriginalArgs():
        arg.WriteClientSideValidationCode(file, func)
      file.Write("  helper_->%s(%s);\n" %
                 (func.name, func.MakeHelperArgString("")))
      file.Write("  CheckGLError();\n")
      self.WriteClientGLReturnLog(func, file)
      file.Write("}\n")
      file.Write("\n")

  def WriteGLES2InterfaceHeader(self, func, file):
    """Writes the GLES2 Interface."""
    file.Write("virtual %s %s(%s) = 0;\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))

  def WriteMojoGLES2ImplHeader(self, func, file):
    """Writes the Mojo GLES2 implementation header."""
    file.Write("%s %s(%s) override;\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))

  def WriteMojoGLES2Impl(self, func, file):
    """Writes the Mojo GLES2 implementation."""
    file.Write("%s MojoGLES2Impl::%s(%s) {\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))
    # TODO(alhaad): Add Mojo C thunk for each of the following methods and
    # remove this.
    func_list = ["GenQueriesEXT", "BeginQueryEXT", "MapTexSubImage2DCHROMIUM",
                 "UnmapTexSubImage2DCHROMIUM", "DeleteQueriesEXT",
                 "EndQueryEXT", "GetQueryObjectuivEXT", "ShallowFlushCHROMIUM"]
    if func.original_name in func_list:
      file.Write("return static_cast<gpu::gles2::GLES2Interface*>"
                 "(MojoGLES2GetGLES2Interface(context_))->" +
                 func.original_name + "(" + func.MakeOriginalArgString("") +
                 ");")
      file.Write("}")
      return

    extensions = ["CHROMIUM_sync_point", "CHROMIUM_texture_mailbox"]
    if func.IsCoreGLFunction() or func.GetInfo("extension") in extensions:
      file.Write("MojoGLES2MakeCurrent(context_);");
      func_return = "gl" + func.original_name + "(" + \
          func.MakeOriginalArgString("") + ");"
      if func.return_type == "void":
        file.Write(func_return);
      else:
        file.Write("return " + func_return);
    else:
      file.Write("NOTREACHED() << \"Unimplemented %s.\";\n" %
                 func.original_name);
      if func.return_type != "void":
        file.Write("return 0;")
    file.Write("}")

  def WriteGLES2InterfaceStub(self, func, file):
    """Writes the GLES2 Interface stub declaration."""
    file.Write("%s %s(%s) override;\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))

  def WriteGLES2InterfaceStubImpl(self, func, file):
    """Writes the GLES2 Interface stub declaration."""
    args = func.GetOriginalArgs()
    arg_string = ", ".join(
        ["%s /* %s */" % (arg.type, arg.name) for arg in args])
    file.Write("%s GLES2InterfaceStub::%s(%s) {\n" %
               (func.return_type, func.original_name, arg_string))
    if func.return_type != "void":
      file.Write("  return 0;\n")
    file.Write("}\n")

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Writes the GLES2 Implemention unit test."""
    client_test = func.GetInfo('client_test')
    if (func.can_auto_generate and
        (client_test == None or client_test == True)):
      code = """
TEST_F(GLES2ImplementationTest, %(name)s) {
  struct Cmds {
    cmds::%(name)s cmd;
  };
  Cmds expected;
  expected.cmd.Init(%(cmd_args)s);

  gl_->%(name)s(%(args)s);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}
"""
      cmd_arg_strings = [
        arg.GetValidClientSideCmdArg(func) for arg in func.GetCmdArgs()
      ]

      gl_arg_strings = [
        arg.GetValidClientSideArg(func) for arg in func.GetOriginalArgs()
      ]

      file.Write(code % {
            'name': func.name,
            'args': ", ".join(gl_arg_strings),
            'cmd_args': ", ".join(cmd_arg_strings),
          })

      # Test constants for invalid values, as they are not tested by the
      # service.
      constants = [arg for arg in func.GetOriginalArgs() if arg.IsConstant()]
      if constants:
        code = """
TEST_F(GLES2ImplementationTest, %(name)sInvalidConstantArg%(invalid_index)d) {
  gl_->%(name)s(%(args)s);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(%(gl_error)s, CheckError());
}
"""
        for invalid_arg in constants:
          gl_arg_strings = []
          invalid = invalid_arg.GetInvalidArg(func)
          for arg in func.GetOriginalArgs():
            if arg is invalid_arg:
              gl_arg_strings.append(invalid[0])
            else:
              gl_arg_strings.append(arg.GetValidClientSideArg(func))

          file.Write(code % {
            'name': func.name,
            'invalid_index': func.GetOriginalArgs().index(invalid_arg),
            'args': ", ".join(gl_arg_strings),
            'gl_error': invalid[2],
          })
    else:
      if client_test != False:
        file.Write("// TODO(zmo): Implement unit test for %s\n" % func.name)

  def WriteDestinationInitalizationValidation(self, func, file):
    """Writes the client side destintion initialization validation."""
    for arg in func.GetOriginalArgs():
      arg.WriteDestinationInitalizationValidation(file, func)

  def WriteTraceEvent(self, func, file):
    file.Write('  TRACE_EVENT0("gpu", "GLES2Implementation::%s");\n' %
               func.original_name)

  def WriteImmediateCmdComputeSize(self, func, file):
    """Writes the size computation code for the immediate version of a cmd."""
    file.Write("  static uint32_t ComputeSize(uint32_t size_in_bytes) {\n")
    file.Write("    return static_cast<uint32_t>(\n")
    file.Write("        sizeof(ValueType) +  // NOLINT\n")
    file.Write("        RoundSizeToMultipleOfEntries(size_in_bytes));\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSetHeader(self, func, file):
    """Writes the SetHeader function for the immediate version of a cmd."""
    file.Write("  void SetHeader(uint32_t size_in_bytes) {\n")
    file.Write("    header.SetCmdByTotalSize<ValueType>(size_in_bytes);\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdInit(self, func, file):
    """Writes the Init function for the immediate version of a command."""
    raise NotImplementedError(func.name)

  def WriteImmediateCmdSet(self, func, file):
    """Writes the Set function for the immediate version of a command."""
    raise NotImplementedError(func.name)

  def WriteCmdHelper(self, func, file):
    """Writes the cmd helper definition for a cmd."""
    code = """  void %(name)s(%(typed_args)s) {
    gles2::cmds::%(name)s* c = GetCmdSpace<gles2::cmds::%(name)s>();
    if (c) {
      c->Init(%(args)s);
    }
  }

"""
    file.Write(code % {
          "name": func.name,
          "typed_args": func.MakeTypedCmdArgString(""),
          "args": func.MakeCmdArgString(""),
        })

  def WriteImmediateCmdHelper(self, func, file):
    """Writes the cmd helper definition for the immediate version of a cmd."""
    code = """  void %(name)s(%(typed_args)s) {
    const uint32_t s = 0;  // TODO(gman): compute correct size
    gles2::cmds::%(name)s* c =
        GetImmediateCmdSpaceTotalSize<gles2::cmds::%(name)s>(s);
    if (c) {
      c->Init(%(args)s);
    }
  }

"""
    file.Write(code % {
           "name": func.name,
           "typed_args": func.MakeTypedCmdArgString(""),
           "args": func.MakeCmdArgString(""),
        })


class StateSetHandler(TypeHandler):
  """Handler for commands that simply set state."""

  def __init__(self):
    TypeHandler.__init__(self)

  def WriteHandlerImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    state_name = func.GetInfo('state')
    state = _STATES[state_name]
    states = state['states']
    args = func.GetOriginalArgs()
    for ndx,item in enumerate(states):
      code = []
      if 'range_checks' in item:
        for range_check in item['range_checks']:
          code.append("%s %s" % (args[ndx].name, range_check['check']))
      if 'nan_check' in item:
        # Drivers might generate an INVALID_VALUE error when a value is set
        # to NaN. This is allowed behavior under GLES 3.0 section 2.1.1 or
        # OpenGL 4.5 section 2.3.4.1 - providing NaN allows undefined results.
        # Make this behavior consistent within Chromium, and avoid leaking GL
        # errors by generating the error in the command buffer instead of
        # letting the GL driver generate it.
        code.append("std::isnan(%s)" % args[ndx].name)
      if len(code):
        file.Write("  if (%s) {\n" % " ||\n      ".join(code))
        file.Write(
          '    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE,'
          ' "%s", "%s out of range");\n' %
          (func.name, args[ndx].name))
        file.Write("    return error::kNoError;\n")
        file.Write("  }\n")
    code = []
    for ndx,item in enumerate(states):
      code.append("state_.%s != %s" % (item['name'], args[ndx].name))
    file.Write("  if (%s) {\n" % " ||\n      ".join(code))
    for ndx,item in enumerate(states):
      file.Write("    state_.%s = %s;\n" % (item['name'], args[ndx].name))
    if 'state_flag' in state:
      file.Write("    %s = true;\n" % state['state_flag'])
    if not func.GetInfo("no_gl"):
      for ndx,item in enumerate(states):
        if item.get('cached', False):
          file.Write("    state_.%s = %s;\n" %
                     (CachedStateName(item), args[ndx].name))
      file.Write("    %s(%s);\n" %
                 (func.GetGLFunctionName(), func.MakeOriginalArgString("")))
    file.Write("  }\n")

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    TypeHandler.WriteServiceUnitTest(self, func, file, *extras)
    state_name = func.GetInfo('state')
    state = _STATES[state_name]
    states = state['states']
    for ndx,item in enumerate(states):
      if 'range_checks' in item:
        for check_ndx, range_check in enumerate(item['range_checks']):
          valid_test = """
TEST_P(%(test_name)s, %(name)sInvalidValue%(ndx)d_%(check_ndx)d) {
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}
"""
          name = func.name
          arg_strings = [
            arg.GetValidArg(func) \
            for arg in func.GetOriginalArgs() if not arg.IsConstant()
          ]

          arg_strings[ndx] = range_check['test_value']
          vars = {
            'name': name,
            'ndx': ndx,
            'check_ndx': check_ndx,
            'args': ", ".join(arg_strings),
          }
          for extra in extras:
            vars.update(extra)
          file.Write(valid_test % vars)
      if 'nan_check' in item:
        valid_test = """
TEST_P(%(test_name)s, %(name)sNaNValue%(ndx)d) {
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}
"""
        name = func.name
        arg_strings = [
          arg.GetValidArg(func) \
          for arg in func.GetOriginalArgs() if not arg.IsConstant()
        ]

        arg_strings[ndx] = 'nanf("")'
        vars = {
          'name': name,
          'ndx': ndx,
          'args': ", ".join(arg_strings),
        }
        for extra in extras:
          vars.update(extra)
        file.Write(valid_test % vars)


class StateSetRGBAlphaHandler(TypeHandler):
  """Handler for commands that simply set state that have rgb/alpha."""

  def __init__(self):
    TypeHandler.__init__(self)

  def WriteHandlerImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    state_name = func.GetInfo('state')
    state = _STATES[state_name]
    states = state['states']
    args = func.GetOriginalArgs()
    num_args = len(args)
    code = []
    for ndx,item in enumerate(states):
      code.append("state_.%s != %s" % (item['name'], args[ndx % num_args].name))
    file.Write("  if (%s) {\n" % " ||\n      ".join(code))
    for ndx, item in enumerate(states):
      file.Write("    state_.%s = %s;\n" %
                 (item['name'], args[ndx % num_args].name))
    if 'state_flag' in state:
      file.Write("    %s = true;\n" % state['state_flag'])
    if not func.GetInfo("no_gl"):
      file.Write("    %s(%s);\n" %
                 (func.GetGLFunctionName(), func.MakeOriginalArgString("")))
      file.Write("  }\n")


class StateSetFrontBackSeparateHandler(TypeHandler):
  """Handler for commands that simply set state that have front/back."""

  def __init__(self):
    TypeHandler.__init__(self)

  def WriteHandlerImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    state_name = func.GetInfo('state')
    state = _STATES[state_name]
    states = state['states']
    args = func.GetOriginalArgs()
    face = args[0].name
    num_args = len(args)
    file.Write("  bool changed = false;\n")
    for group_ndx, group in enumerate(Grouper(num_args - 1, states)):
      file.Write("  if (%s == %s || %s == GL_FRONT_AND_BACK) {\n" %
                 (face, ('GL_FRONT', 'GL_BACK')[group_ndx], face))
      code = []
      for ndx, item in enumerate(group):
        code.append("state_.%s != %s" % (item['name'], args[ndx + 1].name))
      file.Write("    changed |= %s;\n" % " ||\n        ".join(code))
      file.Write("  }\n")
    file.Write("  if (changed) {\n")
    for group_ndx, group in enumerate(Grouper(num_args - 1, states)):
      file.Write("    if (%s == %s || %s == GL_FRONT_AND_BACK) {\n" %
                 (face, ('GL_FRONT', 'GL_BACK')[group_ndx], face))
      for ndx, item in enumerate(group):
        file.Write("      state_.%s = %s;\n" %
                   (item['name'], args[ndx + 1].name))
      file.Write("    }\n")
    if 'state_flag' in state:
      file.Write("    %s = true;\n" % state['state_flag'])
    if not func.GetInfo("no_gl"):
      file.Write("    %s(%s);\n" %
                 (func.GetGLFunctionName(), func.MakeOriginalArgString("")))
    file.Write("  }\n")


class StateSetFrontBackHandler(TypeHandler):
  """Handler for commands that simply set state that set both front/back."""

  def __init__(self):
    TypeHandler.__init__(self)

  def WriteHandlerImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    state_name = func.GetInfo('state')
    state = _STATES[state_name]
    states = state['states']
    args = func.GetOriginalArgs()
    num_args = len(args)
    code = []
    for group_ndx, group in enumerate(Grouper(num_args, states)):
      for ndx, item in enumerate(group):
        code.append("state_.%s != %s" % (item['name'], args[ndx].name))
    file.Write("  if (%s) {\n" % " ||\n      ".join(code))
    for group_ndx, group in enumerate(Grouper(num_args, states)):
      for ndx, item in enumerate(group):
        file.Write("    state_.%s = %s;\n" % (item['name'], args[ndx].name))
    if 'state_flag' in state:
      file.Write("    %s = true;\n" % state['state_flag'])
    if not func.GetInfo("no_gl"):
      file.Write("    %s(%s);\n" %
                 (func.GetGLFunctionName(), func.MakeOriginalArgString("")))
    file.Write("  }\n")


class StateSetNamedParameter(TypeHandler):
  """Handler for commands that set a state chosen with an enum parameter."""

  def __init__(self):
    TypeHandler.__init__(self)

  def WriteHandlerImplementation(self, func, file):
    """Overridden from TypeHandler."""
    state_name = func.GetInfo('state')
    state = _STATES[state_name]
    states = state['states']
    args = func.GetOriginalArgs()
    num_args = len(args)
    assert num_args == 2
    file.Write("  switch (%s) {\n" % args[0].name)
    for state in states:
      file.Write("    case %s:\n" % state['enum'])
      file.Write("      if (state_.%s != %s) {\n" %
                 (state['name'], args[1].name))
      file.Write("        state_.%s = %s;\n" % (state['name'], args[1].name))
      if not func.GetInfo("no_gl"):
        file.Write("        %s(%s);\n" %
                   (func.GetGLFunctionName(), func.MakeOriginalArgString("")))
      file.Write("      }\n")
      file.Write("      break;\n")
    file.Write("    default:\n")
    file.Write("      NOTREACHED();\n")
    file.Write("  }\n")


class CustomHandler(TypeHandler):
  """Handler for commands that are auto-generated but require minor tweaks."""

  def __init__(self):
    TypeHandler.__init__(self)

  def WriteServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteImmediateServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteBucketServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): %s\n\n" % func.name)

  def WriteImmediateServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): %s\n\n" % func.name)

  def WriteImmediateCmdGetTotalSize(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write(
        "    uint32_t total_size = 0;  // TODO(gman): get correct size.\n")

  def WriteImmediateCmdInit(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  void Init(%s) {\n" % func.MakeTypedCmdArgString("_"))
    self.WriteImmediateCmdGetTotalSize(func, file)
    file.Write("    SetHeader(total_size);\n")
    args = func.GetCmdArgs()
    for arg in args:
      file.Write("    %s = _%s;\n" % (arg.name, arg.name))
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSet(self, func, file):
    """Overrriden from TypeHandler."""
    copy_args = func.MakeCmdArgString("_", False)
    file.Write("  void* Set(void* cmd%s) {\n" %
               func.MakeTypedCmdArgString("_", True))
    self.WriteImmediateCmdGetTotalSize(func, file)
    file.Write("    static_cast<ValueType*>(cmd)->Init(%s);\n" % copy_args)
    file.Write("    return NextImmediateCmdAddressTotalSize<ValueType>("
               "cmd, total_size);\n")
    file.Write("  }\n")
    file.Write("\n")


class TodoHandler(CustomHandler):
  """Handle for commands that are not yet implemented."""

  def NeedsDataTransferFunction(self, func):
    """Overriden from TypeHandler."""
    return False

  def WriteImmediateFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("%s GLES2Implementation::%s(%s) {\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))
    file.Write("  // TODO: for now this is a no-op\n")
    file.Write(
        "  SetGLError("
        "GL_INVALID_OPERATION, \"gl%s\", \"not implemented\");\n" %
        func.name)
    if func.return_type != "void":
      file.Write("  return 0;\n")
    file.Write("}\n")
    file.Write("\n")

  def WriteServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    self.WriteServiceHandlerFunctionHeader(func, file)
    file.Write("  // TODO: for now this is a no-op\n")
    file.Write(
        "  LOCAL_SET_GL_ERROR("
        "GL_INVALID_OPERATION, \"gl%s\", \"not implemented\");\n" %
        func.name)
    file.Write("  return error::kNoError;\n")
    file.Write("}\n")
    file.Write("\n")


class HandWrittenHandler(CustomHandler):
  """Handler for comands where everything must be written by hand."""

  def InitFunction(self, func):
    """Add or adjust anything type specific for this function."""
    CustomHandler.InitFunction(self, func)
    func.can_auto_generate = False

  def NeedsDataTransferFunction(self, func):
    """Overriden from TypeHandler."""
    # If specified explicitly, force the data transfer method.
    if func.GetInfo('data_transfer_methods'):
      return True
    return False

  def WriteStruct(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteDocs(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): %s\n\n" % func.name)

  def WriteImmediateServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): %s\n\n" % func.name)

  def WriteBucketServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): %s\n\n" % func.name)

  def WriteServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteImmediateServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteBucketServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteImmediateCmdHelper(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteCmdHelper(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): Write test for %s\n" % func.name)

  def WriteImmediateFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): Write test for %s\n" % func.name)

  def WriteBucketFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): Write test for %s\n" % func.name)



class ManualHandler(CustomHandler):
  """Handler for commands who's handlers must be written by hand."""

  def __init__(self):
    CustomHandler.__init__(self)

  def InitFunction(self, func):
    """Overrriden from TypeHandler."""
    if (func.name == 'CompressedTexImage2DBucket'):
      func.cmd_args = func.cmd_args[:-1]
      func.AddCmdArg(Argument('bucket_id', 'GLuint'))
    else:
      CustomHandler.InitFunction(self, func)

  def WriteServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteBucketServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): %s\n\n" % func.name)

  def WriteImmediateServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): %s\n\n" % func.name)

  def WriteImmediateServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteImmediateFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): Implement test for %s\n" % func.name)

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    if func.GetInfo('impl_func'):
      super(ManualHandler, self).WriteGLES2Implementation(func, file)

  def WriteGLES2ImplementationHeader(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("%s %s(%s) override;\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))
    file.Write("\n")

  def WriteImmediateCmdGetTotalSize(self, func, file):
    """Overrriden from TypeHandler."""
    # TODO(gman): Move this data to _FUNCTION_INFO?
    CustomHandler.WriteImmediateCmdGetTotalSize(self, func, file)


class DataHandler(TypeHandler):
  """Handler for glBufferData, glBufferSubData, glTexImage2D, glTexSubImage2D,
     glCompressedTexImage2D, glCompressedTexImageSub2D."""
  def __init__(self):
    TypeHandler.__init__(self)

  def InitFunction(self, func):
    """Overrriden from TypeHandler."""
    if func.name == 'CompressedTexSubImage2DBucket':
      func.cmd_args = func.cmd_args[:-1]
      func.AddCmdArg(Argument('bucket_id', 'GLuint'))

  def WriteGetDataSizeCode(self, func, file):
    """Overrriden from TypeHandler."""
    # TODO(gman): Move this data to _FUNCTION_INFO?
    name = func.name
    if name.endswith("Immediate"):
      name = name[0:-9]
    if name == 'BufferData' or name == 'BufferSubData':
      file.Write("  uint32_t data_size = size;\n")
    elif (name == 'CompressedTexImage2D' or
          name == 'CompressedTexSubImage2D'):
      file.Write("  uint32_t data_size = imageSize;\n")
    elif (name == 'CompressedTexSubImage2DBucket'):
      file.Write("  Bucket* bucket = GetBucket(c.bucket_id);\n")
      file.Write("  uint32_t data_size = bucket->size();\n")
      file.Write("  GLsizei imageSize = data_size;\n")
    elif name == 'TexImage2D' or name == 'TexSubImage2D':
      code = """  uint32_t data_size;
  if (!GLES2Util::ComputeImageDataSize(
      width, height, format, type, unpack_alignment_, &data_size)) {
    return error::kOutOfBounds;
  }
"""
      file.Write(code)
    else:
      file.Write(
          "// uint32_t data_size = 0;  // TODO(gman): get correct size!\n")

  def WriteImmediateCmdGetTotalSize(self, func, file):
    """Overrriden from TypeHandler."""
    pass

  def WriteImmediateCmdSizeTest(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  EXPECT_EQ(sizeof(cmd), total_size);\n")

  def WriteImmediateCmdInit(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  void Init(%s) {\n" % func.MakeTypedCmdArgString("_"))
    self.WriteImmediateCmdGetTotalSize(func, file)
    file.Write("    SetHeader(total_size);\n")
    args = func.GetCmdArgs()
    for arg in args:
      file.Write("    %s = _%s;\n" % (arg.name, arg.name))
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSet(self, func, file):
    """Overrriden from TypeHandler."""
    copy_args = func.MakeCmdArgString("_", False)
    file.Write("  void* Set(void* cmd%s) {\n" %
               func.MakeTypedCmdArgString("_", True))
    self.WriteImmediateCmdGetTotalSize(func, file)
    file.Write("    static_cast<ValueType*>(cmd)->Init(%s);\n" % copy_args)
    file.Write("    return NextImmediateCmdAddressTotalSize<ValueType>("
               "cmd, total_size);\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    # TODO(gman): Remove this exception.
    file.Write("// TODO(gman): Implement test for %s\n" % func.name)
    return

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): %s\n\n" % func.name)

  def WriteImmediateServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    file.Write("// TODO(gman): %s\n\n" % func.name)

  def WriteBucketServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    if not func.name == 'CompressedTexSubImage2DBucket':
      TypeHandler.WriteBucketServiceImplemenation(self, func, file)


class BindHandler(TypeHandler):
  """Handler for glBind___ type functions."""

  def __init__(self):
    TypeHandler.__init__(self)

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""

    if len(func.GetOriginalArgs()) == 1:
      valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);"""
      if func.IsUnsafe():
        valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}
"""
      else:
        valid_test += """
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}
"""
      if func.GetInfo("gen_func"):
          valid_test += """
TEST_P(%(test_name)s, %(name)sValidArgsNewId) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(kNewServiceId));
  EXPECT_CALL(*gl_, %(gl_gen_func_name)s(1, _))
     .WillOnce(SetArgumentPointee<1>(kNewServiceId));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(kNewClientId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_TRUE(Get%(resource_type)s(kNewClientId) != NULL);
}
"""
      self.WriteValidUnitTest(func, file, valid_test, {
          'resource_type': func.GetOriginalArgs()[0].resource_type,
          'gl_gen_func_name': func.GetInfo("gen_func"),
      }, *extras)
    else:
      valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);"""
      if func.IsUnsafe():
        valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}
"""
      else:
        valid_test += """
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}
"""
      if func.GetInfo("gen_func"):
        valid_test += """
TEST_P(%(test_name)s, %(name)sValidArgsNewId) {
  EXPECT_CALL(*gl_,
              %(gl_func_name)s(%(gl_args_with_new_id)s));
  EXPECT_CALL(*gl_, %(gl_gen_func_name)s(1, _))
     .WillOnce(SetArgumentPointee<1>(kNewServiceId));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args_with_new_id)s);"""
        if func.IsUnsafe():
          valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_TRUE(Get%(resource_type)s(kNewClientId) != NULL);
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}
"""
        else:
          valid_test += """
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_TRUE(Get%(resource_type)s(kNewClientId) != NULL);
}
"""

      gl_args_with_new_id = []
      args_with_new_id = []
      for arg in func.GetOriginalArgs():
        if hasattr(arg, 'resource_type'):
          gl_args_with_new_id.append('kNewServiceId')
          args_with_new_id.append('kNewClientId')
        else:
          gl_args_with_new_id.append(arg.GetValidGLArg(func))
          args_with_new_id.append(arg.GetValidArg(func))
      self.WriteValidUnitTest(func, file, valid_test, {
          'args_with_new_id': ", ".join(args_with_new_id),
          'gl_args_with_new_id': ", ".join(gl_args_with_new_id),
          'resource_type': func.GetResourceIdArg().resource_type,
          'gl_gen_func_name': func.GetInfo("gen_func"),
      }, *extras)

    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs%(arg_index)d_%(value_index)d) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s)).Times(0);
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::%(parse_result)s, ExecuteCmd(cmd));%(gl_error_test)s
}
"""
    self.WriteInvalidUnitTest(func, file, invalid_test, *extras)

  def WriteGLES2Implementation(self, func, file):
    """Writes the GLES2 Implemention."""

    impl_func = func.GetInfo('impl_func')
    impl_decl = func.GetInfo('impl_decl')

    if (func.can_auto_generate and
          (impl_func == None or impl_func == True) and
          (impl_decl == None or impl_decl == True)):

      file.Write("%s GLES2Implementation::%s(%s) {\n" %
                 (func.return_type, func.original_name,
                  func.MakeTypedOriginalArgString("")))
      file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
      func.WriteDestinationInitalizationValidation(file)
      self.WriteClientGLCallLog(func, file)
      for arg in func.GetOriginalArgs():
        arg.WriteClientSideValidationCode(file, func)

      code = """  if (Is%(type)sReservedId(%(id)s)) {
    SetGLError(GL_INVALID_OPERATION, "%(name)s\", \"%(id)s reserved id");
    return;
  }
  %(name)sHelper(%(arg_string)s);
  CheckGLError();
}

"""
      name_arg = func.GetResourceIdArg()
      file.Write(code % {
          'name': func.name,
          'arg_string': func.MakeOriginalArgString(""),
          'id': name_arg.name,
          'type': name_arg.resource_type,
          'lc_type': name_arg.resource_type.lower(),
        })

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Overrriden from TypeHandler."""
    client_test = func.GetInfo('client_test')
    if client_test == False:
      return
    code = """
TEST_F(GLES2ImplementationTest, %(name)s) {
  struct Cmds {
    cmds::%(name)s cmd;
  };
  Cmds expected;
  expected.cmd.Init(%(cmd_args)s);

  gl_->%(name)s(%(args)s);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));"""
    if not func.IsUnsafe():
      code += """
  ClearCommands();
  gl_->%(name)s(%(args)s);
  EXPECT_TRUE(NoCommandsWritten());"""
    code += """
}
"""
    cmd_arg_strings = [
      arg.GetValidClientSideCmdArg(func) for arg in func.GetCmdArgs()
    ]
    gl_arg_strings = [
      arg.GetValidClientSideArg(func) for arg in func.GetOriginalArgs()
    ]

    file.Write(code % {
          'name': func.name,
          'args': ", ".join(gl_arg_strings),
          'cmd_args': ", ".join(cmd_arg_strings),
        })


class GENnHandler(TypeHandler):
  """Handler for glGen___ type functions."""

  def __init__(self):
    TypeHandler.__init__(self)

  def InitFunction(self, func):
    """Overrriden from TypeHandler."""
    pass

  def WriteGetDataSizeCode(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
"""
    file.Write(code)

  def WriteHandlerImplementation (self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  if (!%sHelper(n, %s)) {\n"
               "    return error::kInvalidArguments;\n"
               "  }\n" %
               (func.name, func.GetLastOriginalArg().name))

  def WriteImmediateHandlerImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    if func.IsUnsafe():
      file.Write("""  for (GLsizei ii = 0; ii < n; ++ii) {
    if (group_->Get%(resource_name)sServiceId(%(last_arg_name)s[ii], NULL)) {
      return error::kInvalidArguments;
    }
  }
  scoped_ptr<GLuint[]> service_ids(new GLuint[n]);
  gl%(func_name)s(n, service_ids.get());
  for (GLsizei ii = 0; ii < n; ++ii) {
    group_->Add%(resource_name)sId(%(last_arg_name)s[ii], service_ids[ii]);
  }
""" % { 'func_name': func.original_name,
        'last_arg_name': func.GetLastOriginalArg().name,
        'resource_name': func.GetInfo('resource_type') })
    else:
      file.Write("  if (!%sHelper(n, %s)) {\n"
                 "    return error::kInvalidArguments;\n"
                 "  }\n" %
                 (func.original_name, func.GetLastOriginalArg().name))

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    log_code = ("""  GPU_CLIENT_LOG_CODE_BLOCK({
    for (GLsizei i = 0; i < n; ++i) {
      GPU_CLIENT_LOG("  " << i << ": " << %s[i]);
    }
  });""" % func.GetOriginalArgs()[1].name)
    args = {
        'log_code': log_code,
        'return_type': func.return_type,
        'name': func.original_name,
        'typed_args': func.MakeTypedOriginalArgString(""),
        'args': func.MakeOriginalArgString(""),
        'resource_types': func.GetInfo('resource_types'),
        'count_name': func.GetOriginalArgs()[0].name,
      }
    file.Write(
        "%(return_type)s GLES2Implementation::%(name)s(%(typed_args)s) {\n" %
        args)
    func.WriteDestinationInitalizationValidation(file)
    self.WriteClientGLCallLog(func, file)
    for arg in func.GetOriginalArgs():
      arg.WriteClientSideValidationCode(file, func)
    not_shared = func.GetInfo('not_shared')
    if not_shared:
      alloc_code = (

"""  IdAllocator* id_allocator = GetIdAllocator(id_namespaces::k%s);
  for (GLsizei ii = 0; ii < n; ++ii)
    %s[ii] = id_allocator->AllocateID();""" %
  (func.GetInfo('resource_types'), func.GetOriginalArgs()[1].name))
    else:
      alloc_code = ("""  GetIdHandler(id_namespaces::k%(resource_types)s)->
      MakeIds(this, 0, %(args)s);""" % args)
    args['alloc_code'] = alloc_code

    code = """ GPU_CLIENT_SINGLE_THREAD_CHECK();
%(alloc_code)s
  %(name)sHelper(%(args)s);
  helper_->%(name)sImmediate(%(args)s);
  if (share_group_->bind_generates_resource())
    helper_->CommandBufferHelper::Flush();
%(log_code)s
  CheckGLError();
}

"""
    file.Write(code % args)

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Overrriden from TypeHandler."""
    code = """
TEST_F(GLES2ImplementationTest, %(name)s) {
  GLuint ids[2] = { 0, };
  struct Cmds {
    cmds::%(name)sImmediate gen;
    GLuint data[2];
  };
  Cmds expected;
  expected.gen.Init(arraysize(ids), &ids[0]);
  expected.data[0] = k%(types)sStartId;
  expected.data[1] = k%(types)sStartId + 1;
  gl_->%(name)s(arraysize(ids), &ids[0]);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(k%(types)sStartId, ids[0]);
  EXPECT_EQ(k%(types)sStartId + 1, ids[1]);
}
"""
    file.Write(code % {
          'name': func.name,
          'types': func.GetInfo('resource_types'),
        })

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(1, _))
      .WillOnce(SetArgumentPointee<1>(kNewServiceId));
  GetSharedMemoryAs<GLuint*>()[0] = kNewClientId;
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());"""
    if func.IsUnsafe():
      valid_test += """
  GLuint service_id;
  EXPECT_TRUE(Get%(resource_name)sServiceId(kNewClientId, &service_id));
  EXPECT_EQ(kNewServiceId, service_id)
}
"""
    else:
      valid_test += """
  EXPECT_TRUE(Get%(resource_name)s(kNewClientId, &service_id) != NULL);
}
"""
    self.WriteValidUnitTest(func, file, valid_test, {
        'resource_name': func.GetInfo('resource_type'),
      }, *extras)
    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(_, _)).Times(0);
  GetSharedMemoryAs<GLuint*>()[0] = client_%(resource_name)s_id_;
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::kInvalidArguments, ExecuteCmd(cmd));
}
"""
    self.WriteValidUnitTest(func, file, invalid_test, {
          'resource_name': func.GetInfo('resource_type').lower(),
        }, *extras)

  def WriteImmediateServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(1, _))
      .WillOnce(SetArgumentPointee<1>(kNewServiceId));
  cmds::%(name)s* cmd = GetImmediateAs<cmds::%(name)s>();
  GLuint temp = kNewClientId;
  SpecializedSetup<cmds::%(name)s, 0>(true);"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    valid_test += """
  cmd->Init(1, &temp);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(*cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());"""
    if func.IsUnsafe():
      valid_test += """
  GLuint service_id;
  EXPECT_TRUE(Get%(resource_name)sServiceId(kNewClientId, &service_id));
  EXPECT_EQ(kNewServiceId, service_id);
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand,
            ExecuteImmediateCmd(*cmd, sizeof(temp)));
}
"""
    else:
      valid_test += """
  EXPECT_TRUE(Get%(resource_name)s(kNewClientId) != NULL);
}
"""
    self.WriteValidUnitTest(func, file, valid_test, {
        'resource_name': func.GetInfo('resource_type'),
      }, *extras)
    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(_, _)).Times(0);
  cmds::%(name)s* cmd = GetImmediateAs<cmds::%(name)s>();
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmd->Init(1, &client_%(resource_name)s_id_);"""
    if func.IsUnsafe():
      invalid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kInvalidArguments,
            ExecuteImmediateCmd(*cmd, sizeof(&client_%(resource_name)s_id_)));
  decoder_->set_unsafe_es3_apis_enabled(false);
}
"""
    else:
      invalid_test += """
  EXPECT_EQ(error::kInvalidArguments,
            ExecuteImmediateCmd(*cmd, sizeof(&client_%(resource_name)s_id_)));
}
"""
    self.WriteValidUnitTest(func, file, invalid_test, {
          'resource_name': func.GetInfo('resource_type').lower(),
        }, *extras)

  def WriteImmediateCmdComputeSize(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  static uint32_t ComputeDataSize(GLsizei n) {\n")
    file.Write(
        "    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT\n")
    file.Write("  }\n")
    file.Write("\n")
    file.Write("  static uint32_t ComputeSize(GLsizei n) {\n")
    file.Write("    return static_cast<uint32_t>(\n")
    file.Write("        sizeof(ValueType) + ComputeDataSize(n));  // NOLINT\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSetHeader(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  void SetHeader(GLsizei n) {\n")
    file.Write("    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdInit(self, func, file):
    """Overrriden from TypeHandler."""
    last_arg = func.GetLastOriginalArg()
    file.Write("  void Init(%s, %s _%s) {\n" %
               (func.MakeTypedCmdArgString("_"),
                last_arg.type, last_arg.name))
    file.Write("    SetHeader(_n);\n")
    args = func.GetCmdArgs()
    for arg in args:
      file.Write("    %s = _%s;\n" % (arg.name, arg.name))
    file.Write("    memcpy(ImmediateDataAddress(this),\n")
    file.Write("           _%s, ComputeDataSize(_n));\n" % last_arg.name)
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSet(self, func, file):
    """Overrriden from TypeHandler."""
    last_arg = func.GetLastOriginalArg()
    copy_args = func.MakeCmdArgString("_", False)
    file.Write("  void* Set(void* cmd%s, %s _%s) {\n" %
               (func.MakeTypedCmdArgString("_", True),
                last_arg.type, last_arg.name))
    file.Write("    static_cast<ValueType*>(cmd)->Init(%s, _%s);\n" %
               (copy_args, last_arg.name))
    file.Write("    const uint32_t size = ComputeSize(_n);\n")
    file.Write("    return NextImmediateCmdAddressTotalSize<ValueType>("
               "cmd, size);\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdHelper(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  void %(name)s(%(typed_args)s) {
    const uint32_t size = gles2::cmds::%(name)s::ComputeSize(n);
    gles2::cmds::%(name)s* c =
        GetImmediateCmdSpaceTotalSize<gles2::cmds::%(name)s>(size);
    if (c) {
      c->Init(%(args)s);
    }
  }

"""
    file.Write(code % {
          "name": func.name,
          "typed_args": func.MakeTypedOriginalArgString(""),
          "args": func.MakeOriginalArgString(""),
        })

  def WriteImmediateFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("TEST_F(GLES2FormatTest, %s) {\n" % func.name)
    file.Write("  static GLuint ids[] = { 12, 23, 34, };\n")
    file.Write("  cmds::%s& cmd = *GetBufferAs<cmds::%s>();\n" %
               (func.name, func.name))
    file.Write("  void* next_cmd = cmd.Set(\n")
    file.Write("      &cmd, static_cast<GLsizei>(arraysize(ids)), ids);\n")
    file.Write("  EXPECT_EQ(static_cast<uint32_t>(cmds::%s::kCmdId),\n" %
               func.name)
    file.Write("            cmd.header.command);\n")
    file.Write("  EXPECT_EQ(sizeof(cmd) +\n")
    file.Write("            RoundSizeToMultipleOfEntries(cmd.n * 4u),\n")
    file.Write("            cmd.header.size * 4u);\n")
    file.Write("  EXPECT_EQ(static_cast<GLsizei>(arraysize(ids)), cmd.n);\n");
    file.Write("  CheckBytesWrittenMatchesExpectedSize(\n")
    file.Write("      next_cmd, sizeof(cmd) +\n")
    file.Write("      RoundSizeToMultipleOfEntries(arraysize(ids) * 4u));\n")
    file.Write("  // TODO(gman): Check that ids were inserted;\n")
    file.Write("}\n")
    file.Write("\n")


class CreateHandler(TypeHandler):
  """Handler for glCreate___ type functions."""

  def __init__(self):
    TypeHandler.__init__(self)

  def InitFunction(self, func):
    """Overrriden from TypeHandler."""
    func.AddCmdArg(Argument("client_id", 'uint32_t'))

  def __GetResourceType(self, func):
    if func.return_type == "GLsync":
      return "Sync"
    else:
      return func.name[6:]  # Create*

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  %(id_type_cast)sEXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s))
      .WillOnce(Return(%(const_service_id)s));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s%(comma)skNewClientId);"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    valid_test += """
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());"""
    if func.IsUnsafe():
      valid_test += """
  %(return_type)s service_id = 0;
  EXPECT_TRUE(Get%(resource_type)sServiceId(kNewClientId, &service_id));
  EXPECT_EQ(%(const_service_id)s, service_id);
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
}
"""
    else:
      valid_test += """
  EXPECT_TRUE(Get%(resource_type)s(kNewClientId));
}
"""
    comma = ""
    cmd_arg_count = 0
    for arg in func.GetOriginalArgs():
      if not arg.IsConstant():
        cmd_arg_count += 1
    if cmd_arg_count:
      comma = ", "
    if func.return_type == 'GLsync':
      id_type_cast = ("const GLsync kNewServiceIdGLuint = reinterpret_cast"
                      "<GLsync>(kNewServiceId);\n  ")
      const_service_id = "kNewServiceIdGLuint"
    else:
      id_type_cast = ""
      const_service_id = "kNewServiceId"
    self.WriteValidUnitTest(func, file, valid_test, {
          'comma': comma,
          'resource_type': self.__GetResourceType(func),
          'return_type': func.return_type,
          'id_type_cast': id_type_cast,
          'const_service_id': const_service_id,
        }, *extras)
    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs%(arg_index)d_%(value_index)d) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s)).Times(0);
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s%(comma)skNewClientId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));%(gl_error_test)s
}
"""
    self.WriteInvalidUnitTest(func, file, invalid_test, {
          'comma': comma,
        }, *extras)

  def WriteHandlerImplementation (self, func, file):
    """Overrriden from TypeHandler."""
    if func.IsUnsafe():
      code = """  uint32_t client_id = c.client_id;
  %(return_type)s service_id = 0;
  if (group_->Get%(resource_name)sServiceId(client_id, &service_id)) {
    return error::kInvalidArguments;
  }
  service_id = %(gl_func_name)s(%(gl_args)s);
  if (service_id) {
    group_->Add%(resource_name)sId(client_id, service_id);
  }
"""
    else:
      code = """  uint32_t client_id = c.client_id;
  if (Get%(resource_name)s(client_id)) {
    return error::kInvalidArguments;
  }
  %(return_type)s service_id = %(gl_func_name)s(%(gl_args)s);
  if (service_id) {
    Create%(resource_name)s(client_id, service_id%(gl_args_with_comma)s);
  }
"""
    file.Write(code % {
        'resource_name': self.__GetResourceType(func),
        'return_type': func.return_type,
        'gl_func_name': func.GetGLFunctionName(),
        'gl_args': func.MakeOriginalArgString(""),
        'gl_args_with_comma': func.MakeOriginalArgString("", True) })

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("%s GLES2Implementation::%s(%s) {\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))
    file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
    func.WriteDestinationInitalizationValidation(file)
    self.WriteClientGLCallLog(func, file)
    for arg in func.GetOriginalArgs():
      arg.WriteClientSideValidationCode(file, func)
    file.Write("  GLuint client_id;\n")
    if func.return_type == "GLsync":
      file.Write(
          "  GetIdHandler(id_namespaces::kSyncs)->\n")
    else:
      file.Write(
          "  GetIdHandler(id_namespaces::kProgramsAndShaders)->\n")
    file.Write("      MakeIds(this, 0, 1, &client_id);\n")
    file.Write("  helper_->%s(%s);\n" %
               (func.name, func.MakeCmdArgString("")))
    file.Write('  GPU_CLIENT_LOG("returned " << client_id);\n')
    file.Write("  CheckGLError();\n")
    if func.return_type == "GLsync":
      file.Write("  return reinterpret_cast<GLsync>(client_id);\n")
    else:
      file.Write("  return client_id;\n")
    file.Write("}\n")
    file.Write("\n")


class DeleteHandler(TypeHandler):
  """Handler for glDelete___ single resource type functions."""

  def __init__(self):
    TypeHandler.__init__(self)

  def WriteServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    if func.IsUnsafe():
      TypeHandler.WriteServiceImplementation(self, func, file)
    # HandleDeleteShader and HandleDeleteProgram are manually written.
    pass

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("%s GLES2Implementation::%s(%s) {\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))
    file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
    func.WriteDestinationInitalizationValidation(file)
    self.WriteClientGLCallLog(func, file)
    for arg in func.GetOriginalArgs():
      arg.WriteClientSideValidationCode(file, func)
    file.Write(
        "  GPU_CLIENT_DCHECK(%s != 0);\n" % func.GetOriginalArgs()[-1].name)
    file.Write("  %sHelper(%s);\n" %
               (func.original_name, func.GetOriginalArgs()[-1].name))
    file.Write("  CheckGLError();\n")
    file.Write("}\n")
    file.Write("\n")

  def WriteHandlerImplementation (self, func, file):
    """Overrriden from TypeHandler."""
    assert len(func.GetOriginalArgs()) == 1
    arg = func.GetOriginalArgs()[0]
    if func.IsUnsafe():
      file.Write("""  %(arg_type)s service_id = 0;
  if (group_->Get%(resource_type)sServiceId(%(arg_name)s, &service_id)) {
    glDelete%(resource_type)s(service_id);
    group_->Remove%(resource_type)sId(%(arg_name)s);
  } else {
     LOCAL_SET_GL_ERROR(
         GL_INVALID_VALUE, "gl%(func_name)s", "unknown %(arg_name)s");
  }
""" % { 'resource_type': func.GetInfo('resource_type'),
        'arg_name': arg.name,
        'arg_type': arg.type,
        'func_name': func.original_name })
    else:
      file.Write("  %sHelper(%s);\n" % (func.original_name, arg.name))

class DELnHandler(TypeHandler):
  """Handler for glDelete___ type functions."""

  def __init__(self):
    TypeHandler.__init__(self)

  def WriteGetDataSizeCode(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  uint32_t data_size;
  if (!SafeMultiplyUint32(n, sizeof(GLuint), &data_size)) {
    return error::kOutOfBounds;
  }
"""
    file.Write(code)

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Overrriden from TypeHandler."""
    code = """
TEST_F(GLES2ImplementationTest, %(name)s) {
  GLuint ids[2] = { k%(types)sStartId, k%(types)sStartId + 1 };
  struct Cmds {
    cmds::%(name)sImmediate del;
    GLuint data[2];
  };
  Cmds expected;
  expected.del.Init(arraysize(ids), &ids[0]);
  expected.data[0] = k%(types)sStartId;
  expected.data[1] = k%(types)sStartId + 1;
  gl_->%(name)s(arraysize(ids), &ids[0]);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}
"""
    file.Write(code % {
          'name': func.name,
          'types': func.GetInfo('resource_types'),
        })

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(
      *gl_,
      %(gl_func_name)s(1, Pointee(kService%(upper_resource_name)sId)))
      .Times(1);
  GetSharedMemoryAs<GLuint*>()[0] = client_%(resource_name)s_id_;
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
  EXPECT_TRUE(
      Get%(upper_resource_name)s(client_%(resource_name)s_id_) == NULL);
}
"""
    self.WriteValidUnitTest(func, file, valid_test, {
          'resource_name': func.GetInfo('resource_type').lower(),
          'upper_resource_name': func.GetInfo('resource_type'),
        }, *extras)
    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs) {
  GetSharedMemoryAs<GLuint*>()[0] = kInvalidClientId;
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
}
"""
    self.WriteValidUnitTest(func, file, invalid_test, *extras)

  def WriteImmediateServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(
      *gl_,
      %(gl_func_name)s(1, Pointee(kService%(upper_resource_name)sId)))
      .Times(1);
  cmds::%(name)s& cmd = *GetImmediateAs<cmds::%(name)s>();
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmd.Init(1, &client_%(resource_name)s_id_);"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    valid_test += """
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(client_%(resource_name)s_id_)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());"""
    if func.IsUnsafe():
      valid_test += """
  EXPECT_FALSE(Get%(upper_resource_name)sServiceId(
      client_%(resource_name)s_id_, NULL));
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand,
            ExecuteImmediateCmd(cmd, sizeof(client_%(resource_name)s_id_)));
}
"""
    else:
      valid_test += """
  EXPECT_TRUE(
      Get%(upper_resource_name)s(client_%(resource_name)s_id_) == NULL);
}
"""
    self.WriteValidUnitTest(func, file, valid_test, {
          'resource_name': func.GetInfo('resource_type').lower(),
          'upper_resource_name': func.GetInfo('resource_type'),
        }, *extras)
    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs) {
  cmds::%(name)s& cmd = *GetImmediateAs<cmds::%(name)s>();
  SpecializedSetup<cmds::%(name)s, 0>(false);
  GLuint temp = kInvalidClientId;
  cmd.Init(1, &temp);"""
    if func.IsUnsafe():
      invalid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(temp)));
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand,
            ExecuteImmediateCmd(cmd, sizeof(temp)));
}
"""
    else:
      invalid_test += """
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(temp)));
}
"""
    self.WriteValidUnitTest(func, file, invalid_test, *extras)

  def WriteHandlerImplementation (self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  %sHelper(n, %s);\n" %
               (func.name, func.GetLastOriginalArg().name))

  def WriteImmediateHandlerImplementation (self, func, file):
    """Overrriden from TypeHandler."""
    if func.IsUnsafe():
      file.Write("""  for (GLsizei ii = 0; ii < n; ++ii) {
    GLuint service_id = 0;
    if (group_->Get%(resource_type)sServiceId(
            %(last_arg_name)s[ii], &service_id)) {
      glDelete%(resource_type)ss(1, &service_id);
      group_->Remove%(resource_type)sId(%(last_arg_name)s[ii]);
    }
  }
""" % { 'resource_type': func.GetInfo('resource_type'),
        'last_arg_name': func.GetLastOriginalArg().name })
    else:
      file.Write("  %sHelper(n, %s);\n" %
                 (func.original_name, func.GetLastOriginalArg().name))

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    impl_decl = func.GetInfo('impl_decl')
    if impl_decl == None or impl_decl == True:
      args = {
          'return_type': func.return_type,
          'name': func.original_name,
          'typed_args': func.MakeTypedOriginalArgString(""),
          'args': func.MakeOriginalArgString(""),
          'resource_type': func.GetInfo('resource_type').lower(),
          'count_name': func.GetOriginalArgs()[0].name,
        }
      file.Write(
          "%(return_type)s GLES2Implementation::%(name)s(%(typed_args)s) {\n" %
          args)
      file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
      func.WriteDestinationInitalizationValidation(file)
      self.WriteClientGLCallLog(func, file)
      file.Write("""  GPU_CLIENT_LOG_CODE_BLOCK({
    for (GLsizei i = 0; i < n; ++i) {
      GPU_CLIENT_LOG("  " << i << ": " << %s[i]);
    }
  });
""" % func.GetOriginalArgs()[1].name)
      file.Write("""  GPU_CLIENT_DCHECK_CODE_BLOCK({
    for (GLsizei i = 0; i < n; ++i) {
      DCHECK(%s[i] != 0);
    }
  });
""" % func.GetOriginalArgs()[1].name)
      for arg in func.GetOriginalArgs():
        arg.WriteClientSideValidationCode(file, func)
      code = """  %(name)sHelper(%(args)s);
  CheckGLError();
}

"""
      file.Write(code % args)

  def WriteImmediateCmdComputeSize(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  static uint32_t ComputeDataSize(GLsizei n) {\n")
    file.Write(
        "    return static_cast<uint32_t>(sizeof(GLuint) * n);  // NOLINT\n")
    file.Write("  }\n")
    file.Write("\n")
    file.Write("  static uint32_t ComputeSize(GLsizei n) {\n")
    file.Write("    return static_cast<uint32_t>(\n")
    file.Write("        sizeof(ValueType) + ComputeDataSize(n));  // NOLINT\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSetHeader(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  void SetHeader(GLsizei n) {\n")
    file.Write("    header.SetCmdByTotalSize<ValueType>(ComputeSize(n));\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdInit(self, func, file):
    """Overrriden from TypeHandler."""
    last_arg = func.GetLastOriginalArg()
    file.Write("  void Init(%s, %s _%s) {\n" %
               (func.MakeTypedCmdArgString("_"),
                last_arg.type, last_arg.name))
    file.Write("    SetHeader(_n);\n")
    args = func.GetCmdArgs()
    for arg in args:
      file.Write("    %s = _%s;\n" % (arg.name, arg.name))
    file.Write("    memcpy(ImmediateDataAddress(this),\n")
    file.Write("           _%s, ComputeDataSize(_n));\n" % last_arg.name)
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSet(self, func, file):
    """Overrriden from TypeHandler."""
    last_arg = func.GetLastOriginalArg()
    copy_args = func.MakeCmdArgString("_", False)
    file.Write("  void* Set(void* cmd%s, %s _%s) {\n" %
               (func.MakeTypedCmdArgString("_", True),
                last_arg.type, last_arg.name))
    file.Write("    static_cast<ValueType*>(cmd)->Init(%s, _%s);\n" %
               (copy_args, last_arg.name))
    file.Write("    const uint32_t size = ComputeSize(_n);\n")
    file.Write("    return NextImmediateCmdAddressTotalSize<ValueType>("
               "cmd, size);\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdHelper(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  void %(name)s(%(typed_args)s) {
    const uint32_t size = gles2::cmds::%(name)s::ComputeSize(n);
    gles2::cmds::%(name)s* c =
        GetImmediateCmdSpaceTotalSize<gles2::cmds::%(name)s>(size);
    if (c) {
      c->Init(%(args)s);
    }
  }

"""
    file.Write(code % {
          "name": func.name,
          "typed_args": func.MakeTypedOriginalArgString(""),
          "args": func.MakeOriginalArgString(""),
        })

  def WriteImmediateFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("TEST_F(GLES2FormatTest, %s) {\n" % func.name)
    file.Write("  static GLuint ids[] = { 12, 23, 34, };\n")
    file.Write("  cmds::%s& cmd = *GetBufferAs<cmds::%s>();\n" %
               (func.name, func.name))
    file.Write("  void* next_cmd = cmd.Set(\n")
    file.Write("      &cmd, static_cast<GLsizei>(arraysize(ids)), ids);\n")
    file.Write("  EXPECT_EQ(static_cast<uint32_t>(cmds::%s::kCmdId),\n" %
               func.name)
    file.Write("            cmd.header.command);\n")
    file.Write("  EXPECT_EQ(sizeof(cmd) +\n")
    file.Write("            RoundSizeToMultipleOfEntries(cmd.n * 4u),\n")
    file.Write("            cmd.header.size * 4u);\n")
    file.Write("  EXPECT_EQ(static_cast<GLsizei>(arraysize(ids)), cmd.n);\n");
    file.Write("  CheckBytesWrittenMatchesExpectedSize(\n")
    file.Write("      next_cmd, sizeof(cmd) +\n")
    file.Write("      RoundSizeToMultipleOfEntries(arraysize(ids) * 4u));\n")
    file.Write("  // TODO(gman): Check that ids were inserted;\n")
    file.Write("}\n")
    file.Write("\n")


class GETnHandler(TypeHandler):
  """Handler for GETn for glGetBooleanv, glGetFloatv, ... type functions."""

  def __init__(self):
    TypeHandler.__init__(self)

  def NeedsDataTransferFunction(self, func):
    """Overriden from TypeHandler."""
    return False

  def WriteServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    self.WriteServiceHandlerFunctionHeader(func, file)
    last_arg = func.GetLastOriginalArg()
    # All except shm_id and shm_offset.
    all_but_last_args = func.GetCmdArgs()[:-2]
    for arg in all_but_last_args:
      arg.WriteGetCode(file)

    code = """  typedef cmds::%(func_name)s::Result Result;
  GLsizei num_values = 0;
  GetNumValuesReturnedForGLGet(pname, &num_values);
  Result* result = GetSharedMemoryAs<Result*>(
      c.%(last_arg_name)s_shm_id, c.%(last_arg_name)s_shm_offset,
      Result::ComputeSize(num_values));
  %(last_arg_type)s %(last_arg_name)s = result ? result->GetData() : NULL;
"""
    file.Write(code % {
        'last_arg_type': last_arg.type,
        'last_arg_name': last_arg.name,
        'func_name': func.name,
      })
    func.WriteHandlerValidation(file)
    code = """  // Check that the client initialized the result.
  if (result->size != 0) {
    return error::kInvalidArguments;
  }
"""
    shadowed = func.GetInfo('shadowed')
    if not shadowed:
      file.Write('  LOCAL_COPY_REAL_GL_ERRORS_TO_WRAPPER("%s");\n' % func.name)
    file.Write(code)
    func.WriteHandlerImplementation(file)
    if shadowed:
      code = """  result->SetNumResults(num_values);
  return error::kNoError;
}
"""
    else:
     code = """  GLenum error = glGetError();
  if (error == GL_NO_ERROR) {
    result->SetNumResults(num_values);
  } else {
    LOCAL_SET_GL_ERROR(error, "%(func_name)s", "");
  }
  return error::kNoError;
}

"""
    file.Write(code % {'func_name': func.name})

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    impl_decl = func.GetInfo('impl_decl')
    if impl_decl == None or impl_decl == True:
      file.Write("%s GLES2Implementation::%s(%s) {\n" %
                 (func.return_type, func.original_name,
                  func.MakeTypedOriginalArgString("")))
      file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
      func.WriteDestinationInitalizationValidation(file)
      self.WriteClientGLCallLog(func, file)
      for arg in func.GetOriginalArgs():
        arg.WriteClientSideValidationCode(file, func)
      all_but_last_args = func.GetOriginalArgs()[:-1]
      args = []
      has_length_arg = False
      for arg in all_but_last_args:
        if arg.type == 'GLsync':
          args.append('ToGLuint(%s)' % arg.name)
        elif arg.name.endswith('size') and arg.type == 'GLsizei':
          continue
        elif arg.name == 'length':
          has_length_arg = True
          continue
        else:
          args.append(arg.name)
      arg_string = ", ".join(args)
      all_arg_string = (
          ", ".join([
            "%s" % arg.name
              for arg in func.GetOriginalArgs() if not arg.IsConstant()]))
      self.WriteTraceEvent(func, file)
      code = """  if (%(func_name)sHelper(%(all_arg_string)s)) {
    return;
  }
  typedef cmds::%(func_name)s::Result Result;
  Result* result = GetResultAs<Result*>();
  if (!result) {
    return;
  }
  result->SetNumResults(0);
  helper_->%(func_name)s(%(arg_string)s,
      GetResultShmId(), GetResultShmOffset());
  WaitForCmd();
  result->CopyResult(%(last_arg_name)s);
  GPU_CLIENT_LOG_CODE_BLOCK({
    for (int32_t i = 0; i < result->GetNumResults(); ++i) {
      GPU_CLIENT_LOG("  " << i << ": " << result->GetData()[i]);
    }
  });"""
      if has_length_arg:
        code += """
  if (length) {
    *length = result->GetNumResults();
  }"""
      code += """
  CheckGLError();
}
"""
      file.Write(code % {
          'func_name': func.name,
          'arg_string': arg_string,
          'all_arg_string': all_arg_string,
          'last_arg_name': func.GetLastOriginalArg().name,
        })

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Writes the GLES2 Implemention unit test."""
    code = """
TEST_F(GLES2ImplementationTest, %(name)s) {
  struct Cmds {
    cmds::%(name)s cmd;
  };
  typedef cmds::%(name)s::Result::Type ResultType;
  ResultType result = 0;
  Cmds expected;
  ExpectedMemoryInfo result1 = GetExpectedResultMemory(
      sizeof(uint32_t) + sizeof(ResultType));
  expected.cmd.Init(%(cmd_args)s, result1.id, result1.offset);
  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result1.ptr, SizedResultHelper<ResultType>(1)))
      .RetiresOnSaturation();
  gl_->%(name)s(%(args)s, &result);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_EQ(static_cast<ResultType>(1), result);
}
"""
    first_cmd_arg = func.GetCmdArgs()[0].GetValidNonCachedClientSideCmdArg(func)
    if not first_cmd_arg:
      return

    first_gl_arg = func.GetOriginalArgs()[0].GetValidNonCachedClientSideArg(
        func)

    cmd_arg_strings = [first_cmd_arg]
    for arg in func.GetCmdArgs()[1:-2]:
      cmd_arg_strings.append(arg.GetValidClientSideCmdArg(func))
    gl_arg_strings = [first_gl_arg]
    for arg in func.GetOriginalArgs()[1:-1]:
      gl_arg_strings.append(arg.GetValidClientSideArg(func))

    file.Write(code % {
          'name': func.name,
          'args': ", ".join(gl_arg_strings),
          'cmd_args': ", ".join(cmd_arg_strings),
        })

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(*gl_, GetError())
      .WillOnce(Return(GL_NO_ERROR))
      .WillOnce(Return(GL_NO_ERROR))
      .RetiresOnSaturation();
  SpecializedSetup<cmds::%(name)s, 0>(true);
  typedef cmds::%(name)s::Result Result;
  Result* result = static_cast<Result*>(shared_memory_address_);
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(local_gl_args)s));
  result->size = 0;
  cmds::%(name)s cmd;
  cmd.Init(%(cmd_args)s);"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    valid_test += """
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(decoder_->GetGLES2Util()->GLGetNumValuesReturned(
                %(valid_pname)s),
            result->GetNumResults());
  EXPECT_EQ(GL_NO_ERROR, GetGLError());"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));"""
    valid_test += """
}
"""
    gl_arg_strings = []
    cmd_arg_strings = []
    valid_pname = ''
    for arg in func.GetOriginalArgs()[:-1]:
      if arg.name == 'length':
        gl_arg_value = 'nullptr'
      elif arg.name.endswith('size'):
        gl_arg_value = ("decoder_->GetGLES2Util()->GLGetNumValuesReturned(%s)" %
            valid_pname)
      elif arg.type == 'GLsync':
        gl_arg_value = 'reinterpret_cast<GLsync>(kServiceSyncId)'
      else:
        gl_arg_value = arg.GetValidGLArg(func)
      gl_arg_strings.append(gl_arg_value)
      if arg.name == 'pname':
        valid_pname = gl_arg_value
      if arg.name.endswith('size') or arg.name == 'length':
        continue
      if arg.type == 'GLsync':
        arg_value = 'client_sync_id_'
      else:
        arg_value = arg.GetValidArg(func)
      cmd_arg_strings.append(arg_value)
    if func.GetInfo('gl_test_func') == 'glGetIntegerv':
      gl_arg_strings.append("_")
    else:
      gl_arg_strings.append("result->GetData()")
    cmd_arg_strings.append("shared_memory_id_")
    cmd_arg_strings.append("shared_memory_offset_")

    self.WriteValidUnitTest(func, file, valid_test, {
        'local_gl_args': ", ".join(gl_arg_strings),
        'cmd_args': ", ".join(cmd_arg_strings),
        'valid_pname': valid_pname,
      }, *extras)

    if not func.IsUnsafe():
      invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs%(arg_index)d_%(value_index)d) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s)).Times(0);
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s::Result* result =
      static_cast<cmds::%(name)s::Result*>(shared_memory_address_);
  result->size = 0;
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::%(parse_result)s, ExecuteCmd(cmd));
  EXPECT_EQ(0u, result->size);%(gl_error_test)s
}
"""
      self.WriteInvalidUnitTest(func, file, invalid_test, *extras)

class ArrayArgTypeHandler(TypeHandler):
  """Base class for type handlers that handle args that are arrays"""

  def __init__(self):
    TypeHandler.__init__(self)

  def GetArrayType(self, func):
    """Returns the type of the element in the element array being PUT to."""
    for arg in func.GetOriginalArgs():
      if arg.IsPointer():
        element_type = arg.GetPointedType()
        return element_type

    # Special case: array type handler is used for a function that is forwarded
    # to the actual array type implementation
    element_type = func.GetOriginalArgs()[-1].type
    assert all(arg.type == element_type \
               for arg in func.GetOriginalArgs()[-self.GetArrayCount(func):])
    return element_type

  def GetArrayCount(self, func):
    """Returns the count of the elements in the array being PUT to."""
    return func.GetInfo('count')

class PUTHandler(ArrayArgTypeHandler):
  """Handler for glTexParameter_v, glVertexAttrib_v functions."""

  def __init__(self):
    ArrayArgTypeHandler.__init__(self)

  def WriteServiceUnitTest(self, func, file, *extras):
    """Writes the service unit test for a command."""
    expected_call = "EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s));"
    if func.GetInfo("first_element_only"):
      gl_arg_strings = [
        arg.GetValidGLArg(func) for arg in func.GetOriginalArgs()
      ]
      gl_arg_strings[-1] = "*" + gl_arg_strings[-1]
      expected_call = ("EXPECT_CALL(*gl_, %%(gl_func_name)s(%s));" %
          ", ".join(gl_arg_strings))
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  GetSharedMemoryAs<%(data_type)s*>()[0] = %(data_value)s;
  %(expected_call)s
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}
"""
    extra = {
      'data_type': self.GetArrayType(func),
      'data_value': func.GetInfo('data_value') or '0',
      'expected_call': expected_call,
    }
    self.WriteValidUnitTest(func, file, valid_test, extra, *extras)

    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs%(arg_index)d_%(value_index)d) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s)).Times(0);
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  GetSharedMemoryAs<%(data_type)s*>()[0] = %(data_value)s;
  EXPECT_EQ(error::%(parse_result)s, ExecuteCmd(cmd));%(gl_error_test)s
}
"""
    self.WriteInvalidUnitTest(func, file, invalid_test, extra, *extras)

  def WriteImmediateServiceUnitTest(self, func, file, *extras):
    """Writes the service unit test for a command."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  cmds::%(name)s& cmd = *GetImmediateAs<cmds::%(name)s>();
  SpecializedSetup<cmds::%(name)s, 0>(true);
  %(data_type)s temp[%(data_count)s] = { %(data_value)s, };
  cmd.Init(%(gl_args)s, &temp[0]);
  EXPECT_CALL(
      *gl_,
      %(gl_func_name)s(%(gl_args)s, %(data_ref)sreinterpret_cast<
          %(data_type)s*>(ImmediateDataAddress(&cmd))));"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    valid_test += """
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand,
            ExecuteImmediateCmd(cmd, sizeof(temp)));"""
    valid_test += """
}
"""
    gl_arg_strings = [
      arg.GetValidGLArg(func) for arg in func.GetOriginalArgs()[0:-1]
    ]
    gl_any_strings = ["_"] * len(gl_arg_strings)

    extra = {
      'data_ref': ("*" if func.GetInfo('first_element_only') else ""),
      'data_type': self.GetArrayType(func),
      'data_count': self.GetArrayCount(func),
      'data_value': func.GetInfo('data_value') or '0',
      'gl_args': ", ".join(gl_arg_strings),
      'gl_any_args': ", ".join(gl_any_strings),
    }
    self.WriteValidUnitTest(func, file, valid_test, extra, *extras)

    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs%(arg_index)d_%(value_index)d) {
  cmds::%(name)s& cmd = *GetImmediateAs<cmds::%(name)s>();"""
    if func.IsUnsafe():
      invalid_test += """
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_any_args)s, _)).Times(1);
"""
    else:
      invalid_test += """
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_any_args)s, _)).Times(0);
"""
    invalid_test += """
  SpecializedSetup<cmds::%(name)s, 0>(false);
  %(data_type)s temp[%(data_count)s] = { %(data_value)s, };
  cmd.Init(%(all_but_last_args)s, &temp[0]);"""
    if func.IsUnsafe():
      invalid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::%(parse_result)s,
            ExecuteImmediateCmd(cmd, sizeof(temp)));
  decoder_->set_unsafe_es3_apis_enabled(false);
}
"""
    else:
      invalid_test += """
  EXPECT_EQ(error::%(parse_result)s,
            ExecuteImmediateCmd(cmd, sizeof(temp)));
  %(gl_error_test)s
}
"""
    self.WriteInvalidUnitTest(func, file, invalid_test, extra, *extras)

  def WriteGetDataSizeCode(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  uint32_t data_size;
  if (!ComputeDataSize(1, sizeof(%s), %d, &data_size)) {
    return error::kOutOfBounds;
  }
"""
    file.Write(code % (self.GetArrayType(func), self.GetArrayCount(func)))
    if func.IsImmediate():
      file.Write("  if (data_size > immediate_data_size) {\n")
      file.Write("    return error::kOutOfBounds;\n")
      file.Write("  }\n")

  def __NeedsToCalcDataCount(self, func):
    use_count_func = func.GetInfo('use_count_func')
    return use_count_func != None and use_count_func != False

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    impl_func = func.GetInfo('impl_func')
    if (impl_func != None and impl_func != True):
      return;
    file.Write("%s GLES2Implementation::%s(%s) {\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))
    file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
    func.WriteDestinationInitalizationValidation(file)
    self.WriteClientGLCallLog(func, file)

    if self.__NeedsToCalcDataCount(func):
      file.Write("  size_t count = GLES2Util::Calc%sDataCount(%s);\n" %
                 (func.name, func.GetOriginalArgs()[0].name))
      file.Write("  DCHECK_LE(count, %du);\n" % self.GetArrayCount(func))
    else:
      file.Write("  size_t count = %d;" % self.GetArrayCount(func))
    file.Write("  for (size_t ii = 0; ii < count; ++ii)\n")
    file.Write('    GPU_CLIENT_LOG("value[" << ii << "]: " << %s[ii]);\n' %
               func.GetLastOriginalArg().name)
    for arg in func.GetOriginalArgs():
      arg.WriteClientSideValidationCode(file, func)
    file.Write("  helper_->%sImmediate(%s);\n" %
               (func.name, func.MakeOriginalArgString("")))
    file.Write("  CheckGLError();\n")
    file.Write("}\n")
    file.Write("\n")

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Writes the GLES2 Implemention unit test."""
    client_test = func.GetInfo('client_test')
    if (client_test != None and client_test != True):
      return;
    code = """
TEST_F(GLES2ImplementationTest, %(name)s) {
  %(type)s data[%(count)d] = {0};
  struct Cmds {
    cmds::%(name)sImmediate cmd;
    %(type)s data[%(count)d];
  };

  for (int jj = 0; jj < %(count)d; ++jj) {
    data[jj] = static_cast<%(type)s>(jj);
  }
  Cmds expected;
  expected.cmd.Init(%(cmd_args)s, &data[0]);
  gl_->%(name)s(%(args)s, &data[0]);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}
"""
    cmd_arg_strings = [
      arg.GetValidClientSideCmdArg(func) for arg in func.GetCmdArgs()[0:-2]
    ]
    gl_arg_strings = [
      arg.GetValidClientSideArg(func) for arg in func.GetOriginalArgs()[0:-1]
    ]

    file.Write(code % {
          'name': func.name,
          'type': self.GetArrayType(func),
          'count': self.GetArrayCount(func),
          'args': ", ".join(gl_arg_strings),
          'cmd_args': ", ".join(cmd_arg_strings),
        })

  def WriteImmediateCmdComputeSize(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  static uint32_t ComputeDataSize() {\n")
    file.Write("    return static_cast<uint32_t>(\n")
    file.Write("        sizeof(%s) * %d);\n" %
               (self.GetArrayType(func), self.GetArrayCount(func)))
    file.Write("  }\n")
    file.Write("\n")
    if self.__NeedsToCalcDataCount(func):
      file.Write("  static uint32_t ComputeEffectiveDataSize(%s %s) {\n" %
                 (func.GetOriginalArgs()[0].type,
                  func.GetOriginalArgs()[0].name))
      file.Write("    return static_cast<uint32_t>(\n")
      file.Write("        sizeof(%s) * GLES2Util::Calc%sDataCount(%s));\n" %
                 (self.GetArrayType(func), func.original_name,
                  func.GetOriginalArgs()[0].name))
      file.Write("  }\n")
      file.Write("\n")
    file.Write("  static uint32_t ComputeSize() {\n")
    file.Write("    return static_cast<uint32_t>(\n")
    file.Write(
        "        sizeof(ValueType) + ComputeDataSize());\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSetHeader(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  void SetHeader() {\n")
    file.Write(
        "    header.SetCmdByTotalSize<ValueType>(ComputeSize());\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdInit(self, func, file):
    """Overrriden from TypeHandler."""
    last_arg = func.GetLastOriginalArg()
    file.Write("  void Init(%s, %s _%s) {\n" %
               (func.MakeTypedCmdArgString("_"),
                last_arg.type, last_arg.name))
    file.Write("    SetHeader();\n")
    args = func.GetCmdArgs()
    for arg in args:
      file.Write("    %s = _%s;\n" % (arg.name, arg.name))
    file.Write("    memcpy(ImmediateDataAddress(this),\n")
    if self.__NeedsToCalcDataCount(func):
      file.Write("           _%s, ComputeEffectiveDataSize(%s));" %
                 (last_arg.name, func.GetOriginalArgs()[0].name))
      file.Write("""
    DCHECK_GE(ComputeDataSize(), ComputeEffectiveDataSize(%(arg)s));
    char* pointer = reinterpret_cast<char*>(ImmediateDataAddress(this)) +
        ComputeEffectiveDataSize(%(arg)s);
    memset(pointer, 0, ComputeDataSize() - ComputeEffectiveDataSize(%(arg)s));
""" % { 'arg': func.GetOriginalArgs()[0].name, })
    else:
      file.Write("           _%s, ComputeDataSize());\n" % last_arg.name)
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSet(self, func, file):
    """Overrriden from TypeHandler."""
    last_arg = func.GetLastOriginalArg()
    copy_args = func.MakeCmdArgString("_", False)
    file.Write("  void* Set(void* cmd%s, %s _%s) {\n" %
               (func.MakeTypedCmdArgString("_", True),
                last_arg.type, last_arg.name))
    file.Write("    static_cast<ValueType*>(cmd)->Init(%s, _%s);\n" %
               (copy_args, last_arg.name))
    file.Write("    const uint32_t size = ComputeSize();\n")
    file.Write("    return NextImmediateCmdAddressTotalSize<ValueType>("
               "cmd, size);\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdHelper(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  void %(name)s(%(typed_args)s) {
    const uint32_t size = gles2::cmds::%(name)s::ComputeSize();
    gles2::cmds::%(name)s* c =
        GetImmediateCmdSpaceTotalSize<gles2::cmds::%(name)s>(size);
    if (c) {
      c->Init(%(args)s);
    }
  }

"""
    file.Write(code % {
          "name": func.name,
          "typed_args": func.MakeTypedOriginalArgString(""),
          "args": func.MakeOriginalArgString(""),
        })

  def WriteImmediateFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("TEST_F(GLES2FormatTest, %s) {\n" % func.name)
    file.Write("  const int kSomeBaseValueToTestWith = 51;\n")
    file.Write("  static %s data[] = {\n" % self.GetArrayType(func))
    for v in range(0, self.GetArrayCount(func)):
      file.Write("    static_cast<%s>(kSomeBaseValueToTestWith + %d),\n" %
                 (self.GetArrayType(func), v))
    file.Write("  };\n")
    file.Write("  cmds::%s& cmd = *GetBufferAs<cmds::%s>();\n" %
               (func.name, func.name))
    file.Write("  void* next_cmd = cmd.Set(\n")
    file.Write("      &cmd")
    args = func.GetCmdArgs()
    for value, arg in enumerate(args):
      file.Write(",\n      static_cast<%s>(%d)" % (arg.type, value + 11))
    file.Write(",\n      data);\n")
    args = func.GetCmdArgs()
    file.Write("  EXPECT_EQ(static_cast<uint32_t>(cmds::%s::kCmdId),\n"
               % func.name)
    file.Write("            cmd.header.command);\n")
    file.Write("  EXPECT_EQ(sizeof(cmd) +\n")
    file.Write("            RoundSizeToMultipleOfEntries(sizeof(data)),\n")
    file.Write("            cmd.header.size * 4u);\n")
    for value, arg in enumerate(args):
      file.Write("  EXPECT_EQ(static_cast<%s>(%d), cmd.%s);\n" %
                 (arg.type, value + 11, arg.name))
    file.Write("  CheckBytesWrittenMatchesExpectedSize(\n")
    file.Write("      next_cmd, sizeof(cmd) +\n")
    file.Write("      RoundSizeToMultipleOfEntries(sizeof(data)));\n")
    file.Write("  // TODO(gman): Check that data was inserted;\n")
    file.Write("}\n")
    file.Write("\n")


class PUTnHandler(ArrayArgTypeHandler):
  """Handler for PUTn 'glUniform__v' type functions."""

  def __init__(self):
    ArrayArgTypeHandler.__init__(self)

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overridden from TypeHandler."""
    ArrayArgTypeHandler.WriteServiceUnitTest(self, func, file, *extras)

    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgsCountTooLarge) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}
"""
    gl_arg_strings = []
    arg_strings = []
    for count, arg in enumerate(func.GetOriginalArgs()):
      # hardcoded to match unit tests.
      if count == 0:
        # the location of the second element of the 2nd uniform.
        # defined in GLES2DecoderBase::SetupShaderForUniform
        gl_arg_strings.append("3")
        arg_strings.append("ProgramManager::MakeFakeLocation(1, 1)")
      elif count == 1:
        # the number of elements that gl will be called with.
        gl_arg_strings.append("3")
        # the number of elements requested in the command.
        arg_strings.append("5")
      else:
        gl_arg_strings.append(arg.GetValidGLArg(func))
        if not arg.IsConstant():
          arg_strings.append(arg.GetValidArg(func))
    extra = {
      'gl_args': ", ".join(gl_arg_strings),
      'args': ", ".join(arg_strings),
    }
    self.WriteValidUnitTest(func, file, valid_test, extra, *extras)

  def WriteImmediateServiceUnitTest(self, func, file, *extras):
    """Overridden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  cmds::%(name)s& cmd = *GetImmediateAs<cmds::%(name)s>();
  EXPECT_CALL(
      *gl_,
      %(gl_func_name)s(%(gl_args)s,
          reinterpret_cast<%(data_type)s*>(ImmediateDataAddress(&cmd))));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  %(data_type)s temp[%(data_count)s * 2] = { 0, };
  cmd.Init(%(args)s, &temp[0]);"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    valid_test += """
  EXPECT_EQ(error::kNoError,
            ExecuteImmediateCmd(cmd, sizeof(temp)));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand,
            ExecuteImmediateCmd(cmd, sizeof(temp)));"""
    valid_test += """
}
"""
    gl_arg_strings = []
    gl_any_strings = []
    arg_strings = []
    for arg in func.GetOriginalArgs()[0:-1]:
      gl_arg_strings.append(arg.GetValidGLArg(func))
      gl_any_strings.append("_")
      if not arg.IsConstant():
        arg_strings.append(arg.GetValidArg(func))
    extra = {
      'data_type': self.GetArrayType(func),
      'data_count': self.GetArrayCount(func),
      'args': ", ".join(arg_strings),
      'gl_args': ", ".join(gl_arg_strings),
      'gl_any_args': ", ".join(gl_any_strings),
    }
    self.WriteValidUnitTest(func, file, valid_test, extra, *extras)

    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs%(arg_index)d_%(value_index)d) {
  cmds::%(name)s& cmd = *GetImmediateAs<cmds::%(name)s>();
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_any_args)s, _)).Times(0);
  SpecializedSetup<cmds::%(name)s, 0>(false);
  %(data_type)s temp[%(data_count)s * 2] = { 0, };
  cmd.Init(%(all_but_last_args)s, &temp[0]);
  EXPECT_EQ(error::%(parse_result)s,
            ExecuteImmediateCmd(cmd, sizeof(temp)));%(gl_error_test)s
}
"""
    self.WriteInvalidUnitTest(func, file, invalid_test, extra, *extras)

  def WriteGetDataSizeCode(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  uint32_t data_size;
  if (!ComputeDataSize(count, sizeof(%s), %d, &data_size)) {
    return error::kOutOfBounds;
  }
"""
    file.Write(code % (self.GetArrayType(func), self.GetArrayCount(func)))
    if func.IsImmediate():
      file.Write("  if (data_size > immediate_data_size) {\n")
      file.Write("    return error::kOutOfBounds;\n")
      file.Write("  }\n")

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("%s GLES2Implementation::%s(%s) {\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))
    file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
    func.WriteDestinationInitalizationValidation(file)
    self.WriteClientGLCallLog(func, file)
    last_pointer_name = func.GetLastOriginalPointerArg().name
    file.Write("""  GPU_CLIENT_LOG_CODE_BLOCK({
    for (GLsizei i = 0; i < count; ++i) {
""")
    values_str = ' << ", " << '.join(
        ["%s[%d + i * %d]" % (
            last_pointer_name, ndx, self.GetArrayCount(func)) for ndx in range(
                0, self.GetArrayCount(func))])
    file.Write('       GPU_CLIENT_LOG("  " << i << ": " << %s);\n' % values_str)
    file.Write("    }\n  });\n")
    for arg in func.GetOriginalArgs():
      arg.WriteClientSideValidationCode(file, func)
    file.Write("  helper_->%sImmediate(%s);\n" %
               (func.name, func.MakeInitString("")))
    file.Write("  CheckGLError();\n")
    file.Write("}\n")
    file.Write("\n")

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Writes the GLES2 Implemention unit test."""
    code = """
TEST_F(GLES2ImplementationTest, %(name)s) {
  %(type)s data[%(count_param)d][%(count)d] = {{0}};
  struct Cmds {
    cmds::%(name)sImmediate cmd;
    %(type)s data[%(count_param)d][%(count)d];
  };

  Cmds expected;
  for (int ii = 0; ii < %(count_param)d; ++ii) {
    for (int jj = 0; jj < %(count)d; ++jj) {
      data[ii][jj] = static_cast<%(type)s>(ii * %(count)d + jj);
    }
  }
  expected.cmd.Init(%(cmd_args)s);
  gl_->%(name)s(%(args)s);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}
"""
    cmd_arg_strings = []
    for arg in func.GetCmdArgs():
      if arg.name.endswith("_shm_id"):
        cmd_arg_strings.append("&data[0][0]")
      elif arg.name.endswith("_shm_offset"):
        continue
      else:
        cmd_arg_strings.append(arg.GetValidClientSideCmdArg(func))
    gl_arg_strings = []
    count_param = 0
    for arg in func.GetOriginalArgs():
      if arg.IsPointer():
        valid_value = "&data[0][0]"
      else:
        valid_value = arg.GetValidClientSideArg(func)
      gl_arg_strings.append(valid_value)
      if arg.name == "count":
        count_param = int(valid_value)
    file.Write(code % {
          'name': func.name,
          'type': self.GetArrayType(func),
          'count': self.GetArrayCount(func),
          'args': ", ".join(gl_arg_strings),
          'cmd_args': ", ".join(cmd_arg_strings),
          'count_param': count_param,
        })

    # Test constants for invalid values, as they are not tested by the
    # service.
    constants = [
      arg for arg in func.GetOriginalArgs()[0:-1] if arg.IsConstant()
    ]
    if not constants:
      return

    code = """
TEST_F(GLES2ImplementationTest, %(name)sInvalidConstantArg%(invalid_index)d) {
  %(type)s data[%(count_param)d][%(count)d] = {{0}};
  for (int ii = 0; ii < %(count_param)d; ++ii) {
    for (int jj = 0; jj < %(count)d; ++jj) {
      data[ii][jj] = static_cast<%(type)s>(ii * %(count)d + jj);
    }
  }
  gl_->%(name)s(%(args)s);
  EXPECT_TRUE(NoCommandsWritten());
  EXPECT_EQ(%(gl_error)s, CheckError());
}
"""
    for invalid_arg in constants:
      gl_arg_strings = []
      invalid = invalid_arg.GetInvalidArg(func)
      for arg in func.GetOriginalArgs():
        if arg is invalid_arg:
          gl_arg_strings.append(invalid[0])
        elif arg.IsPointer():
          gl_arg_strings.append("&data[0][0]")
        else:
          valid_value = arg.GetValidClientSideArg(func)
          gl_arg_strings.append(valid_value)
          if arg.name == "count":
            count_param = int(valid_value)

      file.Write(code % {
        'name': func.name,
        'invalid_index': func.GetOriginalArgs().index(invalid_arg),
        'type': self.GetArrayType(func),
        'count': self.GetArrayCount(func),
        'args': ", ".join(gl_arg_strings),
        'gl_error': invalid[2],
        'count_param': count_param,
      })


  def WriteImmediateCmdComputeSize(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  static uint32_t ComputeDataSize(GLsizei count) {\n")
    file.Write("    return static_cast<uint32_t>(\n")
    file.Write("        sizeof(%s) * %d * count);  // NOLINT\n" %
               (self.GetArrayType(func), self.GetArrayCount(func)))
    file.Write("  }\n")
    file.Write("\n")
    file.Write("  static uint32_t ComputeSize(GLsizei count) {\n")
    file.Write("    return static_cast<uint32_t>(\n")
    file.Write(
        "        sizeof(ValueType) + ComputeDataSize(count));  // NOLINT\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSetHeader(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  void SetHeader(GLsizei count) {\n")
    file.Write(
        "    header.SetCmdByTotalSize<ValueType>(ComputeSize(count));\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdInit(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  void Init(%s) {\n" %
               func.MakeTypedInitString("_"))
    file.Write("    SetHeader(_count);\n")
    args = func.GetCmdArgs()
    for arg in args:
      file.Write("    %s = _%s;\n" % (arg.name, arg.name))
    file.Write("    memcpy(ImmediateDataAddress(this),\n")
    pointer_arg = func.GetLastOriginalPointerArg()
    file.Write("           _%s, ComputeDataSize(_count));\n" % pointer_arg.name)
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdSet(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  void* Set(void* cmd%s) {\n" %
               func.MakeTypedInitString("_", True))
    file.Write("    static_cast<ValueType*>(cmd)->Init(%s);\n" %
               func.MakeInitString("_"))
    file.Write("    const uint32_t size = ComputeSize(_count);\n")
    file.Write("    return NextImmediateCmdAddressTotalSize<ValueType>("
               "cmd, size);\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdHelper(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  void %(name)s(%(typed_args)s) {
    const uint32_t size = gles2::cmds::%(name)s::ComputeSize(count);
    gles2::cmds::%(name)s* c =
        GetImmediateCmdSpaceTotalSize<gles2::cmds::%(name)s>(size);
    if (c) {
      c->Init(%(args)s);
    }
  }

"""
    file.Write(code % {
          "name": func.name,
          "typed_args": func.MakeTypedInitString(""),
          "args": func.MakeInitString("")
        })

  def WriteImmediateFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    args = func.GetOriginalArgs()
    count_param = 0
    for arg in args:
      if arg.name == "count":
        count_param = int(arg.GetValidClientSideCmdArg(func))
    file.Write("TEST_F(GLES2FormatTest, %s) {\n" % func.name)
    file.Write("  const int kSomeBaseValueToTestWith = 51;\n")
    file.Write("  static %s data[] = {\n" % self.GetArrayType(func))
    for v in range(0, self.GetArrayCount(func) * count_param):
      file.Write("    static_cast<%s>(kSomeBaseValueToTestWith + %d),\n" %
                 (self.GetArrayType(func), v))
    file.Write("  };\n")
    file.Write("  cmds::%s& cmd = *GetBufferAs<cmds::%s>();\n" %
               (func.name, func.name))
    file.Write("  const GLsizei kNumElements = %d;\n" % count_param)
    file.Write("  const size_t kExpectedCmdSize =\n")
    file.Write("      sizeof(cmd) + kNumElements * sizeof(%s) * %d;\n" %
               (self.GetArrayType(func), self.GetArrayCount(func)))
    file.Write("  void* next_cmd = cmd.Set(\n")
    file.Write("      &cmd")
    for value, arg in enumerate(args):
      if arg.IsPointer():
        file.Write(",\n      data")
      elif arg.IsConstant():
        continue
      else:
        file.Write(",\n      static_cast<%s>(%d)" % (arg.type, value + 1))
    file.Write(");\n")
    file.Write("  EXPECT_EQ(static_cast<uint32_t>(cmds::%s::kCmdId),\n" %
               func.name)
    file.Write("            cmd.header.command);\n")
    file.Write("  EXPECT_EQ(kExpectedCmdSize, cmd.header.size * 4u);\n")
    for value, arg in enumerate(args):
      if arg.IsPointer() or arg.IsConstant():
        continue
      file.Write("  EXPECT_EQ(static_cast<%s>(%d), cmd.%s);\n" %
                 (arg.type, value + 1, arg.name))
    file.Write("  CheckBytesWrittenMatchesExpectedSize(\n")
    file.Write("      next_cmd, sizeof(cmd) +\n")
    file.Write("      RoundSizeToMultipleOfEntries(sizeof(data)));\n")
    file.Write("  // TODO(gman): Check that data was inserted;\n")
    file.Write("}\n")
    file.Write("\n")

class PUTSTRHandler(ArrayArgTypeHandler):
  """Handler for functions that pass a string array."""

  def __init__(self):
    ArrayArgTypeHandler.__init__(self)

  def __GetDataArg(self, func):
    """Return the argument that points to the 2D char arrays"""
    for arg in func.GetOriginalArgs():
      if arg.IsPointer2D():
        return arg
    return None

  def __GetLengthArg(self, func):
    """Return the argument that holds length for each char array"""
    for arg in func.GetOriginalArgs():
      if arg.IsPointer() and not arg.IsPointer2D():
        return arg
    return None

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("%s GLES2Implementation::%s(%s) {\n" %
               (func.return_type, func.original_name,
                func.MakeTypedOriginalArgString("")))
    file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
    func.WriteDestinationInitalizationValidation(file)
    self.WriteClientGLCallLog(func, file)
    data_arg = self.__GetDataArg(func)
    length_arg = self.__GetLengthArg(func)
    log_code_block = """  GPU_CLIENT_LOG_CODE_BLOCK({
    for (GLsizei ii = 0; ii < count; ++ii) {
      if (%(data)s[ii]) {"""
    if length_arg == None:
      log_code_block += """
        GPU_CLIENT_LOG("  " << ii << ": ---\\n" << %(data)s[ii] << "\\n---");"""
    else:
      log_code_block += """
        if (%(length)s && %(length)s[ii] >= 0) {
          const std::string my_str(%(data)s[ii], %(length)s[ii]);
          GPU_CLIENT_LOG("  " << ii << ": ---\\n" << my_str << "\\n---");
        } else {
          GPU_CLIENT_LOG("  " << ii << ": ---\\n" << %(data)s[ii] << "\\n---");
        }"""
    log_code_block += """
      } else {
        GPU_CLIENT_LOG("  " << ii << ": NULL");
      }
    }
  });
"""
    file.Write(log_code_block % {
          'data': data_arg.name,
          'length': length_arg.name if not length_arg == None else ''
      })
    for arg in func.GetOriginalArgs():
      arg.WriteClientSideValidationCode(file, func)

    bucket_args = []
    for arg in func.GetOriginalArgs():
      if arg.name == 'count' or arg == self.__GetLengthArg(func):
        continue
      if arg == self.__GetDataArg(func):
        bucket_args.append('kResultBucketId')
      else:
        bucket_args.append(arg.name)
    code_block = """
  if (!PackStringsToBucket(count, %(data)s, %(length)s, "gl%(func_name)s")) {
    return;
  }
  helper_->%(func_name)sBucket(%(bucket_args)s);
  helper_->SetBucketSize(kResultBucketId, 0);
  CheckGLError();
}

"""
    file.Write(code_block % {
        'data': data_arg.name,
        'length': length_arg.name if not length_arg == None else 'NULL',
        'func_name': func.name,
        'bucket_args': ', '.join(bucket_args),
      })

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Overrriden from TypeHandler."""
    code = """
TEST_F(GLES2ImplementationTest, %(name)s) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const char* kString1 = "happy";
  const char* kString2 = "ending";
  const size_t kString1Size = ::strlen(kString1) + 1;
  const size_t kString2Size = ::strlen(kString2) + 1;
  const size_t kHeaderSize = sizeof(GLint) * 3;
  const size_t kSourceSize = kHeaderSize + kString1Size + kString2Size;
  const size_t kPaddedHeaderSize =
      transfer_buffer_->RoundToAlignment(kHeaderSize);
  const size_t kPaddedString1Size =
      transfer_buffer_->RoundToAlignment(kString1Size);
  const size_t kPaddedString2Size =
      transfer_buffer_->RoundToAlignment(kString2Size);
  struct Cmds {
    cmd::SetBucketSize set_bucket_size;
    cmd::SetBucketData set_bucket_header;
    cmd::SetToken set_token1;
    cmd::SetBucketData set_bucket_data1;
    cmd::SetToken set_token2;
    cmd::SetBucketData set_bucket_data2;
    cmd::SetToken set_token3;
    cmds::%(name)sBucket cmd_bucket;
    cmd::SetBucketSize clear_bucket_size;
  };

  ExpectedMemoryInfo mem0 = GetExpectedMemory(kPaddedHeaderSize);
  ExpectedMemoryInfo mem1 = GetExpectedMemory(kPaddedString1Size);
  ExpectedMemoryInfo mem2 = GetExpectedMemory(kPaddedString2Size);

  Cmds expected;
  expected.set_bucket_size.Init(kBucketId, kSourceSize);
  expected.set_bucket_header.Init(
      kBucketId, 0, kHeaderSize, mem0.id, mem0.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_bucket_data1.Init(
      kBucketId, kHeaderSize, kString1Size, mem1.id, mem1.offset);
  expected.set_token2.Init(GetNextToken());
  expected.set_bucket_data2.Init(
      kBucketId, kHeaderSize + kString1Size, kString2Size, mem2.id,
      mem2.offset);
  expected.set_token3.Init(GetNextToken());
  expected.cmd_bucket.Init(%(bucket_args)s);
  expected.clear_bucket_size.Init(kBucketId, 0);
  const char* kStrings[] = { kString1, kString2 };
  gl_->%(name)s(%(gl_args)s);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}
"""
    gl_args = []
    bucket_args = []
    for arg in func.GetOriginalArgs():
      if arg == self.__GetDataArg(func):
        gl_args.append('kStrings')
        bucket_args.append('kBucketId')
      elif arg == self.__GetLengthArg(func):
        gl_args.append('NULL')
      elif arg.name == 'count':
        gl_args.append('2')
      else:
        gl_args.append(arg.GetValidClientSideArg(func))
        bucket_args.append(arg.GetValidClientSideArg(func))
    file.Write(code % {
        'name': func.name,
        'gl_args': ", ".join(gl_args),
        'bucket_args': ", ".join(bucket_args),
      })

    if self.__GetLengthArg(func) == None:
      return
    code = """
TEST_F(GLES2ImplementationTest, %(name)sWithLength) {
  const uint32 kBucketId = GLES2Implementation::kResultBucketId;
  const char* kString = "foobar******";
  const size_t kStringSize = 6;  // We only need "foobar".
  const size_t kHeaderSize = sizeof(GLint) * 2;
  const size_t kSourceSize = kHeaderSize + kStringSize + 1;
  const size_t kPaddedHeaderSize =
      transfer_buffer_->RoundToAlignment(kHeaderSize);
  const size_t kPaddedStringSize =
      transfer_buffer_->RoundToAlignment(kStringSize + 1);
  struct Cmds {
    cmd::SetBucketSize set_bucket_size;
    cmd::SetBucketData set_bucket_header;
    cmd::SetToken set_token1;
    cmd::SetBucketData set_bucket_data;
    cmd::SetToken set_token2;
    cmds::ShaderSourceBucket shader_source_bucket;
    cmd::SetBucketSize clear_bucket_size;
  };

  ExpectedMemoryInfo mem0 = GetExpectedMemory(kPaddedHeaderSize);
  ExpectedMemoryInfo mem1 = GetExpectedMemory(kPaddedStringSize);

  Cmds expected;
  expected.set_bucket_size.Init(kBucketId, kSourceSize);
  expected.set_bucket_header.Init(
      kBucketId, 0, kHeaderSize, mem0.id, mem0.offset);
  expected.set_token1.Init(GetNextToken());
  expected.set_bucket_data.Init(
      kBucketId, kHeaderSize, kStringSize + 1, mem1.id, mem1.offset);
  expected.set_token2.Init(GetNextToken());
  expected.shader_source_bucket.Init(%(bucket_args)s);
  expected.clear_bucket_size.Init(kBucketId, 0);
  const char* kStrings[] = { kString };
  const GLint kLength[] = { kStringSize };
  gl_->%(name)s(%(gl_args)s);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
}
"""
    gl_args = []
    for arg in func.GetOriginalArgs():
      if arg == self.__GetDataArg(func):
        gl_args.append('kStrings')
      elif arg == self.__GetLengthArg(func):
        gl_args.append('kLength')
      elif arg.name == 'count':
        gl_args.append('1')
      else:
        gl_args.append(arg.GetValidClientSideArg(func))
    file.Write(code % {
        'name': func.name,
        'gl_args': ", ".join(gl_args),
        'bucket_args': ", ".join(bucket_args),
      })

  def WriteBucketServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    cmd_args = []
    cmd_args_with_invalid_id = []
    gl_args = []
    for index, arg in enumerate(func.GetOriginalArgs()):
      if arg == self.__GetLengthArg(func):
        gl_args.append('_')
      elif arg.name == 'count':
        gl_args.append('1')
      elif arg == self.__GetDataArg(func):
        cmd_args.append('kBucketId')
        cmd_args_with_invalid_id.append('kBucketId')
        gl_args.append('_')
      elif index == 0:  # Resource ID arg
        cmd_args.append(arg.GetValidArg(func))
        cmd_args_with_invalid_id.append('kInvalidClientId')
        gl_args.append(arg.GetValidGLArg(func))
      else:
        cmd_args.append(arg.GetValidArg(func))
        cmd_args_with_invalid_id.append(arg.GetValidArg(func))
        gl_args.append(arg.GetValidGLArg(func))

    test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s));
  const uint32 kBucketId = 123;
  const char kSource0[] = "hello";
  const char* kSource[] = { kSource0 };
  const char kValidStrEnd = 0;
  SetBucketAsCStrings(kBucketId, 1, kSource, 1, kValidStrEnd);
  cmds::%(name)s cmd;
  cmd.Init(%(cmd_args)s);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));"""
    if func.IsUnsafe():
      test += """
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));
"""
    test += """
}
"""
    self.WriteValidUnitTest(func, file, test, {
        'cmd_args': ", ".join(cmd_args),
        'gl_args': ", ".join(gl_args),
      }, *extras)

    test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs) {
  const uint32 kBucketId = 123;
  const char kSource0[] = "hello";
  const char* kSource[] = { kSource0 };
  const char kValidStrEnd = 0;
  decoder_->set_unsafe_es3_apis_enabled(true);
  cmds::%(name)s cmd;
  // Test no bucket.
  cmd.Init(%(cmd_args)s);
  EXPECT_NE(error::kNoError, ExecuteCmd(cmd));
  // Test invalid client.
  SetBucketAsCStrings(kBucketId, 1, kSource, 1, kValidStrEnd);
  cmd.Init(%(cmd_args_with_invalid_id)s);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}
"""
    self.WriteValidUnitTest(func, file, test, {
        'cmd_args': ", ".join(cmd_args),
        'cmd_args_with_invalid_id': ", ".join(cmd_args_with_invalid_id),
      }, *extras)

    test = """
TEST_P(%(test_name)s, %(name)sInvalidHeader) {
  const uint32 kBucketId = 123;
  const char kSource0[] = "hello";
  const char* kSource[] = { kSource0 };
  const char kValidStrEnd = 0;
  const GLsizei kCount = static_cast<GLsizei>(arraysize(kSource));
  const GLsizei kTests[] = {
      kCount + 1,
      0,
      std::numeric_limits<GLsizei>::max(),
      -1,
  };
  decoder_->set_unsafe_es3_apis_enabled(true);
  for (size_t ii = 0; ii < arraysize(kTests); ++ii) {
    SetBucketAsCStrings(kBucketId, 1, kSource, kTests[ii], kValidStrEnd);
    cmds::%(name)s cmd;
    cmd.Init(%(cmd_args)s);
    EXPECT_EQ(error::kInvalidArguments, ExecuteCmd(cmd));
  }
}
"""
    self.WriteValidUnitTest(func, file, test, {
        'cmd_args': ", ".join(cmd_args),
      }, *extras)

    test = """
TEST_P(%(test_name)s, %(name)sInvalidStringEnding) {
  const uint32 kBucketId = 123;
  const char kSource0[] = "hello";
  const char* kSource[] = { kSource0 };
  const char kInvalidStrEnd = '*';
  SetBucketAsCStrings(kBucketId, 1, kSource, 1, kInvalidStrEnd);
  cmds::%(name)s cmd;
  cmd.Init(%(cmd_args)s);
  decoder_->set_unsafe_es3_apis_enabled(true);
  EXPECT_EQ(error::kInvalidArguments, ExecuteCmd(cmd));
}
"""
    self.WriteValidUnitTest(func, file, test, {
        'cmd_args': ", ".join(cmd_args),
      }, *extras)


class PUTXnHandler(ArrayArgTypeHandler):
  """Handler for glUniform?f functions."""
  def __init__(self):
    ArrayArgTypeHandler.__init__(self)

  def WriteHandlerImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  %(type)s temp[%(count)s] = { %(values)s};"""
    if func.IsUnsafe():
      code += """
  gl%(name)sv(%(location)s, 1, &temp[0]);
"""
    else:
      code += """
  Do%(name)sv(%(location)s, 1, &temp[0]);
"""
    values = ""
    args = func.GetOriginalArgs()
    count = int(self.GetArrayCount(func))
    num_args = len(args)
    for ii in range(count):
      values += "%s, " % args[len(args) - count + ii].name

    file.Write(code % {
        'name': func.name,
        'count': self.GetArrayCount(func),
        'type': self.GetArrayType(func),
        'location': args[0].name,
        'args': func.MakeOriginalArgString(""),
        'values': values,
      })

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(*gl_, %(name)sv(%(local_args)s));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    valid_test += """
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));"""
    valid_test += """
}
"""
    args = func.GetOriginalArgs()
    local_args = "%s, 1, _" % args[0].GetValidGLArg(func)
    self.WriteValidUnitTest(func, file, valid_test, {
        'name': func.name,
        'count': self.GetArrayCount(func),
        'local_args': local_args,
      }, *extras)

    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs%(arg_index)d_%(value_index)d) {
  EXPECT_CALL(*gl_, %(name)sv(_, _, _).Times(0);
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::%(parse_result)s, ExecuteCmd(cmd));%(gl_error_test)s
}
"""
    self.WriteInvalidUnitTest(func, file, invalid_test, {
        'name': func.GetInfo('name'),
        'count': self.GetArrayCount(func),
      })


class GLcharHandler(CustomHandler):
  """Handler for functions that pass a single string ."""

  def __init__(self):
    CustomHandler.__init__(self)

  def WriteImmediateCmdComputeSize(self, func, file):
    """Overrriden from TypeHandler."""
    file.Write("  static uint32_t ComputeSize(uint32_t data_size) {\n")
    file.Write("    return static_cast<uint32_t>(\n")
    file.Write("        sizeof(ValueType) + data_size);  // NOLINT\n")
    file.Write("  }\n")

  def WriteImmediateCmdSetHeader(self, func, file):
    """Overrriden from TypeHandler."""
    code = """
  void SetHeader(uint32_t data_size) {
    header.SetCmdBySize<ValueType>(data_size);
  }
"""
    file.Write(code)

  def WriteImmediateCmdInit(self, func, file):
    """Overrriden from TypeHandler."""
    last_arg = func.GetLastOriginalArg()
    args = func.GetCmdArgs()
    set_code = []
    for arg in args:
      set_code.append("    %s = _%s;" % (arg.name, arg.name))
    code = """
  void Init(%(typed_args)s, uint32_t _data_size) {
    SetHeader(_data_size);
%(set_code)s
    memcpy(ImmediateDataAddress(this), _%(last_arg)s, _data_size);
  }

"""
    file.Write(code % {
          "typed_args": func.MakeTypedArgString("_"),
          "set_code": "\n".join(set_code),
          "last_arg": last_arg.name
        })

  def WriteImmediateCmdSet(self, func, file):
    """Overrriden from TypeHandler."""
    last_arg = func.GetLastOriginalArg()
    file.Write("  void* Set(void* cmd%s, uint32_t _data_size) {\n" %
               func.MakeTypedCmdArgString("_", True))
    file.Write("    static_cast<ValueType*>(cmd)->Init(%s, _data_size);\n" %
               func.MakeCmdArgString("_"))
    file.Write("    return NextImmediateCmdAddress<ValueType>("
               "cmd, _data_size);\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteImmediateCmdHelper(self, func, file):
    """Overrriden from TypeHandler."""
    code = """  void %(name)s(%(typed_args)s) {
    const uint32_t data_size = strlen(name);
    gles2::cmds::%(name)s* c =
        GetImmediateCmdSpace<gles2::cmds::%(name)s>(data_size);
    if (c) {
      c->Init(%(args)s, data_size);
    }
  }

"""
    file.Write(code % {
          "name": func.name,
          "typed_args": func.MakeTypedOriginalArgString(""),
          "args": func.MakeOriginalArgString(""),
        })


  def WriteImmediateFormatTest(self, func, file):
    """Overrriden from TypeHandler."""
    init_code = []
    check_code = []
    all_but_last_arg = func.GetCmdArgs()[:-1]
    for value, arg in enumerate(all_but_last_arg):
      init_code.append("      static_cast<%s>(%d)," % (arg.type, value + 11))
    for value, arg in enumerate(all_but_last_arg):
      check_code.append("  EXPECT_EQ(static_cast<%s>(%d), cmd.%s);" %
                        (arg.type, value + 11, arg.name))
    code = """
TEST_F(GLES2FormatTest, %(func_name)s) {
  cmds::%(func_name)s& cmd = *GetBufferAs<cmds::%(func_name)s>();
  static const char* const test_str = \"test string\";
  void* next_cmd = cmd.Set(
      &cmd,
%(init_code)s
      test_str,
      strlen(test_str));
  EXPECT_EQ(static_cast<uint32_t>(cmds::%(func_name)s::kCmdId),
            cmd.header.command);
  EXPECT_EQ(sizeof(cmd) +
            RoundSizeToMultipleOfEntries(strlen(test_str)),
            cmd.header.size * 4u);
  EXPECT_EQ(static_cast<char*>(next_cmd),
            reinterpret_cast<char*>(&cmd) + sizeof(cmd) +
                RoundSizeToMultipleOfEntries(strlen(test_str)));
%(check_code)s
  EXPECT_EQ(static_cast<uint32_t>(strlen(test_str)), cmd.data_size);
  EXPECT_EQ(0, memcmp(test_str, ImmediateDataAddress(&cmd), strlen(test_str)));
  CheckBytesWritten(
      next_cmd,
      sizeof(cmd) + RoundSizeToMultipleOfEntries(strlen(test_str)),
      sizeof(cmd) + strlen(test_str));
}

"""
    file.Write(code % {
          'func_name': func.name,
          'init_code': "\n".join(init_code),
          'check_code': "\n".join(check_code),
        })


class GLcharNHandler(CustomHandler):
  """Handler for functions that pass a single string with an optional len."""

  def __init__(self):
    CustomHandler.__init__(self)

  def InitFunction(self, func):
    """Overrriden from TypeHandler."""
    func.cmd_args = []
    func.AddCmdArg(Argument('bucket_id', 'GLuint'))

  def NeedsDataTransferFunction(self, func):
    """Overriden from TypeHandler."""
    return False

  def AddBucketFunction(self, generator, func):
    """Overrriden from TypeHandler."""
    pass

  def WriteServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    self.WriteServiceHandlerFunctionHeader(func, file)
    file.Write("""
  GLuint bucket_id = static_cast<GLuint>(c.%(bucket_id)s);
  Bucket* bucket = GetBucket(bucket_id);
  if (!bucket || bucket->size() == 0) {
    return error::kInvalidArguments;
  }
  std::string str;
  if (!bucket->GetAsString(&str)) {
    return error::kInvalidArguments;
  }
  %(gl_func_name)s(0, str.c_str());
  return error::kNoError;
}

""" % {
    'name': func.name,
    'gl_func_name': func.GetGLFunctionName(),
    'bucket_id': func.cmd_args[0].name,
  })


class IsHandler(TypeHandler):
  """Handler for glIs____ type and glGetError functions."""

  def __init__(self):
    TypeHandler.__init__(self)

  def InitFunction(self, func):
    """Overrriden from TypeHandler."""
    func.AddCmdArg(Argument("result_shm_id", 'uint32_t'))
    func.AddCmdArg(Argument("result_shm_offset", 'uint32_t'))
    if func.GetInfo('result') == None:
      func.AddInfo('result', ['uint32_t'])

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s));
  SpecializedSetup<cmds::%(name)s, 0>(true);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s%(comma)sshared_memory_id_, shared_memory_offset_);"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    valid_test += """
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());"""
    if func.IsUnsafe():
      valid_test += """
  decoder_->set_unsafe_es3_apis_enabled(false);
  EXPECT_EQ(error::kUnknownCommand, ExecuteCmd(cmd));"""
    valid_test += """
}
"""
    comma = ""
    if len(func.GetOriginalArgs()):
      comma =", "
    self.WriteValidUnitTest(func, file, valid_test, {
          'comma': comma,
        }, *extras)

    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs%(arg_index)d_%(value_index)d) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s)).Times(0);
  SpecializedSetup<cmds::%(name)s, 0>(false);
  cmds::%(name)s cmd;
  cmd.Init(%(args)s%(comma)sshared_memory_id_, shared_memory_offset_);
  EXPECT_EQ(error::%(parse_result)s, ExecuteCmd(cmd));%(gl_error_test)s
}
"""
    self.WriteInvalidUnitTest(func, file, invalid_test, {
          'comma': comma,
        }, *extras)

    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgsBadSharedMemoryId) {
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s)).Times(0);
  SpecializedSetup<cmds::%(name)s, 0>(false);"""
    if func.IsUnsafe():
      invalid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    invalid_test += """
  cmds::%(name)s cmd;
  cmd.Init(%(args)s%(comma)skInvalidSharedMemoryId, shared_memory_offset_);
  EXPECT_EQ(error::kOutOfBounds, ExecuteCmd(cmd));
  cmd.Init(%(args)s%(comma)sshared_memory_id_, kInvalidSharedMemoryOffset);
  EXPECT_EQ(error::kOutOfBounds, ExecuteCmd(cmd));"""
    if func.IsUnsafe():
      invalid_test += """
  decoder_->set_unsafe_es3_apis_enabled(true);"""
    invalid_test += """
}
"""
    self.WriteValidUnitTest(func, file, invalid_test, {
          'comma': comma,
        }, *extras)

  def WriteServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    self.WriteServiceHandlerFunctionHeader(func, file)
    args = func.GetOriginalArgs()
    for arg in args:
      arg.WriteGetCode(file)

    code = """  typedef cmds::%(func_name)s::Result Result;
  Result* result_dst = GetSharedMemoryAs<Result*>(
      c.result_shm_id, c.result_shm_offset, sizeof(*result_dst));
  if (!result_dst) {
    return error::kOutOfBounds;
  }
"""
    file.Write(code % {'func_name': func.name})
    func.WriteHandlerValidation(file)
    if func.IsUnsafe():
      assert func.GetInfo('id_mapping')
      assert len(func.GetInfo('id_mapping')) == 1
      assert len(args) == 1
      id_type = func.GetInfo('id_mapping')[0]
      file.Write("  %s service_%s = 0;\n" % (args[0].type, id_type.lower()))
      file.Write("  *result_dst = group_->Get%sServiceId(%s, &service_%s);\n" %
                 (id_type, id_type.lower(), id_type.lower()))
    else:
      file.Write("  *result_dst = %s(%s);\n" %
                 (func.GetGLFunctionName(), func.MakeOriginalArgString("")))
    file.Write("  return error::kNoError;\n")
    file.Write("}\n")
    file.Write("\n")

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    impl_func = func.GetInfo('impl_func')
    if impl_func == None or impl_func == True:
      error_value = func.GetInfo("error_value") or "GL_FALSE"
      file.Write("%s GLES2Implementation::%s(%s) {\n" %
                 (func.return_type, func.original_name,
                  func.MakeTypedOriginalArgString("")))
      file.Write("  GPU_CLIENT_SINGLE_THREAD_CHECK();\n")
      self.WriteTraceEvent(func, file)
      func.WriteDestinationInitalizationValidation(file)
      self.WriteClientGLCallLog(func, file)
      file.Write("  typedef cmds::%s::Result Result;\n" % func.name)
      file.Write("  Result* result = GetResultAs<Result*>();\n")
      file.Write("  if (!result) {\n")
      file.Write("    return %s;\n" % error_value)
      file.Write("  }\n")
      file.Write("  *result = 0;\n")
      assert len(func.GetOriginalArgs()) == 1
      id_arg = func.GetOriginalArgs()[0]
      if id_arg.type == 'GLsync':
        arg_string = "ToGLuint(%s)" % func.MakeOriginalArgString("")
      else:
        arg_string = func.MakeOriginalArgString("")
      file.Write(
          "  helper_->%s(%s, GetResultShmId(), GetResultShmOffset());\n" %
              (func.name, arg_string))
      file.Write("  WaitForCmd();\n")
      file.Write("  %s result_value = *result" % func.return_type)
      if func.return_type == "GLboolean":
        file.Write(" != 0")
      file.Write(';\n  GPU_CLIENT_LOG("returned " << result_value);\n')
      file.Write("  CheckGLError();\n")
      file.Write("  return result_value;\n")
      file.Write("}\n")
      file.Write("\n")

  def WriteGLES2ImplementationUnitTest(self, func, file):
    """Overrriden from TypeHandler."""
    client_test = func.GetInfo('client_test')
    if client_test == None or client_test == True:
      code = """
TEST_F(GLES2ImplementationTest, %(name)s) {
  struct Cmds {
    cmds::%(name)s cmd;
  };

  Cmds expected;
  ExpectedMemoryInfo result1 =
      GetExpectedResultMemory(sizeof(cmds::%(name)s::Result));
  expected.cmd.Init(%(cmd_id_value)s, result1.id, result1.offset);

  EXPECT_CALL(*command_buffer(), OnFlush())
      .WillOnce(SetMemory(result1.ptr, uint32_t(GL_TRUE)))
      .RetiresOnSaturation();

  GLboolean result = gl_->%(name)s(%(gl_id_value)s);
  EXPECT_EQ(0, memcmp(&expected, commands_, sizeof(expected)));
  EXPECT_TRUE(result);
}
"""
      args = func.GetOriginalArgs()
      assert len(args) == 1
      file.Write(code % {
          'name': func.name,
          'cmd_id_value': args[0].GetValidClientSideCmdArg(func),
          'gl_id_value': args[0].GetValidClientSideArg(func) })


class STRnHandler(TypeHandler):
  """Handler for GetProgramInfoLog, GetShaderInfoLog, GetShaderSource, and
  GetTranslatedShaderSourceANGLE."""

  def __init__(self):
    TypeHandler.__init__(self)

  def InitFunction(self, func):
    """Overrriden from TypeHandler."""
    # remove all but the first cmd args.
    cmd_args = func.GetCmdArgs()
    func.ClearCmdArgs()
    func.AddCmdArg(cmd_args[0])
    # add on a bucket id.
    func.AddCmdArg(Argument('bucket_id', 'uint32_t'))

  def WriteGLES2Implementation(self, func, file):
    """Overrriden from TypeHandler."""
    code_1 = """%(return_type)s GLES2Implementation::%(func_name)s(%(args)s) {
  GPU_CLIENT_SINGLE_THREAD_CHECK();
"""
    code_2 = """  GPU_CLIENT_LOG("[" << GetLogPrefix()
      << "] gl%(func_name)s" << "("
      << %(arg0)s << ", "
      << %(arg1)s << ", "
      << static_cast<void*>(%(arg2)s) << ", "
      << static_cast<void*>(%(arg3)s) << ")");
  helper_->SetBucketSize(kResultBucketId, 0);
  helper_->%(func_name)s(%(id_name)s, kResultBucketId);
  std::string str;
  GLsizei max_size = 0;
  if (GetBucketAsString(kResultBucketId, &str)) {
    if (bufsize > 0) {
      max_size =
          std::min(static_cast<size_t>(%(bufsize_name)s) - 1, str.size());
      memcpy(%(dest_name)s, str.c_str(), max_size);
      %(dest_name)s[max_size] = '\\0';
      GPU_CLIENT_LOG("------\\n" << %(dest_name)s << "\\n------");
    }
  }
  if (%(length_name)s != NULL) {
    *%(length_name)s = max_size;
  }
  CheckGLError();
}
"""
    args = func.GetOriginalArgs()
    str_args = {
      'return_type': func.return_type,
      'func_name': func.original_name,
      'args': func.MakeTypedOriginalArgString(""),
      'id_name': args[0].name,
      'bufsize_name': args[1].name,
      'length_name': args[2].name,
      'dest_name': args[3].name,
      'arg0': args[0].name,
      'arg1': args[1].name,
      'arg2': args[2].name,
      'arg3': args[3].name,
    }
    file.Write(code_1 % str_args)
    func.WriteDestinationInitalizationValidation(file)
    file.Write(code_2 % str_args)

  def WriteServiceUnitTest(self, func, file, *extras):
    """Overrriden from TypeHandler."""
    valid_test = """
TEST_P(%(test_name)s, %(name)sValidArgs) {
  const char* kInfo = "hello";
  const uint32_t kBucketId = 123;
  SpecializedSetup<cmds::%(name)s, 0>(true);
%(expect_len_code)s
  EXPECT_CALL(*gl_, %(gl_func_name)s(%(gl_args)s))
      .WillOnce(DoAll(SetArgumentPointee<2>(strlen(kInfo)),
                      SetArrayArgument<3>(kInfo, kInfo + strlen(kInfo) + 1)));
  cmds::%(name)s cmd;
  cmd.Init(%(args)s);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  CommonDecoder::Bucket* bucket = decoder_->GetBucket(kBucketId);
  ASSERT_TRUE(bucket != NULL);
  EXPECT_EQ(strlen(kInfo) + 1, bucket->size());
  EXPECT_EQ(0, memcmp(bucket->GetData(0, bucket->size()), kInfo,
                      bucket->size()));
  EXPECT_EQ(GL_NO_ERROR, GetGLError());
}
"""
    args = func.GetOriginalArgs()
    id_name = args[0].GetValidGLArg(func)
    get_len_func = func.GetInfo('get_len_func')
    get_len_enum = func.GetInfo('get_len_enum')
    sub = {
        'id_name': id_name,
        'get_len_func': get_len_func,
        'get_len_enum': get_len_enum,
        'gl_args': '%s, strlen(kInfo) + 1, _, _' %
             args[0].GetValidGLArg(func),
        'args': '%s, kBucketId' % args[0].GetValidArg(func),
        'expect_len_code': '',
    }
    if get_len_func and get_len_func[0:2] == 'gl':
      sub['expect_len_code'] = (
        "  EXPECT_CALL(*gl_, %s(%s, %s, _))\n"
        "      .WillOnce(SetArgumentPointee<2>(strlen(kInfo) + 1));") % (
            get_len_func[2:], id_name, get_len_enum)
    self.WriteValidUnitTest(func, file, valid_test, sub, *extras)

    invalid_test = """
TEST_P(%(test_name)s, %(name)sInvalidArgs) {
  const uint32_t kBucketId = 123;
  EXPECT_CALL(*gl_, %(gl_func_name)s(_, _, _, _))
      .Times(0);
  cmds::%(name)s cmd;
  cmd.Init(kInvalidClientId, kBucketId);
  EXPECT_EQ(error::kNoError, ExecuteCmd(cmd));
  EXPECT_EQ(GL_INVALID_VALUE, GetGLError());
}
"""
    self.WriteValidUnitTest(func, file, invalid_test, *extras)

  def WriteServiceImplementation(self, func, file):
    """Overrriden from TypeHandler."""
    pass

class NamedType(object):
  """A class that represents a type of an argument in a client function.

  A type of an argument that is to be passed through in the command buffer
  command. Currently used only for the arguments that are specificly named in
  the 'cmd_buffer_functions.txt' file, mostly enums.
  """

  def __init__(self, info):
    assert not 'is_complete' in info or info['is_complete'] == True
    self.info = info
    self.valid = info['valid']
    if 'invalid' in info:
      self.invalid = info['invalid']
    else:
      self.invalid = []
    if 'valid_es3' in info:
      self.valid_es3 = info['valid_es3']
    else:
      self.valid_es3 = []
    if 'deprecated_es3' in info:
      self.deprecated_es3 = info['deprecated_es3']
    else:
      self.deprecated_es3 = []

  def GetType(self):
    return self.info['type']

  def GetInvalidValues(self):
    return self.invalid

  def GetValidValues(self):
    return self.valid

  def GetValidValuesES3(self):
    return self.valid_es3

  def GetDeprecatedValuesES3(self):
    return self.deprecated_es3

  def IsConstant(self):
    if not 'is_complete' in self.info:
      return False

    return len(self.GetValidValues()) == 1

  def GetConstantValue(self):
    return self.GetValidValues()[0]

class Argument(object):
  """A class that represents a function argument."""

  cmd_type_map_ = {
    'GLenum': 'uint32_t',
    'GLint': 'int32_t',
    'GLintptr': 'int32_t',
    'GLsizei': 'int32_t',
    'GLsizeiptr': 'int32_t',
    'GLfloat': 'float',
    'GLclampf': 'float',
  }
  need_validation_ = ['GLsizei*', 'GLboolean*', 'GLenum*', 'GLint*']

  def __init__(self, name, type):
    self.name = name
    self.optional = type.endswith("Optional*")
    if self.optional:
      type = type[:-9] + "*"
    self.type = type

    if type in self.cmd_type_map_:
      self.cmd_type = self.cmd_type_map_[type]
    else:
      self.cmd_type = 'uint32_t'

  def IsPointer(self):
    """Returns true if argument is a pointer."""
    return False

  def IsPointer2D(self):
    """Returns true if argument is a 2D pointer."""
    return False

  def IsConstant(self):
    """Returns true if the argument has only one valid value."""
    return False

  def AddCmdArgs(self, args):
    """Adds command arguments for this argument to the given list."""
    if not self.IsConstant():
      return args.append(self)

  def AddInitArgs(self, args):
    """Adds init arguments for this argument to the given list."""
    if not self.IsConstant():
      return args.append(self)

  def GetValidArg(self, func):
    """Gets a valid value for this argument."""
    valid_arg = func.GetValidArg(self)
    if valid_arg != None:
      return valid_arg

    index = func.GetOriginalArgs().index(self)
    return str(index + 1)

  def GetValidClientSideArg(self, func):
    """Gets a valid value for this argument."""
    valid_arg = func.GetValidArg(self)
    if valid_arg != None:
      return valid_arg

    if self.IsPointer():
      return 'nullptr'
    index = func.GetOriginalArgs().index(self)
    if self.type == 'GLsync':
      return ("reinterpret_cast<GLsync>(%d)" % (index + 1))
    return str(index + 1)

  def GetValidClientSideCmdArg(self, func):
    """Gets a valid value for this argument."""
    valid_arg = func.GetValidArg(self)
    if valid_arg != None:
      return valid_arg
    try:
      index = func.GetOriginalArgs().index(self)
      return str(index + 1)
    except ValueError:
      pass
    index = func.GetCmdArgs().index(self)
    return str(index + 1)

  def GetValidGLArg(self, func):
    """Gets a valid GL value for this argument."""
    value = self.GetValidArg(func)
    if self.type == 'GLsync':
      return ("reinterpret_cast<GLsync>(%s)" % value)
    return value

  def GetValidNonCachedClientSideArg(self, func):
    """Returns a valid value for this argument in a GL call.
    Using the value will produce a command buffer service invocation.
    Returns None if there is no such value."""
    value = '123'
    if self.type == 'GLsync':
      return ("reinterpret_cast<GLsync>(%s)" % value)
    return value

  def GetValidNonCachedClientSideCmdArg(self, func):
    """Returns a valid value for this argument in a command buffer command.
    Calling the GL function with the value returned by
    GetValidNonCachedClientSideArg will result in a command buffer command
    that contains the value returned by this function. """
    return '123'

  def GetNumInvalidValues(self, func):
    """returns the number of invalid values to be tested."""
    return 0

  def GetInvalidArg(self, index):
    """returns an invalid value and expected parse result by index."""
    return ("---ERROR0---", "---ERROR2---", None)

  def GetLogArg(self):
    """Get argument appropriate for LOG macro."""
    if self.type == 'GLboolean':
      return 'GLES2Util::GetStringBool(%s)' % self.name
    if self.type == 'GLenum':
      return 'GLES2Util::GetStringEnum(%s)' % self.name
    return self.name

  def WriteGetCode(self, file):
    """Writes the code to get an argument from a command structure."""
    if self.type == 'GLsync':
      my_type = 'GLuint'
    else:
      my_type = self.type
    file.Write("  %s %s = static_cast<%s>(c.%s);\n" %
               (my_type, self.name, my_type, self.name))

  def WriteValidationCode(self, file, func):
    """Writes the validation code for an argument."""
    pass

  def WriteClientSideValidationCode(self, file, func):
    """Writes the validation code for an argument."""
    pass

  def WriteDestinationInitalizationValidation(self, file, func):
    """Writes the client side destintion initialization validation."""
    pass

  def WriteDestinationInitalizationValidatationIfNeeded(self, file, func):
    """Writes the client side destintion initialization validation if needed."""
    parts = self.type.split(" ")
    if len(parts) > 1:
      return
    if parts[0] in self.need_validation_:
      file.Write(
          "  GPU_CLIENT_VALIDATE_DESTINATION_%sINITALIZATION(%s, %s);\n" %
          ("OPTIONAL_" if self.optional else "", self.type[:-1], self.name))


  def WriteGetAddress(self, file):
    """Writes the code to get the address this argument refers to."""
    pass

  def GetImmediateVersion(self):
    """Gets the immediate version of this argument."""
    return self

  def GetBucketVersion(self):
    """Gets the bucket version of this argument."""
    return self


class BoolArgument(Argument):
  """class for GLboolean"""

  def __init__(self, name, type):
    Argument.__init__(self, name, 'GLboolean')

  def GetValidArg(self, func):
    """Gets a valid value for this argument."""
    return 'true'

  def GetValidClientSideArg(self, func):
    """Gets a valid value for this argument."""
    return 'true'

  def GetValidClientSideCmdArg(self, func):
    """Gets a valid value for this argument."""
    return 'true'

  def GetValidGLArg(self, func):
    """Gets a valid GL value for this argument."""
    return 'true'


class UniformLocationArgument(Argument):
  """class for uniform locations."""

  def __init__(self, name):
    Argument.__init__(self, name, "GLint")

  def WriteGetCode(self, file):
    """Writes the code to get an argument from a command structure."""
    code = """  %s %s = static_cast<%s>(c.%s);
"""
    file.Write(code % (self.type, self.name, self.type, self.name))

class DataSizeArgument(Argument):
  """class for data_size which Bucket commands do not need."""

  def __init__(self, name):
    Argument.__init__(self, name, "uint32_t")

  def GetBucketVersion(self):
    return None


class SizeArgument(Argument):
  """class for GLsizei and GLsizeiptr."""

  def __init__(self, name, type):
    Argument.__init__(self, name, type)

  def GetNumInvalidValues(self, func):
    """overridden from Argument."""
    if func.IsImmediate():
      return 0
    return 1

  def GetInvalidArg(self, index):
    """overridden from Argument."""
    return ("-1", "kNoError", "GL_INVALID_VALUE")

  def WriteValidationCode(self, file, func):
    """overridden from Argument."""
    if func.IsUnsafe():
      return
    code = """  if (%(var_name)s < 0) {
    LOCAL_SET_GL_ERROR(GL_INVALID_VALUE, "gl%(func_name)s", "%(var_name)s < 0");
    return error::kNoError;
  }
"""
    file.Write(code % {
        "var_name": self.name,
        "func_name": func.original_name,
      })

  def WriteClientSideValidationCode(self, file, func):
    """overridden from Argument."""
    code = """  if (%(var_name)s < 0) {
    SetGLError(GL_INVALID_VALUE, "gl%(func_name)s", "%(var_name)s < 0");
    return;
  }
"""
    file.Write(code % {
        "var_name": self.name,
        "func_name": func.original_name,
      })


class SizeNotNegativeArgument(SizeArgument):
  """class for GLsizeiNotNegative. It's NEVER allowed to be negative"""

  def __init__(self, name, type, gl_type):
    SizeArgument.__init__(self, name, gl_type)

  def GetInvalidArg(self, index):
    """overridden from SizeArgument."""
    return ("-1", "kOutOfBounds", "GL_NO_ERROR")

  def WriteValidationCode(self, file, func):
    """overridden from SizeArgument."""
    pass


class EnumBaseArgument(Argument):
  """Base class for EnumArgument, IntArgument, BitfieldArgument, and
  ValidatedBoolArgument."""

  def __init__(self, name, gl_type, type, gl_error):
    Argument.__init__(self, name, gl_type)

    self.local_type = type
    self.gl_error = gl_error
    name = type[len(gl_type):]
    self.type_name = name
    self.named_type = NamedType(_NAMED_TYPE_INFO[name])

  def IsConstant(self):
    return self.named_type.IsConstant()

  def GetConstantValue(self):
    return self.named_type.GetConstantValue()

  def WriteValidationCode(self, file, func):
    if func.IsUnsafe():
      return
    if self.named_type.IsConstant():
      return
    file.Write("  if (!validators_->%s.IsValid(%s)) {\n" %
               (ToUnderscore(self.type_name), self.name))
    if self.gl_error == "GL_INVALID_ENUM":
      file.Write(
          "    LOCAL_SET_GL_ERROR_INVALID_ENUM(\"gl%s\", %s, \"%s\");\n" %
          (func.original_name, self.name, self.name))
    else:
      file.Write(
          "    LOCAL_SET_GL_ERROR(%s, \"gl%s\", \"%s %s\");\n" %
          (self.gl_error, func.original_name, self.name, self.gl_error))
    file.Write("    return error::kNoError;\n")
    file.Write("  }\n")

  def WriteClientSideValidationCode(self, file, func):
    if not self.named_type.IsConstant():
      return
    file.Write("  if (%s != %s) {" % (self.name,
                                      self.GetConstantValue()))
    file.Write(
      "    SetGLError(%s, \"gl%s\", \"%s %s\");\n" %
      (self.gl_error, func.original_name, self.name, self.gl_error))
    if func.return_type == "void":
      file.Write("    return;\n")
    else:
      file.Write("    return %s;\n" % func.GetErrorReturnString())
    file.Write("  }\n")

  def GetValidArg(self, func):
    valid_arg = func.GetValidArg(self)
    if valid_arg != None:
      return valid_arg
    valid = self.named_type.GetValidValues()
    if valid:
      num_valid = len(valid)
      return valid[0]

    index = func.GetOriginalArgs().index(self)
    return str(index + 1)

  def GetValidClientSideArg(self, func):
    """Gets a valid value for this argument."""
    return self.GetValidArg(func)

  def GetValidClientSideCmdArg(self, func):
    """Gets a valid value for this argument."""
    valid_arg = func.GetValidArg(self)
    if valid_arg != None:
      return valid_arg

    valid = self.named_type.GetValidValues()
    if valid:
      num_valid = len(valid)
      return valid[0]

    try:
      index = func.GetOriginalArgs().index(self)
      return str(index + 1)
    except ValueError:
      pass
    index = func.GetCmdArgs().index(self)
    return str(index + 1)

  def GetValidGLArg(self, func):
    """Gets a valid value for this argument."""
    return self.GetValidArg(func)

  def GetNumInvalidValues(self, func):
    """returns the number of invalid values to be tested."""
    return len(self.named_type.GetInvalidValues())

  def GetInvalidArg(self, index):
    """returns an invalid value by index."""
    invalid = self.named_type.GetInvalidValues()
    if invalid:
      num_invalid = len(invalid)
      if index >= num_invalid:
        index = num_invalid - 1
      return (invalid[index], "kNoError", self.gl_error)
    return ("---ERROR1---", "kNoError", self.gl_error)


class EnumArgument(EnumBaseArgument):
  """A class that represents a GLenum argument"""

  def __init__(self, name, type):
    EnumBaseArgument.__init__(self, name, "GLenum", type, "GL_INVALID_ENUM")

  def GetLogArg(self):
    """Overridden from Argument."""
    return ("GLES2Util::GetString%s(%s)" %
            (self.type_name, self.name))


class IntArgument(EnumBaseArgument):
  """A class for a GLint argument that can only accept specific values.

  For example glTexImage2D takes a GLint for its internalformat
  argument instead of a GLenum.
  """

  def __init__(self, name, type):
    EnumBaseArgument.__init__(self, name, "GLint", type, "GL_INVALID_VALUE")


class ValidatedBoolArgument(EnumBaseArgument):
  """A class for a GLboolean argument that can only accept specific values.

  For example glUniformMatrix takes a GLboolean for it's transpose but it
  must be false.
  """

  def __init__(self, name, type):
    EnumBaseArgument.__init__(self, name, "GLboolean", type, "GL_INVALID_VALUE")

  def GetLogArg(self):
    """Overridden from Argument."""
    return 'GLES2Util::GetStringBool(%s)' % self.name


class BitFieldArgument(EnumBaseArgument):
  """A class for a GLbitfield argument that can only accept specific values.

  For example glFenceSync takes a GLbitfield for its flags argument bit it
  must be 0.
  """

  def __init__(self, name, type):
    EnumBaseArgument.__init__(self, name, "GLbitfield", type,
                              "GL_INVALID_VALUE")


class ImmediatePointerArgument(Argument):
  """A class that represents an immediate argument to a function.

  An immediate argument is one where the data follows the command.
  """

  def __init__(self, name, type):
    Argument.__init__(self, name, type)

  def IsPointer(self):
    return True

  def GetPointedType(self):
    match = re.match('(const\s+)?(?P<element_type>[\w]+)\s*\*', self.type)
    assert match
    return match.groupdict()['element_type']

  def AddCmdArgs(self, args):
    """Overridden from Argument."""
    pass

  def WriteGetCode(self, file):
    """Overridden from Argument."""
    file.Write(
      "  %s %s = GetImmediateDataAs<%s>(\n" %
      (self.type, self.name, self.type))
    file.Write("      c, data_size, immediate_data_size);\n")

  def WriteValidationCode(self, file, func):
    """Overridden from Argument."""
    if self.optional:
      return
    file.Write("  if (%s == NULL) {\n" % self.name)
    file.Write("    return error::kOutOfBounds;\n")
    file.Write("  }\n")

  def GetImmediateVersion(self):
    """Overridden from Argument."""
    return None

  def WriteDestinationInitalizationValidation(self, file, func):
    """Overridden from Argument."""
    self.WriteDestinationInitalizationValidatationIfNeeded(file, func)

  def GetLogArg(self):
    """Overridden from Argument."""
    return "static_cast<const void*>(%s)" % self.name


class PointerArgument(Argument):
  """A class that represents a pointer argument to a function."""

  def __init__(self, name, type):
    Argument.__init__(self, name, type)

  def IsPointer(self):
    """Overridden from Argument."""
    return True

  def IsPointer2D(self):
    """Overridden from Argument."""
    return self.type.count('*') == 2

  def GetPointedType(self):
    match = re.match('(const\s+)?(?P<element_type>[\w]+)\s*\*', self.type)
    assert match
    return match.groupdict()['element_type']

  def GetValidArg(self, func):
    """Overridden from Argument."""
    return "shared_memory_id_, shared_memory_offset_"

  def GetValidGLArg(self, func):
    """Overridden from Argument."""
    return "reinterpret_cast<%s>(shared_memory_address_)" % self.type

  def GetNumInvalidValues(self, func):
    """Overridden from Argument."""
    return 2

  def GetInvalidArg(self, index):
    """Overridden from Argument."""
    if index == 0:
      return ("kInvalidSharedMemoryId, 0", "kOutOfBounds", None)
    else:
      return ("shared_memory_id_, kInvalidSharedMemoryOffset",
              "kOutOfBounds", None)

  def GetLogArg(self):
    """Overridden from Argument."""
    return "static_cast<const void*>(%s)" % self.name

  def AddCmdArgs(self, args):
    """Overridden from Argument."""
    args.append(Argument("%s_shm_id" % self.name, 'uint32_t'))
    args.append(Argument("%s_shm_offset" % self.name, 'uint32_t'))

  def WriteGetCode(self, file):
    """Overridden from Argument."""
    file.Write(
        "  %s %s = GetSharedMemoryAs<%s>(\n" %
        (self.type, self.name, self.type))
    file.Write(
        "      c.%s_shm_id, c.%s_shm_offset, data_size);\n" %
        (self.name, self.name))

  def WriteGetAddress(self, file):
    """Overridden from Argument."""
    file.Write(
        "  %s %s = GetSharedMemoryAs<%s>(\n" %
        (self.type, self.name, self.type))
    file.Write(
        "      %s_shm_id, %s_shm_offset, %s_size);\n" %
        (self.name, self.name, self.name))

  def WriteValidationCode(self, file, func):
    """Overridden from Argument."""
    if self.optional:
      return
    file.Write("  if (%s == NULL) {\n" % self.name)
    file.Write("    return error::kOutOfBounds;\n")
    file.Write("  }\n")

  def GetImmediateVersion(self):
    """Overridden from Argument."""
    return ImmediatePointerArgument(self.name, self.type)

  def GetBucketVersion(self):
    """Overridden from Argument."""
    if self.type.find('char') >= 0:
      if self.IsPointer2D():
        return InputStringArrayBucketArgument(self.name, self.type)
      return InputStringBucketArgument(self.name, self.type)
    return BucketPointerArgument(self.name, self.type)

  def WriteDestinationInitalizationValidation(self, file, func):
    """Overridden from Argument."""
    self.WriteDestinationInitalizationValidatationIfNeeded(file, func)


class BucketPointerArgument(PointerArgument):
  """A class that represents an bucket argument to a function."""

  def __init__(self, name, type):
    Argument.__init__(self, name, type)

  def AddCmdArgs(self, args):
    """Overridden from Argument."""
    pass

  def WriteGetCode(self, file):
    """Overridden from Argument."""
    file.Write(
      "  %s %s = bucket->GetData(0, data_size);\n" %
      (self.type, self.name))

  def WriteValidationCode(self, file, func):
    """Overridden from Argument."""
    pass

  def GetImmediateVersion(self):
    """Overridden from Argument."""
    return None

  def WriteDestinationInitalizationValidation(self, file, func):
    """Overridden from Argument."""
    self.WriteDestinationInitalizationValidatationIfNeeded(file, func)

  def GetLogArg(self):
    """Overridden from Argument."""
    return "static_cast<const void*>(%s)" % self.name


class InputStringBucketArgument(Argument):
  """A string input argument where the string is passed in a bucket."""

  def __init__(self, name, type):
    Argument.__init__(self, name + "_bucket_id", "uint32_t")

  def IsPointer(self):
    """Overridden from Argument."""
    return True

  def IsPointer2D(self):
    """Overridden from Argument."""
    return False


class InputStringArrayBucketArgument(Argument):
  """A string array input argument where the strings are passed in a bucket."""

  def __init__(self, name, type):
    Argument.__init__(self, name + "_bucket_id", "uint32_t")
    self._original_name = name

  def WriteGetCode(self, file):
    """Overridden from Argument."""
    code = """
  Bucket* bucket = GetBucket(c.%(name)s);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  GLsizei count = 0;
  std::vector<char*> strs;
  std::vector<GLint> len;
  if (!bucket->GetAsStrings(&count, &strs, &len)) {
    return error::kInvalidArguments;
  }
  const char** %(original_name)s =
      strs.size() > 0 ? const_cast<const char**>(&strs[0]) : NULL;
  const GLint* length =
      len.size() > 0 ? const_cast<const GLint*>(&len[0]) : NULL;
  (void)length;
"""
    file.Write(code % {
        'name': self.name,
        'original_name': self._original_name,
      })

  def GetValidArg(self, func):
    return "kNameBucketId"

  def GetValidGLArg(self, func):
    return "_"

  def IsPointer(self):
    """Overridden from Argument."""
    return True

  def IsPointer2D(self):
    """Overridden from Argument."""
    return True


class ResourceIdArgument(Argument):
  """A class that represents a resource id argument to a function."""

  def __init__(self, name, type):
    match = re.match("(GLid\w+)", type)
    self.resource_type = match.group(1)[4:]
    if self.resource_type == "Sync":
      type = type.replace(match.group(1), "GLsync")
    else:
      type = type.replace(match.group(1), "GLuint")
    Argument.__init__(self, name, type)

  def WriteGetCode(self, file):
    """Overridden from Argument."""
    if self.type == "GLsync":
      my_type = "GLuint"
    else:
      my_type = self.type
    file.Write("  %s %s = c.%s;\n" % (my_type, self.name, self.name))

  def GetValidArg(self, func):
    return "client_%s_id_" % self.resource_type.lower()

  def GetValidGLArg(self, func):
    if self.resource_type == "Sync":
      return "reinterpret_cast<GLsync>(kService%sId)" % self.resource_type
    return "kService%sId" % self.resource_type


class ResourceIdBindArgument(Argument):
  """Represents a resource id argument to a bind function."""

  def __init__(self, name, type):
    match = re.match("(GLidBind\w+)", type)
    self.resource_type = match.group(1)[8:]
    type = type.replace(match.group(1), "GLuint")
    Argument.__init__(self, name, type)

  def WriteGetCode(self, file):
    """Overridden from Argument."""
    code = """  %(type)s %(name)s = c.%(name)s;
"""
    file.Write(code % {'type': self.type, 'name': self.name})

  def GetValidArg(self, func):
    return "client_%s_id_" % self.resource_type.lower()

  def GetValidGLArg(self, func):
    return "kService%sId" % self.resource_type


class ResourceIdZeroArgument(Argument):
  """Represents a resource id argument to a function that can be zero."""

  def __init__(self, name, type):
    match = re.match("(GLidZero\w+)", type)
    self.resource_type = match.group(1)[8:]
    type = type.replace(match.group(1), "GLuint")
    Argument.__init__(self, name, type)

  def WriteGetCode(self, file):
    """Overridden from Argument."""
    file.Write("  %s %s = c.%s;\n" % (self.type, self.name, self.name))

  def GetValidArg(self, func):
    return "client_%s_id_" % self.resource_type.lower()

  def GetValidGLArg(self, func):
    return "kService%sId" % self.resource_type

  def GetNumInvalidValues(self, func):
    """returns the number of invalid values to be tested."""
    return 1

  def GetInvalidArg(self, index):
    """returns an invalid value by index."""
    return ("kInvalidClientId", "kNoError", "GL_INVALID_VALUE")


class Function(object):
  """A class that represents a function."""

  type_handlers = {
    '': TypeHandler(),
    'Bind': BindHandler(),
    'Create': CreateHandler(),
    'Custom': CustomHandler(),
    'Data': DataHandler(),
    'Delete': DeleteHandler(),
    'DELn': DELnHandler(),
    'GENn': GENnHandler(),
    'GETn': GETnHandler(),
    'GLchar': GLcharHandler(),
    'GLcharN': GLcharNHandler(),
    'HandWritten': HandWrittenHandler(),
    'Is': IsHandler(),
    'Manual': ManualHandler(),
    'PUT': PUTHandler(),
    'PUTn': PUTnHandler(),
    'PUTSTR': PUTSTRHandler(),
    'PUTXn': PUTXnHandler(),
    'StateSet': StateSetHandler(),
    'StateSetRGBAlpha': StateSetRGBAlphaHandler(),
    'StateSetFrontBack': StateSetFrontBackHandler(),
    'StateSetFrontBackSeparate': StateSetFrontBackSeparateHandler(),
    'StateSetNamedParameter': StateSetNamedParameter(),
    'STRn': STRnHandler(),
    'Todo': TodoHandler(),
  }

  def __init__(self, name, info):
    self.name = name
    self.original_name = info['original_name']

    self.original_args = self.ParseArgs(info['original_args'])

    if 'cmd_args' in info:
      self.args_for_cmds = self.ParseArgs(info['cmd_args'])
    else:
      self.args_for_cmds = self.original_args[:]

    self.return_type = info['return_type']
    if self.return_type != 'void':
      self.return_arg = CreateArg(info['return_type'] + " result")
    else:
      self.return_arg = None

    self.num_pointer_args = sum(
      [1 for arg in self.args_for_cmds if arg.IsPointer()])
    if self.num_pointer_args > 0:
      for arg in reversed(self.original_args):
        if arg.IsPointer():
          self.last_original_pointer_arg = arg
          break
    else:
      self.last_original_pointer_arg = None
    self.info = info
    self.type_handler = self.type_handlers[info['type']]
    self.can_auto_generate = (self.num_pointer_args == 0 and
                              info['return_type'] == "void")
    self.InitFunction()

  def ParseArgs(self, arg_string):
    """Parses a function arg string."""
    args = []
    parts = arg_string.split(',')
    for arg_string in parts:
      arg = CreateArg(arg_string)
      if arg:
        args.append(arg)
    return args

  def IsType(self, type_name):
    """Returns true if function is a certain type."""
    return self.info['type'] == type_name

  def InitFunction(self):
    """Creates command args and calls the init function for the type handler.

    Creates argument lists for command buffer commands, eg. self.cmd_args and
    self.init_args.
    Calls the type function initialization.
    Override to create different kind of command buffer command argument lists.
    """
    self.cmd_args = []
    for arg in self.args_for_cmds:
      arg.AddCmdArgs(self.cmd_args)

    self.init_args = []
    for arg in self.args_for_cmds:
      arg.AddInitArgs(self.init_args)

    if self.return_arg:
      self.init_args.append(self.return_arg)

    self.type_handler.InitFunction(self)

  def IsImmediate(self):
    """Returns whether the function is immediate data function or not."""
    return False

  def IsUnsafe(self):
    """Returns whether the function has service side validation or not."""
    return self.GetInfo('unsafe', False)

  def GetInfo(self, name, default = None):
    """Returns a value from the function info for this function."""
    if name in self.info:
      return self.info[name]
    return default

  def GetValidArg(self, arg):
    """Gets a valid argument value for the parameter arg from the function info
    if one exists."""
    try:
      index = self.GetOriginalArgs().index(arg)
    except ValueError:
      return None

    valid_args = self.GetInfo('valid_args')
    if valid_args and str(index) in valid_args:
      return valid_args[str(index)]
    return None

  def AddInfo(self, name, value):
    """Adds an info."""
    self.info[name] = value

  def IsExtension(self):
    return self.GetInfo('extension') or self.GetInfo('extension_flag')

  def IsCoreGLFunction(self):
    return (not self.IsExtension() and
            not self.GetInfo('pepper_interface') and
            not self.IsUnsafe())

  def InPepperInterface(self, interface):
    ext = self.GetInfo('pepper_interface')
    if not interface.GetName():
      return self.IsCoreGLFunction()
    return ext == interface.GetName()

  def InAnyPepperExtension(self):
    return self.IsCoreGLFunction() or self.GetInfo('pepper_interface')

  def GetErrorReturnString(self):
    if self.GetInfo("error_return"):
      return self.GetInfo("error_return")
    elif self.return_type == "GLboolean":
      return "GL_FALSE"
    elif "*" in self.return_type:
      return "NULL"
    return "0"

  def GetGLFunctionName(self):
    """Gets the function to call to execute GL for this command."""
    if self.GetInfo('decoder_func'):
      return self.GetInfo('decoder_func')
    return "gl%s" % self.original_name

  def GetGLTestFunctionName(self):
    gl_func_name = self.GetInfo('gl_test_func')
    if gl_func_name == None:
      gl_func_name = self.GetGLFunctionName()
    if gl_func_name.startswith("gl"):
      gl_func_name = gl_func_name[2:]
    else:
      gl_func_name = self.original_name
    return gl_func_name

  def GetDataTransferMethods(self):
    return self.GetInfo('data_transfer_methods',
                        ['immediate' if self.num_pointer_args == 1 else 'shm'])

  def AddCmdArg(self, arg):
    """Adds a cmd argument to this function."""
    self.cmd_args.append(arg)

  def GetCmdArgs(self):
    """Gets the command args for this function."""
    return self.cmd_args

  def ClearCmdArgs(self):
    """Clears the command args for this function."""
    self.cmd_args = []

  def GetCmdConstants(self):
    """Gets the constants for this function."""
    return [arg for arg in self.args_for_cmds if arg.IsConstant()]

  def GetInitArgs(self):
    """Gets the init args for this function."""
    return self.init_args

  def GetOriginalArgs(self):
    """Gets the original arguments to this function."""
    return self.original_args

  def GetLastOriginalArg(self):
    """Gets the last original argument to this function."""
    return self.original_args[len(self.original_args) - 1]

  def GetLastOriginalPointerArg(self):
    return self.last_original_pointer_arg

  def GetResourceIdArg(self):
    for arg in self.original_args:
      if hasattr(arg, 'resource_type'):
        return arg
    return None

  def _MaybePrependComma(self, arg_string, add_comma):
    """Adds a comma if arg_string is not empty and add_comma is true."""
    comma = ""
    if add_comma and len(arg_string):
      comma = ", "
    return "%s%s" % (comma, arg_string)

  def MakeTypedOriginalArgString(self, prefix, add_comma = False):
    """Gets a list of arguments as they are in GL."""
    args = self.GetOriginalArgs()
    arg_string = ", ".join(
        ["%s %s%s" % (arg.type, prefix, arg.name) for arg in args])
    return self._MaybePrependComma(arg_string, add_comma)

  def MakeOriginalArgString(self, prefix, add_comma = False, separator = ", "):
    """Gets the list of arguments as they are in GL."""
    args = self.GetOriginalArgs()
    arg_string = separator.join(
        ["%s%s" % (prefix, arg.name) for arg in args])
    return self._MaybePrependComma(arg_string, add_comma)

  def MakeTypedHelperArgString(self, prefix, add_comma = False):
    """Gets a list of typed GL arguments after removing unneeded arguments."""
    args = self.GetOriginalArgs()
    arg_string = ", ".join(
        ["%s %s%s" % (
          arg.type,
          prefix,
          arg.name,
        ) for arg in args if not arg.IsConstant()])
    return self._MaybePrependComma(arg_string, add_comma)

  def MakeHelperArgString(self, prefix, add_comma = False, separator = ", "):
    """Gets a list of GL arguments after removing unneeded arguments."""
    args = self.GetOriginalArgs()
    arg_string = separator.join(
        ["%s%s" % (prefix, arg.name)
         for arg in args if not arg.IsConstant()])
    return self._MaybePrependComma(arg_string, add_comma)

  def MakeTypedPepperArgString(self, prefix):
    """Gets a list of arguments as they need to be for Pepper."""
    if self.GetInfo("pepper_args"):
      return self.GetInfo("pepper_args")
    else:
      return self.MakeTypedOriginalArgString(prefix, False)

  def MapCTypeToPepperIdlType(self, ctype, is_for_return_type=False):
    """Converts a C type name to the corresponding Pepper IDL type."""
    idltype = {
        'char*': '[out] str_t',
        'const GLchar* const*': '[out] cstr_t',
        'const char*': 'cstr_t',
        'const void*': 'mem_t',
        'void*': '[out] mem_t',
        'void**': '[out] mem_ptr_t',
    }.get(ctype, ctype)
    # We use "GLxxx_ptr_t" for "GLxxx*".
    matched = re.match(r'(const )?(GL\w+)\*$', ctype)
    if matched:
      idltype = matched.group(2) + '_ptr_t'
      if not matched.group(1):
        idltype = '[out] ' + idltype
    # If an in/out specifier is not specified yet, prepend [in].
    if idltype[0] != '[':
      idltype = '[in] ' + idltype
    # Strip the in/out specifier for a return type.
    if is_for_return_type:
      idltype = re.sub(r'\[\w+\] ', '', idltype)
    return idltype

  def MakeTypedPepperIdlArgStrings(self):
    """Gets a list of arguments as they need to be for Pepper IDL."""
    args = self.GetOriginalArgs()
    return ["%s %s" % (self.MapCTypeToPepperIdlType(arg.type), arg.name)
            for arg in args]

  def GetPepperName(self):
    if self.GetInfo("pepper_name"):
      return self.GetInfo("pepper_name")
    return self.name

  def MakeTypedCmdArgString(self, prefix, add_comma = False):
    """Gets a typed list of arguments as they need to be for command buffers."""
    args = self.GetCmdArgs()
    arg_string = ", ".join(
        ["%s %s%s" % (arg.type, prefix, arg.name) for arg in args])
    return self._MaybePrependComma(arg_string, add_comma)

  def MakeCmdArgString(self, prefix, add_comma = False):
    """Gets the list of arguments as they need to be for command buffers."""
    args = self.GetCmdArgs()
    arg_string = ", ".join(
        ["%s%s" % (prefix, arg.name) for arg in args])
    return self._MaybePrependComma(arg_string, add_comma)

  def MakeTypedInitString(self, prefix, add_comma = False):
    """Gets a typed list of arguments as they need to be for cmd Init/Set."""
    args = self.GetInitArgs()
    arg_string = ", ".join(
        ["%s %s%s" % (arg.type, prefix, arg.name) for arg in args])
    return self._MaybePrependComma(arg_string, add_comma)

  def MakeInitString(self, prefix, add_comma = False):
    """Gets the list of arguments as they need to be for cmd Init/Set."""
    args = self.GetInitArgs()
    arg_string = ", ".join(
        ["%s%s" % (prefix, arg.name) for arg in args])
    return self._MaybePrependComma(arg_string, add_comma)

  def MakeLogArgString(self):
    """Makes a string of the arguments for the LOG macros"""
    args = self.GetOriginalArgs()
    return ' << ", " << '.join([arg.GetLogArg() for arg in args])

  def WriteCommandDescription(self, file):
    """Writes a description of the command."""
    file.Write("//! Command that corresponds to gl%s.\n" % self.original_name)

  def WriteHandlerValidation(self, file):
    """Writes validation code for the function."""
    for arg in self.GetOriginalArgs():
      arg.WriteValidationCode(file, self)
    self.WriteValidationCode(file)

  def WriteHandlerImplementation(self, file):
    """Writes the handler implementation for this command."""
    self.type_handler.WriteHandlerImplementation(self, file)

  def WriteValidationCode(self, file):
    """Writes the validation code for a command."""
    pass

  def WriteCmdFlag(self, file):
    """Writes the cmd cmd_flags constant."""
    flags = []
    # By default trace only at the highest level 3.
    trace_level = int(self.GetInfo('trace_level', default = 3))
    if trace_level not in xrange(0, 4):
      raise KeyError("Unhandled trace_level: %d" % trace_level)

    flags.append('CMD_FLAG_SET_TRACE_LEVEL(%d)' % trace_level)

    if len(flags) > 0:
      cmd_flags = ' | '.join(flags)
    else:
      cmd_flags = 0

    file.Write("  static const uint8 cmd_flags = %s;\n" % cmd_flags)


  def WriteCmdArgFlag(self, file):
    """Writes the cmd kArgFlags constant."""
    file.Write("  static const cmd::ArgFlags kArgFlags = cmd::kFixed;\n")

  def WriteCmdComputeSize(self, file):
    """Writes the ComputeSize function for the command."""
    file.Write("  static uint32_t ComputeSize() {\n")
    file.Write(
        "    return static_cast<uint32_t>(sizeof(ValueType));  // NOLINT\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteCmdSetHeader(self, file):
    """Writes the cmd's SetHeader function."""
    file.Write("  void SetHeader() {\n")
    file.Write("    header.SetCmd<ValueType>();\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteCmdInit(self, file):
    """Writes the cmd's Init function."""
    file.Write("  void Init(%s) {\n" % self.MakeTypedCmdArgString("_"))
    file.Write("    SetHeader();\n")
    args = self.GetCmdArgs()
    for arg in args:
      file.Write("    %s = _%s;\n" % (arg.name, arg.name))
    file.Write("  }\n")
    file.Write("\n")

  def WriteCmdSet(self, file):
    """Writes the cmd's Set function."""
    copy_args = self.MakeCmdArgString("_", False)
    file.Write("  void* Set(void* cmd%s) {\n" %
               self.MakeTypedCmdArgString("_", True))
    file.Write("    static_cast<ValueType*>(cmd)->Init(%s);\n" % copy_args)
    file.Write("    return NextCmdAddress<ValueType>(cmd);\n")
    file.Write("  }\n")
    file.Write("\n")

  def WriteStruct(self, file):
    self.type_handler.WriteStruct(self, file)

  def WriteDocs(self, file):
    self.type_handler.WriteDocs(self, file)

  def WriteCmdHelper(self, file):
    """Writes the cmd's helper."""
    self.type_handler.WriteCmdHelper(self, file)

  def WriteServiceImplementation(self, file):
    """Writes the service implementation for a command."""
    self.type_handler.WriteServiceImplementation(self, file)

  def WriteServiceUnitTest(self, file, *extras):
    """Writes the service implementation for a command."""
    self.type_handler.WriteServiceUnitTest(self, file, *extras)

  def WriteGLES2CLibImplementation(self, file):
    """Writes the GLES2 C Lib Implemention."""
    self.type_handler.WriteGLES2CLibImplementation(self, file)

  def WriteGLES2InterfaceHeader(self, file):
    """Writes the GLES2 Interface declaration."""
    self.type_handler.WriteGLES2InterfaceHeader(self, file)

  def WriteMojoGLES2ImplHeader(self, file):
    """Writes the Mojo GLES2 implementation header declaration."""
    self.type_handler.WriteMojoGLES2ImplHeader(self, file)

  def WriteMojoGLES2Impl(self, file):
    """Writes the Mojo GLES2 implementation declaration."""
    self.type_handler.WriteMojoGLES2Impl(self, file)

  def WriteGLES2InterfaceStub(self, file):
    """Writes the GLES2 Interface Stub declaration."""
    self.type_handler.WriteGLES2InterfaceStub(self, file)

  def WriteGLES2InterfaceStubImpl(self, file):
    """Writes the GLES2 Interface Stub declaration."""
    self.type_handler.WriteGLES2InterfaceStubImpl(self, file)

  def WriteGLES2ImplementationHeader(self, file):
    """Writes the GLES2 Implemention declaration."""
    self.type_handler.WriteGLES2ImplementationHeader(self, file)

  def WriteGLES2Implementation(self, file):
    """Writes the GLES2 Implemention definition."""
    self.type_handler.WriteGLES2Implementation(self, file)

  def WriteGLES2TraceImplementationHeader(self, file):
    """Writes the GLES2 Trace Implemention declaration."""
    self.type_handler.WriteGLES2TraceImplementationHeader(self, file)

  def WriteGLES2TraceImplementation(self, file):
    """Writes the GLES2 Trace Implemention definition."""
    self.type_handler.WriteGLES2TraceImplementation(self, file)

  def WriteGLES2Header(self, file):
    """Writes the GLES2 Implemention unit test."""
    self.type_handler.WriteGLES2Header(self, file)

  def WriteGLES2ImplementationUnitTest(self, file):
    """Writes the GLES2 Implemention unit test."""
    self.type_handler.WriteGLES2ImplementationUnitTest(self, file)

  def WriteDestinationInitalizationValidation(self, file):
    """Writes the client side destintion initialization validation."""
    self.type_handler.WriteDestinationInitalizationValidation(self, file)

  def WriteFormatTest(self, file):
    """Writes the cmd's format test."""
    self.type_handler.WriteFormatTest(self, file)


class PepperInterface(object):
  """A class that represents a function."""

  def __init__(self, info):
    self.name = info["name"]
    self.dev = info["dev"]

  def GetName(self):
    return self.name

  def GetInterfaceName(self):
    upperint = ""
    dev = ""
    if self.name:
      upperint = "_" + self.name.upper()
    if self.dev:
      dev = "_DEV"
    return "PPB_OPENGLES2%s%s_INTERFACE" % (upperint, dev)

  def GetInterfaceString(self):
    dev = ""
    if self.dev:
      dev = "(Dev)"
    return "PPB_OpenGLES2%s%s" % (self.name, dev)

  def GetStructName(self):
    dev = ""
    if self.dev:
      dev = "_Dev"
    return "PPB_OpenGLES2%s%s" % (self.name, dev)


class ImmediateFunction(Function):
  """A class that represnets an immediate function command."""

  def __init__(self, func):
    Function.__init__(
        self,
        "%sImmediate" % func.name,
        func.info)

  def InitFunction(self):
    # Override args in original_args and args_for_cmds with immediate versions
    # of the args.

    new_original_args = []
    for arg in self.original_args:
      new_arg = arg.GetImmediateVersion()
      if new_arg:
        new_original_args.append(new_arg)
    self.original_args = new_original_args

    new_args_for_cmds = []
    for arg in self.args_for_cmds:
      new_arg = arg.GetImmediateVersion()
      if new_arg:
        new_args_for_cmds.append(new_arg)

    self.args_for_cmds = new_args_for_cmds

    Function.InitFunction(self)

  def IsImmediate(self):
    return True

  def WriteCommandDescription(self, file):
    """Overridden from Function"""
    file.Write("//! Immediate version of command that corresponds to gl%s.\n" %
        self.original_name)

  def WriteServiceImplementation(self, file):
    """Overridden from Function"""
    self.type_handler.WriteImmediateServiceImplementation(self, file)

  def WriteHandlerImplementation(self, file):
    """Overridden from Function"""
    self.type_handler.WriteImmediateHandlerImplementation(self, file)

  def WriteServiceUnitTest(self, file, *extras):
    """Writes the service implementation for a command."""
    self.type_handler.WriteImmediateServiceUnitTest(self, file, *extras)

  def WriteValidationCode(self, file):
    """Overridden from Function"""
    self.type_handler.WriteImmediateValidationCode(self, file)

  def WriteCmdArgFlag(self, file):
    """Overridden from Function"""
    file.Write("  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;\n")

  def WriteCmdComputeSize(self, file):
    """Overridden from Function"""
    self.type_handler.WriteImmediateCmdComputeSize(self, file)

  def WriteCmdSetHeader(self, file):
    """Overridden from Function"""
    self.type_handler.WriteImmediateCmdSetHeader(self, file)

  def WriteCmdInit(self, file):
    """Overridden from Function"""
    self.type_handler.WriteImmediateCmdInit(self, file)

  def WriteCmdSet(self, file):
    """Overridden from Function"""
    self.type_handler.WriteImmediateCmdSet(self, file)

  def WriteCmdHelper(self, file):
    """Overridden from Function"""
    self.type_handler.WriteImmediateCmdHelper(self, file)

  def WriteFormatTest(self, file):
    """Overridden from Function"""
    self.type_handler.WriteImmediateFormatTest(self, file)


class BucketFunction(Function):
  """A class that represnets a bucket version of a function command."""

  def __init__(self, func):
    Function.__init__(
      self,
      "%sBucket" % func.name,
      func.info)

  def InitFunction(self):
    # Override args in original_args and args_for_cmds with bucket versions
    # of the args.

    new_original_args = []
    for arg in self.original_args:
      new_arg = arg.GetBucketVersion()
      if new_arg:
        new_original_args.append(new_arg)
    self.original_args = new_original_args

    new_args_for_cmds = []
    for arg in self.args_for_cmds:
      new_arg = arg.GetBucketVersion()
      if new_arg:
        new_args_for_cmds.append(new_arg)

    self.args_for_cmds = new_args_for_cmds

    Function.InitFunction(self)

  def WriteCommandDescription(self, file):
    """Overridden from Function"""
    file.Write("//! Bucket version of command that corresponds to gl%s.\n" %
        self.original_name)

  def WriteServiceImplementation(self, file):
    """Overridden from Function"""
    self.type_handler.WriteBucketServiceImplementation(self, file)

  def WriteHandlerImplementation(self, file):
    """Overridden from Function"""
    self.type_handler.WriteBucketHandlerImplementation(self, file)

  def WriteServiceUnitTest(self, file, *extras):
    """Overridden from Function"""
    self.type_handler.WriteBucketServiceUnitTest(self, file, *extras)

  def MakeOriginalArgString(self, prefix, add_comma = False, separator = ", "):
    """Overridden from Function"""
    args = self.GetOriginalArgs()
    arg_string = separator.join(
        ["%s%s" % (prefix, arg.name[0:-10] if arg.name.endswith("_bucket_id")
                           else arg.name) for arg in args])
    return super(BucketFunction, self)._MaybePrependComma(arg_string, add_comma)


def CreateArg(arg_string):
  """Creates an Argument."""
  arg_parts = arg_string.split()
  if len(arg_parts) == 1 and arg_parts[0] == 'void':
    return None
  # Is this a pointer argument?
  elif arg_string.find('*') >= 0:
    return PointerArgument(
        arg_parts[-1],
        " ".join(arg_parts[0:-1]))
  # Is this a resource argument? Must come after pointer check.
  elif arg_parts[0].startswith('GLidBind'):
    return ResourceIdBindArgument(arg_parts[-1], " ".join(arg_parts[0:-1]))
  elif arg_parts[0].startswith('GLidZero'):
    return ResourceIdZeroArgument(arg_parts[-1], " ".join(arg_parts[0:-1]))
  elif arg_parts[0].startswith('GLid'):
    return ResourceIdArgument(arg_parts[-1], " ".join(arg_parts[0:-1]))
  elif arg_parts[0].startswith('GLenum') and len(arg_parts[0]) > 6:
    return EnumArgument(arg_parts[-1], " ".join(arg_parts[0:-1]))
  elif arg_parts[0].startswith('GLbitfield') and len(arg_parts[0]) > 10:
    return BitFieldArgument(arg_parts[-1], " ".join(arg_parts[0:-1]))
  elif arg_parts[0].startswith('GLboolean') and len(arg_parts[0]) > 9:
    return ValidatedBoolArgument(arg_parts[-1], " ".join(arg_parts[0:-1]))
  elif arg_parts[0].startswith('GLboolean'):
    return BoolArgument(arg_parts[-1], " ".join(arg_parts[0:-1]))
  elif arg_parts[0].startswith('GLintUniformLocation'):
    return UniformLocationArgument(arg_parts[-1])
  elif (arg_parts[0].startswith('GLint') and len(arg_parts[0]) > 5 and
        not arg_parts[0].startswith('GLintptr')):
    return IntArgument(arg_parts[-1], " ".join(arg_parts[0:-1]))
  elif (arg_parts[0].startswith('GLsizeiNotNegative') or
        arg_parts[0].startswith('GLintptrNotNegative')):
    return SizeNotNegativeArgument(arg_parts[-1],
                                   " ".join(arg_parts[0:-1]),
                                   arg_parts[0][0:-11])
  elif arg_parts[0].startswith('GLsize'):
    return SizeArgument(arg_parts[-1], " ".join(arg_parts[0:-1]))
  else:
    return Argument(arg_parts[-1], " ".join(arg_parts[0:-1]))


class GLGenerator(object):
  """A class to generate GL command buffers."""

  _function_re = re.compile(r'GL_APICALL(.*?)GL_APIENTRY (.*?) \((.*?)\);')

  def __init__(self, verbose):
    self.original_functions = []
    self.functions = []
    self.verbose = verbose
    self.errors = 0
    self.pepper_interfaces = []
    self.interface_info = {}
    self.generated_cpp_filenames = []

    for interface in _PEPPER_INTERFACES:
      interface = PepperInterface(interface)
      self.pepper_interfaces.append(interface)
      self.interface_info[interface.GetName()] = interface

  def AddFunction(self, func):
    """Adds a function."""
    self.functions.append(func)

  def GetFunctionInfo(self, name):
    """Gets a type info for the given function name."""
    if name in _FUNCTION_INFO:
      func_info = _FUNCTION_INFO[name].copy()
    else:
      func_info = {}

    if not 'type' in func_info:
      func_info['type'] = ''

    return func_info

  def Log(self, msg):
    """Prints something if verbose is true."""
    if self.verbose:
      print msg

  def Error(self, msg):
    """Prints an error."""
    print "Error: %s" % msg
    self.errors += 1

  def WriteLicense(self, file):
    """Writes the license."""
    file.Write(_LICENSE)

  def WriteNamespaceOpen(self, file):
    """Writes the code for the namespace."""
    file.Write("namespace gpu {\n")
    file.Write("namespace gles2 {\n")
    file.Write("\n")

  def WriteNamespaceClose(self, file):
    """Writes the code to close the namespace."""
    file.Write("}  // namespace gles2\n")
    file.Write("}  // namespace gpu\n")
    file.Write("\n")

  def ParseGLH(self, filename):
    """Parses the cmd_buffer_functions.txt file and extracts the functions"""
    f = open(filename, "r")
    functions = f.read()
    f.close()
    for line in functions.splitlines():
      match = self._function_re.match(line)
      if match:
        func_name = match.group(2)[2:]
        func_info = self.GetFunctionInfo(func_name)
        if func_info['type'] == 'Noop':
          continue

        parsed_func_info = {
          'original_name': func_name,
          'original_args': match.group(3),
          'return_type': match.group(1).strip(),
        }

        for k in parsed_func_info.keys():
          if not k in func_info:
            func_info[k] = parsed_func_info[k]

        f = Function(func_name, func_info)
        self.original_functions.append(f)

        #for arg in f.GetOriginalArgs():
        #  if not isinstance(arg, EnumArgument) and arg.type == 'GLenum':
        #    self.Log("%s uses bare GLenum %s." % (func_name, arg.name))

        gen_cmd = f.GetInfo('gen_cmd')
        if gen_cmd == True or gen_cmd == None:
          if f.type_handler.NeedsDataTransferFunction(f):
            methods = f.GetDataTransferMethods()
            if 'immediate' in methods:
              self.AddFunction(ImmediateFunction(f))
            if 'bucket' in methods:
              self.AddFunction(BucketFunction(f))
            if 'shm' in methods:
              self.AddFunction(f)
          else:
            self.AddFunction(f)

    self.Log("Auto Generated Functions    : %d" %
             len([f for f in self.functions if f.can_auto_generate or
                  (not f.IsType('') and not f.IsType('Custom') and
                   not f.IsType('Todo'))]))

    funcs = [f for f in self.functions if not f.can_auto_generate and
             (f.IsType('') or f.IsType('Custom') or f.IsType('Todo'))]
    self.Log("Non Auto Generated Functions: %d" % len(funcs))

    for f in funcs:
      self.Log("  %-10s %-20s gl%s" % (f.info['type'], f.return_type, f.name))

  def WriteCommandIds(self, filename):
    """Writes the command buffer format"""
    file = CHeaderWriter(filename)
    file.Write("#define GLES2_COMMAND_LIST(OP) \\\n")
    id = 256
    for func in self.functions:
      file.Write("  %-60s /* %d */ \\\n" %
                 ("OP(%s)" % func.name, id))
      id += 1
    file.Write("\n")

    file.Write("enum CommandId {\n")
    file.Write("  kStartPoint = cmd::kLastCommonId,  "
               "// All GLES2 commands start after this.\n")
    file.Write("#define GLES2_CMD_OP(name) k ## name,\n")
    file.Write("  GLES2_COMMAND_LIST(GLES2_CMD_OP)\n")
    file.Write("#undef GLES2_CMD_OP\n")
    file.Write("  kNumCommands\n")
    file.Write("};\n")
    file.Write("\n")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteFormat(self, filename):
    """Writes the command buffer format"""
    file = CHeaderWriter(filename)
    # Forward declaration of a few enums used in constant argument
    # to avoid including GL header files.
    enum_defines = {
        'GL_SYNC_GPU_COMMANDS_COMPLETE': '0x9117',
        'GL_SYNC_FLUSH_COMMANDS_BIT': '0x00000001',
      }
    file.Write('\n')
    for enum in enum_defines:
      file.Write("#define %s %s\n" % (enum, enum_defines[enum]))
    file.Write('\n')
    for func in self.functions:
      if True:
      #gen_cmd = func.GetInfo('gen_cmd')
      #if gen_cmd == True or gen_cmd == None:
        func.WriteStruct(file)
    file.Write("\n")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteDocs(self, filename):
    """Writes the command buffer doc version of the commands"""
    file = CWriter(filename)
    for func in self.functions:
      if True:
      #gen_cmd = func.GetInfo('gen_cmd')
      #if gen_cmd == True or gen_cmd == None:
        func.WriteDocs(file)
    file.Write("\n")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteFormatTest(self, filename):
    """Writes the command buffer format test."""
    file = CHeaderWriter(
      filename,
      "// This file contains unit tests for gles2 commmands\n"
      "// It is included by gles2_cmd_format_test.cc\n"
      "\n")

    for func in self.functions:
      if True:
      #gen_cmd = func.GetInfo('gen_cmd')
      #if gen_cmd == True or gen_cmd == None:
        func.WriteFormatTest(file)

    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteCmdHelperHeader(self, filename):
    """Writes the gles2 command helper."""
    file = CHeaderWriter(filename)

    for func in self.functions:
      if True:
      #gen_cmd = func.GetInfo('gen_cmd')
      #if gen_cmd == True or gen_cmd == None:
        func.WriteCmdHelper(file)

    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteServiceContextStateHeader(self, filename):
    """Writes the service context state header."""
    file = CHeaderWriter(
        filename,
        "// It is included by context_state.h\n")
    file.Write("struct EnableFlags {\n")
    file.Write("  EnableFlags();\n")
    for capability in _CAPABILITY_FLAGS:
      file.Write("  bool %s;\n" % capability['name'])
      file.Write("  bool cached_%s;\n" % capability['name'])
    file.Write("};\n\n")

    for state_name in sorted(_STATES.keys()):
      state = _STATES[state_name]
      for item in state['states']:
        if isinstance(item['default'], list):
          file.Write("%s %s[%d];\n" % (item['type'], item['name'],
                                       len(item['default'])))
        else:
          file.Write("%s %s;\n" % (item['type'], item['name']))

        if item.get('cached', False):
          if isinstance(item['default'], list):
            file.Write("%s cached_%s[%d];\n" % (item['type'], item['name'],
                                                len(item['default'])))
          else:
            file.Write("%s cached_%s;\n" % (item['type'], item['name']))

    file.Write("\n")

    file.Write("""
        inline void SetDeviceCapabilityState(GLenum cap, bool enable) {
          switch (cap) {
        """)
    for capability in _CAPABILITY_FLAGS:
      file.Write("""\
            case GL_%s:
          """ % capability['name'].upper())
      file.Write("""\
              if (enable_flags.cached_%(name)s == enable &&
                  !ignore_cached_state)
                return;
              enable_flags.cached_%(name)s = enable;
              break;
          """ % capability)

    file.Write("""\
            default:
              NOTREACHED();
              return;
          }
          if (enable)
            glEnable(cap);
          else
            glDisable(cap);
        }
        """)

    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteClientContextStateHeader(self, filename):
    """Writes the client context state header."""
    file = CHeaderWriter(
        filename,
        "// It is included by client_context_state.h\n")
    file.Write("struct EnableFlags {\n")
    file.Write("  EnableFlags();\n")
    for capability in _CAPABILITY_FLAGS:
      file.Write("  bool %s;\n" % capability['name'])
    file.Write("};\n\n")

    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteContextStateGetters(self, file, class_name):
    """Writes the state getters."""
    for gl_type in ["GLint", "GLfloat"]:
      file.Write("""
bool %s::GetStateAs%s(
    GLenum pname, %s* params, GLsizei* num_written) const {
  switch (pname) {
""" % (class_name, gl_type, gl_type))
      for state_name in sorted(_STATES.keys()):
        state = _STATES[state_name]
        if 'enum' in state:
          file.Write("    case %s:\n" % state['enum'])
          file.Write("      *num_written = %d;\n" % len(state['states']))
          file.Write("      if (params) {\n")
          for ndx,item in enumerate(state['states']):
            file.Write("        params[%d] = static_cast<%s>(%s);\n" %
                       (ndx, gl_type, item['name']))
          file.Write("      }\n")
          file.Write("      return true;\n")
        else:
          for item in state['states']:
            file.Write("    case %s:\n" % item['enum'])
            if isinstance(item['default'], list):
              item_len = len(item['default'])
              file.Write("      *num_written = %d;\n" % item_len)
              file.Write("      if (params) {\n")
              if item['type'] == gl_type:
                file.Write("        memcpy(params, %s, sizeof(%s) * %d);\n" %
                           (item['name'], item['type'], item_len))
              else:
                file.Write("        for (size_t i = 0; i < %s; ++i) {\n" %
                           item_len)
                file.Write("          params[i] = %s;\n" %
                           (GetGLGetTypeConversion(gl_type, item['type'],
                                                   "%s[i]" % item['name'])))
                file.Write("        }\n");
            else:
              file.Write("      *num_written = 1;\n")
              file.Write("      if (params) {\n")
              file.Write("        params[0] = %s;\n" %
                         (GetGLGetTypeConversion(gl_type, item['type'],
                                                 item['name'])))
            file.Write("      }\n")
            file.Write("      return true;\n")
      for capability in _CAPABILITY_FLAGS:
            file.Write("    case GL_%s:\n" % capability['name'].upper())
            file.Write("      *num_written = 1;\n")
            file.Write("      if (params) {\n")
            file.Write(
                "        params[0] = static_cast<%s>(enable_flags.%s);\n" %
                (gl_type, capability['name']))
            file.Write("      }\n")
            file.Write("      return true;\n")
      file.Write("""    default:
      return false;
  }
}
""")

  def WriteServiceContextStateImpl(self, filename):
    """Writes the context state service implementation."""
    file = CHeaderWriter(
        filename,
        "// It is included by context_state.cc\n")
    code = []
    for capability in _CAPABILITY_FLAGS:
      code.append("%s(%s)" %
                  (capability['name'],
                   ('false', 'true')['default' in capability]))
      code.append("cached_%s(%s)" %
                  (capability['name'],
                   ('false', 'true')['default' in capability]))
    file.Write("ContextState::EnableFlags::EnableFlags()\n    : %s {\n}\n" %
               ",\n      ".join(code))
    file.Write("\n")

    file.Write("void ContextState::Initialize() {\n")
    for state_name in sorted(_STATES.keys()):
      state = _STATES[state_name]
      for item in state['states']:
        if isinstance(item['default'], list):
          for ndx, value in enumerate(item['default']):
            file.Write("  %s[%d] = %s;\n" % (item['name'], ndx, value))
        else:
          file.Write("  %s = %s;\n" % (item['name'], item['default']))
        if item.get('cached', False):
          if isinstance(item['default'], list):
            for ndx, value in enumerate(item['default']):
              file.Write("  cached_%s[%d] = %s;\n" % (item['name'], ndx, value))
          else:
            file.Write("  cached_%s = %s;\n" % (item['name'], item['default']))
    file.Write("}\n")

    file.Write("""
void ContextState::InitCapabilities(const ContextState* prev_state) const {
""")
    def WriteCapabilities(test_prev, es3_caps):
      for capability in _CAPABILITY_FLAGS:
        capability_name = capability['name']
        capability_es3 = 'es3' in capability and capability['es3'] == True
        if capability_es3 and not es3_caps or not capability_es3 and es3_caps:
          continue
        if test_prev:
          file.Write("""  if (prev_state->enable_flags.cached_%s !=
                              enable_flags.cached_%s) {\n""" %
                     (capability_name, capability_name))
        file.Write("    EnableDisable(GL_%s, enable_flags.cached_%s);\n" %
                   (capability_name.upper(), capability_name))
        if test_prev:
          file.Write("  }")

    file.Write("  if (prev_state) {")
    WriteCapabilities(True, False)
    file.Write("    if (feature_info_->IsES3Capable()) {\n")
    WriteCapabilities(True, True)
    file.Write("    }\n")
    file.Write("  } else {")
    WriteCapabilities(False, False)
    file.Write("    if (feature_info_->IsES3Capable()) {\n")
    WriteCapabilities(False, True)
    file.Write("    }\n")
    file.Write("  }")

    file.Write("""}

void ContextState::InitState(const ContextState *prev_state) const {
""")

    def WriteStates(test_prev):
      # We need to sort the keys so the expectations match
      for state_name in sorted(_STATES.keys()):
        state = _STATES[state_name]
        if state['type'] == 'FrontBack':
          num_states = len(state['states'])
          for ndx, group in enumerate(Grouper(num_states / 2, state['states'])):
            if test_prev:
              file.Write("  if (")
            args = []
            for place, item in enumerate(group):
              item_name = CachedStateName(item)
              args.append('%s' % item_name)
              if test_prev:
                if place > 0:
                  file.Write(' ||\n')
                file.Write("(%s != prev_state->%s)" % (item_name, item_name))
            if test_prev:
              file.Write(")\n")
            file.Write(
                "  gl%s(%s, %s);\n" %
                (state['func'], ('GL_FRONT', 'GL_BACK')[ndx], ", ".join(args)))
        elif state['type'] == 'NamedParameter':
          for item in state['states']:
            item_name = CachedStateName(item)

            if 'extension_flag' in item:
              file.Write("  if (feature_info_->feature_flags().%s) {\n  " %
                         item['extension_flag'])
            if test_prev:
              if isinstance(item['default'], list):
                file.Write("  if (memcmp(prev_state->%s, %s, "
                           "sizeof(%s) * %d)) {\n" %
                           (item_name, item_name, item['type'],
                            len(item['default'])))
              else:
                file.Write("  if (prev_state->%s != %s) {\n  " %
                           (item_name, item_name))
            file.Write("  gl%s(%s, %s);\n" %
                       (state['func'],
                        (item['enum_set']
                           if 'enum_set' in item else item['enum']),
                        item['name']))
            if test_prev:
              if 'extension_flag' in item:
                file.Write("  ")
              file.Write("  }")
            if 'extension_flag' in item:
              file.Write("  }")
        else:
          if 'extension_flag' in state:
            file.Write("  if (feature_info_->feature_flags().%s)\n  " %
                       state['extension_flag'])
          if test_prev:
            file.Write("  if (")
          args = []
          for place, item in enumerate(state['states']):
            item_name = CachedStateName(item)
            args.append('%s' % item_name)
            if test_prev:
              if place > 0:
                file.Write(' ||\n')
              file.Write("(%s != prev_state->%s)" %
                         (item_name, item_name))
          if test_prev:
            file.Write("    )\n")
          file.Write("  gl%s(%s);\n" % (state['func'], ", ".join(args)))

    file.Write("  if (prev_state) {")
    WriteStates(True)
    file.Write("  } else {")
    WriteStates(False)
    file.Write("  }")
    file.Write("}\n")

    file.Write("""bool ContextState::GetEnabled(GLenum cap) const {
  switch (cap) {
""")
    for capability in _CAPABILITY_FLAGS:
      file.Write("    case GL_%s:\n" % capability['name'].upper())
      file.Write("      return enable_flags.%s;\n" % capability['name'])
    file.Write("""    default:
      NOTREACHED();
      return false;
  }
}
""")

    self.WriteContextStateGetters(file, "ContextState")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteClientContextStateImpl(self, filename):
    """Writes the context state client side implementation."""
    file = CHeaderWriter(
        filename,
        "// It is included by client_context_state.cc\n")
    code = []
    for capability in _CAPABILITY_FLAGS:
      code.append("%s(%s)" %
                  (capability['name'],
                   ('false', 'true')['default' in capability]))
    file.Write(
      "ClientContextState::EnableFlags::EnableFlags()\n    : %s {\n}\n" %
      ",\n      ".join(code))
    file.Write("\n")

    file.Write("""
bool ClientContextState::SetCapabilityState(
    GLenum cap, bool enabled, bool* changed) {
  *changed = false;
  switch (cap) {
""")
    for capability in _CAPABILITY_FLAGS:
      file.Write("    case GL_%s:\n" % capability['name'].upper())
      file.Write("""      if (enable_flags.%(name)s != enabled) {
         *changed = true;
         enable_flags.%(name)s = enabled;
      }
      return true;
""" % capability)
    file.Write("""    default:
      return false;
  }
}
""")
    file.Write("""bool ClientContextState::GetEnabled(
    GLenum cap, bool* enabled) const {
  switch (cap) {
""")
    for capability in _CAPABILITY_FLAGS:
      file.Write("    case GL_%s:\n" % capability['name'].upper())
      file.Write("      *enabled = enable_flags.%s;\n" % capability['name'])
      file.Write("      return true;\n")
    file.Write("""    default:
      return false;
  }
}
""")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteServiceImplementation(self, filename):
    """Writes the service decorder implementation."""
    file = CHeaderWriter(
        filename,
        "// It is included by gles2_cmd_decoder.cc\n")

    for func in self.functions:
      if True:
      #gen_cmd = func.GetInfo('gen_cmd')
      #if gen_cmd == True or gen_cmd == None:
        func.WriteServiceImplementation(file)

    file.Write("""
bool GLES2DecoderImpl::SetCapabilityState(GLenum cap, bool enabled) {
  switch (cap) {
""")
    for capability in _CAPABILITY_FLAGS:
      file.Write("    case GL_%s:\n" % capability['name'].upper())
      if 'state_flag' in capability:

        file.Write("""\
            state_.enable_flags.%(name)s = enabled;
            if (state_.enable_flags.cached_%(name)s != enabled
                || state_.ignore_cached_state) {
              %(state_flag)s = true;
            }
            return false;
            """ % capability)
      else:
        file.Write("""\
            state_.enable_flags.%(name)s = enabled;
            if (state_.enable_flags.cached_%(name)s != enabled
                || state_.ignore_cached_state) {
              state_.enable_flags.cached_%(name)s = enabled;
              return true;
            }
            return false;
            """ % capability)
    file.Write("""    default:
      NOTREACHED();
      return false;
  }
}
""")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteServiceUnitTests(self, filename):
    """Writes the service decorder unit tests."""
    num_tests = len(self.functions)
    FUNCTIONS_PER_FILE = 98  # hard code this so it doesn't change.
    count = 0
    for test_num in range(0, num_tests, FUNCTIONS_PER_FILE):
      count += 1
      name = filename % count
      file = CHeaderWriter(
          name,
          "// It is included by gles2_cmd_decoder_unittest_%d.cc\n" % count)
      test_name = 'GLES2DecoderTest%d' % count
      end = test_num + FUNCTIONS_PER_FILE
      if end > num_tests:
        end = num_tests
      for idx in range(test_num, end):
        func = self.functions[idx]

        # Do any filtering of the functions here, so that the functions
        # will not move between the numbered files if filtering properties
        # are changed.
        if func.GetInfo('extension_flag'):
          continue

        if True:
        #gen_cmd = func.GetInfo('gen_cmd')
        #if gen_cmd == True or gen_cmd == None:
          if func.GetInfo('unit_test') == False:
            file.Write("// TODO(gman): %s\n" % func.name)
          else:
            func.WriteServiceUnitTest(file, {
              'test_name': test_name
            })
      file.Close()
      self.generated_cpp_filenames.append(file.filename)
    file = CHeaderWriter(
        filename % 0,
        "// It is included by gles2_cmd_decoder_unittest_base.cc\n")
    file.Write(
"""void GLES2DecoderTestBase::SetupInitCapabilitiesExpectations(
      bool es3_capable) {""")
    for capability in _CAPABILITY_FLAGS:
      capability_es3 = 'es3' in capability and capability['es3'] == True
      if not capability_es3:
        file.Write("  ExpectEnableDisable(GL_%s, %s);\n" %
                   (capability['name'].upper(),
                    ('false', 'true')['default' in capability]))

    file.Write("  if (es3_capable) {")
    for capability in _CAPABILITY_FLAGS:
      capability_es3 = 'es3' in capability and capability['es3'] == True
      if capability_es3:
        file.Write("    ExpectEnableDisable(GL_%s, %s);\n" %
                   (capability['name'].upper(),
                    ('false', 'true')['default' in capability]))
    file.Write("""  }
}

void GLES2DecoderTestBase::SetupInitStateExpectations() {
""")

    # We need to sort the keys so the expectations match
    for state_name in sorted(_STATES.keys()):
      state = _STATES[state_name]
      if state['type'] == 'FrontBack':
        num_states = len(state['states'])
        for ndx, group in enumerate(Grouper(num_states / 2, state['states'])):
          args = []
          for item in group:
            if 'expected' in item:
              args.append(item['expected'])
            else:
              args.append(item['default'])
          file.Write(
              "  EXPECT_CALL(*gl_, %s(%s, %s))\n" %
              (state['func'], ('GL_FRONT', 'GL_BACK')[ndx], ", ".join(args)))
          file.Write("      .Times(1)\n")
          file.Write("      .RetiresOnSaturation();\n")
      elif state['type'] == 'NamedParameter':
        for item in state['states']:
          if 'extension_flag' in item:
            file.Write("  if (group_->feature_info()->feature_flags().%s) {\n" %
                       item['extension_flag'])
            file.Write("  ")
          expect_value = item['default']
          if isinstance(expect_value, list):
            # TODO: Currently we do not check array values.
            expect_value = "_"

          file.Write(
              "  EXPECT_CALL(*gl_, %s(%s, %s))\n" %
              (state['func'],
               (item['enum_set']
                           if 'enum_set' in item else item['enum']),
               expect_value))
          file.Write("      .Times(1)\n")
          file.Write("      .RetiresOnSaturation();\n")
          if 'extension_flag' in item:
            file.Write("  }\n")
      else:
        if 'extension_flag' in state:
          file.Write("  if (group_->feature_info()->feature_flags().%s) {\n" %
                     state['extension_flag'])
          file.Write("  ")
        args = []
        for item in state['states']:
          if 'expected' in item:
            args.append(item['expected'])
          else:
            args.append(item['default'])
        # TODO: Currently we do not check array values.
        args = ["_" if isinstance(arg, list) else arg for arg in args]
        file.Write("  EXPECT_CALL(*gl_, %s(%s))\n" %
                   (state['func'], ", ".join(args)))
        file.Write("      .Times(1)\n")
        file.Write("      .RetiresOnSaturation();\n")
        if 'extension_flag' in state:
          file.Write("  }\n")
    file.Write("""}
""")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteServiceUnitTestsForExtensions(self, filename):
    """Writes the service decorder unit tests for functions with extension_flag.

       The functions are special in that they need a specific unit test
       baseclass to turn on the extension.
    """
    functions = [f for f in self.functions if f.GetInfo('extension_flag')]
    file = CHeaderWriter(
      filename,
      "// It is included by gles2_cmd_decoder_unittest_extensions.cc\n")
    for func in functions:
      if True:
        if func.GetInfo('unit_test') == False:
          file.Write("// TODO(gman): %s\n" % func.name)
        else:
          extension = ToCamelCase(
            ToGLExtensionString(func.GetInfo('extension_flag')))
          func.WriteServiceUnitTest(file, {
            'test_name': 'GLES2DecoderTestWith%s' % extension
          })

    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2Header(self, filename):
    """Writes the GLES2 header."""
    file = CHeaderWriter(
        filename,
        "// This file contains Chromium-specific GLES2 declarations.\n\n")

    for func in self.original_functions:
      func.WriteGLES2Header(file)

    file.Write("\n")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2CLibImplementation(self, filename):
    """Writes the GLES2 c lib implementation."""
    file = CHeaderWriter(
        filename,
        "// These functions emulate GLES2 over command buffers.\n")

    for func in self.original_functions:
      func.WriteGLES2CLibImplementation(file)

    file.Write("""
namespace gles2 {

extern const NameToFunc g_gles2_function_table[] = {
""")
    for func in self.original_functions:
      file.Write(
          '  { "gl%s", reinterpret_cast<GLES2FunctionPointer>(gl%s), },\n' %
          (func.name, func.name))
    file.Write("""  { NULL, NULL, },
};

}  // namespace gles2
""")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2InterfaceHeader(self, filename):
    """Writes the GLES2 interface header."""
    file = CHeaderWriter(
        filename,
        "// This file is included by gles2_interface.h to declare the\n"
        "// GL api functions.\n")
    for func in self.original_functions:
      func.WriteGLES2InterfaceHeader(file)
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteMojoGLES2ImplHeader(self, filename):
    """Writes the Mojo GLES2 implementation header."""
    file = CHeaderWriter(
        filename,
        "// This file is included by gles2_interface.h to declare the\n"
        "// GL api functions.\n")

    code = """
#include "gpu/command_buffer/client/gles2_interface.h"
#include "third_party/mojo/src/mojo/public/c/gles2/gles2.h"

namespace mojo {

class MojoGLES2Impl : public gpu::gles2::GLES2Interface {
 public:
  explicit MojoGLES2Impl(MojoGLES2Context context) {
    context_ = context;
  }
  ~MojoGLES2Impl() override {}
    """
    file.Write(code);
    for func in self.original_functions:
      func.WriteMojoGLES2ImplHeader(file)
    code = """
 private:
  MojoGLES2Context context_;
};

}  // namespace mojo
    """
    file.Write(code);
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteMojoGLES2Impl(self, filename):
    """Writes the Mojo GLES2 implementation."""
    file = CWriter(filename)
    file.Write(_LICENSE)
    file.Write(_DO_NOT_EDIT_WARNING)

    code = """
#include "mojo/gpu/mojo_gles2_impl_autogen.h"

#include "base/logging.h"
#include "third_party/mojo/src/mojo/public/c/gles2/chromium_sync_point.h"
#include "third_party/mojo/src/mojo/public/c/gles2/chromium_texture_mailbox.h"
#include "third_party/mojo/src/mojo/public/c/gles2/gles2.h"

namespace mojo {

    """
    file.Write(code);
    for func in self.original_functions:
      func.WriteMojoGLES2Impl(file)
    code = """

}  // namespace mojo
    """
    file.Write(code);
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2InterfaceStub(self, filename):
    """Writes the GLES2 interface stub header."""
    file = CHeaderWriter(
        filename,
        "// This file is included by gles2_interface_stub.h.\n")
    for func in self.original_functions:
      func.WriteGLES2InterfaceStub(file)
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2InterfaceStubImpl(self, filename):
    """Writes the GLES2 interface header."""
    file = CHeaderWriter(
        filename,
        "// This file is included by gles2_interface_stub.cc.\n")
    for func in self.original_functions:
      func.WriteGLES2InterfaceStubImpl(file)
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2ImplementationHeader(self, filename):
    """Writes the GLES2 Implementation header."""
    file = CHeaderWriter(
        filename,
        "// This file is included by gles2_implementation.h to declare the\n"
        "// GL api functions.\n")
    for func in self.original_functions:
      func.WriteGLES2ImplementationHeader(file)
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2Implementation(self, filename):
    """Writes the GLES2 Implementation."""
    file = CHeaderWriter(
        filename,
        "// This file is included by gles2_implementation.cc to define the\n"
        "// GL api functions.\n")
    for func in self.original_functions:
      func.WriteGLES2Implementation(file)
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2TraceImplementationHeader(self, filename):
    """Writes the GLES2 Trace Implementation header."""
    file = CHeaderWriter(
        filename,
        "// This file is included by gles2_trace_implementation.h\n")
    for func in self.original_functions:
      func.WriteGLES2TraceImplementationHeader(file)
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2TraceImplementation(self, filename):
    """Writes the GLES2 Trace Implementation."""
    file = CHeaderWriter(
        filename,
        "// This file is included by gles2_trace_implementation.cc\n")
    for func in self.original_functions:
      func.WriteGLES2TraceImplementation(file)
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2ImplementationUnitTests(self, filename):
    """Writes the GLES2 helper header."""
    file = CHeaderWriter(
        filename,
        "// This file is included by gles2_implementation.h to declare the\n"
        "// GL api functions.\n")
    for func in self.original_functions:
      func.WriteGLES2ImplementationUnitTest(file)
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteServiceUtilsHeader(self, filename):
    """Writes the gles2 auto generated utility header."""
    file = CHeaderWriter(filename)
    for name in sorted(_NAMED_TYPE_INFO.keys()):
      named_type = NamedType(_NAMED_TYPE_INFO[name])
      if named_type.IsConstant():
        continue
      file.Write("ValueValidator<%s> %s;\n" %
                 (named_type.GetType(), ToUnderscore(name)))
    file.Write("\n")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteServiceUtilsImplementation(self, filename):
    """Writes the gles2 auto generated utility implementation."""
    file = CHeaderWriter(filename)
    names = sorted(_NAMED_TYPE_INFO.keys())
    for name in names:
      named_type = NamedType(_NAMED_TYPE_INFO[name])
      if named_type.IsConstant():
        continue
      if named_type.GetValidValues():
        file.Write("static const %s valid_%s_table[] = {\n" %
                   (named_type.GetType(), ToUnderscore(name)))
        for value in named_type.GetValidValues():
          file.Write("  %s,\n" % value)
        file.Write("};\n")
        file.Write("\n")
      if named_type.GetValidValuesES3():
        file.Write("static const %s valid_%s_table_es3[] = {\n" %
                   (named_type.GetType(), ToUnderscore(name)))
        for value in named_type.GetValidValuesES3():
          file.Write("  %s,\n" % value)
        file.Write("};\n")
        file.Write("\n")
      if named_type.GetDeprecatedValuesES3():
        file.Write("static const %s deprecated_%s_table_es3[] = {\n" %
                   (named_type.GetType(), ToUnderscore(name)))
        for value in named_type.GetDeprecatedValuesES3():
          file.Write("  %s,\n" % value)
        file.Write("};\n")
        file.Write("\n")
    file.Write("Validators::Validators()")
    pre = '    : '
    for count, name in enumerate(names):
      named_type = NamedType(_NAMED_TYPE_INFO[name])
      if named_type.IsConstant():
        continue
      if named_type.GetValidValues():
        code = """%(pre)s%(name)s(
          valid_%(name)s_table, arraysize(valid_%(name)s_table))"""
      else:
        code = "%(pre)s%(name)s()"
      file.Write(code % {
        'name': ToUnderscore(name),
        'pre': pre,
      })
      pre = ',\n    '
    file.Write(" {\n");
    file.Write("}\n\n");

    file.Write("void Validators::UpdateValuesES3() {\n")
    for name in names:
      named_type = NamedType(_NAMED_TYPE_INFO[name])
      if named_type.GetDeprecatedValuesES3():
        code = """  %(name)s.RemoveValues(
      deprecated_%(name)s_table_es3, arraysize(deprecated_%(name)s_table_es3));
"""
        file.Write(code % {
          'name': ToUnderscore(name),
        })
      if named_type.GetValidValuesES3():
        code = """  %(name)s.AddValues(
      valid_%(name)s_table_es3, arraysize(valid_%(name)s_table_es3));
"""
        file.Write(code % {
          'name': ToUnderscore(name),
        })
    file.Write("}\n\n");
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteCommonUtilsHeader(self, filename):
    """Writes the gles2 common utility header."""
    file = CHeaderWriter(filename)
    type_infos = sorted(_NAMED_TYPE_INFO.keys())
    for type_info in type_infos:
      if _NAMED_TYPE_INFO[type_info]['type'] == 'GLenum':
        file.Write("static std::string GetString%s(uint32_t value);\n" %
                   type_info)
    file.Write("\n")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteCommonUtilsImpl(self, filename):
    """Writes the gles2 common utility header."""
    enum_re = re.compile(r'\#define\s+(GL_[a-zA-Z0-9_]+)\s+([0-9A-Fa-fx]+)')
    dict = {}
    for fname in ['third_party/khronos/GLES2/gl2.h',
                  'third_party/khronos/GLES2/gl2ext.h',
                  'third_party/khronos/GLES3/gl3.h',
                  'gpu/GLES2/gl2chromium.h',
                  'gpu/GLES2/gl2extchromium.h']:
      lines = open(fname).readlines()
      for line in lines:
        m = enum_re.match(line)
        if m:
          name = m.group(1)
          value = m.group(2)
          if len(value) <= 10:
            if not value in dict:
              dict[value] = name
            # check our own _CHROMIUM macro conflicts with khronos GL headers.
            elif dict[value] != name and (name.endswith('_CHROMIUM') or
                dict[value].endswith('_CHROMIUM')):
              self.Error("code collision: %s and %s have the same code %s" %
                         (dict[value], name, value))

    file = CHeaderWriter(filename)
    file.Write("static const GLES2Util::EnumToString "
               "enum_to_string_table[] = {\n")
    for value in dict:
      file.Write('  { %s, "%s", },\n' % (value, dict[value]))
    file.Write("""};

const GLES2Util::EnumToString* const GLES2Util::enum_to_string_table_ =
    enum_to_string_table;
const size_t GLES2Util::enum_to_string_table_len_ =
    sizeof(enum_to_string_table) / sizeof(enum_to_string_table[0]);

""")

    enums = sorted(_NAMED_TYPE_INFO.keys())
    for enum in enums:
      if _NAMED_TYPE_INFO[enum]['type'] == 'GLenum':
        file.Write("std::string GLES2Util::GetString%s(uint32_t value) {\n" %
                   enum)
        valid_list = _NAMED_TYPE_INFO[enum]['valid']
        if 'valid_es3' in _NAMED_TYPE_INFO[enum]:
          valid_list = valid_list + _NAMED_TYPE_INFO[enum]['valid_es3']
        assert len(valid_list) == len(set(valid_list))
        if len(valid_list) > 0:
          file.Write("  static const EnumToString string_table[] = {\n")
          for value in valid_list:
            file.Write('    { %s, "%s" },\n' % (value, value))
          file.Write("""  };
  return GLES2Util::GetQualifiedEnumString(
      string_table, arraysize(string_table), value);
}

""")
        else:
          file.Write("""  return GLES2Util::GetQualifiedEnumString(
      NULL, 0, value);
}

""")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WritePepperGLES2Interface(self, filename, dev):
    """Writes the Pepper OpenGLES interface definition."""
    file = CWriter(filename)
    file.Write(_LICENSE)
    file.Write(_DO_NOT_EDIT_WARNING)

    file.Write("label Chrome {\n")
    file.Write("  M39 = 1.0\n")
    file.Write("};\n\n")

    if not dev:
      # Declare GL types.
      file.Write("[version=1.0]\n")
      file.Write("describe {\n")
      for gltype in ['GLbitfield', 'GLboolean', 'GLbyte', 'GLclampf',
                     'GLclampx', 'GLenum', 'GLfixed', 'GLfloat', 'GLint',
                     'GLintptr', 'GLshort', 'GLsizei', 'GLsizeiptr',
                     'GLubyte', 'GLuint', 'GLushort']:
        file.Write("  %s;\n" % gltype)
        file.Write("  %s_ptr_t;\n" % gltype)
      file.Write("};\n\n")

    # C level typedefs.
    file.Write("#inline c\n")
    file.Write("#include \"ppapi/c/pp_resource.h\"\n")
    if dev:
      file.Write("#include \"ppapi/c/ppb_opengles2.h\"\n\n")
    else:
      file.Write("\n#ifndef __gl2_h_\n")
      for (k, v) in _GL_TYPES.iteritems():
        file.Write("typedef %s %s;\n" % (v, k))
      file.Write("#ifdef _WIN64\n")
      for (k, v) in _GL_TYPES_64.iteritems():
        file.Write("typedef %s %s;\n" % (v, k))
      file.Write("#else\n")
      for (k, v) in _GL_TYPES_32.iteritems():
        file.Write("typedef %s %s;\n" % (v, k))
      file.Write("#endif  // _WIN64\n")
      file.Write("#endif  // __gl2_h_\n\n")
    file.Write("#endinl\n")

    for interface in self.pepper_interfaces:
      if interface.dev != dev:
        continue
      # Historically, we provide OpenGLES2 interfaces with struct
      # namespace. Not to break code which uses the interface as
      # "struct OpenGLES2", we put it in struct namespace.
      file.Write('\n[macro="%s", force_struct_namespace]\n' %
                 interface.GetInterfaceName())
      file.Write("interface %s {\n" % interface.GetStructName())
      for func in self.original_functions:
        if not func.InPepperInterface(interface):
          continue

        ret_type = func.MapCTypeToPepperIdlType(func.return_type,
                                                is_for_return_type=True)
        func_prefix = "  %s %s(" % (ret_type, func.GetPepperName())
        file.Write(func_prefix)
        file.Write("[in] PP_Resource context")
        for arg in func.MakeTypedPepperIdlArgStrings():
          file.Write(",\n" + " " * len(func_prefix) + arg)
        file.Write(");\n")
      file.Write("};\n\n")


    file.Close()

  def WritePepperGLES2Implementation(self, filename):
    """Writes the Pepper OpenGLES interface implementation."""

    file = CWriter(filename)
    file.Write(_LICENSE)
    file.Write(_DO_NOT_EDIT_WARNING)

    file.Write("#include \"ppapi/shared_impl/ppb_opengles2_shared.h\"\n\n")
    file.Write("#include \"base/logging.h\"\n")
    file.Write("#include \"gpu/command_buffer/client/gles2_implementation.h\"\n")
    file.Write("#include \"ppapi/shared_impl/ppb_graphics_3d_shared.h\"\n")
    file.Write("#include \"ppapi/thunk/enter.h\"\n\n")

    file.Write("namespace ppapi {\n\n")
    file.Write("namespace {\n\n")

    file.Write("typedef thunk::EnterResource<thunk::PPB_Graphics3D_API>"
               " Enter3D;\n\n")

    file.Write("gpu::gles2::GLES2Implementation* ToGles2Impl(Enter3D*"
               " enter) {\n")
    file.Write("  DCHECK(enter);\n")
    file.Write("  DCHECK(enter->succeeded());\n")
    file.Write("  return static_cast<PPB_Graphics3D_Shared*>(enter->object())->"
               "gles2_impl();\n");
    file.Write("}\n\n");

    for func in self.original_functions:
      if not func.InAnyPepperExtension():
        continue

      original_arg = func.MakeTypedPepperArgString("")
      context_arg = "PP_Resource context_id"
      if len(original_arg):
        arg = context_arg + ", " + original_arg
      else:
        arg = context_arg
      file.Write("%s %s(%s) {\n" %
                 (func.return_type, func.GetPepperName(), arg))
      file.Write("  Enter3D enter(context_id, true);\n")
      file.Write("  if (enter.succeeded()) {\n")

      return_str = "" if func.return_type == "void" else "return "
      file.Write("    %sToGles2Impl(&enter)->%s(%s);\n" %
                 (return_str, func.original_name,
                  func.MakeOriginalArgString("")))
      file.Write("  }")
      if func.return_type == "void":
        file.Write("\n")
      else:
        file.Write(" else {\n")
        file.Write("    return %s;\n" % func.GetErrorReturnString())
        file.Write("  }\n")
      file.Write("}\n\n")

    file.Write("}  // namespace\n")

    for interface in self.pepper_interfaces:
      file.Write("const %s* PPB_OpenGLES2_Shared::Get%sInterface() {\n" %
                 (interface.GetStructName(), interface.GetName()))
      file.Write("  static const struct %s "
                 "ppb_opengles2 = {\n" % interface.GetStructName())
      file.Write("    &")
      file.Write(",\n    &".join(
        f.GetPepperName() for f in self.original_functions
          if f.InPepperInterface(interface)))
      file.Write("\n")

      file.Write("  };\n")
      file.Write("  return &ppb_opengles2;\n")
      file.Write("}\n")

    file.Write("}  // namespace ppapi\n")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteGLES2ToPPAPIBridge(self, filename):
    """Connects GLES2 helper library to PPB_OpenGLES2 interface"""

    file = CWriter(filename)
    file.Write(_LICENSE)
    file.Write(_DO_NOT_EDIT_WARNING)

    file.Write("#ifndef GL_GLEXT_PROTOTYPES\n")
    file.Write("#define GL_GLEXT_PROTOTYPES\n")
    file.Write("#endif\n")
    file.Write("#include <GLES2/gl2.h>\n")
    file.Write("#include <GLES2/gl2ext.h>\n")
    file.Write("#include \"ppapi/lib/gl/gles2/gl2ext_ppapi.h\"\n\n")

    for func in self.original_functions:
      if not func.InAnyPepperExtension():
        continue

      interface = self.interface_info[func.GetInfo('pepper_interface') or '']

      file.Write("%s GL_APIENTRY gl%s(%s) {\n" %
                 (func.return_type, func.GetPepperName(),
                  func.MakeTypedPepperArgString("")))
      return_str = "" if func.return_type == "void" else "return "
      interface_str = "glGet%sInterfacePPAPI()" % interface.GetName()
      original_arg = func.MakeOriginalArgString("")
      context_arg = "glGetCurrentContextPPAPI()"
      if len(original_arg):
        arg = context_arg + ", " + original_arg
      else:
        arg = context_arg
      if interface.GetName():
        file.Write("  const struct %s* ext = %s;\n" %
                   (interface.GetStructName(), interface_str))
        file.Write("  if (ext)\n")
        file.Write("    %sext->%s(%s);\n" %
                   (return_str, func.GetPepperName(), arg))
        if return_str:
          file.Write("  %s0;\n" % return_str)
      else:
        file.Write("  %s%s->%s(%s);\n" %
                   (return_str, interface_str, func.GetPepperName(), arg))
      file.Write("}\n\n")
    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteMojoGLCallVisitor(self, filename):
    """Provides the GL implementation for mojo"""
    file = CWriter(filename)
    file.Write(_LICENSE)
    file.Write(_DO_NOT_EDIT_WARNING)

    for func in self.original_functions:
      if not func.IsCoreGLFunction():
        continue
      file.Write("VISIT_GL_CALL(%s, %s, (%s), (%s))\n" %
                             (func.name, func.return_type,
                              func.MakeTypedOriginalArgString(""),
                              func.MakeOriginalArgString("")))

    file.Close()
    self.generated_cpp_filenames.append(file.filename)

  def WriteMojoGLCallVisitorForExtension(self, filename, extension):
    """Provides the GL implementation for mojo for a particular extension"""
    file = CWriter(filename)
    file.Write(_LICENSE)
    file.Write(_DO_NOT_EDIT_WARNING)

    for func in self.original_functions:
      if func.GetInfo("extension") != extension:
        continue
      file.Write("VISIT_GL_CALL(%s, %s, (%s), (%s))\n" %
                             (func.name, func.return_type,
                              func.MakeTypedOriginalArgString(""),
                              func.MakeOriginalArgString("")))

    file.Close()
    self.generated_cpp_filenames.append(file.filename)

def Format(generated_files):
  formatter = "clang-format"
  if platform.system() == "Windows":
    formatter += ".bat"
  for filename in generated_files:
    call([formatter, "-i", "-style=chromium", filename])

def main(argv):
  """This is the main function."""
  parser = OptionParser()
  parser.add_option(
      "--output-dir",
      help="base directory for resulting files, under chrome/src. default is "
      "empty. Use this if you want the result stored under gen.")
  parser.add_option(
      "-v", "--verbose", action="store_true",
      help="prints more output.")

  (options, args) = parser.parse_args(args=argv)

  # Add in states and capabilites to GLState
  gl_state_valid = _NAMED_TYPE_INFO['GLState']['valid']
  for state_name in sorted(_STATES.keys()):
    state = _STATES[state_name]
    if 'extension_flag' in state:
      continue
    if 'enum' in state:
      if not state['enum'] in gl_state_valid:
        gl_state_valid.append(state['enum'])
    else:
      for item in state['states']:
        if 'extension_flag' in item:
          continue
        if not item['enum'] in gl_state_valid:
          gl_state_valid.append(item['enum'])
  for capability in _CAPABILITY_FLAGS:
    valid_value = "GL_%s" % capability['name'].upper()
    if not valid_value in gl_state_valid:
      gl_state_valid.append(valid_value)

  # This script lives under gpu/command_buffer, cd to base directory.
  os.chdir(os.path.dirname(__file__) + "/../..")
  base_dir = os.getcwd()
  gen = GLGenerator(options.verbose)
  gen.ParseGLH("gpu/command_buffer/cmd_buffer_functions.txt")

  # Support generating files under gen/
  if options.output_dir != None:
    os.chdir(options.output_dir)

  gen.WritePepperGLES2Interface("ppapi/api/ppb_opengles2.idl", False)
  gen.WritePepperGLES2Interface("ppapi/api/dev/ppb_opengles2ext_dev.idl", True)
  gen.WriteGLES2ToPPAPIBridge("ppapi/lib/gl/gles2/gles2.c")
  gen.WritePepperGLES2Implementation(
      "ppapi/shared_impl/ppb_opengles2_shared.cc")
  os.chdir(base_dir)
  gen.WriteCommandIds("gpu/command_buffer/common/gles2_cmd_ids_autogen.h")
  gen.WriteFormat("gpu/command_buffer/common/gles2_cmd_format_autogen.h")
  gen.WriteFormatTest(
    "gpu/command_buffer/common/gles2_cmd_format_test_autogen.h")
  gen.WriteGLES2InterfaceHeader(
    "gpu/command_buffer/client/gles2_interface_autogen.h")
  gen.WriteMojoGLES2ImplHeader(
    "mojo/gpu/mojo_gles2_impl_autogen.h")
  gen.WriteMojoGLES2Impl(
    "mojo/gpu/mojo_gles2_impl_autogen.cc")
  gen.WriteGLES2InterfaceStub(
    "gpu/command_buffer/client/gles2_interface_stub_autogen.h")
  gen.WriteGLES2InterfaceStubImpl(
      "gpu/command_buffer/client/gles2_interface_stub_impl_autogen.h")
  gen.WriteGLES2ImplementationHeader(
    "gpu/command_buffer/client/gles2_implementation_autogen.h")
  gen.WriteGLES2Implementation(
    "gpu/command_buffer/client/gles2_implementation_impl_autogen.h")
  gen.WriteGLES2ImplementationUnitTests(
      "gpu/command_buffer/client/gles2_implementation_unittest_autogen.h")
  gen.WriteGLES2TraceImplementationHeader(
      "gpu/command_buffer/client/gles2_trace_implementation_autogen.h")
  gen.WriteGLES2TraceImplementation(
      "gpu/command_buffer/client/gles2_trace_implementation_impl_autogen.h")
  gen.WriteGLES2CLibImplementation(
    "gpu/command_buffer/client/gles2_c_lib_autogen.h")
  gen.WriteCmdHelperHeader(
    "gpu/command_buffer/client/gles2_cmd_helper_autogen.h")
  gen.WriteServiceImplementation(
    "gpu/command_buffer/service/gles2_cmd_decoder_autogen.h")
  gen.WriteServiceContextStateHeader(
    "gpu/command_buffer/service/context_state_autogen.h")
  gen.WriteServiceContextStateImpl(
    "gpu/command_buffer/service/context_state_impl_autogen.h")
  gen.WriteClientContextStateHeader(
    "gpu/command_buffer/client/client_context_state_autogen.h")
  gen.WriteClientContextStateImpl(
      "gpu/command_buffer/client/client_context_state_impl_autogen.h")
  gen.WriteServiceUnitTests(
    "gpu/command_buffer/service/gles2_cmd_decoder_unittest_%d_autogen.h")
  gen.WriteServiceUnitTestsForExtensions(
    "gpu/command_buffer/service/"
    "gles2_cmd_decoder_unittest_extensions_autogen.h")
  gen.WriteServiceUtilsHeader(
    "gpu/command_buffer/service/gles2_cmd_validation_autogen.h")
  gen.WriteServiceUtilsImplementation(
    "gpu/command_buffer/service/"
    "gles2_cmd_validation_implementation_autogen.h")
  gen.WriteCommonUtilsHeader(
    "gpu/command_buffer/common/gles2_cmd_utils_autogen.h")
  gen.WriteCommonUtilsImpl(
    "gpu/command_buffer/common/gles2_cmd_utils_implementation_autogen.h")
  gen.WriteGLES2Header("gpu/GLES2/gl2chromium_autogen.h")
  mojo_gles2_prefix = ("third_party/mojo/src/mojo/public/c/gles2/"
                       "gles2_call_visitor")
  gen.WriteMojoGLCallVisitor(mojo_gles2_prefix + "_autogen.h")
  gen.WriteMojoGLCallVisitorForExtension(
      mojo_gles2_prefix + "_chromium_texture_mailbox_autogen.h",
      "CHROMIUM_texture_mailbox")
  gen.WriteMojoGLCallVisitorForExtension(
      mojo_gles2_prefix + "_chromium_sync_point_autogen.h",
      "CHROMIUM_sync_point")
  gen.WriteMojoGLCallVisitorForExtension(
      mojo_gles2_prefix + "_chromium_sub_image_autogen.h",
      "CHROMIUM_sub_image")
  gen.WriteMojoGLCallVisitorForExtension(
      mojo_gles2_prefix + "_chromium_miscellaneous_autogen.h",
      "CHROMIUM_miscellaneous")
  gen.WriteMojoGLCallVisitorForExtension(
      mojo_gles2_prefix + "_occlusion_query_ext_autogen.h",
      "occlusion_query_EXT")

  Format(gen.generated_cpp_filenames)

  if gen.errors > 0:
    print "%d errors" % gen.errors
    return 1
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
