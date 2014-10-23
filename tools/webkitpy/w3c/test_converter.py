#!/usr/bin/env python

# Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above
#    copyright notice, this list of conditions and the following
#    disclaimer.
# 2. Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials
#    provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

import logging
import re

from webkitpy.common.host import Host
from webkitpy.common.webkit_finder import WebKitFinder
from HTMLParser import HTMLParser


_log = logging.getLogger(__name__)


def convert_for_webkit(new_path, filename, host=Host()):
    """ Converts a file's |contents| so it will function correctly in its |new_path| in Webkit.

    Returns the list of modified properties and the modified text if the file was modifed, None otherwise."""
    contents = host.filesystem.read_binary_file(filename)
    converter = _W3CTestConverter(new_path, filename, host)
    if filename.endswith('.css'):
        return converter.add_webkit_prefix_to_unprefixed_properties(contents)
    else:
        converter.feed(contents)
        converter.close()
        return converter.output()


class _W3CTestConverter(HTMLParser):
    def __init__(self, new_path, filename, host=Host()):
        HTMLParser.__init__(self)

        self._host = host
        self._filesystem = self._host.filesystem
        self._webkit_root = WebKitFinder(self._filesystem).webkit_base()

        self.converted_data = []
        self.converted_properties = []
        self.in_style_tag = False
        self.style_data = []
        self.filename = filename

        resources_path = self.path_from_webkit_root('tests', 'resources')
        resources_relpath = self._filesystem.relpath(resources_path, new_path)
        self.resources_relpath = resources_relpath

        # These settings might vary between WebKit and Blink
        self._css_property_file = self.path_from_webkit_root('Source', 'core', 'css', 'CSSProperties.in')

        self.prefixed_properties = self.read_webkit_prefixed_css_property_list()

        self.prefixed_properties = self.read_webkit_prefixed_css_property_list()
        prop_regex = '([\s{]|^)(' + "|".join(prop.replace('-webkit-', '') for prop in self.prefixed_properties) + ')(\s+:|:)'
        self.prop_re = re.compile(prop_regex)

    def output(self):
        return (self.converted_properties, ''.join(self.converted_data))

    def path_from_webkit_root(self, *comps):
        return self._filesystem.abspath(self._filesystem.join(self._webkit_root, *comps))

    def read_webkit_prefixed_css_property_list(self):
        prefixed_properties = []
        unprefixed_properties = set()

        contents = self._filesystem.read_text_file(self._css_property_file)
        for line in contents.splitlines():
            if re.match('^(#|//|$)', line):
                # skip comments and preprocessor directives
                continue
            prop = line.split()[0]
            # Find properties starting with the -webkit- prefix.
            match = re.match('-webkit-([\w|-]*)', prop)
            if match:
                prefixed_properties.append(match.group(1))
            else:
                unprefixed_properties.add(prop.strip())

        # Ignore any prefixed properties for which an unprefixed version is supported
        return [prop for prop in prefixed_properties if prop not in unprefixed_properties]

    def add_webkit_prefix_to_unprefixed_properties(self, text):
        """ Searches |text| for instances of properties requiring the -webkit- prefix and adds the prefix to them.

        Returns the list of converted properties and the modified text."""

        converted_properties = set()
        text_chunks = []
        cur_pos = 0
        for m in self.prop_re.finditer(text):
            text_chunks.extend([text[cur_pos:m.start()], m.group(1), '-webkit-', m.group(2), m.group(3)])
            converted_properties.add(m.group(2))
            cur_pos = m.end()
        text_chunks.append(text[cur_pos:])

        for prop in converted_properties:
            _log.info('  converting %s', prop)

        # FIXME: Handle the JS versions of these properties and GetComputedStyle, too.
        return (converted_properties, ''.join(text_chunks))

    def convert_style_data(self, data):
        converted = self.add_webkit_prefix_to_unprefixed_properties(data)
        if converted[0]:
            self.converted_properties.extend(list(converted[0]))
        return converted[1]

    def convert_attributes_if_needed(self, tag, attrs):
        converted = self.get_starttag_text()
        if tag in ('script', 'link'):
            target_attr = 'src'
            if tag != 'script':
                target_attr = 'href'
            for attr_name, attr_value in attrs:
                if attr_name == target_attr:
                    new_path = re.sub('/resources/testharness',
                                      self.resources_relpath + '/testharness',
                                      attr_value)
                    converted = re.sub(attr_value, new_path, converted)
                    new_path = re.sub('/common/vendor-prefix',
                                      self.resources_relpath + '/vendor-prefix',
                                      attr_value)
                    converted = re.sub(attr_value, new_path, converted)

        for attr_name, attr_value in attrs:
            if attr_name == 'style':
                new_style = self.convert_style_data(attr_value)
                converted = re.sub(attr_value, new_style, converted)
            if attr_name == 'class' and 'instructions' in attr_value:
                # Always hide instructions, they're for manual testers.
                converted = re.sub(' style=".*?"', '', converted)
                converted = re.sub('\>', ' style="display:none">', converted)

        self.converted_data.append(converted)

    def handle_starttag(self, tag, attrs):
        if tag == 'style':
            self.in_style_tag = True
        self.convert_attributes_if_needed(tag, attrs)

    def handle_endtag(self, tag):
        if tag == 'style':
            self.converted_data.append(self.convert_style_data(''.join(self.style_data)))
            self.in_style_tag = False
            self.style_data = []
        self.converted_data.extend(['</', tag, '>'])

    def handle_startendtag(self, tag, attrs):
        self.convert_attributes_if_needed(tag, attrs)

    def handle_data(self, data):
        if self.in_style_tag:
            self.style_data.append(data)
        else:
            self.converted_data.append(data)

    def handle_entityref(self, name):
        self.converted_data.extend(['&', name, ';'])

    def handle_charref(self, name):
        self.converted_data.extend(['&#', name, ';'])

    def handle_comment(self, data):
        self.converted_data.extend(['<!-- ', data, ' -->'])

    def handle_decl(self, decl):
        self.converted_data.extend(['<!', decl, '>'])

    def handle_pi(self, data):
        self.converted_data.extend(['<?', data, '>'])

