# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The task RPC server code.

This server is an XML-RPC server which serves code from
rpc_methods.RPCMethods.

This server will run until shutdown is called on the server object. This can
be achieved in 2 ways:

- Calling the Quit RPC method defined in RPCMethods
- Not receiving any calls within the idle_timeout_secs time.
"""

import logging
import threading
import time
import SocketServer

#pylint: disable=relative-import
import common_lib
import rpc_methods
import ssl_util
import SimpleJSONRPCServer


class RequestHandler(SimpleJSONRPCServer.SimpleJSONRPCRequestHandler):
  """Restricts access to only specified IP address.

  This call assumes the server is RPCServer.
  """

  def do_POST(self):
    """Verifies the task is authorized to perform RPCs."""
    if self.client_address[0] != self.server.authorized_address:
      logging.error('Received unauthorized RPC request from %s',
                    self.task_address[0])
      self.send_response(403)
      response = 'Forbidden'
      self.send_header('Content-type', 'text/plain')
      self.send_header('Content-length', str(len(response)))
      self.end_headers()
      self.wfile.write(response)
    else:
      return SimpleJSONRPCServer.SimpleJSONRPCRequestHandler.do_POST(self)


class RpcServer(ssl_util.SslRpcServer,
                SocketServer.ThreadingMixIn):
  """Restricts all endpoints to only specified IP addresses."""

  def __init__(self, authorized_address,
               idle_timeout_secs=common_lib.DEFAULT_TIMEOUT_SECS):
    ssl_util.SslRpcServer.__init__(
        self, (common_lib.SERVER_ADDRESS, common_lib.SERVER_PORT),
        allow_none=True, logRequests=False,
        requestHandler=RequestHandler)
    self.authorized_address = authorized_address
    self.idle_timeout_secs = idle_timeout_secs
    self.register_instance(rpc_methods.RPCMethods(self))

    self._shutdown_requested_event = threading.Event()
    self._rpc_received_event = threading.Event()
    self._idle_thread = threading.Thread(target=self._CheckForIdleQuit)

  def shutdown(self):
    """Shutdown the server.

    This overloaded method sets the _shutdown_requested_event to allow the
    idle timeout thread to quit.
    """
    self._shutdown_requested_event.set()
    SimpleJSONRPCServer.SimpleJSONRPCServer.shutdown(self)
    logging.info('Server shutdown complete')

  def serve_forever(self, poll_interval=0.5):
    """Serve forever.

    This overloaded method starts the idle timeout thread before calling
    serve_forever. This ensures the idle timer thread doesn't get started
    without the server running.

    Args:
      poll_interval: The interval to poll for shutdown.
    """
    logging.info('RPC server starting')
    self._idle_thread.start()
    SimpleJSONRPCServer.SimpleJSONRPCServer.serve_forever(self, poll_interval)

  def _dispatch(self, method, params):
    """Dispatch the call to the correct method with the provided params.

    This overloaded method adds logging to help trace connection and
    call problems.

    Args:
      method: The method name to call.
      params: A tuple of parameters to pass.

    Returns:
      The result of the parent class' _dispatch method.
    """
    logging.debug('Calling %s%s', method, params)
    self._rpc_received_event.set()
    return SimpleJSONRPCServer.SimpleJSONRPCServer._dispatch(
        self, method, params)

  def _CheckForIdleQuit(self):
    """Check for, and exit, if the server is idle for too long.

    This method must be run in a separate thread to avoid a deadlock when
    calling server.shutdown.
    """
    timeout = time.time() + self.idle_timeout_secs
    while time.time() < timeout:
      if self._shutdown_requested_event.is_set():
        # An external source called shutdown()
        return
      elif self._rpc_received_event.is_set():
        logging.debug('Resetting the idle timeout')
        timeout = time.time() + self.idle_timeout_secs
        self._rpc_received_event.clear()
      time.sleep(1)
    # We timed out, kill the server
    logging.warning('Shutting down the server due to the idle timeout')
    self.shutdown()
