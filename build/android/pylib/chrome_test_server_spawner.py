# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A "Test Server Spawner" that handles killing/stopping per-test test servers.

It's used to accept requests from the device to spawn and kill instances of the
chrome test server on the host.
"""
# pylint: disable=W0702

import BaseHTTPServer
import json
import logging
import os
import select
import struct
import subprocess
import sys
import threading
import time
import urlparse

from pylib import constants
from pylib import ports

from pylib.forwarder import Forwarder


# Path that are needed to import necessary modules when launching a testserver.
os.environ['PYTHONPATH'] = os.environ.get('PYTHONPATH', '') + (':%s:%s:%s:%s:%s'
    % (os.path.join(constants.DIR_SOURCE_ROOT, 'third_party'),
       os.path.join(constants.DIR_SOURCE_ROOT, 'third_party', 'tlslite'),
       os.path.join(constants.DIR_SOURCE_ROOT, 'third_party', 'pyftpdlib',
                    'src'),
       os.path.join(constants.DIR_SOURCE_ROOT, 'net', 'tools', 'testserver'),
       os.path.join(constants.DIR_SOURCE_ROOT, 'sync', 'tools', 'testserver')))


SERVER_TYPES = {
    'http': '',
    'ftp': '-f',
    'sync': '',  # Sync uses its own script, and doesn't take a server type arg.
    'tcpecho': '--tcp-echo',
    'udpecho': '--udp-echo',
}


# The timeout (in seconds) of starting up the Python test server.
TEST_SERVER_STARTUP_TIMEOUT = 10

def _WaitUntil(predicate, max_attempts=5):
  """Blocks until the provided predicate (function) is true.

  Returns:
    Whether the provided predicate was satisfied once (before the timeout).
  """
  sleep_time_sec = 0.025
  for _ in xrange(1, max_attempts):
    if predicate():
      return True
    time.sleep(sleep_time_sec)
    sleep_time_sec = min(1, sleep_time_sec * 2)  # Don't wait more than 1 sec.
  return False


def _CheckPortAvailable(port):
  """Returns True if |port| is available."""
  return _WaitUntil(lambda: ports.IsHostPortAvailable(port))


def _CheckPortNotAvailable(port):
  """Returns True if |port| is not available."""
  return _WaitUntil(lambda: not ports.IsHostPortAvailable(port))


def _CheckDevicePortStatus(device, port):
  """Returns whether the provided port is used."""
  return _WaitUntil(lambda: ports.IsDevicePortUsed(device, port))


def _GetServerTypeCommandLine(server_type):
  """Returns the command-line by the given server type.

  Args:
    server_type: the server type to be used (e.g. 'http').

  Returns:
    A string containing the command-line argument.
  """
  if server_type not in SERVER_TYPES:
    raise NotImplementedError('Unknown server type: %s' % server_type)
  if server_type == 'udpecho':
    raise Exception('Please do not run UDP echo tests because we do not have '
                    'a UDP forwarder tool.')
  return SERVER_TYPES[server_type]


class TestServerThread(threading.Thread):
  """A thread to run the test server in a separate process."""

  def __init__(self, ready_event, arguments, device, tool):
    """Initialize TestServerThread with the following argument.

    Args:
      ready_event: event which will be set when the test server is ready.
      arguments: dictionary of arguments to run the test server.
      device: An instance of DeviceUtils.
      tool: instance of runtime error detection tool.
    """
    threading.Thread.__init__(self)
    self.wait_event = threading.Event()
    self.stop_flag = False
    self.ready_event = ready_event
    self.ready_event.clear()
    self.arguments = arguments
    self.device = device
    self.tool = tool
    self.test_server_process = None
    self.is_ready = False
    self.host_port = self.arguments['port']
    assert isinstance(self.host_port, int)
    # The forwarder device port now is dynamically allocated.
    self.forwarder_device_port = 0
    # Anonymous pipe in order to get port info from test server.
    self.pipe_in = None
    self.pipe_out = None
    self.process = None
    self.command_line = []

  def _WaitToStartAndGetPortFromTestServer(self):
    """Waits for the Python test server to start and gets the port it is using.

    The port information is passed by the Python test server with a pipe given
    by self.pipe_out. It is written as a result to |self.host_port|.

    Returns:
      Whether the port used by the test server was successfully fetched.
    """
    assert self.host_port == 0 and self.pipe_out and self.pipe_in
    (in_fds, _, _) = select.select([self.pipe_in, ], [], [],
                                   TEST_SERVER_STARTUP_TIMEOUT)
    if len(in_fds) == 0:
      logging.error('Failed to wait to the Python test server to be started.')
      return False
    # First read the data length as an unsigned 4-byte value.  This
    # is _not_ using network byte ordering since the Python test server packs
    # size as native byte order and all Chromium platforms so far are
    # configured to use little-endian.
    # TODO(jnd): Change the Python test server and local_test_server_*.cc to
    # use a unified byte order (either big-endian or little-endian).
    data_length = os.read(self.pipe_in, struct.calcsize('=L'))
    if data_length:
      (data_length,) = struct.unpack('=L', data_length)
      assert data_length
    if not data_length:
      logging.error('Failed to get length of server data.')
      return False
    port_json = os.read(self.pipe_in, data_length)
    if not port_json:
      logging.error('Failed to get server data.')
      return False
    logging.info('Got port json data: %s', port_json)
    port_json = json.loads(port_json)
    if port_json.has_key('port') and isinstance(port_json['port'], int):
      self.host_port = port_json['port']
      return _CheckPortNotAvailable(self.host_port)
    logging.error('Failed to get port information from the server data.')
    return False

  def _GenerateCommandLineArguments(self):
    """Generates the command line to run the test server.

    Note that all options are processed by following the definitions in
    testserver.py.
    """
    if self.command_line:
      return

    args_copy = dict(self.arguments)

    # Translate the server type.
    type_cmd = _GetServerTypeCommandLine(args_copy.pop('server-type'))
    if type_cmd:
      self.command_line.append(type_cmd)

    # Use a pipe to get the port given by the instance of Python test server
    # if the test does not specify the port.
    assert self.host_port == args_copy['port']
    if self.host_port == 0:
      (self.pipe_in, self.pipe_out) = os.pipe()
      self.command_line.append('--startup-pipe=%d' % self.pipe_out)

    # Pass the remaining arguments as-is.
    for key, values in args_copy.iteritems():
      if not isinstance(values, list):
        values = [values]
      for value in values:
        if value is None:
          self.command_line.append('--%s' % key)
        else:
          self.command_line.append('--%s=%s' % (key, value))

  def _CloseUnnecessaryFDsForTestServerProcess(self):
    # This is required to avoid subtle deadlocks that could be caused by the
    # test server child process inheriting undesirable file descriptors such as
    # file lock file descriptors.
    for fd in xrange(0, 1024):
      if fd != self.pipe_out:
        try:
          os.close(fd)
        except:
          pass

  def run(self):
    logging.info('Start running the thread!')
    self.wait_event.clear()
    self._GenerateCommandLineArguments()
    command = constants.DIR_SOURCE_ROOT
    if self.arguments['server-type'] == 'sync':
      command = [os.path.join(command, 'sync', 'tools', 'testserver',
                              'sync_testserver.py')] + self.command_line
    else:
      command = [os.path.join(command, 'net', 'tools', 'testserver',
                              'testserver.py')] + self.command_line
    logging.info('Running: %s', command)
    # Pass DIR_SOURCE_ROOT as the child's working directory so that relative
    # paths in the arguments are resolved correctly.
    self.process = subprocess.Popen(
        command, preexec_fn=self._CloseUnnecessaryFDsForTestServerProcess,
        cwd=constants.DIR_SOURCE_ROOT)
    if self.process:
      if self.pipe_out:
        self.is_ready = self._WaitToStartAndGetPortFromTestServer()
      else:
        self.is_ready = _CheckPortNotAvailable(self.host_port)
    if self.is_ready:
      Forwarder.Map([(0, self.host_port)], self.device, self.tool)
      # Check whether the forwarder is ready on the device.
      self.is_ready = False
      device_port = Forwarder.DevicePortForHostPort(self.host_port)
      if device_port and _CheckDevicePortStatus(self.device, device_port):
        self.is_ready = True
        self.forwarder_device_port = device_port
    # Wake up the request handler thread.
    self.ready_event.set()
    # Keep thread running until Stop() gets called.
    _WaitUntil(lambda: self.stop_flag, max_attempts=sys.maxint)
    if self.process.poll() is None:
      self.process.kill()
    Forwarder.UnmapDevicePort(self.forwarder_device_port, self.device)
    self.process = None
    self.is_ready = False
    if self.pipe_out:
      os.close(self.pipe_in)
      os.close(self.pipe_out)
      self.pipe_in = None
      self.pipe_out = None
    logging.info('Test-server has died.')
    self.wait_event.set()

  def Stop(self):
    """Blocks until the loop has finished.

    Note that this must be called in another thread.
    """
    if not self.process:
      return
    self.stop_flag = True
    self.wait_event.wait()


class SpawningServerRequestHandler(BaseHTTPServer.BaseHTTPRequestHandler):
  """A handler used to process http GET/POST request."""

  def _SendResponse(self, response_code, response_reason, additional_headers,
                    contents):
    """Generates a response sent to the client from the provided parameters.

    Args:
      response_code: number of the response status.
      response_reason: string of reason description of the response.
      additional_headers: dict of additional headers. Each key is the name of
                          the header, each value is the content of the header.
      contents: string of the contents we want to send to client.
    """
    self.send_response(response_code, response_reason)
    self.send_header('Content-Type', 'text/html')
    # Specify the content-length as without it the http(s) response will not
    # be completed properly (and the browser keeps expecting data).
    self.send_header('Content-Length', len(contents))
    for header_name in additional_headers:
      self.send_header(header_name, additional_headers[header_name])
    self.end_headers()
    self.wfile.write(contents)
    self.wfile.flush()

  def _StartTestServer(self):
    """Starts the test server thread."""
    logging.info('Handling request to spawn a test server.')
    content_type = self.headers.getheader('content-type')
    if content_type != 'application/json':
      raise Exception('Bad content-type for start request.')
    content_length = self.headers.getheader('content-length')
    if not content_length:
      content_length = 0
    try:
      content_length = int(content_length)
    except:
      raise Exception('Bad content-length for start request.')
    logging.info(content_length)
    test_server_argument_json = self.rfile.read(content_length)
    logging.info(test_server_argument_json)
    assert not self.server.test_server_instance
    ready_event = threading.Event()
    self.server.test_server_instance = TestServerThread(
        ready_event,
        json.loads(test_server_argument_json),
        self.server.device,
        self.server.tool)
    self.server.test_server_instance.setDaemon(True)
    self.server.test_server_instance.start()
    ready_event.wait()
    if self.server.test_server_instance.is_ready:
      self._SendResponse(200, 'OK', {}, json.dumps(
          {'port': self.server.test_server_instance.forwarder_device_port,
           'message': 'started'}))
      logging.info('Test server is running on port: %d.',
                   self.server.test_server_instance.host_port)
    else:
      self.server.test_server_instance.Stop()
      self.server.test_server_instance = None
      self._SendResponse(500, 'Test Server Error.', {}, '')
      logging.info('Encounter problem during starting a test server.')

  def _KillTestServer(self):
    """Stops the test server instance."""
    # There should only ever be one test server at a time. This may do the
    # wrong thing if we try and start multiple test servers.
    if not self.server.test_server_instance:
      return
    port = self.server.test_server_instance.host_port
    logging.info('Handling request to kill a test server on port: %d.', port)
    self.server.test_server_instance.Stop()
    # Make sure the status of test server is correct before sending response.
    if _CheckPortAvailable(port):
      self._SendResponse(200, 'OK', {}, 'killed')
      logging.info('Test server on port %d is killed', port)
    else:
      self._SendResponse(500, 'Test Server Error.', {}, '')
      logging.info('Encounter problem during killing a test server.')
    self.server.test_server_instance = None

  def do_POST(self):
    parsed_path = urlparse.urlparse(self.path)
    action = parsed_path.path
    logging.info('Action for POST method is: %s.', action)
    if action == '/start':
      self._StartTestServer()
    else:
      self._SendResponse(400, 'Unknown request.', {}, '')
      logging.info('Encounter unknown request: %s.', action)

  def do_GET(self):
    parsed_path = urlparse.urlparse(self.path)
    action = parsed_path.path
    params = urlparse.parse_qs(parsed_path.query, keep_blank_values=1)
    logging.info('Action for GET method is: %s.', action)
    for param in params:
      logging.info('%s=%s', param, params[param][0])
    if action == '/kill':
      self._KillTestServer()
    elif action == '/ping':
      # The ping handler is used to check whether the spawner server is ready
      # to serve the requests. We don't need to test the status of the test
      # server when handling ping request.
      self._SendResponse(200, 'OK', {}, 'ready')
      logging.info('Handled ping request and sent response.')
    else:
      self._SendResponse(400, 'Unknown request', {}, '')
      logging.info('Encounter unknown request: %s.', action)


class SpawningServer(object):
  """The class used to start/stop a http server."""

  def __init__(self, test_server_spawner_port, device, tool):
    logging.info('Creating new spawner on port: %d.', test_server_spawner_port)
    self.server = BaseHTTPServer.HTTPServer(('', test_server_spawner_port),
                                            SpawningServerRequestHandler)
    self.server.device = device
    self.server.tool = tool
    self.server.test_server_instance = None
    self.server.build_type = constants.GetBuildType()

  def _Listen(self):
    logging.info('Starting test server spawner')
    self.server.serve_forever()

  def Start(self):
    """Starts the test server spawner."""
    listener_thread = threading.Thread(target=self._Listen)
    listener_thread.setDaemon(True)
    listener_thread.start()

  def Stop(self):
    """Stops the test server spawner.

    Also cleans the server state.
    """
    self.CleanupState()
    self.server.shutdown()

  def CleanupState(self):
    """Cleans up the spawning server state.

    This should be called if the test server spawner is reused,
    to avoid sharing the test server instance.
    """
    if self.server.test_server_instance:
      self.server.test_server_instance.Stop()
      self.server.test_server_instance = None
