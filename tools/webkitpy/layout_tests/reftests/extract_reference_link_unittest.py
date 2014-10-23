# Copyright (C) 2011 Google Inc. All rights reserved.
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

import unittest

from webkitpy.layout_tests.reftests import extract_reference_link


class ExtractLinkMatchTest(unittest.TestCase):

    def test_getExtractMatch(self):
        html_1 = """<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>CSS Test: DESCRIPTION OF TEST</title>
<link rel="author" title="NAME_OF_AUTHOR"
href="mailto:EMAIL OR http://CONTACT_PAGE"/>
<link rel="help" href="RELEVANT_SPEC_SECTION"/>
<link rel="match" href="green-box-ref.xht" />
<link rel="match" href="blue-box-ref.xht" />
<link rel="mismatch" href="red-box-notref.xht" />
<link rel="mismatch" href="red-box-notref.xht" />
<meta name="flags" content="TOKENS" />
<meta name="assert" content="TEST ASSERTION"/>
<style type="text/css"><![CDATA[
CSS FOR TEST
]]></style>
</head>
<body>
CONTENT OF TEST
</body>
</html>
"""
        matches, mismatches = extract_reference_link.get_reference_link(html_1)
        self.assertItemsEqual(matches,
                              ["green-box-ref.xht", "blue-box-ref.xht"])
        self.assertItemsEqual(mismatches,
                              ["red-box-notref.xht", "red-box-notref.xht"])

        html_2 = ""
        empty_tuple_1 = extract_reference_link.get_reference_link(html_2)
        self.assertEqual(empty_tuple_1, ([], []))

        # Link does not have a "ref" attribute.
        html_3 = """<link href="RELEVANT_SPEC_SECTION"/>"""
        empty_tuple_2 = extract_reference_link.get_reference_link(html_3)
        self.assertEqual(empty_tuple_2, ([], []))

        # Link does not have a "href" attribute.
        html_4 = """<link rel="match"/>"""
        empty_tuple_3 = extract_reference_link.get_reference_link(html_4)
        self.assertEqual(empty_tuple_3, ([], []))

        # Link does not have a "/" at the end.
        html_5 = """<link rel="help" href="RELEVANT_SPEC_SECTION">"""
        empty_tuple_4 = extract_reference_link.get_reference_link(html_5)
        self.assertEqual(empty_tuple_4, ([], []))
