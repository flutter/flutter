# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility functions (file reading, simple IDL parsing by regexes) for IDL build.

Design doc: http://www.chromium.org/developers/design-documents/idl-build
"""

import os
import cPickle as pickle
import re
import string
import subprocess


class IdlBadFilenameError(Exception):
    """Raised if an IDL filename disagrees with the interface name in the file."""
    pass


def idl_filename_to_interface_name(idl_filename):
    # interface name is the root of the basename: InterfaceName.idl
    return os.path.splitext(os.path.basename(idl_filename))[0]


################################################################################
# Basic file reading/writing
################################################################################

def get_file_contents(filename):
    with open(filename) as f:
        return f.read()


def read_file_to_list(filename):
    """Returns a list of (stripped) lines for a given filename."""
    with open(filename) as f:
        return [line.rstrip('\n') for line in f]


def resolve_cygpath(cygdrive_names):
    if not cygdrive_names:
        return []
    cmd = ['cygpath', '-f', '-', '-wa']
    process = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    idl_file_names = []
    for file_name in cygdrive_names:
        process.stdin.write('%s\n' % file_name)
        process.stdin.flush()
        idl_file_names.append(process.stdout.readline().rstrip())
    process.stdin.close()
    process.wait()
    return idl_file_names


def read_idl_files_list_from_file(filename):
    """Similar to read_file_to_list, but also resolves cygpath."""
    with open(filename) as input_file:
        file_names = sorted([os.path.realpath(line.rstrip('\n'))
                             for line in input_file])
        idl_file_names = [file_name for file_name in file_names
                          if not file_name.startswith('/cygdrive')]
        cygdrive_names = [file_name for file_name in file_names
                          if file_name.startswith('/cygdrive')]
        idl_file_names.extend(resolve_cygpath(cygdrive_names))
        return idl_file_names


def read_pickle_files(pickle_filenames):
    for pickle_filename in pickle_filenames:
        with open(pickle_filename) as pickle_file:
            yield pickle.load(pickle_file)


def write_file(new_text, destination_filename, only_if_changed):
    if only_if_changed and os.path.isfile(destination_filename):
        with open(destination_filename) as destination_file:
            if destination_file.read() == new_text:
                return
    destination_dirname = os.path.dirname(destination_filename)
    if not os.path.exists(destination_dirname):
        os.makedirs(destination_dirname)
    with open(destination_filename, 'w') as destination_file:
        destination_file.write(new_text)


def write_pickle_file(pickle_filename, data, only_if_changed):
    if only_if_changed and os.path.isfile(pickle_filename):
        with open(pickle_filename) as pickle_file:
            try:
                if pickle.load(pickle_file) == data:
                    return
            except (EOFError, pickle.UnpicklingError):
                # If trouble unpickling, overwrite
                pass
    with open(pickle_filename, 'w') as pickle_file:
        pickle.dump(data, pickle_file)


################################################################################
# IDL parsing
#
# We use regular expressions for parsing; this is incorrect (Web IDL is not a
# regular language), but simple and sufficient in practice.
# Leading and trailing context (e.g. following '{') used to avoid false matches.
################################################################################

def get_partial_interface_name_from_idl(file_contents):
    match = re.search(r'partial\s+interface\s+(\w+)\s*{', file_contents)
    return match and match.group(1)


def get_implements_from_idl(file_contents, interface_name):
    """Returns lists of implementing and implemented interfaces.

    Rule is: identifier-A implements identifier-B;
    i.e., implement*ing* implements implement*ed*;
    http://www.w3.org/TR/WebIDL/#idl-implements-statements

    Returns two lists of interfaces: identifier-As and identifier-Bs.
    An 'implements' statements can be present in the IDL file for either the
    implementing or the implemented interface, but not other files.
    """
    implements_re = (r'^\s*'
                     r'(\w+)\s+'
                     r'implements\s+'
                     r'(\w+)\s*'
                     r';')
    implements_matches = re.finditer(implements_re, file_contents, re.MULTILINE)
    implements_pairs = [match.groups() for match in implements_matches]

    foreign_implements = [pair for pair in implements_pairs
                          if interface_name not in pair]
    if foreign_implements:
        left, right = foreign_implements.pop()
        raise IdlBadFilenameError(
                'implements statement found in unrelated IDL file.\n'
                'Statement is:\n'
                '    %s implements %s;\n'
                'but filename is unrelated "%s.idl"' %
                (left, right, interface_name))

    return (
        [left for left, right in implements_pairs if right == interface_name],
        [right for left, right in implements_pairs if left == interface_name])


def is_callback_interface_from_idl(file_contents):
    match = re.search(r'callback\s+interface\s+\w+\s*{', file_contents)
    return bool(match)


def is_dictionary_from_idl(file_contents):
    match = re.search(r'dictionary\s+\w+\s*{', file_contents)
    return bool(match)


def get_parent_interface(file_contents):
    match = re.search(r'interface\s+'
                      r'\w+\s*'
                      r':\s*(\w+)\s*'
                      r'{',
                      file_contents)
    return match and match.group(1)


def get_interface_extended_attributes_from_idl(file_contents):
    # Strip comments
    # re.compile needed b/c Python 2.6 doesn't support flags in re.sub
    single_line_comment_re = re.compile(r'//.*$', flags=re.MULTILINE)
    block_comment_re = re.compile(r'/\*.*?\*/', flags=re.MULTILINE | re.DOTALL)
    file_contents = re.sub(single_line_comment_re, '', file_contents)
    file_contents = re.sub(block_comment_re, '', file_contents)

    match = re.search(r'\[(.*)\]\s*'
                      r'((callback|partial)\s+)?'
                      r'(interface|exception)\s+'
                      r'\w+\s*'
                      r'(:\s*\w+\s*)?'
                      r'{',
                      file_contents, flags=re.DOTALL)
    if not match:
        return {}

    extended_attributes_string = match.group(1)
    extended_attributes = {}
    # FIXME: this splitting is WRONG: it fails on extended attributes where lists of
    # multiple values are used, which are seperated by a comma and a space.
    parts = [extended_attribute.strip()
             for extended_attribute in re.split(',\s+', extended_attributes_string)
             # Discard empty parts, which may exist due to trailing comma
             if extended_attribute.strip()]
    for part in parts:
        name, _, value = map(string.strip, part.partition('='))
        extended_attributes[name] = value
    return extended_attributes


def get_put_forward_interfaces_from_idl(file_contents):
    put_forwards_pattern = (r'\[[^\]]*PutForwards=[^\]]*\]\s+'
                            r'readonly\s+'
                            r'attribute\s+'
                            r'(\w+)')
    return sorted(set(match.group(1)
                      for match in re.finditer(put_forwards_pattern,
                                               file_contents,
                                               flags=re.DOTALL)))
