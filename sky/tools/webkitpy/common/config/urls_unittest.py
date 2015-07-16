# Copyright (C) 2012 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
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

import unittest

from .urls import parse_bug_id, parse_attachment_id


class URLsTest(unittest.TestCase):
    def test_parse_bug_id(self):
        # FIXME: These would be all better as doctests
        self.assertEqual(12345, parse_bug_id("http://webkit.org/b/12345"))
        self.assertEqual(12345, parse_bug_id("foo\n\nhttp://webkit.org/b/12345\nbar\n\n"))
        self.assertEqual(12345, parse_bug_id("http://bugs.webkit.org/show_bug.cgi?id=12345"))
        self.assertEqual(12345, parse_bug_id("http://bugs.webkit.org/show_bug.cgi?id=12345&ctype=xml"))
        self.assertEqual(12345, parse_bug_id("http://bugs.webkit.org/show_bug.cgi?id=12345&ctype=xml&excludefield=attachmentdata"))
        self.assertEqual(12345, parse_bug_id("http://bugs.webkit.org/show_bug.cgi?id=12345excludefield=attachmentdata&ctype=xml"))

        # Our url parser is super-fragile, but at least we're testing it.
        self.assertIsNone(parse_bug_id("http://www.webkit.org/b/12345"))
        self.assertIsNone(parse_bug_id("http://bugs.webkit.org/show_bug.cgi?ctype=xml&id=12345"))
        self.assertIsNone(parse_bug_id("http://bugs.webkit.org/show_bug.cgi?ctype=xml&id=12345&excludefield=attachmentdata"))
        self.assertIsNone(parse_bug_id("http://bugs.webkit.org/show_bug.cgi?ctype=xml&excludefield=attachmentdata&id=12345"))
        self.assertIsNone(parse_bug_id("http://bugs.webkit.org/show_bug.cgi?excludefield=attachmentdata&ctype=xml&id=12345"))
        self.assertIsNone(parse_bug_id("http://bugs.webkit.org/show_bug.cgi?excludefield=attachmentdata&id=12345&ctype=xml"))

    def test_parse_attachment_id(self):
        self.assertEqual(12345, parse_attachment_id("https://bugs.webkit.org/attachment.cgi?id=12345&action=review"))
        self.assertEqual(12345, parse_attachment_id("https://bugs.webkit.org/attachment.cgi?id=12345&action=edit"))
        self.assertEqual(12345, parse_attachment_id("https://bugs.webkit.org/attachment.cgi?id=12345&action=prettypatch"))
        self.assertEqual(12345, parse_attachment_id("https://bugs.webkit.org/attachment.cgi?id=12345&action=diff"))

        # Direct attachment links are hosted from per-bug subdomains:
        self.assertEqual(12345, parse_attachment_id("https://bug-23456-attachments.webkit.org/attachment.cgi?id=12345"))
        # Make sure secure attachment URLs work too.
        self.assertEqual(12345, parse_attachment_id("https://bug-23456-attachments.webkit.org/attachment.cgi?id=12345&t=Bqnsdkl9fs"))
