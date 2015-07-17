#!/usr/bin/python
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

"""Module for looking up symbolic debugging information.

The information can include symbol names, offsets, and source locations.
"""

import glob
import itertools
import logging
import os
import re
import struct
import subprocess
import zipfile

CHROME_SRC = os.path.join(os.path.realpath(os.path.dirname(__file__)),
                          os.pardir, os.pardir, os.pardir, os.pardir)
ANDROID_BUILD_TOP = CHROME_SRC
SYMBOLS_DIR = CHROME_SRC
CHROME_SYMBOLS_DIR = CHROME_SRC

ARCH = "arm"

TOOLCHAIN_INFO = None

# See:
# http://bugs.python.org/issue14315
# https://hg.python.org/cpython/rev/6dd5e9556a60#l2.8
def PatchZipFile():
  oldDecodeExtra = zipfile.ZipInfo._decodeExtra
  def decodeExtra(self):
    try:
      oldDecodeExtra(self)
    except struct.error:
      pass
  zipfile.ZipInfo._decodeExtra = decodeExtra
PatchZipFile()

def Uname():
  """'uname' for constructing prebuilt/<...> and out/host/<...> paths."""
  uname = os.uname()[0]
  if uname == "Darwin":
    proc = os.uname()[-1]
    if proc == "i386" or proc == "x86_64":
      return "darwin-x86"
    return "darwin-ppc"
  if uname == "Linux":
    return "linux-x86"
  return uname

def ToolPath(tool, toolchain_info=None):
  """Return a full qualified path to the specified tool"""
  # ToolPath looks for the tools in the completely incorrect directory.
  # This looks in the checked in android_tools.
  if ARCH == "arm":
    toolchain_source = "arm-linux-androideabi-4.9"
    toolchain_prefix = "arm-linux-androideabi"
    ndk = "ndk"
  elif ARCH == "arm64":
    toolchain_source = "aarch64-linux-android-4.9"
    toolchain_prefix = "aarch64-linux-android"
    ndk = "ndk"
  elif ARCH == "x86":
    toolchain_source = "x86-4.9"
    toolchain_prefix = "i686-linux-android"
    ndk = "ndk"
  elif ARCH == "x86_64" or ARCH == "x64":
    toolchain_source = "x86_64-4.9"
    toolchain_prefix = "x86_64-linux-android"
    ndk = "ndk"
  elif ARCH == "mips":
    toolchain_source = "mipsel-linux-android-4.9"
    toolchain_prefix = "mipsel-linux-android"
    ndk = "ndk"
  else:
    raise Exception("Could not find tool chain")

  toolchain_subdir = (
      "third_party/android_tools/%s/toolchains/%s/prebuilt/linux-x86_64/bin" %
       (ndk, toolchain_source))

  return os.path.join(CHROME_SRC,
                      toolchain_subdir,
                      toolchain_prefix + "-" + tool)

def FindToolchain():
  """Look for the latest available toolchain

  Args:
    None

  Returns:
    A pair of strings containing toolchain label and target prefix.
  """
  global TOOLCHAIN_INFO
  if TOOLCHAIN_INFO is not None:
    return TOOLCHAIN_INFO

  ## Known toolchains, newer ones in the front.
  gcc_version = "4.9"
  if ARCH == "arm64":
    known_toolchains = [
      ("aarch64-linux-android-" + gcc_version, "aarch64", "aarch64-linux-android")
    ]
  elif ARCH == "arm":
    known_toolchains = [
      ("arm-linux-androideabi-" + gcc_version, "arm", "arm-linux-androideabi")
    ]
  elif ARCH =="x86":
    known_toolchains = [
      ("x86-" + gcc_version, "x86", "i686-linux-android")
    ]
  elif ARCH =="x86_64" or ARCH =="x64":
    known_toolchains = [
      ("x86_64-" + gcc_version, "x86_64", "x86_64-linux-android")
    ]
  elif ARCH == "mips":
    known_toolchains = [
      ("mipsel-linux-android-" + gcc_version, "mips", "mipsel-linux-android")
    ]
  else:
    known_toolchains = []

  logging.debug('FindToolcahin: known_toolchains=%s' % known_toolchains)
  # Look for addr2line to check for valid toolchain path.
  for (label, platform, target) in known_toolchains:
    toolchain_info = (label, platform, target);
    if os.path.exists(ToolPath("addr2line", toolchain_info)):
      TOOLCHAIN_INFO = toolchain_info
      print "Using toolchain from :" + ToolPath("", TOOLCHAIN_INFO)
      return toolchain_info

  raise Exception("Could not find tool chain")

