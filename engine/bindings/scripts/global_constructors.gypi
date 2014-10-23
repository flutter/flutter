# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This file is meant to be included into a target to provide an action
# to compute global objects in a component.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'core_global_constructors_idls',
#   'dependencies': [
#     'component_global_objects',
#   ],
#   'variables': {
#     'idl_files': '<(list_of_idl_files)',
#     'global_objects_file': '<(some_dir)/GlobalObjectsComponent.pickle',
#     'global_names_idl_files': [
#       'GlobalName',
#       '<(sky_core_output_dir)/GlobalScopeComponentConstructors.idl',
#       # ...
#     ],
#     'outputs': [
#       '<@(component_global_constructors_generated_idl_files)',
#       '<@(component_global_constructors_generated_header_files)',
#     ],
#   },
#   'includes': ['path/to/this/gypi/file'],
# },
#
# Required variables:
#  idl_files - List of .idl files that will be searched in.
#    This should *only* contain main IDL files, excluding dependencies and
#    testing, which should not appear on global objects.
#  global_objects - Pickle file of global objects.
#  global_names_idl_files - pairs (GlobalName, Constructors.idl)
#  outputs - List of output files.
#    Passed as a variable here, included by the template in the action.
#
# Spec: http://heycam.github.io/webidl/#Global
#       http://heycam.github.io/webidl/#Exposed
# Design document: http://www.chromium.org/developers/design-documents/idl-build

{
  'type': 'none',
  'actions': [{
    'action_name': 'generate_<(_target_name)',
    'message': 'Generating IDL files for constructors on global objects for <(_target_name)',
    'variables': {
      'idl_files_list': '<|(<(_target_name)_idl_files_list.tmp <@(idl_files))',
    },
    'includes': ['scripts.gypi'],
    'inputs': [
      '<(bindings_scripts_dir)/generate_global_constructors.py',
      '<(bindings_scripts_dir)/utilities.py',
      '<(idl_files_list)',
      '<@(idl_files)',
      '<(global_objects_file)',
    ],
    'outputs': ['<@(outputs)'],
    'action': [
      'python',
      '<(bindings_scripts_dir)/generate_global_constructors.py',
      '--idl-files-list',
      '<(idl_files_list)',
      '--global-objects-file',
      '<(global_objects_file)',
      '--write-file-only-if-changed',
      '<(write_file_only_if_changed)',
      '--',
      '<@(global_names_idl_files)',
    ],
  }],
}
