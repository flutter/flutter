# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import atexit
import datetime
import email.utils
import errno
import hashlib
import logging
import math
import os.path
import socket
import threading

import SimpleHTTPServer
import SocketServer

_ZERO = datetime.timedelta(0)


class UTC_TZINFO(datetime.tzinfo):
  """UTC time zone representation."""

  def utcoffset(self, _):
    return _ZERO

  def tzname(self, _):
    return "UTC"

  def dst(self, _):
     return _ZERO

_UTC = UTC_TZINFO()


class _SilentTCPServer(SocketServer.TCPServer):
  """A TCPServer that won't display any error, unless debugging is enabled. This
  is useful because the client might stop while it is fetching an URL, which
  causes spurious error messages.
  """
  allow_reuse_address = True

  def handle_error(self, request, client_address):
    """Override the base class method to have conditional logging."""
    if logging.getLogger().isEnabledFor(logging.DEBUG):
      SocketServer.TCPServer.handle_error(self, request, client_address)


def _GetHandlerClassForPath(mappings):
  """Creates a handler override for SimpleHTTPServer.

  Args:
    mappings: List of tuples (prefix, local_base_path), mapping path prefixes
        without the leading slash to local filesystem directory paths. The first
        matching prefix will be used each time.
  """
  for prefix, _ in mappings:
    assert not prefix.startswith('/'), ('Prefixes for the http server mappings '
                                        'should skip the leading slash.')

  class RequestHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
    """Handler for SocketServer.TCPServer that will serve the files from
    local directiories over http.
    """

    def __init__(self, *args, **kwargs):
      self.etag = None
      SimpleHTTPServer.SimpleHTTPRequestHandler.__init__(self, *args, **kwargs)

    def get_etag(self):
      if self.etag:
        return self.etag

      path = self.translate_path(self.path)
      if not os.path.isfile(path):
        return None

      sha256 = hashlib.sha256()
      BLOCKSIZE = 65536
      with open(path, 'rb') as hashed:
        buf = hashed.read(BLOCKSIZE)
        while len(buf) > 0:
          sha256.update(buf)
          buf = hashed.read(BLOCKSIZE)
      self.etag = '"%s"' % sha256.hexdigest()
      return self.etag

    def send_head(self):
      # Always close the connection after each request, as the keep alive
      # support from SimpleHTTPServer doesn't like when the client requests to
      # close the connection before downloading the full response content.
      # pylint: disable=W0201
      self.close_connection = 1

      path = self.translate_path(self.path)
      if os.path.isfile(path):
        # Handle If-None-Match
        etag = self.get_etag()
        if ('If-None-Match' in self.headers and
            etag == self.headers['If-None-Match']):
          self.send_response(304)
          return None

        # Handle If-Modified-Since
        if ('If-None-Match' not in self.headers and
            'If-Modified-Since' in self.headers):
          last_modified = datetime.datetime.fromtimestamp(
              math.floor(os.stat(path).st_mtime), tz=_UTC)
          ims = datetime.datetime(
              *email.utils.parsedate(self.headers['If-Modified-Since'])[:6],
              tzinfo=_UTC)
          if last_modified <= ims:
            self.send_response(304)
            return None

      return SimpleHTTPServer.SimpleHTTPRequestHandler.send_head(self)

    def end_headers(self):
      path = self.translate_path(self.path)

      if os.path.isfile(path):
        etag = self.get_etag()
        if etag:
          self.send_header('ETag', etag)
          self.send_header('Cache-Control', 'must-revalidate')

      return SimpleHTTPServer.SimpleHTTPRequestHandler.end_headers(self)

    def translate_path(self, path):
      # Parent translate_path() will strip away the query string and fragment
      # identifier, but also will prepend the cwd to the path. relpath() gives
      # us the relative path back.
      normalized_path = os.path.relpath(
          SimpleHTTPServer.SimpleHTTPRequestHandler.translate_path(self, path))

      for prefix, local_base_path in mappings:
        if normalized_path.startswith(prefix):
          return os.path.join(local_base_path, normalized_path[len(prefix):])

      # This class is only used internally, and we're adding a catch-all ''
      # prefix at the end of |mappings|.
      assert False

    def guess_type(self, path):
      # This is needed so that Sky files without shebang can still run thanks to
      # content-type mappings.
      # TODO(ppi): drop this part once we can rely on the Sky files declaring
      # correct shebang.
      if path.endswith('.dart'):
        return 'application/dart'
      elif path.endswith('.sky'):
        return 'text/sky'
      return SimpleHTTPServer.SimpleHTTPRequestHandler.guess_type(self, path)

    def log_message(self, *_):
      """Override the base class method to disable logging."""
      pass

  RequestHandler.protocol_version = 'HTTP/1.1'
  return RequestHandler


def StartHttpServer(local_dir_path, host_port=0, additional_mappings=None):
  """Starts an http server serving files from |local_dir_path| on |host_port|.

  Args:
    local_dir_path: Path to the local filesystem directory to be served over
        http under.
    host_port: Port on the host machine to run the server on. Pass 0 to use a
        system-assigned port.
    additional_mappings: List of tuples (prefix, local_base_path) mapping
        URLs that start with |prefix| to local directory at |local_base_path|.
        The prefixes should skip the leading slash.

  Returns:
    Tuple of the server address and the port on which it runs.
  """
  assert local_dir_path
  mappings = additional_mappings if additional_mappings else []
  mappings.append(('', local_dir_path))
  handler_class = _GetHandlerClassForPath(mappings)

  try:
    httpd = _SilentTCPServer(('127.0.0.1', host_port), handler_class)
    atexit.register(httpd.shutdown)

    http_thread = threading.Thread(target=httpd.serve_forever)
    http_thread.daemon = True
    http_thread.start()
    print 'Started http://%s:%d to host %s.' % (httpd.server_address[0],
                                                httpd.server_address[1],
                                                local_dir_path)
    return httpd.server_address
  except socket.error as v:
    error_code = v[0]
    print 'Failed to start http server for %s on port %d: %s.' % (
        local_dir_path, host_port, os.strerror(error_code))
    if error_code == errno.EADDRINUSE:
      print ('  Run `fuser %d/tcp` to find out which process is using the port.'
             % host_port)
    print '---'
    raise
