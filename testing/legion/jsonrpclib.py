# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Module to implement the JSON-RPC protocol.

This module uses xmlrpclib as the base and only overrides those
portions that implement the XML-RPC protocol. These portions are rewritten
to use the JSON-RPC protocol instead.

When large portions of code need to be rewritten the original code and
comments are preserved. The intention here is to keep the amount of code
change to a minimum.

This module only depends on default Python modules. No third party code is
required to use this module.
"""
import json
import urllib
import xmlrpclib as _base

__version__ = '1.0.0'
gzip_encode = _base.gzip_encode
gzip = _base.gzip


class Error(Exception):

  def __str__(self):
    return repr(self)


class ProtocolError(Error):
  """Indicates a JSON protocol error."""

  def __init__(self, url, errcode, errmsg, headers):
    Error.__init__(self)
    self.url = url
    self.errcode = errcode
    self.errmsg = errmsg
    self.headers = headers

  def __repr__(self):
    return (
        '<ProtocolError for %s: %s %s>' %
        (self.url, self.errcode, self.errmsg))


class ResponseError(Error):
  """Indicates a broken response package."""
  pass


class Fault(Error):
  """Indicates a JSON-RPC fault package."""

  def __init__(self, code, message):
    Error.__init__(self)
    if not isinstance(code, int):
      raise ProtocolError('Fault code must be an integer.')
    self.code = code
    self.message = message

  def __repr__(self):
      return (
          '<Fault %s: %s>' %
          (self.code, repr(self.message))
          )


def CreateRequest(methodname, params, ident=''):
  """Create a valid JSON-RPC request.

  Args:
    methodname: The name of the remote method to invoke.
    params: The parameters to pass to the remote method. This should be a
        list or tuple and able to be encoded by the default JSON parser.

  Returns:
    A valid JSON-RPC request object.
  """
  request = {
      'jsonrpc': '2.0',
      'method': methodname,
      'params': params,
      'id': ident
      }

  return request


def CreateRequestString(methodname, params, ident=''):
  """Create a valid JSON-RPC request string.

  Args:
    methodname: The name of the remote method to invoke.
    params: The parameters to pass to the remote method.
        These parameters need to be encode-able by the default JSON parser.
    ident: The request identifier.

  Returns:
    A valid JSON-RPC request string.
  """
  return json.dumps(CreateRequest(methodname, params, ident))


def CreateResponse(data, ident):
  """Create a JSON-RPC response.

  Args:
    data: The data to return.
    ident: The response identifier.

  Returns:
    A valid JSON-RPC response object.
  """
  if isinstance(data, Fault):
    response = {
        'jsonrpc': '2.0',
        'error': {
            'code': data.code,
            'message': data.message},
        'id': ident
        }
  else:
    response = {
        'jsonrpc': '2.0',
        'response': data,
        'id': ident
        }

  return response


def CreateResponseString(data, ident):
  """Create a JSON-RPC response string.

  Args:
    data: The data to return.
    ident: The response identifier.

  Returns:
    A valid JSON-RPC response object.
  """
  return json.dumps(CreateResponse(data, ident))


def ParseHTTPResponse(response):
  """Parse an HTTP response object and return the JSON object.

  Args:
    response: An HTTP response object.

  Returns:
    The returned JSON-RPC object.

  Raises:
    ProtocolError: if the object format is not correct.
    Fault: If a Fault error is returned from the server.
  """
  # Check for new http response object, else it is a file object
  if hasattr(response, 'getheader'):
    if response.getheader('Content-Encoding', '') == 'gzip':
      stream = _base.GzipDecodedResponse(response)
    else:
      stream = response
  else:
    stream = response

  data = ''
  while 1:
    chunk = stream.read(1024)
    if not chunk:
      break
    data += chunk

  response = json.loads(data)
  ValidateBasicJSONRPCData(response)

  if 'response' in response:
    ValidateResponse(response)
    return response['response']
  elif 'error' in response:
    ValidateError(response)
    code = response['error']['code']
    message = response['error']['message']
    raise Fault(code, message)
  else:
    raise ProtocolError('No valid JSON returned')


def ValidateRequest(data):
  """Validate a JSON-RPC request object.

  Args:
    data: The JSON-RPC object (dict).

  Raises:
    ProtocolError: if the object format is not correct.
  """
  ValidateBasicJSONRPCData(data)
  if 'method' not in data or 'params' not in data:
    raise ProtocolError('JSON is not a valid request')


def ValidateResponse(data):
  """Validate a JSON-RPC response object.

  Args:
    data: The JSON-RPC object (dict).

  Raises:
    ProtocolError: if the object format is not correct.
  """
  ValidateBasicJSONRPCData(data)
  if 'response' not in data:
    raise ProtocolError('JSON is not a valid response')


def ValidateError(data):
  """Validate a JSON-RPC error object.

  Args:
    data: The JSON-RPC object (dict).

  Raises:
    ProtocolError: if the object format is not correct.
  """
  ValidateBasicJSONRPCData(data)
  if ('error' not in data or
      'code' not in data['error'] or
      'message' not in data['error']):
    raise ProtocolError('JSON is not a valid error response')


def ValidateBasicJSONRPCData(data):
  """Validate a basic JSON-RPC object.

  Args:
    data: The JSON-RPC object (dict).

  Raises:
    ProtocolError: if the object format is not correct.
  """
  error = None
  if not isinstance(data, dict):
    error = 'JSON data is not a dictionary'
  elif 'jsonrpc' not in data or data['jsonrpc'] != '2.0':
    error = 'JSON is not a valid JSON RPC 2.0 message'
  elif 'id' not in data:
    error = 'JSON data missing required id entry'
  if error:
    raise ProtocolError(error)


class Transport(_base.Transport):
  """RPC transport class.

  This class extends the functionality of xmlrpclib.Transport and only
  overrides the operations needed to change the protocol from XML-RPC to
  JSON-RPC.
  """

  user_agent = 'jsonrpclib.py/' + __version__

  def send_content(self, connection, request_body):
    """Send the request."""
    connection.putheader('Content-Type','application/json')

    #optionally encode the request
    if (self.encode_threshold is not None and
        self.encode_threshold < len(request_body) and
        gzip):
      connection.putheader('Content-Encoding', 'gzip')
      request_body = gzip_encode(request_body)

    connection.putheader('Content-Length', str(len(request_body)))
    connection.endheaders(request_body)

  def single_request(self, host, handler, request_body, verbose=0):
    """Issue a single JSON-RPC request."""

    h = self.make_connection(host)
    if verbose:
      h.set_debuglevel(1)
    try:
      self.send_request(h, handler, request_body)
      self.send_host(h, host)
      self.send_user_agent(h)
      self.send_content(h, request_body)

      response = h.getresponse(buffering=True)
      if response.status == 200:
        self.verbose = verbose  #pylint: disable=attribute-defined-outside-init

        return self.parse_response(response)

    except Fault:
      raise
    except Exception:
      # All unexpected errors leave connection in
      # a strange state, so we clear it.
      self.close()
      raise

    # discard any response data and raise exception
    if response.getheader('content-length', 0):
      response.read()
    raise ProtocolError(
        host + handler,
        response.status, response.reason,
        response.msg,
        )

  def parse_response(self, response):
    """Parse the HTTP resoponse from the server."""
    return ParseHTTPResponse(response)


class SafeTransport(_base.SafeTransport):
  """Transport class for HTTPS servers.

  This class extends the functionality of xmlrpclib.SafeTransport and only
  overrides the operations needed to change the protocol from XML-RPC to
  JSON-RPC.
  """

  def parse_response(self, response):
    return ParseHTTPResponse(response)


class ServerProxy(_base.ServerProxy):
  """Proxy class to the RPC server.

  This class extends the functionality of xmlrpclib.ServerProxy and only
  overrides the operations needed to change the protocol from XML-RPC to
  JSON-RPC.
  """

  def __init__(self, uri, transport=None, encoding=None, verbose=0,
               allow_none=0, use_datetime=0):
    urltype, _ = urllib.splittype(uri)
    if urltype not in ('http', 'https'):
      raise IOError('unsupported JSON-RPC protocol')

    _base.ServerProxy.__init__(self, uri, transport, encoding, verbose,
                               allow_none, use_datetime)
    transport_type, uri = urllib.splittype(uri)
    if transport is None:
      if transport_type == 'https':
        transport = SafeTransport(use_datetime=use_datetime)
      else:
        transport = Transport(use_datetime=use_datetime)
    self.__transport = transport

  def __request(self, methodname, params):
    """Call a method on the remote server."""
    request = CreateRequestString(methodname, params)

    response = self.__transport.request(
        self.__host,
        self.__handler,
        request,
        verbose=self.__verbose
        )

    return response


Server = ServerProxy
