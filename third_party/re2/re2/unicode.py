# Copyright 2008 The RE2 Authors.  All Rights Reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

"""Parser for Unicode data files (as distributed by unicode.org)."""

import os
import re
import urllib2

# Directory or URL where Unicode tables reside.
_UNICODE_DIR = "http://www.unicode.org/Public/6.0.0/ucd"

# Largest valid Unicode code value.
_RUNE_MAX = 0x10FFFF


class Error(Exception):
  """Unicode error base class."""


class InputError(Error):
  """Unicode input error class.  Raised on invalid input."""


def _UInt(s):
  """Converts string to Unicode code point ('263A' => 0x263a).

  Args:
    s: string to convert

  Returns:
    Unicode code point

  Raises:
    InputError: the string is not a valid Unicode value.
  """

  try:
    v = int(s, 16)
  except ValueError:
    v = -1
  if len(s) < 4 or len(s) > 6 or v < 0 or v > _RUNE_MAX:
    raise InputError("invalid Unicode value %s" % (s,))
  return v


def _URange(s):
  """Converts string to Unicode range.

    '0001..0003' => [1, 2, 3].
    '0001' => [1].

  Args:
    s: string to convert

  Returns:
    Unicode range

  Raises:
    InputError: the string is not a valid Unicode range.
  """
  a = s.split("..")
  if len(a) == 1:
    return [_UInt(a[0])]
  if len(a) == 2:
    lo = _UInt(a[0])
    hi = _UInt(a[1])
    if lo < hi:
      return range(lo, hi + 1)
  raise InputError("invalid Unicode range %s" % (s,))


def _UStr(v):
  """Converts Unicode code point to hex string.

    0x263a => '0x263A'.

  Args:
    v: code point to convert

  Returns:
    Unicode string

  Raises:
    InputError: the argument is not a valid Unicode value.
  """
  if v < 0 or v > _RUNE_MAX:
    raise InputError("invalid Unicode value %s" % (v,))
  return "0x%04X" % (v,)


def _ParseContinue(s):
  """Parses a Unicode continuation field.

  These are of the form '<Name, First>' or '<Name, Last>'.
  Instead of giving an explicit range in a single table entry,
  some Unicode tables use two entries, one for the first
  code value in the range and one for the last.
  The first entry's description is '<Name, First>' instead of 'Name'
  and the second is '<Name, Last>'.

    '<Name, First>' => ('Name', 'First')
    '<Name, Last>' => ('Name', 'Last')
    'Anything else' => ('Anything else', None)

  Args:
    s: continuation field string

  Returns:
    pair: name and ('First', 'Last', or None)
  """

  match = re.match("<(.*), (First|Last)>", s)
  if match is not None:
    return match.groups()
  return (s, None)


