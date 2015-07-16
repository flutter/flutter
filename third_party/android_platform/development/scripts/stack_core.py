#!/usr/bin/env python
#
# Copyright (C) 2013 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""stack symbolizes native crash dumps."""

import re

import symbol

def PrintTraceLines(trace_lines):
  """Print back trace."""
  maxlen = max(map(lambda tl: len(tl[1]), trace_lines))
  print
  print "Stack Trace:"
  print "  RELADDR   " + "FUNCTION".ljust(maxlen) + "  FILE:LINE"
  for tl in trace_lines:
    (addr, symbol_with_offset, location) = tl
    print "  %8s  %s  %s" % (addr, symbol_with_offset.ljust(maxlen), location)
  return


def PrintValueLines(value_lines):
  """Print stack data values."""
  maxlen = max(map(lambda tl: len(tl[2]), value_lines))
  print
  print "Stack Data:"
  print "  ADDR      VALUE     " + "FUNCTION".ljust(maxlen) + "  FILE:LINE"
  for vl in value_lines:
    (addr, value, symbol_with_offset, location) = vl
    print "  %8s  %8s  %s  %s" % (addr, value, symbol_with_offset.ljust(maxlen), location)
  return

UNKNOWN = "<unknown>"
HEAP = "[heap]"
STACK = "[stack]"


def PrintOutput(trace_lines, value_lines, more_info):
  if trace_lines:
    PrintTraceLines(trace_lines)
  if value_lines:
    # TODO(cjhopman): it seems that symbol.SymbolInformation always fails to
    # find information for addresses in value_lines in chrome libraries, and so
    # value_lines have little value to us and merely clutter the output.
    # Since information is sometimes contained in these lines (from system
    # libraries), don't completely disable them.
    if more_info:
      PrintValueLines(value_lines)

def PrintDivider():
  print
  print "-----------------------------------------------------\n"

