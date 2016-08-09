#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# suppressions.py

"""Post-process Valgrind suppression matcher.

Suppressions are defined as follows:

# optional one-line comments anywhere in the suppressions file.
{
  <Short description of the error>
  Toolname:Errortype
  fun:function_name
  obj:object_filename
  fun:wildcarded_fun*_name
  # an ellipsis wildcards zero or more functions in a stack.
  ...
  fun:some_other_function_name
}

If ran from the command line, suppressions.py does a self-test
of the Suppression class.
"""

import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__),
                                '..', 'python', 'google'))
import path_utils


ELLIPSIS = '...'


def GetSuppressions():
  suppressions_root = path_utils.ScriptDir()
  JOIN = os.path.join

  result = {}

  supp_filename = JOIN(suppressions_root, "memcheck", "suppressions.txt")
  vg_common = ReadSuppressionsFromFile(supp_filename)
  result['common_suppressions'] = vg_common

  supp_filename = JOIN(suppressions_root, "memcheck", "suppressions_linux.txt")
  vg_linux = ReadSuppressionsFromFile(supp_filename)
  result['linux_suppressions'] = vg_linux

  supp_filename = JOIN(suppressions_root, "memcheck", "suppressions_mac.txt")
  vg_mac = ReadSuppressionsFromFile(supp_filename)
  result['mac_suppressions'] = vg_mac

  supp_filename = JOIN(suppressions_root, "drmemory", "suppressions.txt")
  result['drmem_suppressions'] = ReadSuppressionsFromFile(supp_filename)
  supp_filename = JOIN(suppressions_root, "drmemory", "suppressions_full.txt")
  result['drmem_full_suppressions'] = ReadSuppressionsFromFile(supp_filename)

  return result


def GlobToRegex(glob_pattern, ignore_case=False):
  """Translate glob wildcards (*?) into regex syntax.  Escape the rest."""
  regex = ''
  for char in glob_pattern:
    if char == '*':
      regex += '.*'
    elif char == '?':
      regex += '.'
    elif ignore_case and char.isalpha():
      regex += '[%s%s]' % (char.lower(), char.upper())
    else:
      regex += re.escape(char)
  return ''.join(regex)


def StripAndSkipCommentsIterator(lines):
  """Generator of (line_no, line) pairs that strips comments and whitespace."""
  for (line_no, line) in enumerate(lines):
    line = line.strip()  # Drop \n
    if line.startswith('#'):
      continue  # Comments
    # Skip comment lines, but not empty lines, they indicate the end of a
    # suppression.  Add one to the line number as well, since most editors use
    # 1-based numberings, and enumerate is 0-based.
    yield (line_no + 1, line)


class Suppression(object):
  """This class represents a single stack trace suppression.

  Attributes:
    description: A string representing the error description.
    type: A string representing the error type, e.g. Memcheck:Leak.
    stack: The lines comprising the stack trace for the suppression.
    regex: The actual regex used to match against scraped reports.
  """

  def __init__(self, description, type, stack, defined_at, regex):
    """Inits Suppression.

    description, type, stack, regex: same as class attributes
    defined_at: file:line identifying where the suppression was defined
    """
    self.description = description
    self.type = type
    self.stack = stack
    self.defined_at = defined_at
    self.regex = re.compile(regex, re.MULTILINE)

  def Match(self, suppression_from_report):
    """Returns bool indicating whether this suppression matches
       the suppression generated from Valgrind error report.

       We match our suppressions against generated suppressions
       (not against reports) since they have the same format
       while the reports are taken from XML, contain filenames,
       they are demangled, and are generally more difficult to
       parse.

    Args:
      suppression_from_report: list of strings (function names).
    Returns:
      True if the suppression is not empty and matches the report.
    """
    if not self.stack:
      return False
    lines = [f.strip() for f in suppression_from_report]
    return self.regex.match('\n'.join(lines) + '\n') is not None


def FilenameToTool(filename):
  """Return the name of the tool that a file is related to, or None.

  Example mappings:
    tools/valgrind/drmemory/suppressions.txt -> drmemory
    tools/valgrind/drmemory/suppressions_full.txt -> drmemory
    tools/valgrind/memcheck/suppressions.txt -> memcheck
    tools/valgrind/memcheck/suppressions_mac.txt -> memcheck
  """
  filename = os.path.abspath(filename)
  parts = filename.split(os.sep)
  tool = parts[-2]
  if tool in ('drmemory', 'memcheck'):
    return tool
  return None


