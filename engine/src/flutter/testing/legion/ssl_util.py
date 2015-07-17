# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility library to add SSL support to the RPC server."""

import logging
import ssl
import subprocess
import tempfile

#pylint: disable=relative-import
import common_lib
import jsonrpclib
import SimpleJSONRPCServer


class Error(Exception):
  pass


def CreateKeyFile():
  """Creates an SSL keyfile and returns the path."""
  keyfile = tempfile.mkstemp()[1]
  cmd = [
    'openssl',
    'genrsa',
    '-out', keyfile,
    '2048'
    ]
  _RunCommand(cmd)
  return keyfile


def CreateCsrFile(keyfile):
  """Creates an SSL CSR file and returns the path."""
  csrfile = tempfile.mkstemp()[1]
  cmd = [
      'openssl',
      'req',
      '-new',
      '-key', keyfile,
      '-out', csrfile,
      '-subj', '/C=NA/ST=NA/L=NA/O=Chromium/OU=Test/CN=chromium.org'
      ]
  _RunCommand(cmd)
  return csrfile


def CreateCrtFile(keyfile, csrfile):
  """Creates an SSL CRT file and returns the path."""
  crtfile = tempfile.mkstemp()[1]
  cmd = [
      'openssl',
      'x509',
      '-req',
      '-days', '1',
      '-in', csrfile,
      '-signkey', keyfile,
      '-out', crtfile
      ]
  _RunCommand(cmd)
  return crtfile


def CreatePemFile():
  """Creates an SSL PEM file and returns the path."""
  keyfile = CreateKeyFile()
  csrfile = CreateCsrFile(keyfile)
  crtfile = CreateCrtFile(keyfile, csrfile)
  pemfile = tempfile.mkstemp()[1]
  with open(keyfile) as k:
    with open(crtfile) as c:
      with open(pemfile, 'wb') as p:
        p.write('%s\n%s' % (k.read(), c.read()))
  return pemfile


def _RunCommand(cmd):
  try:
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  except OSError as e:
    raise Error('Failed to run %s: %s' % (' '.join(cmd), e))
  out, err = p.communicate()
  if p.returncode != 0:
    raise Error(err)
  return out


class SslRpcServer(SimpleJSONRPCServer.SimpleJSONRPCServer):
  """Class to add SSL support to the RPC server."""

  def __init__(self, *args, **kwargs):
    SimpleJSONRPCServer.SimpleJSONRPCServer.__init__(self, *args, **kwargs)
    self.socket = ssl.wrap_socket(self.socket, certfile=CreatePemFile(),
                                  server_side=True)

  @staticmethod
  def Connect(server, port=common_lib.SERVER_PORT):
    """Creates and returns a connection to an SSL RPC server."""
    addr = 'https://%s:%d' % (server, port)
    logging.debug('Connecting to RPC server at %s', addr)
    return jsonrpclib.ServerProxy(addr, allow_none=True)