def GetAapt():
  """Returns the path to aapt.

  Args:
    None

  Returns:
    the pathname of the 'aapt' executable.
  """
  sdk_home = os.path.join('third_party', 'android_tools', 'sdk')
  sdk_home = os.environ.get('SDK_HOME', sdk_home)
  aapt_exe = glob.glob(os.path.join(sdk_home, 'build-tools', '*', 'aapt'))
  if not aapt_exe:
    return None
  return sorted(aapt_exe, key=os.path.getmtime, reverse=True)[0]

def ApkMatchPackageName(aapt, apk_path, package_name):
  """Returns true the APK's package name matches package_name.

  Args:
    aapt: pathname for the 'aapt' executable.
    apk_path: pathname of the APK file.
    package_name: package name to match.

  Returns:
    True if the package name matches or aapt is None, False otherwise.
  """
  if not aapt:
    # Allow false positives
    return True
  aapt_output = subprocess.check_output(
      [aapt, 'dump', 'badging', apk_path]).split('\n')
  package_name_re = re.compile(r'package: .*name=\'(\S*)\'')
  for line in aapt_output:
    match = package_name_re.match(line)
    if match:
      return package_name == match.group(1)
  return False

def PathListJoin(prefix_list, suffix_list):
   """Returns each prefix in prefix_list joined with each suffix in suffix list.

   Args:
     prefix_list: list of path prefixes.
     suffix_list: list of path suffixes.

   Returns:
     List of paths each of which joins a prefix with a suffix.
   """
   return [
       os.path.join(prefix, suffix)
       for prefix in prefix_list for suffix in suffix_list ]

def GetCandidates(dirs, filepart, candidate_fun):
  """Returns a list of candidate filenames.

  Args:
    dirs: a list of the directory part of the pathname.
    filepart: the file part of the pathname.
    candidate_fun: a function to apply to each candidate, returns a list.

  Returns:
    A list of candidate files ordered by modification time, newest first.
  """
  out_dir = os.environ.get('CHROMIUM_OUT_DIR', 'out')
  out_dir = os.path.join(CHROME_SYMBOLS_DIR, out_dir)
  buildtype = os.environ.get('BUILDTYPE')
  if buildtype:
    buildtype_list = [ buildtype ]
  else:
    buildtype_list = [ 'Debug', 'Release' ]

  candidates = PathListJoin([out_dir], buildtype_list) + [CHROME_SYMBOLS_DIR]
  candidates = PathListJoin(candidates, dirs)
  candidates = PathListJoin(candidates, [filepart])
  logging.debug('GetCandidates: prefiltered candidates = %s' % candidates)
  candidates = list(
      itertools.chain.from_iterable(map(candidate_fun, candidates)))
  candidates = sorted(candidates, key=os.path.getmtime, reverse=True)
  return candidates

def GetCandidateApks():
  """Returns a list of APKs which could contain the library.

  Args:
    None

  Returns:
    list of APK filename which could contain the library.
  """
  return GetCandidates(['apks'], '*.apk', glob.glob)

def GetCrazyLib(apk_filename):
  """Returns the name of the first crazy library from this APK.

  Args:
    apk_filename: name of an APK file.

  Returns:
    Name of the first library which would be crazy loaded from this APK.
  """
  zip_file = zipfile.ZipFile(apk_filename, 'r')
  for filename in zip_file.namelist():
    match = re.match('lib/[^/]*/crazy.(lib.*[.]so)', filename)
    if match:
      return match.group(1)

def GetApkFromLibrary(device_library_path):
  match = re.match(r'.*/([^/]*)-[0-9]+(\/[^/]*)?\.apk$', device_library_path)
  if not match:
    return None
  return match.group(1)

def GetMatchingApks(package_name):
  """Find any APKs which match the package indicated by the device_apk_name.

  Args:
     device_apk_name: name of the APK on the device.

  Returns:
     A list of APK filenames which could contain the desired library.
  """
  return filter(
      lambda candidate_apk:
          ApkMatchPackageName(GetAapt(), candidate_apk, package_name),
      GetCandidateApks())

def MapDeviceApkToLibrary(device_apk_name):
  """Provide a library name which corresponds with device_apk_name.

  Args:
    device_apk_name: name of the APK on the device.

  Returns:
    Name of the library which corresponds to that APK.
  """
  matching_apks = GetMatchingApks(device_apk_name)
  logging.debug('MapDeviceApkToLibrary: matching_apks=%s' % matching_apks)
  for matching_apk in matching_apks:
    crazy_lib = GetCrazyLib(matching_apk)
    if crazy_lib:
      return crazy_lib

def GetCandidateLibraries(library_name):
  """Returns a list of candidate library filenames.

  Args:
    library_name: basename of the library to match.

  Returns:
    A list of matching library filenames for library_name.
  """
  return GetCandidates(
      ['lib', 'lib.target', '.'], library_name,
      lambda filename: filter(os.path.exists, [filename]))

