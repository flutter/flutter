# Copyright (C) 2010 Google Inc. All rights reserved.
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

"""Unit tests for update_webgl_conformance_tests."""

import unittest

from webkitpy.webgl import update_webgl_conformance_tests as webgl


def construct_script(name):
    return "<script src=\"" + name + "\"></script>\n"


def construct_style(name):
    return "<link rel=\"stylesheet\" href=\"" + name + "\">"


class TestTranslation(unittest.TestCase):
    def assert_unchanged(self, text):
        self.assertEqual(text, webgl.translate_khronos_test(text))

    def assert_translate(self, input, output):
        self.assertEqual(output, webgl.translate_khronos_test(input))

    def test_simple_unchanged(self):
        self.assert_unchanged("")
        self.assert_unchanged("<html></html>")

    def test_header_strip(self):
        single_line_header = "<!-- single line header. -->"
        multi_line_header = """<!-- this is a multi-line
                header.  it should all be removed too.
                -->"""
        text = "<html></html>"
        self.assert_translate(single_line_header, "")
        self.assert_translate(single_line_header + text, text)
        self.assert_translate(multi_line_header + text, text)

    def dont_strip_other_headers(self):
        self.assert_unchanged("<html>\n<!-- don't remove comments on other lines. -->\n</html>")

    def test_include_rewriting(self):
        # Mappings to None are unchanged
        styles = {
            "../resources/js-test-style.css": "../../js/resources/js-test-style.css",
            "fail.css": None,
            "resources/stylesheet.css": None,
            "../resources/style.css": None,
        }
        scripts = {
            "../resources/js-test-pre.js": "../../js/resources/js-test-pre.js",
            "../resources/js-test-post.js": "../../js/resources/js-test-post.js",
            "../resources/desktop-gl-constants.js": "resources/desktop-gl-constants.js",

            "resources/shadow-offset.js": None,
            "../resources/js-test-post-async.js": None,
        }

        input_text = ""
        output_text = ""
        for input, output in styles.items():
            input_text += construct_style(input)
            output_text += construct_style(output if output else input)
        for input, output in scripts.items():
            input_text += construct_script(input)
            output_text += construct_script(output if output else input)

        head = '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">\n<html>\n<head>\n'
        foot = '</head>\n<body>\n</body>\n</html>'
        input_text = head + input_text + foot
        output_text = head + output_text + foot
        self.assert_translate(input_text, output_text)