def ReadSuppressionsFromFile(filename):
  """Read suppressions from the given file and return them as a list"""
  tool_to_parser = {
    "drmemory":  ReadDrMemorySuppressions,
    "memcheck":  ReadValgrindStyleSuppressions,
  }
  tool = FilenameToTool(filename)
  assert tool in tool_to_parser, (
      "unknown tool %s for filename %s" % (tool, filename))
  parse_func = tool_to_parser[tool]

  # Consider non-existent files to be empty.
  if not os.path.exists(filename):
    return []

  input_file = file(filename, 'r')
  try:
    return parse_func(input_file, filename)
  except SuppressionError:
    input_file.close()
    raise


class ValgrindStyleSuppression(Suppression):
  """A suppression using the Valgrind syntax.

  Most tools, even ones that are not Valgrind-based, use this syntax.

  Attributes:
    Same as Suppression.
  """

  def __init__(self, description, type, stack, defined_at):
    """Creates a suppression using the Memcheck syntax."""
    regex = '{\n.*\n%s\n' % type
    for line in stack:
      if line == ELLIPSIS:
        regex += '(.*\n)*'
      else:
        regex += GlobToRegex(line)
        regex += '\n'
    regex += '(.*\n)*'
    regex += '}'

    # In the recent version of valgrind-variant we've switched
    # from memcheck's default Addr[1248]/Value[1248]/Cond suppression types
    # to simply Unaddressable/Uninitialized.
    # The suppression generator no longer gives us "old" types thus
    # for the "new-type" suppressions:
    #  * Memcheck:Unaddressable should also match Addr* reports,
    #  * Memcheck:Uninitialized should also match Cond and Value reports,
    #
    # We also want to support legacy suppressions (e.g. copied from
    # upstream bugs etc), so:
    #  * Memcheck:Addr[1248] suppressions should match Unaddressable reports,
    #  * Memcheck:Cond and Memcheck:Value[1248] should match Uninitialized.
    # Please note the latest two rules only apply to the
    # tools/valgrind/waterfall.sh suppression matcher and the real
    # valgrind-variant Memcheck will not suppress
    # e.g. Addr1 printed as Unaddressable with Addr4 suppression.
    # Be careful to check the access size while copying legacy suppressions!
    for sz in [1, 2, 4, 8]:
      regex = regex.replace("\nMemcheck:Addr%d\n" % sz,
                            "\nMemcheck:(Addr%d|Unaddressable)\n" % sz)
      regex = regex.replace("\nMemcheck:Value%d\n" % sz,
                            "\nMemcheck:(Value%d|Uninitialized)\n" % sz)
    regex = regex.replace("\nMemcheck:Cond\n",
                          "\nMemcheck:(Cond|Uninitialized)\n")
    regex = regex.replace("\nMemcheck:Unaddressable\n",
                          "\nMemcheck:(Addr.|Unaddressable)\n")
    regex = regex.replace("\nMemcheck:Uninitialized\n",
                          "\nMemcheck:(Cond|Value.|Uninitialized)\n")

    return super(ValgrindStyleSuppression, self).__init__(
        description, type, stack, defined_at, regex)

  def __str__(self):
    """Stringify."""
    lines = [self.description, self.type] + self.stack
    return "{\n   %s\n}\n" % "\n   ".join(lines)


class SuppressionError(Exception):
  def __init__(self, message, happened_at):
    self._message = message
    self._happened_at = happened_at

  def __str__(self):
    return 'Error reading suppressions at %s!\n%s' % (
        self._happened_at, self._message)


