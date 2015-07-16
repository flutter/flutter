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

import css_properties
import in_generator
from name_utilities import lower_first
import template_expander


class StyleBuilderWriter(css_properties.CSSProperties):
    filters = {
        'lower_first': lower_first,
    }

    def __init__(self, in_file_path):
        super(StyleBuilderWriter, self).__init__(in_file_path)
        self._outputs = {('StyleBuilderFunctions.h'): self.generate_style_builder_functions_h,
                         ('StyleBuilderFunctions.cpp'): self.generate_style_builder_functions_cpp,
                         ('StyleBuilder.cpp'): self.generate_style_builder,
                        }

        def set_if_none(property, key, value):
            if property[key] is None:
                property[key] = value

        for property in self._properties.values():
            upper_camel = property['upper_camel_name']
            set_if_none(property, 'name_for_methods', upper_camel.replace('Webkit', ''))
            name = property['name_for_methods']
            set_if_none(property, 'type_name', 'E' + name)
            set_if_none(property, 'getter', lower_first(name))
            set_if_none(property, 'setter', 'set' + name)
            set_if_none(property, 'initial', 'initial' + name)
            if property['custom_all']:
                property['custom_initial'] = True
                property['custom_inherit'] = True
                property['custom_value'] = True
            property['should_declare_functions'] = not property['use_handlers_for'] and not property['longhands'] \
                                                   and not property['direction_aware'] and not property['builder_skip']

        self._properties['CSSPropertyFont']['should_declare_functions'] = True

    @template_expander.use_jinja('StyleBuilderFunctions.h.tmpl',
                                 filters=filters)
    def generate_style_builder_functions_h(self):
        return {
            'properties': self._properties,
        }

    @template_expander.use_jinja('StyleBuilderFunctions.cpp.tmpl',
                                 filters=filters)
    def generate_style_builder_functions_cpp(self):
        return {
            'properties': self._properties,
        }

    @template_expander.use_jinja('StyleBuilder.cpp.tmpl', filters=filters)
    def generate_style_builder(self):
        return {
            'properties': self._properties,
        }


if __name__ == '__main__':
    in_generator.Maker(StyleBuilderWriter).main(sys.argv)
