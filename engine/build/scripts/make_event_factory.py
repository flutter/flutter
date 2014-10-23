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

import os.path
import sys
import shutil

from in_file import InFile
import name_macros
import name_utilities
import template_expander


def case_insensitive_matching(name):
    return (name == ('HTMLEvents')
            or name == 'Event'
            or name == 'Events'
            or name.startswith('UIEvent')
            or name.startswith('CustomEvent')
            or name.startswith('MouseEvent'))

class EventFactoryWriter(name_macros.Writer):
    defaults = {
        'ImplementedAs': None,
        'Conditional': None,
        'RuntimeEnabled': None,
    }
    default_parameters = {
        'namespace': '',
        'suffix': '',
    }
    filters = {
        'cpp_name': name_utilities.cpp_name,
        'enable_conditional': name_utilities.enable_conditional_if_endif,
        'lower_first': name_utilities.lower_first,
        'case_insensitive_matching': case_insensitive_matching,
        'script_name': name_utilities.script_name,
    }

    def __init__(self, in_file_path):
        super(EventFactoryWriter, self).__init__(in_file_path)
        if self.namespace == 'EventTarget':
            return
        self._outputs[(self.namespace + self.suffix + ".cpp")] = self.generate_implementation

    @template_expander.use_jinja('EventFactory.cpp.tmpl', filters=filters)
    def generate_implementation(self):
        return {
            'namespace': self.namespace,
            'suffix': self.suffix,
            'events': self.in_file.name_dictionaries,
        }


if __name__ == "__main__":
    name_macros.Maker(EventFactoryWriter).main(sys.argv)