def ConvertTrace(lines, more_info):
  """Convert strings containing native crash to a stack."""
  process_info_line = re.compile("(pid: [0-9]+, tid: [0-9]+.*)")
  signal_line = re.compile("(signal [0-9]+ \(.*\).*)")
  register_line = re.compile("(([ ]*[0-9a-z]{2} [0-9a-f]{8}){4})")
  thread_line = re.compile("(.*)(\-\-\- ){15}\-\-\-")
  dalvik_jni_thread_line = re.compile("(\".*\" prio=[0-9]+ tid=[0-9]+ NATIVE.*)")
  dalvik_native_thread_line = re.compile("(\".*\" sysTid=[0-9]+ nice=[0-9]+.*)")

  width = "{8}"
  if symbol.ARCH == "arm64" or symbol.ARCH == "x86_64":
    width = "{16}"

  # Matches LOG(FATAL) lines, like the following example:
  #   [FATAL:source_file.cc(33)] Check failed: !instances_.empty()
  log_fatal_line = re.compile("(\[FATAL\:.*\].*)$")

  # Note that both trace and value line matching allow for variable amounts of
  # whitespace (e.g. \t). This is because the we want to allow for the stack
  # tool to operate on AndroidFeedback provided system logs. AndroidFeedback
  # strips out double spaces that are found in tombsone files and logcat output.
  #
  # Examples of matched trace lines include lines from tombstone files like:
  #   #00  pc 001cf42e  /data/data/com.my.project/lib/libmyproject.so
  #   #00  pc 001cf42e  /data/data/com.my.project/lib/libmyproject.so (symbol)
  # Or lines from AndroidFeedback crash report system logs like:
  #   03-25 00:51:05.520 I/DEBUG ( 65): #00 pc 001cf42e /data/data/com.my.project/lib/libmyproject.so
  # Please note the spacing differences.
  trace_line = re.compile("(.*)\#(?P<frame>[0-9]+)[ \t]+(..)[ \t]+(0x)?(?P<address>[0-9a-f]{0,16})[ \t]+(?P<lib>[^\r\n \t]*)(?P<symbol_present> \((?P<symbol_name>.*)\))?")  # pylint: disable-msg=C6310

  # Matches lines emitted by src/base/debug/stack_trace_android.cc, like:
  #   #00 0x7324d92d /data/app-lib/org.chromium.native_test-1/libbase.cr.so+0x0006992d
  # This pattern includes the unused named capture groups <symbol_present> and
  # <symbol_name> so that it can interoperate with the |trace_line| regex.
  debug_trace_line = re.compile(
      '(.*)(?P<frame>\#[0-9]+ 0x[0-9a-f]' + width + ') '
      '(?P<lib>[^+]+)\+0x(?P<address>[0-9a-f]' + width + ')'
      '(?P<symbol_present>)(?P<symbol_name>)')

  # Examples of matched value lines include:
  #   bea4170c  8018e4e9  /data/data/com.my.project/lib/libmyproject.so
  #   bea4170c  8018e4e9  /data/data/com.my.project/lib/libmyproject.so (symbol)
  #   03-25 00:51:05.530 I/DEBUG ( 65): bea4170c 8018e4e9 /data/data/com.my.project/lib/libmyproject.so
  # Again, note the spacing differences.
  value_line = re.compile("(.*)([0-9a-f]" + width + ")[ \t]+([0-9a-f]" + width + ")[ \t]+([^\r\n \t]*)( \((.*)\))?")
  # Lines from 'code around' sections of the output will be matched before
  # value lines because otheriwse the 'code around' sections will be confused as
  # value lines.
  #
  # Examples include:
  #   801cf40c ffffc4cc 00b2f2c5 00b2f1c7 00c1e1a8
  #   03-25 00:51:05.530 I/DEBUG ( 65): 801cf40c ffffc4cc 00b2f2c5 00b2f1c7 00c1e1a8
  code_line = re.compile("(.*)[ \t]*[a-f0-9]" + width +
                         "[ \t]*[a-f0-9]" + width +
                         "[ \t]*[a-f0-9]" + width +
                         "[ \t]*[a-f0-9]" + width +
                         "[ \t]*[a-f0-9]" + width +
                         "[ \t]*[ \r\n]")  # pylint: disable-msg=C6310

  trace_lines = []
  value_lines = []
  last_frame = -1

  # It is faster to get symbol information with a single call rather than with
  # separate calls for each line. Since symbol.SymbolInformation caches results,
  # we can extract all the addresses that we will want symbol information for
  # from the log and call symbol.SymbolInformation so that the results are
  # cached in the following lookups.
  code_addresses = {}
  for ln in lines:
    line = unicode(ln, errors='ignore')
    lib, address = None, None

    match = trace_line.match(line) or debug_trace_line.match(line)
    if match:
      address, lib = match.group('address', 'lib')

    match = value_line.match(line)
    if match and not code_line.match(line):
      (_0, _1, address, lib, _2, _3) = match.groups()

    if lib:
      code_addresses.setdefault(lib, set()).add(address)

  for lib in code_addresses:
    symbol.SymbolInformationForSet(
        symbol.TranslateLibPath(lib), code_addresses[lib], more_info)

  for ln in lines:
    # AndroidFeedback adds zero width spaces into its crash reports. These
    # should be removed or the regular expresssions will fail to match.
    line = unicode(ln, errors='ignore')
    process_header = process_info_line.search(line)
    signal_header = signal_line.search(line)
    register_header = register_line.search(line)
    thread_header = thread_line.search(line)
    dalvik_jni_thread_header = dalvik_jni_thread_line.search(line)
    dalvik_native_thread_header = dalvik_native_thread_line.search(line)
    log_fatal_header = log_fatal_line.search(line)
    if (process_header or signal_header or register_header or thread_header or
        dalvik_jni_thread_header or dalvik_native_thread_header or
        log_fatal_header) :
      if trace_lines or value_lines:
        PrintOutput(trace_lines, value_lines, more_info)
        PrintDivider()
        trace_lines = []
        value_lines = []
        last_frame = -1
      if process_header:
        print process_header.group(1)
      if signal_header:
        print signal_header.group(1)
      if register_header:
        print register_header.group(1)
      if thread_header:
        print thread_header.group(1)
      if dalvik_jni_thread_header:
        print dalvik_jni_thread_header.group(1)
      if dalvik_native_thread_header:
        print dalvik_native_thread_header.group(1)
      if log_fatal_header:
        print log_fatal_header.group(1)
      continue

    match = trace_line.match(line) or debug_trace_line.match(line)
    if match:
      frame, code_addr, area, symbol_present, symbol_name = match.group(
          'frame', 'address', 'lib', 'symbol_present', 'symbol_name')

      if frame <= last_frame and (trace_lines or value_lines):
        PrintOutput(trace_lines, value_lines, more_info)
        PrintDivider()
        trace_lines = []
        value_lines = []
      last_frame = frame

      if area == UNKNOWN or area == HEAP or area == STACK:
        trace_lines.append((code_addr, "", area))
      else:
        # If a calls b which further calls c and c is inlined to b, we want to
        # display "a -> b -> c" in the stack trace instead of just "a -> c"
        info = symbol.SymbolInformation(area, code_addr, more_info)
        nest_count = len(info) - 1
        for (source_symbol, source_location, object_symbol_with_offset) in info:
          if not source_symbol:
            if symbol_present:
              source_symbol = symbol.CallCppFilt(symbol_name)
            else:
              source_symbol = UNKNOWN
          if not source_location:
            source_location = area
          if nest_count > 0:
            nest_count = nest_count - 1
            trace_lines.append(("v------>", source_symbol, source_location))
          else:
            if not object_symbol_with_offset:
              object_symbol_with_offset = source_symbol
            trace_lines.append((code_addr,
                                object_symbol_with_offset,
                                source_location))
    if code_line.match(line):
      # Code lines should be ignored. If this were exluded the 'code around'
      # sections would trigger value_line matches.
      continue;
    match = value_line.match(line)
    if match:
      (unused_, addr, value, area, symbol_present, symbol_name) = match.groups()
      if area == UNKNOWN or area == HEAP or area == STACK or not area:
        value_lines.append((addr, value, "", area))
      else:
        info = symbol.SymbolInformation(area, value, more_info)
        (source_symbol, source_location, object_symbol_with_offset) = info.pop()
        if not source_symbol:
          if symbol_present:
            source_symbol = symbol.CallCppFilt(symbol_name)
          else:
            source_symbol = UNKNOWN
        if not source_location:
          source_location = area
        if not object_symbol_with_offset:
          object_symbol_with_offset = source_symbol
        value_lines.append((addr,
                            value,
                            object_symbol_with_offset,
                            source_location))

  PrintOutput(trace_lines, value_lines, more_info)
