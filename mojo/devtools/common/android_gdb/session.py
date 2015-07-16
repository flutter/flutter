# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Manages a debugging session with GDB.

This module is meant to be imported from inside GDB. Once loaded, the
|DebugSession| attaches GDB to a running Mojo Shell process on an Android
device using a remote gdbserver.

At startup and each time the execution stops, |DebugSession| associates
debugging symbols for every frame. For more information, see |DebugSession|
documentation.
"""

import gdb
import glob
import itertools
import logging
import os
import os.path
import shutil
import subprocess
import sys
import tempfile
import traceback

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import android_gdb.config as config
from android_gdb.remote_file_connection import RemoteFileConnection
from android_gdb.signatures import get_signature


logging.getLogger().setLevel(logging.INFO)


def _gdb_execute(command):
  """Executes a GDB command."""
  return gdb.execute(command, to_string=True)


class Mapping(object):
  """Represents a mapped memory region."""
  def __init__(self, line):
    self.start = int(line[0], 16)
    self.end = int(line[1], 16)
    self.size = int(line[2], 16)
    self.offset = int(line[3], 16)
    self.filename = line[4]


def _get_mapped_files():
  """Retrieves all the files mapped into the debugged process memory.

  Returns:
    List of mapped memory regions grouped by files.
  """
  # info proc map returns a space-separated table with the following fields:
  # start address, end address, size, offset, file path.
  mappings = [Mapping(x) for x in
              [x.split() for x in
               _gdb_execute("info proc map").split('\n')]
              if len(x) == 5 and x[4][0] == '/']
  res = {}
  for m in mappings:
    libname = m.filename[m.filename.rfind('/') + 1:]
    res[libname] = res.get(libname, []) + [m]
  return res.values()


class DebugSession(object):
  def __init__(self, build_directory, package_name, pyelftools_dir=None,
               adb='adb'):
    self._build_directory = build_directory
    if not os.path.exists(self._build_directory):
      logging.fatal("Please pass a valid build directory")
      sys.exit(1)
    self._package_name = package_name
    self._adb = adb
    self._remote_file_cache = os.path.join(os.getenv('HOME'), '.mojosymbols')

    if pyelftools_dir != None:
      sys.path.append(pyelftools_dir)
    try:
      import elftools.elf.elffile as elffile
    except ImportError:
      logging.fatal("Unable to find elftools module; please install it "
                    "(for exmple, using 'pip install elftools')")
      sys.exit(1)

    self._elffile_module = elffile

    self._libraries = self._find_libraries(build_directory)
    self._rfc = RemoteFileConnection('localhost', 10000)
    self._remote_file_reader_process = None
    if not os.path.exists(self._remote_file_cache):
      os.makedirs(self._remote_file_cache)
    self._done_mapping = set()
    self._downloaded_files = []

  def __del__(self):
    # Note that, per python interpreter documentation, __del__ is not
    # guaranteed to be called when the interpreter (GDB, in our case) quits.
    # Also, most (all?) globals are no longer available at this time (launching
    # a subprocess does not work).
    self.stop()

  def stop(self, _unused_return_value=None):
    if self._remote_file_reader_process != None:
      self._remote_file_reader_process.kill()

  def _find_libraries(self, lib_dir):
    """Finds all libraries in |lib_dir| and key them by their signatures.
    """
    res = {}
    for fn in glob.glob('%s/*.so' % lib_dir):
      with open(fn, 'r') as f:
        s = get_signature(f, self._elffile_module)
        if s is not None:
          res[s] = fn
    return res

  def _associate_symbols(self, mapping, local_file):
    with open(local_file, "r") as f:
      elf = self._elffile_module.ELFFile(f)
      s = elf.get_section_by_name(".text")
      text_address = mapping[0].start + s['sh_offset']
      _gdb_execute("add-symbol-file %s 0x%x" % (local_file, text_address))

  def _download_file(self, remote):
    """Downloads a remote file through GDB connection.

    Returns:
      The filename of the downloaded file
    """
    temp_file = tempfile.NamedTemporaryFile()
    logging.info("Downloading file %s" % remote)
    _gdb_execute("remote get %s %s" % (remote, temp_file.name))
    # This allows the deletion of temporary files on disk when the debugging
    # session terminates.
    self._downloaded_files.append(temp_file)
    return temp_file.name

  def _download_and_associate_symbol(self, mapping):
    self._associate_symbols(mapping, self._download_file(mapping[0].filename))

  def _find_mapping_for_address(self, mappings, address):
    """Returns the list of all mappings of the file occupying the |address|
    memory address.
    """
    for file_mappings in mappings:
      for mapping in file_mappings:
        if address >= mapping.start and address <= mapping.end:
          return file_mappings
    return None

  def _try_to_map(self, mapping):
    remote_file = mapping[0].filename
    if remote_file in self._done_mapping:
      return False
    self._done_mapping.add(remote_file)
    self._rfc.open(remote_file)
    signature = get_signature(self._rfc, self._elffile_module)
    if signature is not None:
      if signature in self._libraries:
        self._associate_symbols(mapping, self._libraries[signature])
      else:
        # This library file is not known locally. Download it from the device
        # and put it in cache so, if it got symbols, we can see them.
        local_file = os.path.join(self._remote_file_cache, signature)
        if not os.path.exists(local_file):
          tmp_output = self._download_file(remote_file)
          shutil.move(tmp_output, local_file)
        self._associate_symbols(mapping, local_file)
      return True
    return False

  def _update_symbols(self):
    """Updates the mapping between symbols as seen from GDB and local library
    files."""
    logging.info("Updating symbols")
    mapped_files = _get_mapped_files()
    _gdb_execute("info threads")
    nb_threads = len(_gdb_execute("info threads").split("\n")) - 2
    # Map all symbols from native libraries packages with the APK.
    for file_mappings in mapped_files:
      filename = file_mappings[0].filename
      if ((filename.startswith('/data/data/') or
           filename.startswith('/data/app')) and
          not filename.endswith('.apk') and
          not filename.endswith('.dex')):
        logging.info('Pre-mapping: %s' % file_mappings[0].filename)
        self._try_to_map(file_mappings)
    for i in xrange(nb_threads):
      try:
        _gdb_execute("thread %d" % (i + 1))
        frame = gdb.newest_frame()
        while frame and frame.is_valid():
          if frame.name() is None:
            m = self._find_mapping_for_address(mapped_files, frame.pc())
            if m is not None and self._try_to_map(m):
              # Force gdb to recompute its frames.
              _gdb_execute("info threads")
              frame = gdb.newest_frame()
              assert frame.is_valid()
          if (frame.older() is not None and
              frame.older().is_valid() and
              frame.older().pc() != frame.pc()):
            frame = frame.older()
          else:
            frame = None
      except gdb.error:
        traceback.print_exc()

  def _get_device_application_pid(self, application):
    """Gets the PID of an application running on a device."""
    output = subprocess.check_output([self._adb, 'shell', 'ps'])
    for line in output.split('\n'):
      elements = line.split()
      if len(elements) > 0 and elements[-1] == application:
        return elements[1]
    return None

  def start(self):
    """Starts a debugging session."""
    gdbserver_pid = self._get_device_application_pid('gdbserver')
    if gdbserver_pid is not None:
      subprocess.check_call([self._adb, 'shell', 'kill', gdbserver_pid])
    shell_pid = self._get_device_application_pid(self._package_name)
    if shell_pid is None:
      raise Exception('Unable to find a running mojo shell.')
    subprocess.check_call([self._adb, 'forward', 'tcp:9999', 'tcp:9999'])
    subprocess.Popen(
        [self._adb, 'shell', 'gdbserver', '--attach', ':9999', shell_pid],
        # os.setpgrp ensures signals passed to this file (such as SIGINT) are
        # not propagated to child processes.
        preexec_fn = os.setpgrp)

    # Kill stray remote reader processes. See __del__ comment for more info.
    remote_file_reader_pid = self._get_device_application_pid(
        config.REMOTE_FILE_READER_DEVICE_PATH)
    if remote_file_reader_pid is not None:
      subprocess.check_call([self._adb, 'shell', 'kill',
                             remote_file_reader_pid])
    self._remote_file_reader_process = subprocess.Popen(
        [self._adb, 'shell', config.REMOTE_FILE_READER_DEVICE_PATH],
        stdout=subprocess.PIPE, preexec_fn = os.setpgrp)
    port = int(self._remote_file_reader_process.stdout.readline())
    subprocess.check_call([self._adb, 'forward', 'tcp:10000', 'tcp:%d' % port])
    self._rfc.connect()

    _gdb_execute('target remote localhost:9999')

    self._update_symbols()
    def on_stop(_):
      self._update_symbols()
    gdb.events.stop.connect(on_stop)
    gdb.events.exited.connect(self.stop)
