# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This file is meant to be included into a target to provide an action
# to compute global objects in a component.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'component_global_objects',
#   'variables': {
#     'idl_files': '<(list_of_idl_files)',
#     'input_files': ['<(some_dir)/GlobalObjectBaseComponent.pickle'],
#     'output_file': '<(some_dir)/GlobalObjectsComponent.pickle',
#   },
#   'includes': ['path/to/this/gypi/file'],
# },
#
# Required variables:
#  idl_files - List of .idl files that will be searched in.
#    This should *only* contain main IDL files, excluding dependencies and
#    testing, which should not define global objects.
#  output_file - Pickle file of output.
#
# Optional variables:
#  input_files - List of input pickle files of global objects in base
#    components. In this case make sure to include a dependencies section
#    in the target to ensure this is generated.
#
# Spec: http://heycam.github.io/webidl/#Global
# Design document: http://www.chromium.org/developers/design-documents/idl-build

{
  'type': 'none',
  'actions': [{
    'action_name': 'compute_<(_target_name)',
    'message': 'Computing global objects for <(_target_name)',
    'variables': {
      'input_files%': [],
      'idl_files_list': '<|(<(_target_name)_idl_files_list.tmp <@(idl_files))',
    },
    'includes': ['scripts.gypi'],
    'inputs': [
      '<(bindings_scripts_dir)/compute_global_objects.py',
      '<(bindings_scripts_dir)/utilities.py',
      '<(idl_files_list)',
      '<@(idl_files)',
    ],
    'outputs': [
      '<(output_file)',
    ],
    'action': [
      'python',
      '<(bindings_scripts_dir)/compute_global_objects.py',
      '--idl-files-list',
      '<(idl_files_list)',
      '--write-file-only-if-changed',
      '<(write_file_only_if_changed)',
      '--',
      '<@(input_files)',
      '<(output_file)',
     ],
  }],
}
