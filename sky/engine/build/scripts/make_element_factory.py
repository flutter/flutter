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
from collections import defaultdict

import in_generator
import template_expander
import name_utilities

from make_qualified_names import MakeQualifiedNamesWriter


class MakeElementFactoryWriter(MakeQualifiedNamesWriter):
    defaults = dict(MakeQualifiedNamesWriter.default_parameters, **{
        'JSInterfaceName': None,
        'Conditional': None,
        'constructorNeedsCreatedByParser': None,
        'interfaceName': None,
        'noConstructor': None,
        'noTypeHelpers': None,
        'runtimeEnabled': None,
    })
    default_parameters = dict(MakeQualifiedNamesWriter.default_parameters, **{
        'fallbackInterfaceName': '',
        'fallbackJSInterfaceName': '',
    })
    filters = MakeQualifiedNamesWriter.filters

    def __init__(self, in_file_paths):
        super(MakeElementFactoryWriter, self).__init__(in_file_paths)

        # FIXME: When we start using these element factories, we'll want to
        # remove the "new" prefix and also have our base class generate
        # *Names.h and *Names.cpp.
        self._outputs.update({
            (self.namespace + 'ElementFactory.h'): self.generate_factory_header,
            (self.namespace + 'ElementFactory.cpp'): self.generate_factory_implementation,
            ('V8' + self.namespace + 'ElementWrapperFactory.h'): self.generate_wrapper_factory_header,
            ('V8' + self.namespace + 'ElementWrapperFactory.cpp'): self.generate_wrapper_factory_implementation,
        })

        fallback_interface = self.tags_in_file.parameters['fallbackInterfaceName'].strip('"')
        fallback_js_interface = self.tags_in_file.parameters['fallbackJSInterfaceName'].strip('"') or fallback_interface

        interface_counts = defaultdict(int)
        tags = self._template_context['tags']
        for tag in tags:
            tag['has_js_interface'] = self._has_js_interface(tag)
            tag['js_interface'] = self._js_interface(tag)
            tag['interface'] = self._interface(tag)
            interface_counts[tag['interface']] += 1

        for tag in tags:
            tag['multipleTagNames'] = (interface_counts[tag['interface']] > 1 or tag['interface'] == fallback_interface)

        self._template_context.update({
            'fallback_interface': fallback_interface,
            'fallback_js_interface': fallback_js_interface,
        })

    @template_expander.use_jinja('ElementFactory.h.tmpl', filters=filters)
    def generate_factory_header(self):
        return self._template_context

    @template_expander.use_jinja('ElementFactory.cpp.tmpl', filters=filters)
    def generate_factory_implementation(self):
        return self._template_context

    @template_expander.use_jinja('ElementWrapperFactory.h.tmpl', filters=filters)
    def generate_wrapper_factory_header(self):
        return self._template_context

    @template_expander.use_jinja('ElementWrapperFactory.cpp.tmpl', filters=filters)
    def generate_wrapper_factory_implementation(self):
        return self._template_context

    def _interface(self, tag):
        if tag['interfaceName']:
            return tag['interfaceName']
        name = name_utilities.upper_first(tag['name'])
        # FIXME: We shouldn't hard-code HTML here.
        if name == 'HTML':
            name = 'Html'
        dash = name.find('-')
        while dash != -1:
            name = name[:dash] + name[dash + 1].upper() + name[dash + 2:]
            dash = name.find('-')
        return '%s%sElement' % (self.namespace, name)

    def _js_interface(self, tag):
        if tag['JSInterfaceName']:
            return tag['JSInterfaceName']
        return self._interface(tag)

    def _has_js_interface(self, tag):
        return not tag['noConstructor'] and self._js_interface(tag) != ('%sElement' % self.namespace)


if __name__ == "__main__":
    in_generator.Maker(MakeElementFactoryWriter).main(sys.argv)
