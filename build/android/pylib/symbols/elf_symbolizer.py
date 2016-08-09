# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import collections
import datetime
import logging
import multiprocessing
import os
import posixpath
import Queue
import re
import subprocess
import sys
import threading
import time


# addr2line builds a possibly infinite memory cache that can exhaust
# the computer's memory if allowed to grow for too long. This constant
# controls how many lookups we do before restarting the process. 4000
# gives near peak performance without extreme memory usage.
ADDR2LINE_RECYCLE_LIMIT = 4000


class ELFSymbolizer(object):
  """An uber-fast (multiprocessing, pipelined and asynchronous) ELF symbolizer.

  This class is a frontend for addr2line (part of GNU binutils), designed to
  symbolize batches of large numbers of symbols for a given ELF file. It
  supports sharding symbolization against many addr2line instances and
  pipelining of multiple requests per each instance (in order to hide addr2line
  internals and OS pipe latencies).

  The interface exhibited by this class is a very simple asynchronous interface,
  which is based on the following three methods:
  - SymbolizeAsync(): used to request (enqueue) resolution of a given address.
  - The |callback| method: used to communicated back the symbol information.
  - Join(): called to conclude the batch to gather the last outstanding results.
  In essence, before the Join method returns, this class will have issued as
  many callbacks as the number of SymbolizeAsync() calls. In this regard, note
  that due to multiprocess sharding, callbacks can be delivered out of order.

  Some background about addr2line:
  - it is invoked passing the elf path in the cmdline, piping the addresses in
    its stdin and getting results on its stdout.
  - it has pretty large response times for the first requests, but it
    works very well in streaming mode once it has been warmed up.
  - it doesn't scale by itself (on more cores). However, spawning multiple
    instances at the same time on the same file is pretty efficient as they
    keep hitting the pagecache and become mostly CPU bound.
  - it might hang or crash, mostly for OOM. This class deals with both of these
    problems.

  Despite the "scary" imports and the multi* words above, (almost) no multi-
  threading/processing is involved from the python viewpoint. Concurrency
  here is achieved by spawning several addr2line subprocesses and handling their
  output pipes asynchronously. Therefore, all the code here (with the exception
  of the Queue instance in Addr2Line) should be free from mind-blowing
  thread-safety concerns.

  The multiprocess sharding works as follows:
  The symbolizer tries to use the lowest number of addr2line instances as
  possible (with respect of |max_concurrent_jobs|) and enqueue all the requests
  in a single addr2line instance. For few symbols (i.e. dozens) sharding isn't
  worth the startup cost.
  The multiprocess logic kicks in as soon as the queues for the existing
  instances grow. Specifically, once all the existing instances reach the
  |max_queue_size| bound, a new addr2line instance is kicked in.
  In the case of a very eager producer (i.e. all |max_concurrent_jobs| instances
  have a backlog of |max_queue_size|), back-pressure is applied on the caller by
  blocking the SymbolizeAsync method.

  This module has been deliberately designed to be dependency free (w.r.t. of
  other modules in this project), to allow easy reuse in external projects.
  """

  def __init__(self, elf_file_path, addr2line_path, callback, inlines=False,
      max_concurrent_jobs=None, addr2line_timeout=30, max_queue_size=50,
      source_root_path=None, strip_base_path=None):
    """Args:
      elf_file_path: path of the elf file to be symbolized.
      addr2line_path: path of the toolchain's addr2line binary.
      callback: a callback which will be invoked for each resolved symbol with
          the two args (sym_info, callback_arg). The former is an instance of
          |ELFSymbolInfo| and contains the symbol information. The latter is an
          embedder-provided argument which is passed to SymbolizeAsync().
      inlines: when True, the ELFSymbolInfo will contain also the details about
          the outer inlining functions. When False, only the innermost function
          will be provided.
      max_concurrent_jobs: Max number of addr2line instances spawned.
          Parallelize responsibly, addr2line is a memory and I/O monster.
      max_queue_size: Max number of outstanding requests per addr2line instance.
      addr2line_timeout: Max time (in seconds) to wait for a addr2line response.
          After the timeout, the instance will be considered hung and respawned.
      source_root_path: In some toolchains only the name of the source file is
          is output, without any path information; disambiguation searches
          through the source directory specified by |source_root_path| argument
          for files whose name matches, adding the full path information to the
          output. For example, if the toolchain outputs "unicode.cc" and there
          is a file called "unicode.cc" located under |source_root_path|/foo,
          the tool will replace "unicode.cc" with
          "|source_root_path|/foo/unicode.cc". If there are multiple files with
          the same name, disambiguation will fail because the tool cannot
          determine which of the files was the source of the symbol.
      strip_base_path: Rebases the symbols source paths onto |source_root_path|
          (i.e replace |strip_base_path| with |source_root_path).
    """
    assert(os.path.isfile(addr2line_path)), 'Cannot find ' + addr2line_path
    self.elf_file_path = elf_file_path
    self.addr2line_path = addr2line_path
    self.callback = callback
    self.inlines = inlines
    self.max_concurrent_jobs = (max_concurrent_jobs or
                                min(multiprocessing.cpu_count(), 4))
    self.max_queue_size = max_queue_size
    self.addr2line_timeout = addr2line_timeout
    self.requests_counter = 0  # For generating monotonic request IDs.
    self._a2l_instances = []  # Up to |max_concurrent_jobs| _Addr2Line inst.

    # If necessary, create disambiguation lookup table
    self.disambiguate = source_root_path is not None
    self.disambiguation_table = {}
    self.strip_base_path = strip_base_path
    if(self.disambiguate):
      self.source_root_path = os.path.abspath(source_root_path)
      self._CreateDisambiguationTable()

    # Create one addr2line instance. More instances will be created on demand
    # (up to |max_concurrent_jobs|) depending on the rate of the requests.
    self._CreateNewA2LInstance()

  def SymbolizeAsync(self, addr, callback_arg=None):
    """Requests symbolization of a given address.

    This method is not guaranteed to return immediately. It generally does, but
    in some scenarios (e.g. all addr2line instances have full queues) it can
    block to create back-pressure.

    Args:
      addr: address to symbolize.
      callback_arg: optional argument which will be passed to the |callback|."""
    assert(isinstance(addr, int))

    # Process all the symbols that have been resolved in the meanwhile.
    # Essentially, this drains all the addr2line(s) out queues.
    for a2l_to_purge in self._a2l_instances:
      a2l_to_purge.ProcessAllResolvedSymbolsInQueue()
      a2l_to_purge.RecycleIfNecessary()

    # Find the best instance according to this logic:
    # 1. Find an existing instance with the shortest queue.
    # 2. If all of instances' queues are full, but there is room in the pool,
    #    (i.e. < |max_concurrent_jobs|) create a new instance.
    # 3. If there were already |max_concurrent_jobs| instances and all of them
    #    had full queues, make back-pressure.

    # 1.
    def _SortByQueueSizeAndReqID(a2l):
      return (a2l.queue_size, a2l.first_request_id)
    a2l = min(self._a2l_instances, key=_SortByQueueSizeAndReqID)

    # 2.
    if (a2l.queue_size >= self.max_queue_size and
        len(self._a2l_instances) < self.max_concurrent_jobs):
      a2l = self._CreateNewA2LInstance()

    # 3.
    if a2l.queue_size >= self.max_queue_size:
      a2l.WaitForNextSymbolInQueue()

    a2l.EnqueueRequest(addr, callback_arg)

  def Join(self):
    """Waits for all the outstanding requests to complete and terminates."""
    for a2l in self._a2l_instances:
      a2l.WaitForIdle()
      a2l.Terminate()

  def _CreateNewA2LInstance(self):
    assert(len(self._a2l_instances) < self.max_concurrent_jobs)
    a2l = ELFSymbolizer.Addr2Line(self)
    self._a2l_instances.append(a2l)
    return a2l

  def _CreateDisambiguationTable(self):
    """ Non-unique file names will result in None entries"""
    start_time = time.time()
    logging.info('Collecting information about available source files...')
    self.disambiguation_table = {}

    for root, _, filenames in os.walk(self.source_root_path):
      for f in filenames:
        self.disambiguation_table[f] = os.path.join(root, f) if (f not in
                                       self.disambiguation_table) else None
    logging.info('Finished collecting information about '
                 'possible files (took %.1f s).',
                 (time.time() - start_time))


  class Addr2Line(object):
    """A python wrapper around an addr2line instance.

    The communication with the addr2line process looks as follows:
      [STDIN]         [STDOUT]  (from addr2line's viewpoint)
    > f001111
    > f002222
                    < Symbol::Name(foo, bar) for f001111
                    < /path/to/source/file.c:line_number
    > f003333
                    < Symbol::Name2() for f002222
                    < /path/to/source/file.c:line_number
                    < Symbol::Name3() for f003333
                    < /path/to/source/file.c:line_number
    """

    SYM_ADDR_RE = re.compile(r'([^:]+):(\?|\d+).*')

    def __init__(self, symbolizer):
      self._symbolizer = symbolizer
      self._lib_file_name = posixpath.basename(symbolizer.elf_file_path)

      # The request queue (i.e. addresses pushed to addr2line's stdin and not
      # yet retrieved on stdout)
      self._request_queue = collections.deque()

      # This is essentially len(self._request_queue). It has been optimized to a
      # separate field because turned out to be a perf hot-spot.
      self.queue_size = 0

      # Keep track of the number of symbols a process has processed to
      # avoid a single process growing too big and using all the memory.
      self._processed_symbols_count = 0

      # Objects required to handle the addr2line subprocess.
      self._proc = None  # Subprocess.Popen(...) instance.
      self._thread = None  # Threading.thread instance.
      self._out_queue = None  # Queue.Queue instance (for buffering a2l stdout).
      self._RestartAddr2LineProcess()

    def EnqueueRequest(self, addr, callback_arg):
      """Pushes an address to addr2line's stdin (and keeps track of it)."""
      self._symbolizer.requests_counter += 1  # For global "age" of requests.
      req_idx = self._symbolizer.requests_counter
      self._request_queue.append((addr, callback_arg, req_idx))
      self.queue_size += 1
      self._WriteToA2lStdin(addr)

    def WaitForIdle(self):
      """Waits until all the pending requests have been symbolized."""
      while self.queue_size > 0:
        self.WaitForNextSymbolInQueue()

    def WaitForNextSymbolInQueue(self):
      """Waits for the next pending request to be symbolized."""
      if not self.queue_size:
        return

      # This outer loop guards against a2l hanging (detecting stdout timeout).
      while True:
        start_time = datetime.datetime.now()
        timeout = datetime.timedelta(seconds=self._symbolizer.addr2line_timeout)

        # The inner loop guards against a2l crashing (checking if it exited).
        while (datetime.datetime.now() - start_time < timeout):
          # poll() returns !None if the process exited. a2l should never exit.
          if self._proc.poll():
            logging.warning('addr2line crashed, respawning (lib: %s).' %
                            self._lib_file_name)
            self._RestartAddr2LineProcess()
            # TODO(primiano): the best thing to do in this case would be
            # shrinking the pool size as, very likely, addr2line is crashed
            # due to low memory (and the respawned one will die again soon).

          try:
            lines = self._out_queue.get(block=True, timeout=0.25)
          except Queue.Empty:
            # On timeout (1/4 s.) repeat the inner loop and check if either the
            # addr2line process did crash or we waited its output for too long.
            continue

          # In nominal conditions, we get straight to this point.
          self._ProcessSymbolOutput(lines)
          return

        # If this point is reached, we waited more than |addr2line_timeout|.
        logging.warning('Hung addr2line process, respawning (lib: %s).' %
                        self._lib_file_name)
        self._RestartAddr2LineProcess()

    def ProcessAllResolvedSymbolsInQueue(self):
      """Consumes all the addr2line output lines produced (without blocking)."""
      if not self.queue_size:
        return
      while True:
        try:
          lines = self._out_queue.get_nowait()
        except Queue.Empty:
          break
        self._ProcessSymbolOutput(lines)

    def RecycleIfNecessary(self):
      """Restarts the process if it has been used for too long.

      A long running addr2line process will consume excessive amounts
      of memory without any gain in performance."""
      if self._processed_symbols_count >= ADDR2LINE_RECYCLE_LIMIT:
        self._RestartAddr2LineProcess()


    def Terminate(self):
      """Kills the underlying addr2line process.

      The poller |_thread| will terminate as well due to the broken pipe."""
      try:
        self._proc.kill()
        self._proc.communicate()  # Essentially wait() without risking deadlock.
      except Exception:  # An exception while terminating? How interesting.
        pass
      self._proc = None

    def _WriteToA2lStdin(self, addr):
      self._proc.stdin.write('%s\n' % hex(addr))
      if self._symbolizer.inlines:
        # In the case of inlines we output an extra blank line, which causes
        # addr2line to emit a (??,??:0) tuple that we use as a boundary marker.
        self._proc.stdin.write('\n')
      self._proc.stdin.flush()

    def _ProcessSymbolOutput(self, lines):
      """Parses an addr2line symbol output and triggers the client callback."""
      (_, callback_arg, _) = self._request_queue.popleft()
      self.queue_size -= 1

      innermost_sym_info = None
      sym_info = None
      for (line1, line2) in lines:
        prev_sym_info = sym_info
        name = line1 if not line1.startswith('?') else None
        source_path = None
        source_line = None
        m = ELFSymbolizer.Addr2Line.SYM_ADDR_RE.match(line2)
        if m:
          if not m.group(1).startswith('?'):
            source_path = m.group(1)
            if not m.group(2).startswith('?'):
              source_line = int(m.group(2))
        else:
          logging.warning('Got invalid symbol path from addr2line: %s' % line2)

        # In case disambiguation is on, and needed
        was_ambiguous = False
        disambiguated = False
        if self._symbolizer.disambiguate:
          if source_path and not posixpath.isabs(source_path):
            path = self._symbolizer.disambiguation_table.get(source_path)
            was_ambiguous = True
            disambiguated = path is not None
            source_path = path if disambiguated else source_path

          # Use absolute paths (so that paths are consistent, as disambiguation
          # uses absolute paths)
          if source_path and not was_ambiguous:
            source_path = os.path.abspath(source_path)

        if source_path and self._symbolizer.strip_base_path:
          # Strip the base path
          source_path = re.sub('^' + self._symbolizer.strip_base_path,
              self._symbolizer.source_root_path or '', source_path)

        sym_info = ELFSymbolInfo(name, source_path, source_line, was_ambiguous,
                                 disambiguated)
        if prev_sym_info:
          prev_sym_info.inlined_by = sym_info
        if not innermost_sym_info:
          innermost_sym_info = sym_info

      self._processed_symbols_count += 1
      self._symbolizer.callback(innermost_sym_info, callback_arg)

    def _RestartAddr2LineProcess(self):
      if self._proc:
        self.Terminate()

      # The only reason of existence of this Queue (and the corresponding
      # Thread below) is the lack of a subprocess.stdout.poll_avail_lines().
      # Essentially this is a pipe able to extract a couple of lines atomically.
      self._out_queue = Queue.Queue()

      # Start the underlying addr2line process in line buffered mode.

      cmd = [self._symbolizer.addr2line_path, '--functions', '--demangle',
          '--exe=' + self._symbolizer.elf_file_path]
      if self._symbolizer.inlines:
        cmd += ['--inlines']
      self._proc = subprocess.Popen(cmd, bufsize=1, stdout=subprocess.PIPE,
          stdin=subprocess.PIPE, stderr=sys.stderr, close_fds=True)

      # Start the poller thread, which simply moves atomically the lines read
      # from the addr2line's stdout to the |_out_queue|.
      self._thread = threading.Thread(
          target=ELFSymbolizer.Addr2Line.StdoutReaderThread,
          args=(self._proc.stdout, self._out_queue, self._symbolizer.inlines))
      self._thread.daemon = True  # Don't prevent early process exit.
      self._thread.start()

      self._processed_symbols_count = 0

      # Replay the pending requests on the new process (only for the case
      # of a hung addr2line timing out during the game).
      for (addr, _, _) in self._request_queue:
        self._WriteToA2lStdin(addr)

    @staticmethod
    def StdoutReaderThread(process_pipe, queue, inlines):
      """The poller thread fn, which moves the addr2line stdout to the |queue|.

      This is the only piece of code not running on the main thread. It merely
      writes to a Queue, which is thread-safe. In the case of inlines, it
      detects the ??,??:0 marker and sends the lines atomically, such that the
      main thread always receives all the lines corresponding to one symbol in
      one shot."""
      try:
        lines_for_one_symbol = []
        while True:
          line1 = process_pipe.readline().rstrip('\r\n')
          line2 = process_pipe.readline().rstrip('\r\n')
          if not line1 or not line2:
            break
          inline_has_more_lines = inlines and (len(lines_for_one_symbol) == 0 or
                                  (line1 != '??' and line2 != '??:0'))
          if not inlines or inline_has_more_lines:
            lines_for_one_symbol += [(line1, line2)]
          if inline_has_more_lines:
            continue
          queue.put(lines_for_one_symbol)
          lines_for_one_symbol = []
        process_pipe.close()

      # Every addr2line processes will die at some point, please die silently.
      except (IOError, OSError):
        pass

    @property
    def first_request_id(self):
      """Returns the request_id of the oldest pending request in the queue."""
      return self._request_queue[0][2] if self._request_queue else 0


class ELFSymbolInfo(object):
  """The result of the symbolization passed as first arg. of each callback."""

  def __init__(self, name, source_path, source_line, was_ambiguous=False,
               disambiguated=False):
    """All the fields here can be None (if addr2line replies with '??')."""
    self.name = name
    self.source_path = source_path
    self.source_line = source_line
    # In the case of |inlines|=True, the |inlined_by| points to the outer
    # function inlining the current one (and so on, to form a chain).
    self.inlined_by = None
    self.disambiguated = disambiguated
    self.was_ambiguous = was_ambiguous

  def __str__(self):
    return '%s [%s:%d]' % (
        self.name or '??', self.source_path or '??', self.source_line or 0)
