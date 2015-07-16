# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines the task RPC methods."""

import logging
import os
import sys
import threading

#pylint: disable=relative-import
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
