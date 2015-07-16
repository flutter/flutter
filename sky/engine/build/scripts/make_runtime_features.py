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

import in_generator
import name_utilities
from name_utilities import lower_first
import template_expander


class RuntimeFeatureWriter(in_generator.Writer):
    class_name = 'RuntimeEnabledFeatures'
    filters = {
        'enable_conditional': name_utilities.enable_conditional_if_endif,
    }

    # FIXME: valid_values and defaults should probably roll into one object.
    valid_values = {
        'status': ['stable', 'experimental', 'test', 'deprecated'],
    }
    defaults = {
        'condition' : None,
        'depends_on' : [],
        'custom': False,
        'status': None,
    }

    _status_aliases = {
        'deprecated': 'test',
    }

    def __init__(self, in_file_path):
        super(RuntimeFeatureWriter, self).__init__(in_file_path)
        self._outputs = {(self.class_name + '.h'): self.generate_header,
                         (self.class_name + '.cpp'): self.generate_implementation,
                        }

        self._features = self.in_file.name_dictionaries
        # Make sure the resulting dictionaries have all the keys we expect.
        for feature in self._features:
            feature['first_lowered_name'] = lower_first(feature['name'])
            feature['status'] = self._status_aliases.get(feature['status'], feature['status'])
            # Most features just check their isFooEnabled bool
            # but some depend on more than one bool.
            enabled_condition = 'is%sEnabled' % feature['name']
            for dependant_name in feature['depends_on']:
                enabled_condition += ' && is%sEnabled' % dependant_name
            feature['enabled_condition'] = enabled_condition
        self._non_custom_features = filter(lambda feature: not feature['custom'], self._features)

    def _feature_sets(self):
        # Another way to think of the status levels is as "sets of features"
        # which is how we're referring to them in this generator.
        return [status for status in self.valid_values['status'] if status not in self._status_aliases]

    @template_expander.use_jinja(class_name + '.h.tmpl', filters=filters)
    def generate_header(self):
        return {
            'features': self._features,
            'feature_sets': self._feature_sets(),
        }

    @template_expander.use_jinja(class_name + '.cpp.tmpl', filters=filters)
    def generate_implementation(self):
        return {
            'features': self._features,
            'feature_sets': self._feature_sets(),
        }


if __name__ == '__main__':
    in_generator.Maker(RuntimeFeatureWriter).main(sys.argv)
