#!/usr/bin/python2.4
#
# Copyright 2008 The RE2 Authors.  All Rights Reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

"""Unittest for the util/regexp/re2/unicode.py module."""

import os
import StringIO
from google3.pyglib import flags
from google3.testing.pybase import googletest
from google3.util.regexp.re2 import unicode

_UNICODE_DIR = os.path.join(flags.FLAGS.test_srcdir, "google3", "third_party",
                            "unicode", "ucd-5.1.0")


class ConvertTest(googletest.TestCase):
  """Test the conversion functions."""

  def testUInt(self):
    self.assertEquals(0x0000, unicode._UInt("0000"))
    self.assertEquals(0x263A, unicode._UInt("263A"))
    self.assertEquals(0x10FFFF, unicode._UInt("10FFFF"))
    self.assertRaises(unicode.InputError, unicode._UInt, "263")
    self.assertRaises(unicode.InputError, unicode._UInt, "263AAAA")
    self.assertRaises(unicode.InputError, unicode._UInt, "110000")

  def testURange(self):
    self.assertEquals([1, 2, 3], unicode._URange("0001..0003"))
    self.assertEquals([1], unicode._URange("0001"))
    self.assertRaises(unicode.InputError, unicode._URange, "0001..0003..0005")
    self.assertRaises(unicode.InputError, unicode._URange, "0003..0001")
    self.assertRaises(unicode.InputError, unicode._URange, "0001..0001")

  def testUStr(self):
    self.assertEquals("0x263A", unicode._UStr(0x263a))
    self.assertEquals("0x10FFFF", unicode._UStr(0x10FFFF))
    self.assertRaises(unicode.InputError, unicode._UStr, 0x110000)
    self.assertRaises(unicode.InputError, unicode._UStr, -1)


_UNICODE_TABLE = """# Commented line, should be ignored.
# The next line is blank and should be ignored.

0041;Capital A;Line 1
0061..007A;Lowercase;Line 2
1F00;<Greek, First>;Ignored
1FFE;<Greek, Last>;Line 3
10FFFF;Runemax;Line 4
0000;Zero;Line 5
"""

_BAD_TABLE1 = """
111111;Not a code point;
"""

_BAD_TABLE2 = """
0000;<Zero, First>;Missing <Zero, Last>
"""

_BAD_TABLE3 = """
0010..0001;Bad range;
"""


class AbortError(Exception):
  """Function should not have been called."""


def Abort():
  raise AbortError("Abort")


def StringTable(s, n, f):
  unicode.ReadUnicodeTable(StringIO.StringIO(s), n, f)


class ReadUnicodeTableTest(googletest.TestCase):
  """Test the ReadUnicodeTable function."""

  def testSimpleTable(self):

    ncall = [0]  # can't assign to ordinary int in DoLine

    def DoLine(codes, fields):
      self.assertEquals(3, len(fields))
      ncall[0] += 1
      self.assertEquals("Line %d" % (ncall[0],), fields[2])
      if ncall[0] == 1:
        self.assertEquals([0x0041], codes)
        self.assertEquals("0041", fields[0])
        self.assertEquals("Capital A", fields[1])
      elif ncall[0] == 2:
        self.assertEquals(range(0x0061, 0x007A + 1), codes)
        self.assertEquals("0061..007A", fields[0])
        self.assertEquals("Lowercase", fields[1])
      elif ncall[0] == 3:
        self.assertEquals(range(0x1F00, 0x1FFE + 1), codes)
        self.assertEquals("1F00..1FFE", fields[0])
        self.assertEquals("Greek", fields[1])
      elif ncall[0] == 4:
        self.assertEquals([0x10FFFF], codes)
        self.assertEquals("10FFFF", fields[0])
        self.assertEquals("Runemax", fields[1])
      elif ncall[0] == 5:
        self.assertEquals([0x0000], codes)
        self.assertEquals("0000", fields[0])
        self.assertEquals("Zero", fields[1])

    StringTable(_UNICODE_TABLE, 3, DoLine)
    self.assertEquals(5, ncall[0])

  def testErrorTables(self):
    self.assertRaises(unicode.InputError, StringTable, _UNICODE_TABLE, 4, Abort)
    self.assertRaises(unicode.InputError, StringTable, _UNICODE_TABLE, 2, Abort)
    self.assertRaises(unicode.InputError, StringTable, _BAD_TABLE1, 3, Abort)
    self.assertRaises(unicode.InputError, StringTable, _BAD_TABLE2, 3, Abort)
    self.assertRaises(unicode.InputError, StringTable, _BAD_TABLE3, 3, Abort)


class ParseContinueTest(googletest.TestCase):
  """Test the ParseContinue function."""

  def testParseContinue(self):
    self.assertEquals(("Private Use", "First"),
                      unicode._ParseContinue("<Private Use, First>"))
    self.assertEquals(("Private Use", "Last"),
                      unicode._ParseContinue("<Private Use, Last>"))
    self.assertEquals(("<Private Use, Blah>", None),
                      unicode._ParseContinue("<Private Use, Blah>"))


class CaseGroupsTest(googletest.TestCase):
  """Test the CaseGroups function (and the CaseFoldingReader)."""

  def FindGroup(self, c):
    if type(c) == str:
      c = ord(c)
    for g in self.groups:
      if c in g:
        return g
    return None

  def testCaseGroups(self):
    self.groups = unicode.CaseGroups(unicode_dir=_UNICODE_DIR)
    self.assertEquals([ord("A"), ord("a")], self.FindGroup("a"))
    self.assertEquals(None, self.FindGroup("0"))


class ScriptsTest(googletest.TestCase):
  """Test the Scripts function (and the ScriptsReader)."""

  def FindScript(self, c):
    if type(c) == str:
      c = ord(c)
    for script, codes in self.scripts.items():
      for code in codes:
        if c == code:
          return script
    return None

  def testScripts(self):
    self.scripts = unicode.Scripts(unicode_dir=_UNICODE_DIR)
    self.assertEquals("Latin", self.FindScript("a"))
    self.assertEquals("Common", self.FindScript("0"))
    self.assertEquals(None, self.FindScript(0xFFFE))


class CategoriesTest(googletest.TestCase):
  """Test the Categories function (and the UnicodeDataReader)."""

  def FindCategory(self, c):
    if type(c) == str:
      c = ord(c)
    short = None
    for category, codes in self.categories.items():
      for code in codes:
        if code == c:
          # prefer category Nd over N
          if len(category) > 1:
            return category
          if short == None:
            short = category
    return short

  def testCategories(self):
    self.categories = unicode.Categories(unicode_dir=_UNICODE_DIR)
    self.assertEquals("Ll", self.FindCategory("a"))
    self.assertEquals("Nd", self.FindCategory("0"))
    self.assertEquals("Lo", self.FindCategory(0xAD00))  # in First, Last range
    self.assertEquals(None, self.FindCategory(0xFFFE))
    self.assertEquals("Lo", self.FindCategory(0x8B5A))
    self.assertEquals("Lo", self.FindCategory(0x6C38))
    self.assertEquals("Lo", self.FindCategory(0x92D2))
    self.assertTrue(ord("a") in self.categories["L"])
    self.assertTrue(ord("0") in self.categories["N"])
    self.assertTrue(0x8B5A in self.categories["L"])
    self.assertTrue(0x6C38 in self.categories["L"])
    self.assertTrue(0x92D2 in self.categories["L"])

def main():
  googletest.main()

if __name__ == "__main__":
  main()
