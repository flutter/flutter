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
import template_expander
import name_utilities

def _symbol(entry):
    if entry['Symbol'] is not None:
        return entry['Symbol']
    # FIXME: Remove this special case for the ugly x-webkit-foo attributes.
    if entry['name'].startswith('-webkit-'):
        return entry['name'].replace('-', '_')[1:]
    return name_utilities.cpp_name(entry).replace('-', '_')


class MakeNamesWriter(in_generator.Writer):
    defaults = {
        'Conditional': None,  # FIXME: Add support for Conditional.
        'ImplementedAs': None,
        'RuntimeEnabled': None,  # What should we do for runtime-enabled features?
        'Symbol': None,
    }
    default_parameters = {
        'export': '',
        'namespace': '',
        'suffix': '',
    }
    filters = {
        'cpp_name': name_utilities.cpp_name,
        'enable_conditional': name_utilities.enable_conditional_if_endif,
        'hash': hasher.hash,
        'script_name': name_utilities.script_name,
        'symbol': _symbol,
        'to_macro_style': name_utilities.to_macro_style,
    }

    def __init__(self, in_file_path):
        super(MakeNamesWriter, self).__init__(in_file_path)

        namespace = self.in_file.parameters['namespace'].strip('"')
        suffix = self.in_file.parameters['suffix'].strip('"')
        export = self.in_file.parameters['export'].strip('"')

        assert namespace, 'A namespace is required.'

        self._outputs = {
            (namespace + suffix + 'Names.h'): self.generate_header,
            (namespace + suffix + 'Names.cpp'): self.generate_implementation,
        }
        self._template_context = {
            'namespace': namespace,
            'suffix': suffix,
            'export': export,
            'entries': self.in_file.name_dictionaries,
        }

    @template_expander.use_jinja("MakeNames.h.tmpl", filters=filters)
    def generate_header(self):
        return self._template_context

    @template_expander.use_jinja("MakeNames.cpp.tmpl", filters=filters)
    def generate_implementation(self):
        return self._template_context


if __name__ == "__main__":
    in_generator.Maker(MakeNamesWriter).main(sys.argv)
