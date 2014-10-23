#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import in_generator
from name_utilities import lower_first


class CSSProperties(in_generator.Writer):
    defaults = {
        'alias_for': None,
        'runtime_flag': None,
        'longhands': '',
        'animatable': False,
        'inherited': False,
        'font': False,
        'svg': False,
        'name_for_methods': None,
        'use_handlers_for': None,
        'getter': None,
        'setter': None,
        'initial': None,
        'type_name': None,
        'converter': None,
        'custom_all': False,
        'custom_initial': False,
        'custom_inherit': False,
        'custom_value': False,
        'builder_skip': False,
        'direction_aware': False,
    }

    valid_values = {
        'animatable': (True, False),
        'inherited': (True, False),
        'font': (True, False),
        'svg': (True, False),
        'custom_all': (True, False),
        'custom_initial': (True, False),
        'custom_inherit': (True, False),
        'custom_value': (True, False),
        'builder_skip': (True, False),
        'direction_aware': (True, False),
    }

    def __init__(self, file_paths):
        in_generator.Writer.__init__(self, file_paths)

        properties = self.in_file.name_dictionaries

        self._aliases = {property['name']: property['alias_for'] for property in properties if property['alias_for']}
        properties = [property for property in properties if not property['alias_for']]

        assert len(properties) <= 1024, 'There are more than 1024 CSS Properties, you need to update CSSProperty.h/StylePropertyMetadata m_propertyID accordingly.'
        # We currently assign 0 to CSSPropertyInvalid
        self._first_enum_value = 1
        for offset, property in enumerate(properties):
            property['property_id'] = css_name_to_enum(property['name'])
            property['upper_camel_name'] = camelcase_css_name(property['name'])
            property['lower_camel_name'] = lower_first(property['upper_camel_name'])
            property['enum_value'] = self._first_enum_value + offset
            property['is_internal'] = property['name'].startswith('-internal-')

        self._properties_list = properties
        self._properties = {property['property_id']: property for property in properties}


def camelcase_css_name(css_name):
    """Convert hyphen-separated-name to UpperCamelCase.

    E.g., '-foo-bar' becomes 'FooBar'.
    """
    return ''.join(word.capitalize() for word in css_name.split('-'))


def css_name_to_enum(css_name):
    return 'CSSProperty' + camelcase_css_name(css_name)
