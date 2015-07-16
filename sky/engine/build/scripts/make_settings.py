#!/usr/bin/env python
# Copyright (C) 2013 Google Inc. All rights reserved.
# Copyright (C) 2013 Igalia S.L. All rights reserved.
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
import in_generator
import template_expander
import name_utilities


def to_passing_type(typename):
    if typename == 'String':
        return 'const String&'
    return typename


def to_idl_type(typename):
    if typename == 'int':
        return 'long'
    if typename == 'unsigned' or typename == 'size_t':
        return 'unsigned long'
    if typename == 'String':
        return 'DOMString'
    if typename == 'bool':
        return 'boolean'
    if typename == 'double':
        return 'double'
    return None


class MakeSettingsWriter(in_generator.Writer):
    defaults = {
        'type': 'bool',
        'initial': None,
        'invalidate': None,
    }
    default_parameters = {}
    filters = {
        'upper_first': name_utilities.upper_first,
        'to_passing_type': to_passing_type,
        'to_idl_type': to_idl_type,
    }

    def __init__(self, in_file_path):
        super(MakeSettingsWriter, self).__init__(in_file_path)

        self.in_file.name_dictionaries.sort(key=lambda entry: entry['name'])

        self._outputs = {
            ('SettingsMacros.h'): self.generate_macros,
        }
        self._template_context = {
            'settings': self.in_file.name_dictionaries,
        }

    @template_expander.use_jinja('SettingsMacros.h.tmpl', filters=filters)
    def generate_macros(self):
        return self._template_context


if __name__ == '__main__':
    in_generator.Maker(MakeSettingsWriter).main(sys.argv)
