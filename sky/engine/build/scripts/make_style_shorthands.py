#!/usr/bin/env python
# Copyright (C) 2013 Intel Corporation. All rights reserved.
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

from collections import defaultdict
import sys

import css_properties
import in_generator
from name_utilities import lower_first
import template_expander


class StylePropertyShorthandWriter(css_properties.CSSProperties):
    class_name = 'StylePropertyShorthand'

    def __init__(self, in_file_path):
        super(StylePropertyShorthandWriter, self).__init__(in_file_path)
        self._outputs = {
            ('StylePropertyShorthand.cpp'): self.generate_style_property_shorthand_cpp,
            ('StylePropertyShorthand.h'): self.generate_style_property_shorthand_h}

        self._longhand_dictionary = defaultdict(list)

        self._properties = {property_id: property for property_id, property in self._properties.items() if property['longhands']}

        for property in self._properties.values():
            property['longhand_property_ids'] = map(css_properties.css_name_to_enum, property['longhands'].split(';'))
            for longhand in property['longhand_property_ids']:
                self._longhand_dictionary[longhand].append(property)

    @template_expander.use_jinja('StylePropertyShorthand.cpp.tmpl')
    def generate_style_property_shorthand_cpp(self):
        return {
            'properties': self._properties,
            'longhands_dictionary': self._longhand_dictionary,
        }

    @template_expander.use_jinja('StylePropertyShorthand.h.tmpl')
    def generate_style_property_shorthand_h(self):
        return {
            'properties': self._properties,
        }

if __name__ == '__main__':
    in_generator.Maker(StylePropertyShorthandWriter).main(sys.argv)
