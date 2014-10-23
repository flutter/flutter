#!/usr/bin/env python

# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import media_feature_symbol
import in_generator
import template_expander
import name_utilities
import sys


class MakeMediaFeaturesWriter(in_generator.Writer):
    defaults = {
        'Conditional': None,  # FIXME: Add support for Conditional.
        'RuntimeEnabled': None,
        'ImplementedAs': None,
    }
    filters = {
        'symbol': media_feature_symbol.getMediaFeatureSymbolWithSuffix(''),
        'to_macro_style': name_utilities.to_macro_style,
    }
    default_parameters = {
        'namespace': '',
        'export': '',
    }

    def __init__(self, in_file_path):
        super(MakeMediaFeaturesWriter, self).__init__(in_file_path)

        self._outputs = {
            ('MediaFeatures.h'): self.generate_header,
        }
        self._template_context = {
            'namespace': '',
            'export': '',
            'entries': self.in_file.name_dictionaries,
        }

    @template_expander.use_jinja('MediaFeatures.h.tmpl', filters=filters)
    def generate_header(self):
        return self._template_context

if __name__ == '__main__':
    in_generator.Maker(MakeMediaFeaturesWriter).main(sys.argv)