def ReadValgrindStyleSuppressions(lines, supp_descriptor):
  """Given a list of lines, returns a list of suppressions.

  Args:
    lines: a list of lines containing suppressions.
    supp_descriptor: should typically be a filename.
        Used only when printing errors.
  """
  result = []
  cur_descr = ''
  cur_type = ''
  cur_stack = []
  in_suppression = False
  nline = 0
  for line in lines:
    nline += 1
    line = line.strip()
    if line.startswith('#'):
      continue
    if not in_suppression:
      if not line:
        # empty lines between suppressions
        pass
      elif line.startswith('{'):
        in_suppression = True
        pass
      else:
        raise SuppressionError('Expected: "{"',
                               "%s:%d" % (supp_descriptor, nline))
    elif line.startswith('}'):
      result.append(
          ValgrindStyleSuppression(cur_descr, cur_type, cur_stack,
                                   "%s:%d" % (supp_descriptor, nline)))
      cur_descr = ''
      cur_type = ''
      cur_stack = []
      in_suppression = False
    elif not cur_descr:
      cur_descr = line
      continue
    elif not cur_type:
      if not line.startswith("Memcheck:"):
        raise SuppressionError(
            'Expected "Memcheck:TYPE", got "%s"' % line,
            "%s:%d" % (supp_descriptor, nline))
      supp_type = line.split(':')[1]
      if not supp_type in ["Addr1", "Addr2", "Addr4", "Addr8",
                           "Cond", "Free", "Jump", "Leak", "Overlap", "Param",
                           "Value1", "Value2", "Value4", "Value8",
                           "Unaddressable", "Uninitialized"]:
        raise SuppressionError('Unknown suppression type "%s"' % supp_type,
                               "%s:%d" % (supp_descriptor, nline))
      cur_type = line
      continue
    elif re.match("^fun:.*|^obj:.*|^\.\.\.$", line):
      cur_stack.append(line.strip())
    elif len(cur_stack) == 0 and cur_type == "Memcheck:Param":
      cur_stack.append(line.strip())
    else:
      raise SuppressionError(
          '"fun:function_name" or "obj:object_file" or "..." expected',
          "%s:%d" % (supp_descriptor, nline))
  return result


def PresubmitCheckSuppressions(supps):
  """Check a list of suppressions and return a list of SuppressionErrors.

  Mostly useful for separating the checking logic from the Presubmit API for
  testing.
  """
  known_supp_names = {}  # Key: name, Value: suppression.
  errors = []
  for s in supps:
    if re.search("<.*suppression.name.here>", s.description):
      # Suppression name line is
      # <insert_a_suppression_name_here> for Memcheck,
      # name=<insert_a_suppression_name_here> for DrMemory
      errors.append(
          SuppressionError(
              "You've forgotten to put a suppression name like bug_XXX",
              s.defined_at))
      continue

    if s.description in known_supp_names:
      errors.append(
          SuppressionError(
              'Suppression named "%s" is defined more than once, '
              'see %s' % (s.description,
                          known_supp_names[s.description].defined_at),
              s.defined_at))
    else:
      known_supp_names[s.description] = s
  return errors


def PresubmitCheck(input_api, output_api):
  """A helper function useful in PRESUBMIT.py
     Returns a list of errors or [].
  """
  sup_regex = re.compile('suppressions.*\.txt$')
  filenames = [f.AbsoluteLocalPath() for f in input_api.AffectedFiles()
                   if sup_regex.search(f.LocalPath())]

  errors = []

  for f in filenames:
    try:
      supps = ReadSuppressionsFromFile(f)
      errors.extend(PresubmitCheckSuppressions(supps))
    except SuppressionError as e:
      errors.append(e)

  return [output_api.PresubmitError(str(e)) for e in errors]


class DrMemorySuppression(Suppression):
  """A suppression using the DrMemory syntax.

  Attributes:
    instr: The instruction to match.
    Rest inherited from Suppression.
  """

  def __init__(self, name, report_type, instr, stack, defined_at):
    """Constructor."""
    self.instr = instr

    # Construct the regex.
    regex = '{\n'
    if report_type == 'LEAK':
      regex += '(POSSIBLE )?LEAK'
    else:
      regex += report_type
    regex += '\nname=.*\n'

    # TODO(rnk): Implement http://crbug.com/107416#c5 .
    # drmemory_analyze.py doesn't generate suppressions with an instruction in
    # them, so these suppressions will always fail to match.  We should override
    # Match to fetch the instruction from the report and try to match against
    # that.
    if instr:
      regex += 'instruction=%s\n' % GlobToRegex(instr)

    for line in stack:
      if line == ELLIPSIS:
        regex += '(.*\n)*'
      elif '!' in line:
        (mod, func) = line.split('!')
        if func == ELLIPSIS:  # mod!ellipsis frame
          regex += '(%s\!.*\n)+' % GlobToRegex(mod, ignore_case=True)
        else:  # mod!func frame
          # Ignore case for the module match, but not the function match.
          regex += '%s\!%s\n' % (GlobToRegex(mod, ignore_case=True),
                                 GlobToRegex(func, ignore_case=False))
      else:
        regex += GlobToRegex(line)
        regex += '\n'
    regex += '(.*\n)*'  # Match anything left in the stack.
    regex += '}'
    return super(DrMemorySuppression, self).__init__(name, report_type, stack,
                                                     defined_at, regex)

  def __str__(self):
    """Stringify."""
    text = self.type + "\n"
    if self.description:
      text += "name=%s\n" % self.description
    if self.instr:
      text += "instruction=%s\n" % self.instr
    text += "\n".join(self.stack)
    text += "\n"
    return text