def ReadUnicodeTable(filename, nfields, doline):
  """Generic Unicode table text file reader.

  The reader takes care of stripping out comments and also
  parsing the two different ways that the Unicode tables specify
  code ranges (using the .. notation and splitting the range across
  multiple lines).

  Each non-comment line in the table is expected to have the given
  number of fields.  The first field is known to be the Unicode value
  and the second field its description.

  The reader calls doline(codes, fields) for each entry in the table.
  If fn raises an exception, the reader prints that exception,
  prefixed with the file name and line number, and continues
  processing the file.  When done with the file, the reader re-raises
  the first exception encountered during the file.

  Arguments:
    filename: the Unicode data file to read, or a file-like object.
    nfields: the number of expected fields per line in that file.
    doline: the function to call for each table entry.

  Raises:
    InputError: nfields is invalid (must be >= 2).
  """

  if nfields < 2:
    raise InputError("invalid number of fields %d" % (nfields,))

  if type(filename) == str:
    if filename.startswith("http://"):
      fil = urllib2.urlopen(filename)
    else:
      fil = open(filename, "r")
  else:
    fil = filename

  first = None        # first code in multiline range
  expect_last = None  # tag expected for "Last" line in multiline range
  lineno = 0          # current line number
  for line in fil:
    lineno += 1
    try:
      # Chop # comments and white space; ignore empty lines.
      sharp = line.find("#")
      if sharp >= 0:
        line = line[:sharp]
      line = line.strip()
      if not line:
        continue

      # Split fields on ";", chop more white space.
      # Must have the expected number of fields.
      fields = [s.strip() for s in line.split(";")]
      if len(fields) != nfields:
        raise InputError("wrong number of fields %d %d - %s" %
                         (len(fields), nfields, line))

      # The Unicode text files have two different ways
      # to list a Unicode range.  Either the first field is
      # itself a range (0000..FFFF), or the range is split
      # across two lines, with the second field noting
      # the continuation.
      codes = _URange(fields[0])
      (name, cont) = _ParseContinue(fields[1])

      if expect_last is not None:
        # If the last line gave the First code in a range,
        # this one had better give the Last one.
        if (len(codes) != 1 or codes[0] <= first or
            cont != "Last" or name != expect_last):
          raise InputError("expected Last line for %s" %
                           (expect_last,))
        codes = range(first, codes[0] + 1)
        first = None
        expect_last = None
        fields[0] = "%04X..%04X" % (codes[0], codes[-1])
        fields[1] = name
      elif cont == "First":
        # Otherwise, if this is the First code in a range,
        # remember it and go to the next line.
        if len(codes) != 1:
          raise InputError("bad First line: range given")
        expect_last = name
        first = codes[0]
        continue

      doline(codes, fields)

    except Exception, e:
      print "%s:%d: %s" % (filename, lineno, e)
      raise

  if expect_last is not None:
    raise InputError("expected Last line for %s; got EOF" %
                     (expect_last,))


def CaseGroups(unicode_dir=_UNICODE_DIR):
  """Returns list of Unicode code groups equivalent under case folding.

  Each group is a sorted list of code points,
  and the list of groups is sorted by first code point
  in the group.

  Args:
    unicode_dir: Unicode data directory

  Returns:
    list of Unicode code groups
  """

  # Dict mapping lowercase code point to fold-equivalent group.
  togroup = {}

  def DoLine(codes, fields):
    """Process single CaseFolding.txt line, updating togroup."""
    (_, foldtype, lower, _) = fields
    if foldtype not in ("C", "S"):
      return
    lower = _UInt(lower)
    togroup.setdefault(lower, [lower]).extend(codes)

  ReadUnicodeTable(unicode_dir+"/CaseFolding.txt", 4, DoLine)

  groups = togroup.values()
  for g in groups:
    g.sort()
  groups.sort()
  return togroup, groups


def Scripts(unicode_dir=_UNICODE_DIR):
  """Returns dict mapping script names to code lists.

  Args:
    unicode_dir: Unicode data directory

  Returns:
    dict mapping script names to code lists
  """

  scripts = {}

  def DoLine(codes, fields):
    """Process single Scripts.txt line, updating scripts."""
    (_, name) = fields
    scripts.setdefault(name, []).extend(codes)

  ReadUnicodeTable(unicode_dir+"/Scripts.txt", 2, DoLine)
  return scripts


def Categories(unicode_dir=_UNICODE_DIR):
  """Returns dict mapping category names to code lists.

  Args:
    unicode_dir: Unicode data directory

  Returns:
    dict mapping category names to code lists
  """

  categories = {}

  def DoLine(codes, fields):
    """Process single UnicodeData.txt line, updating categories."""
    category = fields[2]
    categories.setdefault(category, []).extend(codes)
    # Add codes from Lu into L, etc.
    if len(category) > 1:
      short = category[0]
      categories.setdefault(short, []).extend(codes)

  ReadUnicodeTable(unicode_dir+"/UnicodeData.txt", 15, DoLine)
  return categories

