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

import os.path
import re

from in_generator import Maker
import in_generator
import license
import name_utilities


HEADER_TEMPLATE = """%(license)s

#ifndef %(namespace)s%(suffix)sHeaders_h
#define %(namespace)s%(suffix)sHeaders_h
%(base_header_for_suffix)s
%(includes)s

#endif // %(namespace)s%(suffix)sHeaders_h
"""


INTERFACES_HEADER_TEMPLATE = """%(license)s

#ifndef %(namespace)s%(suffix)sInterfaces_h
#define %(namespace)s%(suffix)sInterfaces_h
%(base_header_for_suffix)s
%(declare_conditional_macros)s

#define %(macro_style_name)s_INTERFACES_FOR_EACH(macro) \\
    \\
%(unconditional_macros)s
    \\
%(conditional_macros)s

#endif // %(namespace)s%(suffix)sInterfaces_h
"""


class Writer(in_generator.Writer):
    def __init__(self, in_file_path):
        super(Writer, self).__init__(in_file_path)
        self.namespace = self.in_file.parameters['namespace'].strip('"')
        self.suffix = self.in_file.parameters['suffix'].strip('"')
        self._entries_by_conditional = {}
        self._unconditional_entries = []
        self._validate_entries()
        self._sort_entries_by_conditional()
        self._outputs = {(self.namespace + self.suffix + "Headers.h"): self.generate_headers_header,
                         (self.namespace + self.suffix + "Interfaces.h"): self.generate_interfaces_header,
                        }

    def _validate_entries(self):
        # If there is more than one entry with the same script name, only the first one will ever
        # be hit in practice, and so we'll silently ignore any properties requested for the second
        # (like RuntimeEnabled - see crbug.com/332588).
        entries_by_script_name = dict()
        for entry in self.in_file.name_dictionaries:
            script_name = name_utilities.script_name(entry)
            if script_name in entries_by_script_name:
                self._fatal('Multiple entries with script_name=%(script_name)s: %(name1)s %(name2)s' % {
                    'script_name': script_name,
                    'name1': entry['name'],
                    'name2': entries_by_script_name[script_name]['name']})
            entries_by_script_name[script_name] = entry

    def _fatal(self, message):
        print 'FATAL ERROR: ' + message
        exit(1)

    def _sort_entries_by_conditional(self):
        unconditional_names = set()
        for entry in self.in_file.name_dictionaries:
            conditional = entry['Conditional']
            if not conditional:
                cpp_name = name_utilities.cpp_name(entry)
                if cpp_name in unconditional_names:
                    continue
                unconditional_names.add(cpp_name)
                self._unconditional_entries.append(entry)
                continue
        for entry in self.in_file.name_dictionaries:
            cpp_name = name_utilities.cpp_name(entry)
            if cpp_name in unconditional_names:
                continue
            conditional = entry['Conditional']
            if not conditional in self._entries_by_conditional:
                self._entries_by_conditional[conditional] = []
            self._entries_by_conditional[conditional].append(entry)

    def _headers_header_include_path(self, entry):
        if entry['ImplementedAs']:
            path = os.path.dirname(entry['name'])
            if len(path):
                path += '/'
            path += entry['ImplementedAs']
        else:
            path = entry['name']
        return path + '.h'

    def _headers_header_includes(self, entries):
        includes = dict()
        for entry in entries:
            cpp_name = name_utilities.cpp_name(entry)
            # Avoid duplicate includes.
            if cpp_name in includes:
                continue
            if self.suffix == 'Modules':
                subdir_name = 'modules'
            else:
                subdir_name = 'core'
            include = '#include "%(path)s"\n#include "bindings/%(subdir_name)s/v8/V8%(script_name)s.h"' % {
                'path': self._headers_header_include_path(entry),
                'script_name': name_utilities.script_name(entry),
                'subdir_name': subdir_name,
            }
            includes[cpp_name] = self.wrap_with_condition(include, entry['Conditional'])
        return includes.values()

    def generate_headers_header(self):
        base_header_for_suffix = ''
        if self.suffix:
            base_header_for_suffix = '\n#include "core/%(namespace)sHeaders.h"\n' % {'namespace': self.namespace}
        return HEADER_TEMPLATE % {
            'license': license.license_for_generated_cpp(),
            'namespace': self.namespace,
            'suffix': self.suffix,
            'base_header_for_suffix': base_header_for_suffix,
            'includes': '\n'.join(self._headers_header_includes(self.in_file.name_dictionaries)),
        }

    def _declare_one_conditional_macro(self, conditional, entries):
        macro_name = '%(macro_style_name)s_INTERFACES_FOR_EACH_%(conditional)s' % {
            'macro_style_name': name_utilities.to_macro_style(self.namespace + self.suffix),
            'conditional': conditional,
        }
        return self.wrap_with_condition("""#define %(macro_name)s(macro) \\
%(declarations)s

#else
#define %(macro_name)s(macro)""" % {
            'macro_name': macro_name,
            'declarations': '\n'.join(sorted(set([
                '    macro(%(cpp_name)s) \\' % {'cpp_name': name_utilities.cpp_name(entry)}
                for entry in entries]))),
        }, conditional)

    def _declare_conditional_macros(self):
        return '\n'.join([
            self._declare_one_conditional_macro(conditional, entries)
            for conditional, entries in self._entries_by_conditional.items()])

    def _unconditional_macro(self, entry):
        return '    macro(%(cpp_name)s) \\' % {'cpp_name': name_utilities.cpp_name(entry)}

    def _conditional_macros(self, conditional):
        return '    %(macro_style_name)s_INTERFACES_FOR_EACH_%(conditional)s(macro) \\' % {
            'macro_style_name': name_utilities.to_macro_style(self.namespace + self.suffix),
            'conditional': conditional,
        }

    def generate_interfaces_header(self):
        base_header_for_suffix = ''
        if self.suffix:
            base_header_for_suffix = '\n#include "core/%(namespace)sInterfaces.h"\n' % {'namespace': self.namespace}
        return INTERFACES_HEADER_TEMPLATE % {
            'license': license.license_for_generated_cpp(),
            'namespace': self.namespace,
            'suffix': self.suffix,
            'base_header_for_suffix': base_header_for_suffix,
            'macro_style_name': name_utilities.to_macro_style(self.namespace + self.suffix),
            'declare_conditional_macros': self._declare_conditional_macros(),
            'unconditional_macros': '\n'.join(sorted(set(map(self._unconditional_macro, self._unconditional_entries)))),
            'conditional_macros': '\n'.join(map(self._conditional_macros, self._entries_by_conditional.keys())),
        }