# Possible DrMemory error report types.  Keep consistent with suppress_name
# array in drmemory/drmemory/report.c.
DRMEMORY_ERROR_TYPES = [
    'UNADDRESSABLE ACCESS',
    'UNINITIALIZED READ',
    'INVALID HEAP ARGUMENT',
    'GDI USAGE ERROR',
    'HANDLE LEAK',
    'LEAK',
    'POSSIBLE LEAK',
    'WARNING',
    ]


# Regexes to match valid drmemory frames.
DRMEMORY_FRAME_PATTERNS = [
    re.compile(r"^.*\!.*$"),              # mod!func
    re.compile(r"^.*!\.\.\.$"),           # mod!ellipsis
    re.compile(r"^\<.*\+0x.*\>$"),        # <mod+0xoffs>
    re.compile(r"^\<not in a module\>$"),
    re.compile(r"^system call .*$"),
    re.compile(r"^\*$"),                  # wildcard
    re.compile(r"^\.\.\.$"),              # ellipsis
    ]


def ReadDrMemorySuppressions(lines, supp_descriptor):
  """Given a list of lines, returns a list of DrMemory suppressions.

  Args:
    lines: a list of lines containing suppressions.
    supp_descriptor: should typically be a filename.
      Used only when parsing errors happen.
  """
  lines = StripAndSkipCommentsIterator(lines)
  suppressions = []
  for (line_no, line) in lines:
    if not line:
      continue
    if line not in DRMEMORY_ERROR_TYPES:
      raise SuppressionError('Expected a DrMemory error type, '
                             'found %r instead\n  Valid error types: %s' %
                             (line, ' '.join(DRMEMORY_ERROR_TYPES)),
                             "%s:%d" % (supp_descriptor, line_no))

    # Suppression starts here.
    report_type = line
    name = ''
    instr = None
    stack = []
    defined_at = "%s:%d" % (supp_descriptor, line_no)
    found_stack = False
    for (line_no, line) in lines:
      if not found_stack and line.startswith('name='):
        name = line.replace('name=', '')
      elif not found_stack and line.startswith('instruction='):
        instr = line.replace('instruction=', '')
      else:
        # Unrecognized prefix indicates start of stack trace.
        found_stack = True
        if not line:
          # Blank line means end of suppression.
          break
        if not any([regex.match(line) for regex in DRMEMORY_FRAME_PATTERNS]):
          raise SuppressionError(
              ('Unexpected stack frame pattern at line %d\n' +
               'Frames should be one of the following:\n' +
               ' module!function\n' +
               ' module!...\n' +
               ' <module+0xhexoffset>\n' +
               ' <not in a module>\n' +
               ' system call Name\n' +
               ' *\n' +
               ' ...\n') % line_no, defined_at)
        stack.append(line)

    if len(stack) == 0:  # In case we hit EOF or blank without any stack frames.
      raise SuppressionError('Suppression "%s" has no stack frames, ends at %d'
                             % (name, line_no), defined_at)
    if stack[-1] == ELLIPSIS:
      raise SuppressionError('Suppression "%s" ends in an ellipsis on line %d' %
                             (name, line_no), defined_at)

    suppressions.append(
        DrMemorySuppression(name, report_type, instr, stack, defined_at))

  return suppressions


def ParseSuppressionOfType(lines, supp_descriptor, def_line_no, report_type):
  """Parse the suppression starting on this line.

  Suppressions start with a type, have an optional name and instruction, and a
  stack trace that ends in a blank line.
  """



def TestStack(stack, positive, negative, suppression_parser=None):
  """A helper function for SelfTest() that checks a single stack.

  Args:
    stack: the stack to match the suppressions.
    positive: the list of suppressions that must match the given stack.
    negative: the list of suppressions that should not match.
    suppression_parser: optional arg for the suppression parser, default is
      ReadValgrindStyleSuppressions.
  """
  if not suppression_parser:
    suppression_parser = ReadValgrindStyleSuppressions
  for supp in positive:
    parsed = suppression_parser(supp.split("\n"), "positive_suppression")
    assert parsed[0].Match(stack.split("\n")), (
        "Suppression:\n%s\ndidn't match stack:\n%s" % (supp, stack))
  for supp in negative:
    parsed = suppression_parser(supp.split("\n"), "negative_suppression")
    assert not parsed[0].Match(stack.split("\n")), (
        "Suppression:\n%s\ndid match stack:\n%s" % (supp, stack))


