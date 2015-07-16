#!/usr/bin/env python
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

import sys

import hasher
import in_generator
import name_utilities
import template_expander

from in_file import InFile


def _symbol(entry):
    # FIXME: Remove this special case for the ugly x-webkit-foo attributes.
    if entry['name'].startswith('x-webkit-'):
        return entry['name'].replace('-', '')[1:]
    return entry['name'].replace('-', '_')


class MakeQualifiedNamesWriter(in_generator.Writer):
    defaults = {
    }
    default_parameters = {
        'namespace': '',
    }
    filters = {
        'hash': hasher.hash,
        'enable_conditional': name_utilities.enable_conditional_if_endif,
        'symbol': _symbol,
        'to_macro_style': name_utilities.to_macro_style,
    }

    def __init__(self, in_file_paths):
        super(MakeQualifiedNamesWriter, self).__init__(None)
        assert len(in_file_paths) <= 2, 'MakeQualifiedNamesWriter requires at most 2 in files, got %d.' % len(in_file_paths)

        if len(in_file_paths) == 2:
            self.tags_in_file = InFile.load_from_files([in_file_paths.pop(0)], self.defaults, self.valid_values, self.default_parameters)
        else:
            self.tags_in_file = None

        self.attrs_in_file = InFile.load_from_files([in_file_paths.pop()], self.defaults, self.valid_values, self.default_parameters)

        self.namespace = self._parameter('namespace')

        self._outputs = {
            (self.namespace + "Names.h"): self.generate_header,
            (self.namespace + "Names.cpp"): self.generate_implementation,
        }
        self._template_context = {
            'namespace': self.namespace,
            'tags': self.tags_in_file.name_dictionaries if self.tags_in_file else [],
            'attrs': self.attrs_in_file.name_dictionaries,
        }

    def _parameter(self, name):
        parameter = self.attrs_in_file.parameters[name].strip('"')
        if self.tags_in_file:
            assert parameter == self.tags_in_file.parameters[name].strip('"'), 'Both in files must have the same %s.' % name
        return parameter

    @template_expander.use_jinja('MakeQualifiedNames.h.tmpl', filters=filters)
    def generate_header(self):
        return self._template_context

    @template_expander.use_jinja('MakeQualifiedNames.cpp.tmpl', filters=filters)
    def generate_implementation(self):
        return self._template_context


if __name__ == "__main__":
    in_generator.Maker(MakeQualifiedNamesWriter).main(sys.argv)