def TranslateLibPath(lib):
  # The filename in the stack trace maybe an APK name rather than a library
  # name. This happens when the library was loaded directly from inside the
  # APK. If this is the case we try to figure out the library name by looking
  # for a matching APK file and finding the name of the library in contains.
  # The name of the APK file on the device is of the form
  # <package_name>-<number>.apk. The APK file on the host may have any name
  # so we look at the APK badging to see if the package name matches.
  apk = GetApkFromLibrary(lib)
  if apk is not None:
    logging.debug('TranslateLibPath: apk=%s' % apk)
    mapping = MapDeviceApkToLibrary(apk)
    if mapping:
      lib = mapping

  # SymbolInformation(lib, addr) receives lib as the path from symbols
  # root to the symbols file. This needs to be translated to point to the
  # correct .so path. If the user doesn't explicitly specify which directory to
  # use, then use the most recently updated one in one of the known directories.
  # If the .so is not found somewhere in CHROME_SYMBOLS_DIR, leave it
  # untranslated in case it is an Android symbol in SYMBOLS_DIR.
  library_name = os.path.basename(lib)

  logging.debug('TranslateLibPath: lib=%s library_name=%s' % (lib, library_name))

  candidate_libraries = GetCandidateLibraries(library_name)
  logging.debug('TranslateLibPath: candidate_libraries=%s' % candidate_libraries)
  if not candidate_libraries:
    return lib

  library_path = os.path.relpath(candidate_libraries[0], SYMBOLS_DIR)
  logging.debug('TranslateLibPath: library_path=%s' % library_path)
  return '/' + library_path

def SymbolInformation(lib, addr, get_detailed_info):
  """Look up symbol information about an address.

  Args:
    lib: library (or executable) pathname containing symbols
    addr: string hexidecimal address

  Returns:
    A list of the form [(source_symbol, source_location,
    object_symbol_with_offset)].

    If the function has been inlined then the list may contain
    more than one element with the symbols for the most deeply
    nested inlined location appearing first.  The list is
    always non-empty, even if no information is available.

    Usually you want to display the source_location and
    object_symbol_with_offset from the last element in the list.
  """
  lib = TranslateLibPath(lib)
  info = SymbolInformationForSet(lib, set([addr]), get_detailed_info)
  return (info and info.get(addr)) or [(None, None, None)]


def SymbolInformationForSet(lib, unique_addrs, get_detailed_info):
  """Look up symbol information for a set of addresses from the given library.

  Args:
    lib: library (or executable) pathname containing symbols
    unique_addrs: set of hexidecimal addresses

  Returns:
    A dictionary of the form {addr: [(source_symbol, source_location,
    object_symbol_with_offset)]} where each address has a list of
    associated symbols and locations.  The list is always non-empty.

    If the function has been inlined then the list may contain
    more than one element with the symbols for the most deeply
    nested inlined location appearing first.  The list is
    always non-empty, even if no information is available.

    Usually you want to display the source_location and
    object_symbol_with_offset from the last element in the list.
  """
  if not lib:
    return None

  addr_to_line = CallAddr2LineForSet(lib, unique_addrs)
  if not addr_to_line:
    return None

  if get_detailed_info:
    addr_to_objdump = CallObjdumpForSet(lib, unique_addrs)
    if not addr_to_objdump:
      return None
  else:
    addr_to_objdump = dict((addr, ("", 0)) for addr in unique_addrs)

  result = {}
  for addr in unique_addrs:
    source_info = addr_to_line.get(addr)
    if not source_info:
      source_info = [(None, None)]
    if addr in addr_to_objdump:
      (object_symbol, object_offset) = addr_to_objdump.get(addr)
      object_symbol_with_offset = FormatSymbolWithOffset(object_symbol,
                                                         object_offset)
    else:
      object_symbol_with_offset = None
    result[addr] = [(source_symbol, source_location, object_symbol_with_offset)
        for (source_symbol, source_location) in source_info]

  return result


class MemoizedForSet(object):
  def __init__(self, fn):
    self.fn = fn
    self.cache = {}

  def __call__(self, lib, unique_addrs):
    lib_cache = self.cache.setdefault(lib, {})

    no_cache = filter(lambda x: x not in lib_cache, unique_addrs)
    if no_cache:
      lib_cache.update((k, None) for k in no_cache)
      result = self.fn(lib, no_cache)
      if result:
        lib_cache.update(result)

    return dict((k, lib_cache[k]) for k in unique_addrs if lib_cache[k])


