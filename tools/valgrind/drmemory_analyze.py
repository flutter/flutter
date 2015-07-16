#!/usr/bin/env python
# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# drmemory_analyze.py

''' Given a Dr. Memory output file, parses errors and uniques them.'''

from collections import defaultdict
import common
import hashlib
import logging
import optparse
import os
import re
import subprocess
import sys
import time

class DrMemoryError:
  def __init__(self, report, suppression, testcase):
    self._report = report
    self._testcase = testcase

    # Chromium-specific transformations of the suppressions:
    # Replace 'any_test.exe' and 'chrome.dll' with '*', then remove the
    # Dr.Memory-generated error ids from the name= lines as they don't
    # make sense in a multiprocess report.
    supp_lines = suppression.split("\n")
    for l in xrange(len(supp_lines)):
      if supp_lines[l].startswith("name="):
        supp_lines[l] = "name=<insert_a_suppression_name_here>"
      if supp_lines[l].startswith("chrome.dll!"):
        supp_lines[l] = supp_lines[l].replace("chrome.dll!", "*!")
      bang_index = supp_lines[l].find("!")
      d_exe_index = supp_lines[l].find(".exe!")
      if bang_index >= 4 and d_exe_index + 4 == bang_index:
        supp_lines[l] = "*" + supp_lines[l][bang_index:]
    self._suppression = "\n".join(supp_lines)

  def __str__(self):
    output = ""
    output += "### BEGIN MEMORY TOOL REPORT (error hash=#%016X#)\n" % \
        self.ErrorHash()
    output += self._report + "\n"
    if self._testcase:
      output += "The report came from the `%s` test.\n" % self._testcase
    output += "Suppression (error hash=#%016X#):\n" % self.ErrorHash()
    output += ("  For more info on using suppressions see "
        "http://dev.chromium.org/developers/how-tos/using-drmemory#TOC-Suppressing-error-reports-from-the-\n")
    output += "{\n%s\n}\n" % self._suppression
    output += "### END MEMORY TOOL REPORT (error hash=#%016X#)\n" % \
        self.ErrorHash()
    return output

  # This is a device-independent hash identifying the suppression.
  # By printing out this hash we can find duplicate reports between tests and
  # different shards running on multiple buildbots
  def ErrorHash(self):
    return int(hashlib.md5(self._suppression).hexdigest()[:16], 16)

  def __hash__(self):
    return hash(self._suppression)

  def __eq__(self, rhs):
    return self._suppression == rhs


class DrMemoryAnalyzer:
  ''' Given a set of Dr.Memory output files, parse all the errors out of
  them, unique them and output the results.'''

  def __init__(self):
    self.known_errors = set()
    self.error_count = 0;

  def ReadLine(self):
    self.line_ = self.cur_fd_.readline()

  def ReadSection(self):
    result = [self.line_]
    self.ReadLine()
    while len(self.line_.strip()) > 0:
      result.append(self.line_)
      self.ReadLine()
    return result

  def ParseReportFile(self, filename, testcase):
    ret = []

    # First, read the generated suppressions file so we can easily lookup a
    # suppression for a given error.
    supp_fd = open(filename.replace("results", "suppress"), 'r')
    generated_suppressions = {}  # Key -> Error #, Value -> Suppression text.
    for line in supp_fd:
      # NOTE: this regexp looks fragile. Might break if the generated
      # suppression format slightly changes.
      m = re.search("# Suppression for Error #([0-9]+)", line.strip())
      if not m:
        continue
      error_id = int(m.groups()[0])
      assert error_id not in generated_suppressions
      # OK, now read the next suppression:
      cur_supp = ""
      for supp_line in supp_fd:
        if supp_line.startswith("#") or supp_line.strip() == "":
          break
        cur_supp += supp_line
      generated_suppressions[error_id] = cur_supp.strip()
    supp_fd.close()

    self.cur_fd_ = open(filename, 'r')
    while True:
      self.ReadLine()
      if (self.line_ == ''): break

      match = re.search("^Error #([0-9]+): (.*)", self.line_)
      if match:
        error_id = int(match.groups()[0])
        self.line_ = match.groups()[1].strip() + "\n"
        report = "".join(self.ReadSection()).strip()
        suppression = generated_suppressions[error_id]
        ret.append(DrMemoryError(report, suppression, testcase))

      if re.search("SUPPRESSIONS USED:", self.line_):
        self.ReadLine()
        while self.line_.strip() != "":
          line = self.line_.strip()
          (count, name) = re.match(" *([0-9\?]+)x(?: \(.*?\))?: (.*)",
                                   line).groups()
          if (count == "?"):
            # Whole-module have no count available: assume 1
            count = 1
          else:
            count = int(count)
          self.used_suppressions[name] += count
          self.ReadLine()

      if self.line_.startswith("ASSERT FAILURE"):
        ret.append(self.line_.strip())

    self.cur_fd_.close()
    return ret

  def Report(self, filenames, testcase, check_sanity):
    sys.stdout.flush()
    # TODO(timurrrr): support positive tests / check_sanity==True
    self.used_suppressions = defaultdict(int)

    to_report = []
    reports_for_this_test = set()
    for f in filenames:
      cur_reports = self.ParseReportFile(f, testcase)

      # Filter out the reports that were there in previous tests.
      for r in cur_reports:
        if r in reports_for_this_test:
          # A similar report is about to be printed for this test.
          pass
        elif r in self.known_errors:
          # A similar report has already been printed in one of the prev tests.
          to_report.append("This error was already printed in some "
                           "other test, see 'hash=#%016X#'" % r.ErrorHash())
          reports_for_this_test.add(r)
        else:
          self.known_errors.add(r)
          reports_for_this_test.add(r)
          to_report.append(r)

    common.PrintUsedSuppressionsList(self.used_suppressions)

    if not to_report:
      logging.info("PASS: No error reports found")
      return 0

    sys.stdout.flush()
    sys.stderr.flush()
    logging.info("Found %i error reports" % len(to_report))
    for report in to_report:
      self.error_count += 1
      logging.info("Report #%d\n%s" % (self.error_count, report))
    logging.info("Total: %i error reports" % len(to_report))
    sys.stdout.flush()
    return -1


def main():
  '''For testing only. The DrMemoryAnalyze class should be imported instead.'''
  parser = optparse.OptionParser("usage: %prog <files to analyze>")

  (options, args) = parser.parse_args()
  if len(args) == 0:
    parser.error("no filename specified")
  filenames = args

  logging.getLogger().setLevel(logging.INFO)
  return DrMemoryAnalyzer().Report(filenames, None, False)


if __name__ == '__main__':
  sys.exit(main())
