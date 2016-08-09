# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Module to implement the SimpleXMLRPCServer module using JSON-RPC.

This module uses SimpleXMLRPCServer as the base and only overrides those
portions that implement the XML-RPC protocol. These portions are rewritten
to use the JSON-RPC protocol instead.

When large portions of code need to be rewritten the original code and
comments are preserved. The intention here is to keep the amount of code
change to a minimum.

This module only depends on default Python modules, as well as jsonrpclib
which also uses only default modules. No third party code is required to
use this module.
"""
import fcntl
import json
import SimpleXMLRPCServer as _base
import SocketServer
import sys
import traceback
try:
  import gzip
except ImportError:
  gzip = None #python can be built without zlib/gzip support

#pylint: disable=relative-import
import jsonrpclib


class SimpleJSONRPCRequestHandler(_base.SimpleXMLRPCRequestHandler):
  """Request handler class for received requests.

  This class extends the functionality of SimpleXMLRPCRequestHandler and only
  overrides the operations needed to change the protocol from XML-RPC to
  JSON-RPC.
  """

  def do_POST(self):
    """Handles the HTTP POST request.

    Attempts to interpret all HTTP POST requests as JSON-RPC calls,
    which are forwarded to the server's _dispatch method for handling.
    """
    # Check that the path is legal
    if not self.is_rpc_path_valid():
      self.report_404()
      return

    try:
      # Get arguments by reading body of request.
      # We read this in chunks to avoid straining
      # socket.read(); around the 10 or 15Mb mark, some platforms
      # begin to have problems (bug #792570).
      max_chunk_size = 10*1024*1024
      size_remaining = int(self.headers['content-length'])
      data = []
      while size_remaining:
        chunk_size = min(size_remaining, max_chunk_size)
        chunk = self.rfile.read(chunk_size)
        if not chunk:
          break
        data.append(chunk)
        size_remaining -= len(data[-1])
      data = ''.join(data)
      data = self.decode_request_content(data)

      if data is None:
        return  # response has been sent

      # In previous versions of SimpleXMLRPCServer, _dispatch
      # could be overridden in this class, instead of in
      # SimpleXMLRPCDispatcher. To maintain backwards compatibility,
      # check to see if a subclass implements _dispatch and dispatch
      # using that method if present.
      response = self.server._marshaled_dispatch(
          data, getattr(self, '_dispatch', None), self.path)

    except Exception, e: # This should only happen if the module is buggy
      # internal error, report as HTTP server error
      self.send_response(500)
      # Send information about the exception if requested
      if (hasattr(self.server, '_send_traceback_header') and
          self.server._send_traceback_header):
        self.send_header('X-exception', str(e))
        self.send_header('X-traceback', traceback.format_exc())

      self.send_header('Content-length', '0')
      self.end_headers()
    else:
      # got a valid JSON RPC response
      self.send_response(200)
      self.send_header('Content-type', 'application/json')

      if self.encode_threshold is not None:
        if len(response) > self.encode_threshold:
          q = self.accept_encodings().get('gzip', 0)
          if q:
            try:
              response = jsonrpclib.gzip_encode(response)
              self.send_header('Content-Encoding', 'gzip')
            except NotImplementedError:
              pass

      self.send_header('Content-length', str(len(response)))
      self.end_headers()
      self.wfile.write(response)


class SimpleJSONRPCDispatcher(_base.SimpleXMLRPCDispatcher):
  """Dispatcher for received JSON-RPC requests.

  This class extends the functionality of SimpleXMLRPCDispatcher and only
  overrides the operations needed to change the protocol from XML-RPC to
  JSON-RPC.
  """

  def _marshaled_dispatch(self, data, dispatch_method=None, path=None):
    """Dispatches an JSON-RPC method from marshalled (JSON) data.

    JSON-RPC methods are dispatched from the marshalled (JSON) data
    using the _dispatch method and the result is returned as
    marshalled data. For backwards compatibility, a dispatch
    function can be provided as an argument (see comment in
    SimpleJSONRPCRequestHandler.do_POST) but overriding the
    existing method through subclassing is the preferred means
    of changing method dispatch behavior.

    Returns:
      The JSON-RPC string to return.
    """
    method = ''
    params = []
    ident = ''
    try:
      request = json.loads(data)
      jsonrpclib.ValidateRequest(request)
      method = request['method']
      params = request['params']
      ident = request['id']

      # generate response
      if dispatch_method is not None:
        response = dispatch_method(method, params)
      else:
        response = self._dispatch(method, params)
      response = jsonrpclib.CreateResponseString(response, ident)

    except jsonrpclib.Fault as fault:
      response = jsonrpclib.CreateResponseString(fault, ident)

    # Catch all exceptions here as they should be raised on the caller side.
    except:  #pylint: disable=bare-except
      # report exception back to server
      exc_type, exc_value, _ = sys.exc_info()
      response = jsonrpclib.CreateResponseString(
          jsonrpclib.Fault(1, '%s:%s' % (exc_type, exc_value)), ident)
    return response


class SimpleJSONRPCServer(SocketServer.TCPServer,
                          SimpleJSONRPCDispatcher):
  """Simple JSON-RPC server.

  This class mimics the functionality of SimpleXMLRPCServer and only
  overrides the operations needed to change the protocol from XML-RPC to
  JSON-RPC.
  """

  allow_reuse_address = True

  # Warning: this is for debugging purposes only! Never set this to True in
  # production code, as will be sending out sensitive information (exception
  # and stack trace details) when exceptions are raised inside
  # SimpleJSONRPCRequestHandler.do_POST
  _send_traceback_header = False

  def __init__(self, addr, requestHandler=SimpleJSONRPCRequestHandler,
               logRequests=True, allow_none=False, encoding=None,
               bind_and_activate=True):
    self.logRequests = logRequests
    SimpleJSONRPCDispatcher.__init__(self, allow_none, encoding)
    SocketServer.TCPServer.__init__(self, addr, requestHandler,
                                    bind_and_activate)

    # [Bug #1222790] If possible, set close-on-exec flag; if a
    # method spawns a subprocess, the subprocess shouldn't have
    # the listening socket open.
    if fcntl is not None and hasattr(fcntl, 'FD_CLOEXEC'):
      flags = fcntl.fcntl(self.fileno(), fcntl.F_GETFD)
      flags |= fcntl.FD_CLOEXEC
      fcntl.fcntl(self.fileno(), fcntl.F_SETFD, flags)
