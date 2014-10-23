# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This file is meant to be included into a target to provide an action
# to compute overall information about interfaces defined in a component.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'interfaces_info_component',
#   'dependencies': [
#       'interfaces_info_individual_base_component',
#       'interfaces_info_individual_component',
#   ],
#   'variables': {
#     'input_files': [
#       '<(bindings_base_component_output_dir)/InterfacesInfoBaseComponentIndividual.pickle',
#       '<(bindings_component_output_dir)/InterfacesInfoComponentIndividual.pickle',
#     ],
#     'output_file':
#       '<(bindings_component_output_dir)/InterfacesInfoComponent.pickle',
#   },
#   'includes': ['path/to/this/gypi/file'],
# },
#
# Required variables:
#  input_files - Pickle files containing info about individual interfaces, both
#    current component and any base components.
#  output_file - Pickle file containing output (overall info).
#
# Design document: http://www.chromium.org/developers/design-documents/idl-build

{
  'type': 'none',
  'actions': [{
    'action_name': 'compute_<(_target_name)',
    'message': 'Computing overall global information about IDL files for <(_target_name)',

    'inputs': [
      '<(bindings_scripts_dir)/compute_interfaces_info_overall.py',
      '<@(input_files)',
    ],
    'outputs': [
      '<(output_file)',
    ],
    'action': [
      'python',
      '<(bindings_scripts_dir)/compute_interfaces_info_overall.py',
      '--write-file-only-if-changed',
      '<(write_file_only_if_changed)',
      '--',
      '<@(input_files)',
      '<(output_file)',
    ],
  }],
}
