# Copyright (C) 2009 Google Inc. All rights reserved.
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

import cStringIO as StringIO
import diff_parser
import re
import unittest

from webkitpy.common.checkout.diff_test_data import DIFF_TEST_DATA

class DiffParserTest(unittest.TestCase):
    maxDiff = None

    def test_diff_parser(self, parser = None):
        if not parser:
            parser = diff_parser.DiffParser(DIFF_TEST_DATA.splitlines())
        self.assertEqual(3, len(parser.files))

        self.assertTrue('WebCore/rendering/style/StyleFlexibleBoxData.h' in parser.files)
        diff = parser.files['WebCore/rendering/style/StyleFlexibleBoxData.h']
        self.assertEqual(7, len(diff.lines))
        # The first two unchaged lines.
        self.assertEqual((47, 47), diff.lines[0][0:2])
        self.assertEqual('', diff.lines[0][2])
        self.assertEqual((48, 48), diff.lines[1][0:2])
        self.assertEqual('    unsigned align : 3; // EBoxAlignment', diff.lines[1][2])
        # The deleted line
        self.assertEqual((50, 0), diff.lines[3][0:2])
        self.assertEqual('    unsigned orient: 1; // EBoxOrient', diff.lines[3][2])

        # The first file looks OK. Let's check the next, more complicated file.
        self.assertTrue('WebCore/rendering/style/StyleRareInheritedData.cpp' in parser.files)
        diff = parser.files['WebCore/rendering/style/StyleRareInheritedData.cpp']
        # There are 3 chunks.
        self.assertEqual(7 + 7 + 9, len(diff.lines))
        # Around an added line.
        self.assertEqual((60, 61), diff.lines[9][0:2])
        self.assertEqual((0, 62), diff.lines[10][0:2])
        self.assertEqual((61, 63), diff.lines[11][0:2])
        # Look through the last chunk, which contains both add's and delete's.
        self.assertEqual((81, 83), diff.lines[14][0:2])
        self.assertEqual((82, 84), diff.lines[15][0:2])
        self.assertEqual((83, 85), diff.lines[16][0:2])
        self.assertEqual((84, 0), diff.lines[17][0:2])
        self.assertEqual((0, 86), diff.lines[18][0:2])
        self.assertEqual((0, 87), diff.lines[19][0:2])
        self.assertEqual((85, 88), diff.lines[20][0:2])
        self.assertEqual((86, 89), diff.lines[21][0:2])
        self.assertEqual((87, 90), diff.lines[22][0:2])

        # Check if a newly added file is correctly handled.
        diff = parser.files['tests/platform/mac/fast/flexbox/box-orient-button-expected.checksum']
        self.assertEqual(1, len(diff.lines))
        self.assertEqual((0, 1), diff.lines[0][0:2])

    def test_diff_converter(self):
        comment_lines = [
            "Hey guys,\n",
            "\n",
            "See my awesome patch below!\n",
            "\n",
            " - Cool Hacker\n",
            "\n",
            ]

        revision_lines = [
            "Subversion Revision 289799\n",
            ]

        svn_diff_lines = [
            "Index: tools/webkitpy/common/checkout/diff_parser.py\n",
            "===================================================================\n",
            "--- tools/webkitpy/common/checkout/diff_parser.py\n",
            "+++ tools/webkitpy/common/checkout/diff_parser.py\n",
            "@@ -59,6 +59,7 @@ def git_diff_to_svn_diff(line):\n",
            ]
        self.assertEqual(diff_parser.get_diff_converter(svn_diff_lines), diff_parser.svn_diff_to_svn_diff)
        self.assertEqual(diff_parser.get_diff_converter(comment_lines + svn_diff_lines), diff_parser.svn_diff_to_svn_diff)
        self.assertEqual(diff_parser.get_diff_converter(revision_lines + svn_diff_lines), diff_parser.svn_diff_to_svn_diff)

        git_diff_lines = [
            "diff --git a/tools/webkitpy/common/checkout/diff_parser.py b/tools/webkitpy/common/checkout/diff_parser.py\n",
            "index 3c5b45b..0197ead 100644\n",
            "--- a/tools/webkitpy/common/checkout/diff_parser.py\n",
            "+++ b/tools/webkitpy/common/checkout/diff_parser.py\n",
            "@@ -59,6 +59,7 @@ def git_diff_to_svn_diff(line):\n",
            ]
        self.assertEqual(diff_parser.get_diff_converter(git_diff_lines), diff_parser.git_diff_to_svn_diff)
        self.assertEqual(diff_parser.get_diff_converter(comment_lines + git_diff_lines), diff_parser.git_diff_to_svn_diff)
        self.assertEqual(diff_parser.get_diff_converter(revision_lines + git_diff_lines), diff_parser.git_diff_to_svn_diff)

    def test_git_mnemonicprefix(self):
        p = re.compile(r' ([a|b])/')

        prefixes = [
            { 'a' : 'i', 'b' : 'w' }, # git-diff (compares the (i)ndex and the (w)ork tree)
            { 'a' : 'c', 'b' : 'w' }, # git-diff HEAD (compares a (c)ommit and the (w)ork tree)
            { 'a' : 'c', 'b' : 'i' }, # git diff --cached (compares a (c)ommit and the (i)ndex)
            { 'a' : 'o', 'b' : 'w' }, # git-diff HEAD:file1 file2 (compares an (o)bject and a (w)ork tree entity)
            { 'a' : '1', 'b' : '2' }, # git diff --no-index a b (compares two non-git things (1) and (2))
        ]

        for prefix in prefixes:
            patch = p.sub(lambda x: " %s/" % prefix[x.group(1)], DIFF_TEST_DATA)
            self.test_diff_parser(diff_parser.DiffParser(patch.splitlines()))

    def test_git_diff_to_svn_diff(self):
        output = """\
Index: tools/webkitpy/common/checkout/diff_parser.py
===================================================================
--- tools/webkitpy/common/checkout/diff_parser.py
+++ tools/webkitpy/common/checkout/diff_parser.py
@@ -59,6 +59,7 @@ def git_diff_to_svn_diff(line):
 A
 B
 C
+D
 E
 F
"""

        inputfmt = StringIO.StringIO("""\
diff --git a/tools/webkitpy/common/checkout/diff_parser.py b/tools/webkitpy/common/checkout/diff_parser.py
index 2ed552c4555db72df16b212547f2c125ae301a04..72870482000c0dba64ce4300ed782c03ee79b74f 100644
--- a/tools/webkitpy/common/checkout/diff_parser.py
+++ b/tools/webkitpy/common/checkout/diff_parser.py
@@ -59,6 +59,7 @@ def git_diff_to_svn_diff(line):
 A
 B
 C
+D
 E
 F
""")
        shortfmt = StringIO.StringIO("""\
diff --git a/tools/webkitpy/common/checkout/diff_parser.py b/tools/webkitpy/common/checkout/diff_parser.py
index b48b162..f300960 100644
--- a/tools/webkitpy/common/checkout/diff_parser.py
+++ b/tools/webkitpy/common/checkout/diff_parser.py
@@ -59,6 +59,7 @@ def git_diff_to_svn_diff(line):
 A
 B
 C
+D
 E
 F
""")

        self.assertMultiLineEqual(output, ''.join(diff_parser.git_diff_to_svn_diff(x) for x in shortfmt.readlines()))
        self.assertMultiLineEqual(output, ''.join(diff_parser.git_diff_to_svn_diff(x) for x in inputfmt.readlines()))
