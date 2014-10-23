#!/usr/bin/python
#
# Copyright (C) 2013 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Compute global interface information for individual IDL files.

Auxiliary module for compute_interfaces_info_overall, which consolidates
this individual information, computing info that spans multiple files
(dependencies and ancestry).

This distinction is so that individual interface info can be computed
separately for each component (avoiding duplicated reading of individual
files), then consolidated using *only* the info visible to a given component.

Design doc: http://www.chromium.org/developers/design-documents/idl-build
"""

from collections import defaultdict
import optparse
import os
import posixpath
import sys

from utilities import get_file_contents, read_file_to_list, idl_filename_to_interface_name, write_pickle_file, get_interface_extended_attributes_from_idl, is_callback_interface_from_idl, is_dictionary_from_idl, get_partial_interface_name_from_idl, get_implements_from_idl, get_parent_interface, get_put_forward_interfaces_from_idl

module_path = os.path.dirname(__file__)
source_path = os.path.normpath(os.path.join(module_path, os.pardir, os.pardir))

# Global variables (filled in and exported)
interfaces_info = {}
partial_interface_files = defaultdict(lambda: {
    'full_paths': [],
    'include_paths': [],
})


def parse_options():
    usage = 'Usage: %prog [options] [generated1.idl]...'
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('--component-dir', help='component directory')
    parser.add_option('--idl-files-list', help='file listing IDL files')
    parser.add_option('--interfaces-info-file', help='output pickle file')
    parser.add_option('--write-file-only-if-changed', type='int', help='if true, do not write an output file if it would be identical to the existing one, which avoids unnecessary rebuilds in ninja')

    options, args = parser.parse_args()
    if options.component_dir is None:
        parser.error('Must specify a component directory using --component-dir.')
    if options.interfaces_info_file is None:
        parser.error('Must specify an output file using --interfaces-info-file.')
    if options.idl_files_list is None:
        parser.error('Must specify a file listing IDL files using --idl-files-list.')
    if options.write_file_only_if_changed is None:
        parser.error('Must specify whether file is only written if changed using --write-file-only-if-changed.')
    options.write_file_only_if_changed = bool(options.write_file_only_if_changed)
    return options, args


################################################################################
# Computations
################################################################################

def relative_dir_posix(idl_filename):
    """Returns relative path to the directory of idl_file in POSIX format."""
    relative_path_local = os.path.relpath(idl_filename, source_path)
    relative_dir_local = os.path.dirname(relative_path_local)
    return relative_dir_local.replace(os.path.sep, posixpath.sep)


def include_path(idl_filename, implemented_as=None):
    """Returns relative path to header file in POSIX format; used in includes.

    POSIX format is used for consistency of output, so reference tests are
    platform-independent.
    """
    relative_dir = relative_dir_posix(idl_filename)

    # IDL file basename is used even if only a partial interface file
    idl_file_basename, _ = os.path.splitext(os.path.basename(idl_filename))
    cpp_class_name = implemented_as or idl_file_basename

    return posixpath.join(relative_dir, cpp_class_name + '.h')


def add_paths_to_partials_dict(partial_interface_name, full_path, this_include_path=None):
    paths_dict = partial_interface_files[partial_interface_name]
    paths_dict['full_paths'].append(full_path)
    if this_include_path:
        paths_dict['include_paths'].append(this_include_path)


def compute_info_individual(idl_filename, component_dir):
    full_path = os.path.realpath(idl_filename)
    idl_file_contents = get_file_contents(full_path)

    extended_attributes = get_interface_extended_attributes_from_idl(idl_file_contents)
    implemented_as = extended_attributes.get('ImplementedAs')
    relative_dir = relative_dir_posix(idl_filename)
    this_include_path = None if 'NoImplHeader' in extended_attributes else include_path(idl_filename, implemented_as)

    # Handle partial interfaces
    partial_interface_name = get_partial_interface_name_from_idl(idl_file_contents)
    if partial_interface_name:
        add_paths_to_partials_dict(partial_interface_name, full_path, this_include_path)
        return

    # If not a partial interface, the basename is the interface name
    interface_name = idl_filename_to_interface_name(idl_filename)

    # 'implements' statements can be included in either the file for the
    # implement*ing* interface (lhs of 'implements') or implement*ed* interface
    # (rhs of 'implements'). Store both for now, then merge to implement*ing*
    # interface later.
    left_interfaces, right_interfaces = get_implements_from_idl(idl_file_contents, interface_name)

    interfaces_info[interface_name] = {
        'component_dir': component_dir,
        'extended_attributes': extended_attributes,
        'full_path': full_path,
        'implemented_as': implemented_as,
        'implemented_by_interfaces': left_interfaces,  # private, merged to next
        'implements_interfaces': right_interfaces,
        'include_path': this_include_path,
        'is_callback_interface': is_callback_interface_from_idl(idl_file_contents),
        'is_dictionary': is_dictionary_from_idl(idl_file_contents),
        # FIXME: temporary private field, while removing old treatement of
        # 'implements': http://crbug.com/360435
        'is_legacy_treat_as_partial_interface': 'LegacyTreatAsPartialInterface' in extended_attributes,
        'parent': get_parent_interface(idl_file_contents),
        # Interfaces that are referenced (used as types) and that we introspect
        # during code generation (beyond interface-level data ([ImplementedAs],
        # is_callback_interface, ancestors, and inherited extended attributes):
        # deep dependencies.
        # These cause rebuilds of referrers, due to the dependency, so these
        # should be minimized; currently only targets of [PutForwards].
        'referenced_interfaces': get_put_forward_interfaces_from_idl(idl_file_contents),
        'relative_dir': relative_dir,
    }


def info_individual():
    """Returns info packaged as a dict."""
    return {
        'interfaces_info': interfaces_info,
        # Can't pickle defaultdict, convert to dict
        'partial_interface_files': dict(partial_interface_files),
    }


################################################################################

def main():
    options, args = parse_options()

    # Static IDL files are passed in a file (generated at GYP time), due to OS
    # command line length limits
    idl_files = read_file_to_list(options.idl_files_list)
    # Generated IDL files are passed at the command line, since these are in the
    # build directory, which is determined at build time, not GYP time, so these
    # cannot be included in the file listing static files
    idl_files.extend(args)

    # Compute information for individual files
    # Information is stored in global variables interfaces_info and
    # partial_interface_files.
    for idl_filename in idl_files:
        compute_info_individual(idl_filename, options.component_dir)

    write_pickle_file(options.interfaces_info_file,
                      info_individual(),
                      options.write_file_only_if_changed)


if __name__ == '__main__':
    sys.exit(main())