@MemoizedForSet
def CallAddr2LineForSet(lib, unique_addrs):
  """Look up line and symbol information for a set of addresses.

  Args:
    lib: library (or executable) pathname containing symbols
    unique_addrs: set of string hexidecimal addresses look up.

  Returns:
    A dictionary of the form {addr: [(symbol, file:line)]} where
    each address has a list of associated symbols and locations
    or an empty list if no symbol information was found.

    If the function has been inlined then the list may contain
    more than one element with the symbols for the most deeply
    nested inlined location appearing first.
  """
  if not lib:
    return None


  symbols = SYMBOLS_DIR + lib
  if not os.path.splitext(symbols)[1] in ['', '.so', '.apk']:
    return None

  if not os.path.isfile(symbols):
    return None

  (label, platform, target) = FindToolchain()
  cmd = [ToolPath("addr2line"), "--functions", "--inlines",
      "--demangle", "--exe=" + symbols]
  child = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)

  result = {}
  addrs = sorted(unique_addrs)
  for addr in addrs:
    child.stdin.write("0x%s\n" % addr)
    child.stdin.flush()
    records = []
    first = True
    while True:
      symbol = child.stdout.readline().strip()
      if symbol == "??":
        symbol = None
      location = child.stdout.readline().strip()
      if location == "??:0":
        location = None
      if symbol is None and location is None:
        break
      records.append((symbol, location))
      if first:
        # Write a blank line as a sentinel so we know when to stop
        # reading inlines from the output.
        # The blank line will cause addr2line to emit "??\n??:0\n".
        child.stdin.write("\n")
        first = False
    result[addr] = records
  child.stdin.close()
  child.stdout.close()
  return result


def StripPC(addr):
  """Strips the Thumb bit a program counter address when appropriate.

  Args:
    addr: the program counter address

  Returns:
    The stripped program counter address.
  """
  global ARCH

  if ARCH == "arm":
    return addr & ~1
  return addr

@MemoizedForSet
def CallObjdumpForSet(lib, unique_addrs):
  """Use objdump to find out the names of the containing functions.

  Args:
    lib: library (or executable) pathname containing symbols
    unique_addrs: set of string hexidecimal addresses to find the functions for.

  Returns:
    A dictionary of the form {addr: (string symbol, offset)}.
  """
  if not lib:
    return None

  symbols = SYMBOLS_DIR + lib
  if not os.path.exists(symbols):
    return None

  symbols = SYMBOLS_DIR + lib
  if not os.path.exists(symbols):
    return None

  result = {}

  # Function lines look like:
  #   000177b0 <android::IBinder::~IBinder()+0x2c>:
  # We pull out the address and function first. Then we check for an optional
  # offset. This is tricky due to functions that look like "operator+(..)+0x2c"
  func_regexp = re.compile("(^[a-f0-9]*) \<(.*)\>:$")
  offset_regexp = re.compile("(.*)\+0x([a-f0-9]*)")

  # A disassembly line looks like:
  #   177b2:  b510        push  {r4, lr}
  asm_regexp = re.compile("(^[ a-f0-9]*):[ a-f0-0]*.*$")

  for target_addr in unique_addrs:
    start_addr_dec = str(StripPC(int(target_addr, 16)))
    stop_addr_dec = str(StripPC(int(target_addr, 16)) + 8)
    cmd = [ToolPath("objdump"),
           "--section=.text",
           "--demangle",
           "--disassemble",
           "--start-address=" + start_addr_dec,
           "--stop-address=" + stop_addr_dec,
           symbols]

    current_symbol = None    # The current function symbol in the disassembly.
    current_symbol_addr = 0  # The address of the current function.

    stream = subprocess.Popen(cmd, stdout=subprocess.PIPE).stdout
    for line in stream:
      # Is it a function line like:
      #   000177b0 <android::IBinder::~IBinder()>:
      components = func_regexp.match(line)
      if components:
        # This is a new function, so record the current function and its address.
        current_symbol_addr = int(components.group(1), 16)
        current_symbol = components.group(2)

        # Does it have an optional offset like: "foo(..)+0x2c"?
        components = offset_regexp.match(current_symbol)
        if components:
          current_symbol = components.group(1)
          offset = components.group(2)
          if offset:
            current_symbol_addr -= int(offset, 16)

      # Is it an disassembly line like:
      #   177b2:  b510        push  {r4, lr}
      components = asm_regexp.match(line)
      if components:
        addr = components.group(1)
        i_addr = int(addr, 16)
        i_target = StripPC(int(target_addr, 16))
        if i_addr == i_target:
          result[target_addr] = (current_symbol, i_target - current_symbol_addr)
    stream.close()

  return result


def CallCppFilt(mangled_symbol):
  cmd = [ToolPath("c++filt")]
  process = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
  process.stdin.write(mangled_symbol)
  process.stdin.write("\n")
  process.stdin.close()
  demangled_symbol = process.stdout.readline().strip()
  process.stdout.close()
  return demangled_symbol

def FormatSymbolWithOffset(symbol, offset):
  if offset == 0:
    return symbol
  return "%s+%d" % (symbol, offset)
