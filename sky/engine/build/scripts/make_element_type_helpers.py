#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys
from collections import defaultdict

import hasher
import in_generator
import name_utilities
import template_expander

from in_file import InFile


def _symbol(tag):
    # FIXME: Remove this special case for the ugly x-webkit-foo attributes.
    if tag['name'].startswith('-webkit-'):
        return tag['name'].replace('-', '_')[1:]
    return name_utilities.cpp_name(tag).replace('-', '_')

class MakeElementTypeHelpersWriter(in_generator.Writer):
    defaults = {
        'Conditional': None,
        'ImplementedAs': None,
        'JSInterfaceName': None,
        'constructorNeedsCreatedByParser': None,
        'interfaceName': None,
        'noConstructor': None,
        'noTypeHelpers': None,
        'runtimeEnabled': None,
    }
    default_parameters = {
        'fallbackInterfaceName': '',
        'namespace': '',
        'fallbackJSInterfaceName': '',
    }
    filters = {
        'enable_conditional': name_utilities.enable_conditional_if_endif,
        'hash': hasher.hash,
        'symbol': _symbol,
    }

    def __init__(self, in_file_path):
        super(MakeElementTypeHelpersWriter, self).__init__(in_file_path)

        self.namespace = self.in_file.parameters['namespace'].strip('"')
        self.fallbackInterface = self.in_file.parameters['fallbackInterfaceName'].strip('"')

        assert self.namespace, 'A namespace is required.'

        self._outputs = {
            (self.namespace + "ElementTypeHelpers.h"): self.generate_helper_header,
        }

        self._template_context = {
            'namespace': self.namespace,
            'tags': self.in_file.name_dictionaries,
        }

        tags = self._template_context['tags']
        interface_counts = defaultdict(int)
        for tag in tags:
            tag['interface'] = self._interface(tag)
            interface_counts[tag['interface']] += 1

        for tag in tags:
            tag['multipleTagNames'] = (interface_counts[tag['interface']] > 1 or tag['interface'] == self.fallbackInterface)

    @template_expander.use_jinja("ElementTypeHelpers.h.tmpl", filters=filters)
    def generate_helper_header(self):
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

if __name__ == "__main__":
    in_generator.Maker(MakeElementTypeHelpersWriter).main(sys.argv)