def TestFailPresubmit(supp_text, error_text, suppression_parser=None):
  """A helper function for SelfTest() that verifies a presubmit check fires.

  Args:
    supp_text: suppression text to parse.
    error_text: text of the presubmit error we expect to find.
    suppression_parser: optional arg for the suppression parser, default is
      ReadValgrindStyleSuppressions.
  """
  if not suppression_parser:
    suppression_parser = ReadValgrindStyleSuppressions
  try:
    supps = suppression_parser(supp_text.split("\n"), "<presubmit suppression>")
  except SuppressionError, e:
    # If parsing raised an exception, match the error text here.
    assert error_text in str(e), (
        "presubmit text %r not in SuppressionError:\n%r" %
        (error_text, str(e)))
  else:
    # Otherwise, run the presubmit checks over the supps.  We expect a single
    # error that has text matching error_text.
    errors = PresubmitCheckSuppressions(supps)
    assert len(errors) == 1, (
        "expected exactly one presubmit error, got:\n%s" % errors)
    assert error_text in str(errors[0]), (
        "presubmit text %r not in SuppressionError:\n%r" %
        (error_text, str(errors[0])))


def SelfTest():
  """Tests the Suppression.Match() capabilities."""

  test_memcheck_stack_1 = """{
    test
    Memcheck:Leak
    fun:absolutly
    fun:brilliant
    obj:condition
    fun:detection
    fun:expression
  }"""

  test_memcheck_stack_2 = """{
    test
    Memcheck:Uninitialized
    fun:absolutly
    fun:brilliant
    obj:condition
    fun:detection
    fun:expression
  }"""

  test_memcheck_stack_3 = """{
    test
    Memcheck:Unaddressable
    fun:absolutly
    fun:brilliant
    obj:condition
    fun:detection
    fun:expression
  }"""

  test_memcheck_stack_4 = """{
    test
    Memcheck:Addr4
    fun:absolutly
    fun:brilliant
    obj:condition
    fun:detection
    fun:expression
  }"""

  positive_memcheck_suppressions_1 = [
    "{\nzzz\nMemcheck:Leak\nfun:absolutly\n}",
    "{\nzzz\nMemcheck:Leak\nfun:ab*ly\n}",
    "{\nzzz\nMemcheck:Leak\nfun:absolutly\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Leak\n...\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Leak\n...\nfun:detection\n}",
    "{\nzzz\nMemcheck:Leak\nfun:absolutly\n...\nfun:detection\n}",
    "{\nzzz\nMemcheck:Leak\nfun:ab*ly\n...\nfun:detection\n}",
    "{\nzzz\nMemcheck:Leak\n...\nobj:condition\n}",
    "{\nzzz\nMemcheck:Leak\n...\nobj:condition\nfun:detection\n}",
    "{\nzzz\nMemcheck:Leak\n...\nfun:brilliant\nobj:condition\n}",
  ]

  positive_memcheck_suppressions_2 = [
    "{\nzzz\nMemcheck:Uninitialized\nfun:absolutly\n}",
    "{\nzzz\nMemcheck:Uninitialized\nfun:ab*ly\n}",
    "{\nzzz\nMemcheck:Uninitialized\nfun:absolutly\nfun:brilliant\n}",
    # Legacy suppression types
    "{\nzzz\nMemcheck:Value1\n...\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Cond\n...\nfun:detection\n}",
    "{\nzzz\nMemcheck:Value8\nfun:absolutly\nfun:brilliant\n}",
  ]

  positive_memcheck_suppressions_3 = [
    "{\nzzz\nMemcheck:Unaddressable\nfun:absolutly\n}",
    "{\nzzz\nMemcheck:Unaddressable\nfun:absolutly\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Unaddressable\nfun:absolutly\nfun:brilliant\n}",
    # Legacy suppression types
    "{\nzzz\nMemcheck:Addr1\n...\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Addr8\n...\nfun:detection\n}",
  ]

  positive_memcheck_suppressions_4 = [
    "{\nzzz\nMemcheck:Addr4\nfun:absolutly\n}",
    "{\nzzz\nMemcheck:Unaddressable\nfun:absolutly\n}",
    "{\nzzz\nMemcheck:Addr4\nfun:absolutly\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Unaddressable\n...\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Addr4\n...\nfun:detection\n}",
  ]

  negative_memcheck_suppressions_1 = [
    "{\nzzz\nMemcheck:Leak\nfun:abnormal\n}",
    "{\nzzz\nMemcheck:Leak\nfun:ab*liant\n}",
    "{\nzzz\nMemcheck:Leak\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Leak\nobj:condition\n}",
    "{\nzzz\nMemcheck:Addr8\nfun:brilliant\n}",
  ]

  negative_memcheck_suppressions_2 = [
    "{\nzzz\nMemcheck:Cond\nfun:abnormal\n}",
    "{\nzzz\nMemcheck:Value2\nfun:abnormal\n}",
    "{\nzzz\nMemcheck:Uninitialized\nfun:ab*liant\n}",
    "{\nzzz\nMemcheck:Value4\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Leak\nobj:condition\n}",
    "{\nzzz\nMemcheck:Addr8\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Unaddressable\nfun:brilliant\n}",
  ]

  negative_memcheck_suppressions_3 = [
    "{\nzzz\nMemcheck:Addr1\nfun:abnormal\n}",
    "{\nzzz\nMemcheck:Uninitialized\nfun:absolutly\n}",
    "{\nzzz\nMemcheck:Addr2\nfun:ab*liant\n}",
    "{\nzzz\nMemcheck:Value4\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Leak\nobj:condition\n}",
    "{\nzzz\nMemcheck:Addr8\nfun:brilliant\n}",
  ]

  negative_memcheck_suppressions_4 = [
    "{\nzzz\nMemcheck:Addr1\nfun:abnormal\n}",
    "{\nzzz\nMemcheck:Addr4\nfun:abnormal\n}",
    "{\nzzz\nMemcheck:Unaddressable\nfun:abnormal\n}",
    "{\nzzz\nMemcheck:Addr1\nfun:absolutly\n}",
    "{\nzzz\nMemcheck:Addr2\nfun:ab*liant\n}",
    "{\nzzz\nMemcheck:Value4\nfun:brilliant\n}",
    "{\nzzz\nMemcheck:Leak\nobj:condition\n}",
    "{\nzzz\nMemcheck:Addr8\nfun:brilliant\n}",
  ]

  TestStack(test_memcheck_stack_1,
            positive_memcheck_suppressions_1,
            negative_memcheck_suppressions_1)
  TestStack(test_memcheck_stack_2,
            positive_memcheck_suppressions_2,
            negative_memcheck_suppressions_2)
  TestStack(test_memcheck_stack_3,
            positive_memcheck_suppressions_3,
            negative_memcheck_suppressions_3)
  TestStack(test_memcheck_stack_4,
            positive_memcheck_suppressions_4,
            negative_memcheck_suppressions_4)

  # TODO(timurrrr): add TestFailPresubmit tests.

  ### DrMemory self tests.

  # http://crbug.com/96010 suppression.
  stack_96010 = """{
    UNADDRESSABLE ACCESS
    name=<insert_a_suppression_name_here>
    *!TestingProfile::FinishInit
    *!TestingProfile::TestingProfile
    *!BrowserAboutHandlerTest_WillHandleBrowserAboutURL_Test::TestBody
    *!testing::Test::Run
  }"""

  suppress_96010 = [
    "UNADDRESSABLE ACCESS\nname=zzz\n...\n*!testing::Test::Run\n",
    ("UNADDRESSABLE ACCESS\nname=zzz\n...\n" +
     "*!BrowserAboutHandlerTest_WillHandleBrowserAboutURL_Test::TestBody\n"),
    "UNADDRESSABLE ACCESS\nname=zzz\n...\n*!BrowserAboutHandlerTest*\n",
    "UNADDRESSABLE ACCESS\nname=zzz\n*!TestingProfile::FinishInit\n",
    # No name should be needed
    "UNADDRESSABLE ACCESS\n*!TestingProfile::FinishInit\n",
    # Whole trace
    ("UNADDRESSABLE ACCESS\n" +
     "*!TestingProfile::FinishInit\n" +
     "*!TestingProfile::TestingProfile\n" +
     "*!BrowserAboutHandlerTest_WillHandleBrowserAboutURL_Test::TestBody\n" +
     "*!testing::Test::Run\n"),
  ]

  negative_96010 = [
    # Wrong type
    "UNINITIALIZED READ\nname=zzz\n*!TestingProfile::FinishInit\n",
    # No ellipsis
    "UNADDRESSABLE ACCESS\nname=zzz\n*!BrowserAboutHandlerTest*\n",
  ]

  TestStack(stack_96010, suppress_96010, negative_96010,
            suppression_parser=ReadDrMemorySuppressions)

  # Invalid heap arg
  stack_invalid = """{
    INVALID HEAP ARGUMENT
    name=asdf
    *!foo
  }"""
  suppress_invalid = [
    "INVALID HEAP ARGUMENT\n*!foo\n",
  ]
  negative_invalid = [
    "UNADDRESSABLE ACCESS\n*!foo\n",
  ]

  TestStack(stack_invalid, suppress_invalid, negative_invalid,
            suppression_parser=ReadDrMemorySuppressions)

  # Suppress only ntdll
  stack_in_ntdll = """{
    UNADDRESSABLE ACCESS
    name=<insert_a_suppression_name_here>
    ntdll.dll!RtlTryEnterCriticalSection
  }"""
  stack_not_ntdll = """{
    UNADDRESSABLE ACCESS
    name=<insert_a_suppression_name_here>
    notntdll.dll!RtlTryEnterCriticalSection
  }"""

  suppress_in_ntdll = [
    "UNADDRESSABLE ACCESS\nntdll.dll!RtlTryEnterCriticalSection\n",
  ]
  suppress_in_any = [
    "UNADDRESSABLE ACCESS\n*!RtlTryEnterCriticalSection\n",
  ]

  TestStack(stack_in_ntdll, suppress_in_ntdll + suppress_in_any, [],
            suppression_parser=ReadDrMemorySuppressions)
  # Make sure we don't wildcard away the "not" part and match ntdll.dll by
  # accident.
  TestStack(stack_not_ntdll, suppress_in_any, suppress_in_ntdll,
            suppression_parser=ReadDrMemorySuppressions)

  # Suppress a POSSIBLE LEAK with LEAK.
  stack_foo_possible = """{
    POSSIBLE LEAK
    name=foo possible
    *!foo
  }"""
  suppress_foo_possible = [ "POSSIBLE LEAK\n*!foo\n" ]
  suppress_foo_leak = [ "LEAK\n*!foo\n" ]
  TestStack(stack_foo_possible, suppress_foo_possible + suppress_foo_leak, [],
            suppression_parser=ReadDrMemorySuppressions)

  # Don't suppress LEAK with POSSIBLE LEAK.
  stack_foo_leak = """{
    LEAK
    name=foo leak
    *!foo
  }"""
  TestStack(stack_foo_leak, suppress_foo_leak, suppress_foo_possible,
            suppression_parser=ReadDrMemorySuppressions)

  # Test case insensitivity of module names.
  stack_user32_mixed_case = """{
    LEAK
    name=<insert>
    USER32.dll!foo
    user32.DLL!bar
    user32.dll!baz
  }"""
  suppress_user32 = [  # Module name case doesn't matter.
      "LEAK\nuser32.dll!foo\nuser32.dll!bar\nuser32.dll!baz\n",
      "LEAK\nUSER32.DLL!foo\nUSER32.DLL!bar\nUSER32.DLL!baz\n",
      ]
  no_suppress_user32 = [  # Function name case matters.
      "LEAK\nuser32.dll!FOO\nuser32.dll!BAR\nuser32.dll!BAZ\n",
      "LEAK\nUSER32.DLL!FOO\nUSER32.DLL!BAR\nUSER32.DLL!BAZ\n",
      ]
  TestStack(stack_user32_mixed_case, suppress_user32, no_suppress_user32,
            suppression_parser=ReadDrMemorySuppressions)

  # Test mod!... frames.
  stack_kernel32_through_ntdll = """{
    LEAK
    name=<insert>
    kernel32.dll!foo
    KERNEL32.dll!bar
    kernel32.DLL!baz
    ntdll.dll!quux
  }"""
  suppress_mod_ellipsis = [
      "LEAK\nkernel32.dll!...\nntdll.dll!quux\n",
      "LEAK\nKERNEL32.DLL!...\nntdll.dll!quux\n",
      ]
  no_suppress_mod_ellipsis = [
      # Need one or more matching frames, not zero, unlike regular ellipsis.
      "LEAK\nuser32.dll!...\nkernel32.dll!...\nntdll.dll!quux\n",
      ]
  TestStack(stack_kernel32_through_ntdll, suppress_mod_ellipsis,
            no_suppress_mod_ellipsis,
            suppression_parser=ReadDrMemorySuppressions)

  # Test that the presubmit checks work.
  forgot_to_name = """
    UNADDRESSABLE ACCESS
    name=<insert_a_suppression_name_here>
    ntdll.dll!RtlTryEnterCriticalSection
  """
  TestFailPresubmit(forgot_to_name, 'forgotten to put a suppression',
                    suppression_parser=ReadDrMemorySuppressions)

  named_twice = """
    UNADDRESSABLE ACCESS
    name=http://crbug.com/1234
    *!foo

    UNADDRESSABLE ACCESS
    name=http://crbug.com/1234
    *!bar
  """
  TestFailPresubmit(named_twice, 'defined more than once',
                    suppression_parser=ReadDrMemorySuppressions)

  forgot_stack = """
    UNADDRESSABLE ACCESS
    name=http://crbug.com/1234
  """
  TestFailPresubmit(forgot_stack, 'has no stack frames',
                    suppression_parser=ReadDrMemorySuppressions)

  ends_in_ellipsis = """
    UNADDRESSABLE ACCESS
    name=http://crbug.com/1234
    ntdll.dll!RtlTryEnterCriticalSection
    ...
  """
  TestFailPresubmit(ends_in_ellipsis, 'ends in an ellipsis',
                    suppression_parser=ReadDrMemorySuppressions)

  bad_stack_frame = """
    UNADDRESSABLE ACCESS
    name=http://crbug.com/1234
    fun:memcheck_style_frame
  """
  TestFailPresubmit(bad_stack_frame, 'Unexpected stack frame pattern',
                    suppression_parser=ReadDrMemorySuppressions)

  # Test FilenameToTool.
  filenames_to_tools = {
    "tools/valgrind/drmemory/suppressions.txt": "drmemory",
    "tools/valgrind/drmemory/suppressions_full.txt": "drmemory",
    "tools/valgrind/memcheck/suppressions.txt": "memcheck",
    "tools/valgrind/memcheck/suppressions_mac.txt": "memcheck",
    "asdf/tools/valgrind/memcheck/suppressions_mac.txt": "memcheck",
    "foo/bar/baz/tools/valgrind/memcheck/suppressions_mac.txt": "memcheck",
    "foo/bar/baz/tools/valgrind/suppressions.txt": None,
    "tools/valgrind/suppressions.txt": None,
  }
  for (filename, expected_tool) in filenames_to_tools.items():
    filename.replace('/', os.sep)  # Make the path look native.
    tool = FilenameToTool(filename)
    assert tool == expected_tool, (
        "failed to get expected tool for filename %r, expected %s, got %s" %
        (filename, expected_tool, tool))

  # Test ValgrindStyleSuppression.__str__.
  supp = ValgrindStyleSuppression("http://crbug.com/1234", "Memcheck:Leak",
                                  ["...", "fun:foo"], "supp.txt:1")
  # Intentional 3-space indent.  =/
  supp_str = ("{\n"
              "   http://crbug.com/1234\n"
              "   Memcheck:Leak\n"
              "   ...\n"
              "   fun:foo\n"
              "}\n")
  assert str(supp) == supp_str, (
      "str(supp) != supp_str:\nleft: %s\nright: %s" % (str(supp), supp_str))

  # Test DrMemorySuppression.__str__.
  supp = DrMemorySuppression(
      "http://crbug.com/1234", "LEAK", None, ["...", "*!foo"], "supp.txt:1")
  supp_str = ("LEAK\n"
              "name=http://crbug.com/1234\n"
              "...\n"
              "*!foo\n")
  assert str(supp) == supp_str, (
      "str(supp) != supp_str:\nleft: %s\nright: %s" % (str(supp), supp_str))

  supp = DrMemorySuppression(
      "http://crbug.com/1234", "UNINITIALIZED READ", "test 0x08(%eax) $0x01",
      ["ntdll.dll!*", "*!foo"], "supp.txt:1")
  supp_str = ("UNINITIALIZED READ\n"
              "name=http://crbug.com/1234\n"
              "instruction=test 0x08(%eax) $0x01\n"
              "ntdll.dll!*\n"
              "*!foo\n")
  assert str(supp) == supp_str, (
      "str(supp) != supp_str:\nleft: %s\nright: %s" % (str(supp), supp_str))


if __name__ == '__main__':
  SelfTest()
  print 'PASS'
