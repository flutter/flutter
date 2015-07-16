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

"""Validate extended attributes.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler#TOC-Extended-attribute-validation
"""


import os.path
import re

module_path = os.path.dirname(__file__)
source_path = os.path.join(module_path, os.pardir, os.pardir)
EXTENDED_ATTRIBUTES_RELATIVE_PATH = os.path.join('bindings',
                                                 'IDLExtendedAttributes.txt')
EXTENDED_ATTRIBUTES_FILENAME = os.path.join(source_path,
                                            EXTENDED_ATTRIBUTES_RELATIVE_PATH)

class IDLInvalidExtendedAttributeError(Exception):
    pass


class IDLExtendedAttributeValidator(object):
    def __init__(self):
        self.valid_extended_attributes = read_extended_attributes_file()

    def validate_extended_attributes(self, definitions):
        # FIXME: this should be done when parsing the file, rather than after.
        for interface in definitions.interfaces.itervalues():
            self.validate_extended_attributes_node(interface)
            for attribute in interface.attributes:
                self.validate_extended_attributes_node(attribute)
            for operation in interface.operations:
                self.validate_extended_attributes_node(operation)
                for argument in operation.arguments:
                    self.validate_extended_attributes_node(argument)

    def validate_extended_attributes_node(self, node):
        for name, values_string in node.extended_attributes.iteritems():
            self.validate_name_values_string(name, values_string)

    def validate_name_values_string(self, name, values_string):
        if name not in self.valid_extended_attributes:
            raise IDLInvalidExtendedAttributeError(
                'Unknown extended attribute [%s]' % name)
        valid_values = self.valid_extended_attributes[name]
        if values_string is None and None not in valid_values:
            raise IDLInvalidExtendedAttributeError(
                'Missing required argument for extended attribute [%s]' % name)
        if '*' in valid_values:  # wildcard, any (non-empty) value ok
            return
        if values_string is None:
            values = set([None])
        elif isinstance(values_string, list):
            values = set(values_string)
        else:
            values = set([values_string])
        invalid_values = values - valid_values
        if invalid_values:
            invalid_value = invalid_values.pop()
            raise IDLInvalidExtendedAttributeError(
                'Invalid value "%s" found in extended attribute [%s=%s]' %
                (invalid_value, name, values_string))


def read_extended_attributes_file():
    def extended_attribute_name_values():
        with open(EXTENDED_ATTRIBUTES_FILENAME) as extended_attributes_file:
            for line in extended_attributes_file:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                name, _, values_string = map(str.strip, line.partition('='))
                value_list = [value.strip() for value in values_string.split('|')]
                yield name, value_list

    valid_extended_attributes = {}
    for name, value_list in extended_attribute_name_values():
        if not value_list:
            valid_extended_attributes[name] = set([None])
            continue
        valid_extended_attributes[name] = set([value if value else None
                                               for value in value_list])
    return valid_extended_attributes
