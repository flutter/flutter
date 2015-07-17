# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines the task RPC methods."""

import logging
import os
import sys
import threading

#pylint: disable=relative-import
import common_lib
import process


class RPCMethods(object):
  """Class exposing RPC methods."""

  _dotted_whitelist = ['subprocess']

  def __init__(self, server):
    self._server = server
    self.subprocess = process.Process

  def _dispatch(self, method, params):
    obj = self
    if '.' in method:
      # Allow only white listed dotted names
      name, method = method.split('.')
      assert name in self._dotted_whitelist
      obj = getattr(self, name)
    return getattr(obj, method)(*params)

  def Echo(self, message):
    """Simple RPC method to print and return a message."""
    logging.info('Echoing %s', message)
    return 'echo %s' % str(message)

  def AbsPath(self, path):
    """Returns the absolute path."""
    return os.path.abspath(path)

  def Quit(self):
    """Call _server.shutdown in another thread.

    This is needed because server.shutdown waits for the server to actually
    quit. However the server cannot shutdown until it completes handling this
    call. Calling this in the same thread results in a deadlock.
    """
    t = threading.Thread(target=self._server.shutdown)
    t.start()

  def GetOutputDir(self):
    """Returns the isolated output directory on the task machine."""
    return common_lib.GetOutputDir()

  def WriteFile(self, path, text, mode='wb+'):
    """Writes a file on the task machine."""
    with open(path, mode) as fh:
      fh.write(text)

  def ReadFile(self, path, mode='rb'):
    """Reads a file from the local task machine."""
    with open(path, mode) as fh:
      return fh.read()

  def PathJoin(self, *parts):
    """Performs an os.path.join on the task machine.

    This is needed due to the fact that there is no guarantee that os.sep will
    be the same across all machines in a particular test. This method will
    join the path parts locally to ensure the correct separator is used.
    """
    return os.path.join(*parts)

  def ListDir(self, path):
    """Returns the results of os.listdir."""
    return os.listdir(path)
