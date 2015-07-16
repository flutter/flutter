# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import socket
import struct


class RemoteFileConnectionException(Exception):
  def __init__(self, *args, **kwargs):
    Exception.__init__(self, *args, **kwargs)


class RemoteFileConnection(object):
  """Client for remote_file_reader server, allowing to read files on an
  remote device.
  """
  def __init__(self, host, port):
    self._host = host
    self._port = port
    self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    self._size_struct = struct.Struct("!i")

  def __del__(self):
    self.disconnect()

  def connect(self):
    self._socket.connect((self._host, self._port))

  def disconnect(self):
    self._socket.close()

  def open(self, filename):
    self._send("O %s\n" % filename)
    result = self._receive(1)
    if result != 'O':
      raise RemoteFileConnectionException("Unable to open file " + filename)

  def seek(self, pos, mode=0):
    self._send("S %d %d\n" % (pos, mode))
    result = self._receive(1)
    if result != 'O':
      raise RemoteFileConnectionException("Unable to seek in file.")

  def read(self, size=0):
    assert size > 0
    self._send("R %d\n" % size)
    result = self._receive(1)
    if result != 'O':
      raise RemoteFileConnectionException("Unable to read file.")
    read_size = self._size_struct.unpack(self._receive(4))[0]
    return self._receive(read_size)

  def _send(self, data):
    while len(data) > 0:
      sent = self._socket.send(data)
      if sent == 0:
        raise RemoteFileConnectionException("Socket connection broken.")
      data = data[sent:]

  def _receive(self, length):
    result = []
    while length > 0:
      chunk = self._socket.recv(length)
      if chunk == '':
        raise RemoteFileConnectionException("Socket connection broken.")
      result.append(chunk)
      length -= len(chunk)
    return ''.join(result)
