#!/usr/bin/env python
#
# Copyright 2012, Google Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


"""Standalone WebSocket server.

Use this file to launch pywebsocket without Apache HTTP Server.


BASIC USAGE
===========

Go to the src directory and run

  $ python mod_pywebsocket/standalone.py [-p <ws_port>]
                                         [-w <websock_handlers>]
                                         [-d <document_root>]

<ws_port> is the port number to use for ws:// connection.

<document_root> is the path to the root directory of HTML files.

<websock_handlers> is the path to the root directory of WebSocket handlers.
If not specified, <document_root> will be used. See __init__.py (or
run $ pydoc mod_pywebsocket) for how to write WebSocket handlers.

For more detail and other options, run

  $ python mod_pywebsocket/standalone.py --help

or see _build_option_parser method below.

For trouble shooting, adding "--log_level debug" might help you.


TRY DEMO
========

Go to the src directory and run standalone.py with -d option to set the
document root to the directory containing example HTMLs and handlers like this:

  $ cd src
  $ PYTHONPATH=. python mod_pywebsocket/standalone.py -d example

to launch pywebsocket with the sample handler and html on port 80. Open
http://localhost/console.html, click the connect button, type something into
the text box next to the send button and click the send button. If everything
is working, you'll see the message you typed echoed by the server.


USING TLS
=========

To run the standalone server with TLS support, run it with -t, -k, and -c
options. When TLS is enabled, the standalone server accepts only TLS connection.

Note that when ssl module is used and the key/cert location is incorrect,
TLS connection silently fails while pyOpenSSL fails on startup.

Example:

  $ PYTHONPATH=. python mod_pywebsocket/standalone.py \
        -d example \
        -p 10443 \
        -t \
        -c ../test/cert/cert.pem \
        -k ../test/cert/key.pem \

Note that when passing a relative path to -c and -k option, it will be resolved
using the document root directory as the base.


USING CLIENT AUTHENTICATION
===========================

To run the standalone server with TLS client authentication support, run it with
--tls-client-auth and --tls-client-ca options in addition to ones required for
TLS support.

Example:

  $ PYTHONPATH=. python mod_pywebsocket/standalone.py -d example -p 10443 -t \
        -c ../test/cert/cert.pem -k ../test/cert/key.pem \
        --tls-client-auth \
        --tls-client-ca=../test/cert/cacert.pem

Note that when passing a relative path to --tls-client-ca option, it will be
resolved using the document root directory as the base.


CONFIGURATION FILE
==================

You can also write a configuration file and use it by specifying the path to
the configuration file by --config option. Please write a configuration file
following the documentation of the Python ConfigParser library. Name of each
entry must be the long version argument name. E.g. to set log level to debug,
add the following line:

log_level=debug

For options which doesn't take value, please add some fake value. E.g. for
--tls option, add the following line:

tls=True

Note that tls will be enabled even if you write tls=False as the value part is
fake.

When both a command line argument and a configuration file entry are set for
the same configuration item, the command line value will override one in the
configuration file.


THREADING
=========

This server is derived from SocketServer.ThreadingMixIn. Hence a thread is
used for each request.


SECURITY WARNING
================

This uses CGIHTTPServer and CGIHTTPServer is not secure.
It may execute arbitrary Python code or external programs. It should not be
used outside a firewall.
"""

import BaseHTTPServer
import CGIHTTPServer
import SimpleHTTPServer
import SocketServer
import ConfigParser
import base64
import httplib
import logging
import logging.handlers
import optparse
import os
import re
import select
import socket
import sys
import threading
import time

from mod_pywebsocket import common
from mod_pywebsocket import dispatch
from mod_pywebsocket import handshake
from mod_pywebsocket import http_header_util
from mod_pywebsocket import memorizingfile
from mod_pywebsocket import util
from mod_pywebsocket.xhr_benchmark_handler import XHRBenchmarkHandler


_DEFAULT_LOG_MAX_BYTES = 1024 * 256
_DEFAULT_LOG_BACKUP_COUNT = 5

_DEFAULT_REQUEST_QUEUE_SIZE = 128

# 1024 is practically large enough to contain WebSocket handshake lines.
_MAX_MEMORIZED_LINES = 1024

# Constants for the --tls_module flag.
_TLS_BY_STANDARD_MODULE = 'ssl'
_TLS_BY_PYOPENSSL = 'pyopenssl'


class _StandaloneConnection(object):
    """Mimic mod_python mp_conn."""

    def __init__(self, request_handler):
        """Construct an instance.

        Args:
            request_handler: A WebSocketRequestHandler instance.
        """

        self._request_handler = request_handler

    def get_local_addr(self):
        """Getter to mimic mp_conn.local_addr."""

        return (self._request_handler.server.server_name,
                self._request_handler.server.server_port)
    local_addr = property(get_local_addr)

    def get_remote_addr(self):
        """Getter to mimic mp_conn.remote_addr.

        Setting the property in __init__ won't work because the request
        handler is not initialized yet there."""

        return self._request_handler.client_address
    remote_addr = property(get_remote_addr)

    def write(self, data):
        """Mimic mp_conn.write()."""

        return self._request_handler.wfile.write(data)

    def read(self, length):
        """Mimic mp_conn.read()."""

        return self._request_handler.rfile.read(length)

    def get_memorized_lines(self):
        """Get memorized lines."""

        return self._request_handler.rfile.get_memorized_lines()


class _StandaloneRequest(object):
    """Mimic mod_python request."""

    def __init__(self, request_handler, use_tls):
        """Construct an instance.

        Args:
            request_handler: A WebSocketRequestHandler instance.
        """

        self._logger = util.get_class_logger(self)

        self._request_handler = request_handler
        self.connection = _StandaloneConnection(request_handler)
        self._use_tls = use_tls
        self.headers_in = request_handler.headers

    def get_uri(self):
        """Getter to mimic request.uri.

        This method returns the raw data at the Request-URI part of the
        Request-Line, while the uri method on the request object of mod_python
        returns the path portion after parsing the raw data. This behavior is
        kept for compatibility.
        """

        return self._request_handler.path
    uri = property(get_uri)

    def get_unparsed_uri(self):
        """Getter to mimic request.unparsed_uri."""

        return self._request_handler.path
    unparsed_uri = property(get_unparsed_uri)

    def get_method(self):
        """Getter to mimic request.method."""

        return self._request_handler.command
    method = property(get_method)

    def get_protocol(self):
        """Getter to mimic request.protocol."""

        return self._request_handler.request_version
    protocol = property(get_protocol)

    def is_https(self):
        """Mimic request.is_https()."""

        return self._use_tls


def _import_ssl():
    global ssl
    try:
        import ssl
        return True
    except ImportError:
        return False


def _import_pyopenssl():
    global OpenSSL
    try:
        import OpenSSL.SSL
        return True
    except ImportError:
        return False


class _StandaloneSSLConnection(object):
    """A wrapper class for OpenSSL.SSL.Connection to
    - provide makefile method which is not supported by the class
    - tweak shutdown method since OpenSSL.SSL.Connection.shutdown doesn't
      accept the "how" argument.
    - convert SysCallError exceptions that its recv method may raise into a
      return value of '', meaning EOF. We cannot overwrite the recv method on
      self._connection since it's immutable.
    """

    _OVERRIDDEN_ATTRIBUTES = ['_connection', 'makefile', 'shutdown', 'recv']

    def __init__(self, connection):
        self._connection = connection

    def __getattribute__(self, name):
        if name in _StandaloneSSLConnection._OVERRIDDEN_ATTRIBUTES:
            return object.__getattribute__(self, name)
        return self._connection.__getattribute__(name)

    def __setattr__(self, name, value):
        if name in _StandaloneSSLConnection._OVERRIDDEN_ATTRIBUTES:
            return object.__setattr__(self, name, value)
        return self._connection.__setattr__(name, value)

    def makefile(self, mode='r', bufsize=-1):
        return socket._fileobject(self, mode, bufsize)

    def shutdown(self, unused_how):
        self._connection.shutdown()

    def recv(self, bufsize, flags=0):
        if flags != 0:
            raise ValueError('Non-zero flags not allowed')

        try:
            return self._connection.recv(bufsize)
        except OpenSSL.SSL.SysCallError, (err, message):
            if err == -1:
                # Suppress "unexpected EOF" exception. See the OpenSSL document
                # for SSL_get_error.
                return ''
            raise


def _alias_handlers(dispatcher, websock_handlers_map_file):
    """Set aliases specified in websock_handler_map_file in dispatcher.

    Args:
        dispatcher: dispatch.Dispatcher instance
        websock_handler_map_file: alias map file
    """

    fp = open(websock_handlers_map_file)
    try:
        for line in fp:
            if line[0] == '#' or line.isspace():
                continue
            m = re.match('(\S+)\s+(\S+)', line)
            if not m:
                logging.warning('Wrong format in map file:' + line)
                continue
            try:
                dispatcher.add_resource_path_alias(
                    m.group(1), m.group(2))
            except dispatch.DispatchException, e:
                logging.error(str(e))
    finally:
        fp.close()


class WebSocketServer(SocketServer.ThreadingMixIn, BaseHTTPServer.HTTPServer):
    """HTTPServer specialized for WebSocket."""

    # Overrides SocketServer.ThreadingMixIn.daemon_threads
    daemon_threads = True
    # Overrides BaseHTTPServer.HTTPServer.allow_reuse_address
    allow_reuse_address = True

    def __init__(self, options):
        """Override SocketServer.TCPServer.__init__ to set SSL enabled
        socket object to self.socket before server_bind and server_activate,
        if necessary.
        """

        # Share a Dispatcher among request handlers to save time for
        # instantiation.  Dispatcher can be shared because it is thread-safe.
        options.dispatcher = dispatch.Dispatcher(
            options.websock_handlers,
            options.scan_dir,
            options.allow_handlers_outside_root_dir)
        if options.websock_handlers_map_file:
            _alias_handlers(options.dispatcher,
                            options.websock_handlers_map_file)
        warnings = options.dispatcher.source_warnings()
        if warnings:
            for warning in warnings:
                logging.warning('Warning in source loading: %s' % warning)

        self._logger = util.get_class_logger(self)

        self.request_queue_size = options.request_queue_size
        self.__ws_is_shut_down = threading.Event()
        self.__ws_serving = False

        SocketServer.BaseServer.__init__(
            self, (options.server_host, options.port), WebSocketRequestHandler)

        # Expose the options object to allow handler objects access it. We name
        # it with websocket_ prefix to avoid conflict.
        self.websocket_server_options = options

        self._create_sockets()
        self.server_bind()
        self.server_activate()

    def _create_sockets(self):
        self.server_name, self.server_port = self.server_address
        self._sockets = []
        if not self.server_name:
            # On platforms that doesn't support IPv6, the first bind fails.
            # On platforms that supports IPv6
            # - If it binds both IPv4 and IPv6 on call with AF_INET6, the
            #   first bind succeeds and the second fails (we'll see 'Address
            #   already in use' error).
            # - If it binds only IPv6 on call with AF_INET6, both call are
            #   expected to succeed to listen both protocol.
            addrinfo_array = [
                (socket.AF_INET6, socket.SOCK_STREAM, '', '', ''),
                (socket.AF_INET, socket.SOCK_STREAM, '', '', '')]
        else:
            addrinfo_array = socket.getaddrinfo(self.server_name,
                                                self.server_port,
                                                socket.AF_UNSPEC,
                                                socket.SOCK_STREAM,
                                                socket.IPPROTO_TCP)
        for addrinfo in addrinfo_array:
            self._logger.info('Create socket on: %r', addrinfo)
            family, socktype, proto, canonname, sockaddr = addrinfo
            try:
                socket_ = socket.socket(family, socktype)
            except Exception, e:
                self._logger.info('Skip by failure: %r', e)
                continue
            server_options = self.websocket_server_options
            if server_options.use_tls:
                # For the case of _HAS_OPEN_SSL, we do wrapper setup after
                # accept.
                if server_options.tls_module == _TLS_BY_STANDARD_MODULE:
                    if server_options.tls_client_auth:
                        if server_options.tls_client_cert_optional:
                            client_cert_ = ssl.CERT_OPTIONAL
                        else:
                            client_cert_ = ssl.CERT_REQUIRED
                    else:
                        client_cert_ = ssl.CERT_NONE
                    socket_ = ssl.wrap_socket(socket_,
                        keyfile=server_options.private_key,
                        certfile=server_options.certificate,
                        ssl_version=ssl.PROTOCOL_SSLv23,
                        ca_certs=server_options.tls_client_ca,
                        cert_reqs=client_cert_,
                        do_handshake_on_connect=False)
            self._sockets.append((socket_, addrinfo))

    def server_bind(self):
        """Override SocketServer.TCPServer.server_bind to enable multiple
        sockets bind.
        """

        failed_sockets = []

        for socketinfo in self._sockets:
            socket_, addrinfo = socketinfo
            self._logger.info('Bind on: %r', addrinfo)
            if self.allow_reuse_address:
                socket_.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                socket_.bind(self.server_address)
            except Exception, e:
                self._logger.info('Skip by failure: %r', e)
                socket_.close()
                failed_sockets.append(socketinfo)
            if self.server_address[1] == 0:
                # The operating system assigns the actual port number for port
                # number 0. This case, the second and later sockets should use
                # the same port number. Also self.server_port is rewritten
                # because it is exported, and will be used by external code.
                self.server_address = (
                    self.server_name, socket_.getsockname()[1])
                self.server_port = self.server_address[1]
                self._logger.info('Port %r is assigned', self.server_port)

        for socketinfo in failed_sockets:
            self._sockets.remove(socketinfo)

    def server_activate(self):
        """Override SocketServer.TCPServer.server_activate to enable multiple
        sockets listen.
        """

        failed_sockets = []

        for socketinfo in self._sockets:
            socket_, addrinfo = socketinfo
            self._logger.info('Listen on: %r', addrinfo)
            try:
                socket_.listen(self.request_queue_size)
            except Exception, e:
                self._logger.info('Skip by failure: %r', e)
                socket_.close()
                failed_sockets.append(socketinfo)

        for socketinfo in failed_sockets:
            self._sockets.remove(socketinfo)

        if len(self._sockets) == 0:
            self._logger.critical(
                'No sockets activated. Use info log level to see the reason.')

    def server_close(self):
        """Override SocketServer.TCPServer.server_close to enable multiple
        sockets close.
        """

        for socketinfo in self._sockets:
            socket_, addrinfo = socketinfo
            self._logger.info('Close on: %r', addrinfo)
            socket_.close()

    def fileno(self):
        """Override SocketServer.TCPServer.fileno."""

        self._logger.critical('Not supported: fileno')
        return self._sockets[0][0].fileno()

    def handle_error(self, request, client_address):
        """Override SocketServer.handle_error."""

        self._logger.error(
            'Exception in processing request from: %r\n%s',
            client_address,
            util.get_stack_trace())
        # Note: client_address is a tuple.

    def get_request(self):
        """Override TCPServer.get_request to wrap OpenSSL.SSL.Connection
        object with _StandaloneSSLConnection to provide makefile method. We
        cannot substitute OpenSSL.SSL.Connection.makefile since it's readonly
        attribute.
        """

        accepted_socket, client_address = self.socket.accept()

        server_options = self.websocket_server_options
        if server_options.use_tls:
            if server_options.tls_module == _TLS_BY_STANDARD_MODULE:
                try:
                    accepted_socket.do_handshake()
                except ssl.SSLError, e:
                    self._logger.debug('%r', e)
                    raise

                # Print cipher in use. Handshake is done on accept.
                self._logger.debug('Cipher: %s', accepted_socket.cipher())
                self._logger.debug('Client cert: %r',
                                   accepted_socket.getpeercert())
            elif server_options.tls_module == _TLS_BY_PYOPENSSL:
                # We cannot print the cipher in use. pyOpenSSL doesn't provide
                # any method to fetch that.

                ctx = OpenSSL.SSL.Context(OpenSSL.SSL.SSLv23_METHOD)
                ctx.use_privatekey_file(server_options.private_key)
                ctx.use_certificate_file(server_options.certificate)

                def default_callback(conn, cert, errnum, errdepth, ok):
                    return ok == 1

                # See the OpenSSL document for SSL_CTX_set_verify.
                if server_options.tls_client_auth:
                    verify_mode = OpenSSL.SSL.VERIFY_PEER
                    if not server_options.tls_client_cert_optional:
                        verify_mode |= OpenSSL.SSL.VERIFY_FAIL_IF_NO_PEER_CERT
                    ctx.set_verify(verify_mode, default_callback)
                    ctx.load_verify_locations(server_options.tls_client_ca,
                                              None)
                else:
                    ctx.set_verify(OpenSSL.SSL.VERIFY_NONE, default_callback)

                accepted_socket = OpenSSL.SSL.Connection(ctx, accepted_socket)
                accepted_socket.set_accept_state()

                # Convert SSL related error into socket.error so that
                # SocketServer ignores them and keeps running.
                #
                # TODO(tyoshino): Convert all kinds of errors.
                try:
                    accepted_socket.do_handshake()
                except OpenSSL.SSL.Error, e:
                    # Set errno part to 1 (SSL_ERROR_SSL) like the ssl module
                    # does.
                    self._logger.debug('%r', e)
                    raise socket.error(1, '%r' % e)
                cert = accepted_socket.get_peer_certificate()
                if cert is not None:
                    self._logger.debug('Client cert subject: %r',
                                       cert.get_subject().get_components())
                accepted_socket = _StandaloneSSLConnection(accepted_socket)
            else:
                raise ValueError('No TLS support module is available')

        return accepted_socket, client_address

    def serve_forever(self, poll_interval=0.5):
        """Override SocketServer.BaseServer.serve_forever."""

        self.__ws_serving = True
        self.__ws_is_shut_down.clear()
        handle_request = self.handle_request
        if hasattr(self, '_handle_request_noblock'):
            handle_request = self._handle_request_noblock
        else:
            self._logger.warning('Fallback to blocking request handler')
        try:
            while self.__ws_serving:
                r, w, e = select.select(
                    [socket_[0] for socket_ in self._sockets],
                    [], [], poll_interval)
                for socket_ in r:
                    self.socket = socket_
                    handle_request()
                self.socket = None
        finally:
            self.__ws_is_shut_down.set()

    def shutdown(self):
        """Override SocketServer.BaseServer.shutdown."""

        self.__ws_serving = False
        self.__ws_is_shut_down.wait()


class WebSocketRequestHandler(CGIHTTPServer.CGIHTTPRequestHandler):
    """CGIHTTPRequestHandler specialized for WebSocket."""

    # Use httplib.HTTPMessage instead of mimetools.Message.
    MessageClass = httplib.HTTPMessage

    def setup(self):
        """Override SocketServer.StreamRequestHandler.setup to wrap rfile
        with MemorizingFile.

        This method will be called by BaseRequestHandler's constructor
        before calling BaseHTTPRequestHandler.handle.
        BaseHTTPRequestHandler.handle will call
        BaseHTTPRequestHandler.handle_one_request and it will call
        WebSocketRequestHandler.parse_request.
        """

        # Call superclass's setup to prepare rfile, wfile, etc. See setup
        # definition on the root class SocketServer.StreamRequestHandler to
        # understand what this does.
        CGIHTTPServer.CGIHTTPRequestHandler.setup(self)

        self.rfile = memorizingfile.MemorizingFile(
            self.rfile,
            max_memorized_lines=_MAX_MEMORIZED_LINES)

    def __init__(self, request, client_address, server):
        self._logger = util.get_class_logger(self)

        self._options = server.websocket_server_options

        # Overrides CGIHTTPServerRequestHandler.cgi_directories.
        self.cgi_directories = self._options.cgi_directories
        # Replace CGIHTTPRequestHandler.is_executable method.
        if self._options.is_executable_method is not None:
            self.is_executable = self._options.is_executable_method

        # This actually calls BaseRequestHandler.__init__.
        CGIHTTPServer.CGIHTTPRequestHandler.__init__(
            self, request, client_address, server)

    def parse_request(self):
        """Override BaseHTTPServer.BaseHTTPRequestHandler.parse_request.

        Return True to continue processing for HTTP(S), False otherwise.

        See BaseHTTPRequestHandler.handle_one_request method which calls
        this method to understand how the return value will be handled.
        """

        # We hook parse_request method, but also call the original
        # CGIHTTPRequestHandler.parse_request since when we return False,
        # CGIHTTPRequestHandler.handle_one_request continues processing and
        # it needs variables set by CGIHTTPRequestHandler.parse_request.
        #
        # Variables set by this method will be also used by WebSocket request
        # handling (self.path, self.command, self.requestline, etc. See also
        # how _StandaloneRequest's members are implemented using these
        # attributes).
        if not CGIHTTPServer.CGIHTTPRequestHandler.parse_request(self):
            return False

        if self._options.use_basic_auth:
            auth = self.headers.getheader('Authorization')
            if auth != self._options.basic_auth_credential:
                self.send_response(401)
                self.send_header('WWW-Authenticate',
                                 'Basic realm="Pywebsocket"')
                self.end_headers()
                self._logger.info('Request basic authentication')
                return True

        host, port, resource = http_header_util.parse_uri(self.path)

        # Special paths for XMLHttpRequest benchmark
        xhr_benchmark_helper_prefix = '/073be001e10950692ccbf3a2ad21c245'
        if resource == (xhr_benchmark_helper_prefix + '_send'):
            xhr_benchmark_handler = XHRBenchmarkHandler(
                self.headers, self.rfile, self.wfile)
            xhr_benchmark_handler.do_send()
            return False
        if resource == (xhr_benchmark_helper_prefix + '_receive'):
            xhr_benchmark_handler = XHRBenchmarkHandler(
                self.headers, self.rfile, self.wfile)
            xhr_benchmark_handler.do_receive()
            return False

        if resource is None:
            self._logger.info('Invalid URI: %r', self.path)
            self._logger.info('Fallback to CGIHTTPRequestHandler')
            return True
        server_options = self.server.websocket_server_options
        if host is not None:
            validation_host = server_options.validation_host
            if validation_host is not None and host != validation_host:
                self._logger.info('Invalid host: %r (expected: %r)',
                                  host,
                                  validation_host)
                self._logger.info('Fallback to CGIHTTPRequestHandler')
                return True
        if port is not None:
            validation_port = server_options.validation_port
            if validation_port is not None and port != validation_port:
                self._logger.info('Invalid port: %r (expected: %r)',
                                  port,
                                  validation_port)
                self._logger.info('Fallback to CGIHTTPRequestHandler')
                return True
        self.path = resource

        request = _StandaloneRequest(self, self._options.use_tls)

        try:
            # Fallback to default http handler for request paths for which
            # we don't have request handlers.
            if not self._options.dispatcher.get_handler_suite(self.path):
                self._logger.info('No handler for resource: %r',
                                  self.path)
                self._logger.info('Fallback to CGIHTTPRequestHandler')
                return True
        except dispatch.DispatchException, e:
            self._logger.info('Dispatch failed for error: %s', e)
            self.send_error(e.status)
            return False

        # If any Exceptions without except clause setup (including
        # DispatchException) is raised below this point, it will be caught
        # and logged by WebSocketServer.

        try:
            try:
                handshake.do_handshake(
                    request,
                    self._options.dispatcher,
                    allowDraft75=self._options.allow_draft75,
                    strict=self._options.strict)
            except handshake.VersionException, e:
                self._logger.info('Handshake failed for version error: %s', e)
                self.send_response(common.HTTP_STATUS_BAD_REQUEST)
                self.send_header(common.SEC_WEBSOCKET_VERSION_HEADER,
                                 e.supported_versions)
                self.end_headers()
                return False
            except handshake.HandshakeException, e:
                # Handshake for ws(s) failed.
                self._logger.info('Handshake failed for error: %s', e)
                self.send_error(e.status)
                return False

            request._dispatcher = self._options.dispatcher
            self._options.dispatcher.transfer_data(request)
        except handshake.AbortedByUserException, e:
            self._logger.info('Aborted: %s', e)
        return False

    def log_request(self, code='-', size='-'):
        """Override BaseHTTPServer.log_request."""

        self._logger.info('"%s" %s %s',
                          self.requestline, str(code), str(size))

    def log_error(self, *args):
        """Override BaseHTTPServer.log_error."""

        # Despite the name, this method is for warnings than for errors.
        # For example, HTTP status code is logged by this method.
        self._logger.warning('%s - %s',
                             self.address_string(),
                             args[0] % args[1:])

    def is_cgi(self):
        """Test whether self.path corresponds to a CGI script.

        Add extra check that self.path doesn't contains ..
        Also check if the file is a executable file or not.
        If the file is not executable, it is handled as static file or dir
        rather than a CGI script.
        """

        if CGIHTTPServer.CGIHTTPRequestHandler.is_cgi(self):
            if '..' in self.path:
                return False
            # strip query parameter from request path
            resource_name = self.path.split('?', 2)[0]
            # convert resource_name into real path name in filesystem.
            scriptfile = self.translate_path(resource_name)
            if not os.path.isfile(scriptfile):
                return False
            if not self.is_executable(scriptfile):
                return False
            return True
        return False


def _get_logger_from_class(c):
    return logging.getLogger('%s.%s' % (c.__module__, c.__name__))


def _configure_logging(options):
    logging.addLevelName(common.LOGLEVEL_FINE, 'FINE')

    logger = logging.getLogger()
    logger.setLevel(logging.getLevelName(options.log_level.upper()))
    if options.log_file:
        handler = logging.handlers.RotatingFileHandler(
                options.log_file, 'a', options.log_max, options.log_count)
    else:
        handler = logging.StreamHandler()
    formatter = logging.Formatter(
            '[%(asctime)s] [%(levelname)s] %(name)s: %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

    deflate_log_level_name = logging.getLevelName(
        options.deflate_log_level.upper())
    _get_logger_from_class(util._Deflater).setLevel(
        deflate_log_level_name)
    _get_logger_from_class(util._Inflater).setLevel(
        deflate_log_level_name)


def _build_option_parser():
    parser = optparse.OptionParser()

    parser.add_option('--config', dest='config_file', type='string',
                      default=None,
                      help=('Path to configuration file. See the file comment '
                            'at the top of this file for the configuration '
                            'file format'))
    parser.add_option('-H', '--server-host', '--server_host',
                      dest='server_host',
                      default='',
                      help='server hostname to listen to')
    parser.add_option('-V', '--validation-host', '--validation_host',
                      dest='validation_host',
                      default=None,
                      help='server hostname to validate in absolute path.')
    parser.add_option('-p', '--port', dest='port', type='int',
                      default=common.DEFAULT_WEB_SOCKET_PORT,
                      help='port to listen to')
    parser.add_option('-P', '--validation-port', '--validation_port',
                      dest='validation_port', type='int',
                      default=None,
                      help='server port to validate in absolute path.')
    parser.add_option('-w', '--websock-handlers', '--websock_handlers',
                      dest='websock_handlers',
                      default='.',
                      help=('The root directory of WebSocket handler files. '
                            'If the path is relative, --document-root is used '
                            'as the base.'))
    parser.add_option('-m', '--websock-handlers-map-file',
                      '--websock_handlers_map_file',
                      dest='websock_handlers_map_file',
                      default=None,
                      help=('WebSocket handlers map file. '
                            'Each line consists of alias_resource_path and '
                            'existing_resource_path, separated by spaces.'))
    parser.add_option('-s', '--scan-dir', '--scan_dir', dest='scan_dir',
                      default=None,
                      help=('Must be a directory under --websock-handlers. '
                            'Only handlers under this directory are scanned '
                            'and registered to the server. '
                            'Useful for saving scan time when the handler '
                            'root directory contains lots of files that are '
                            'not handler file or are handler files but you '
                            'don\'t want them to be registered. '))
    parser.add_option('--allow-handlers-outside-root-dir',
                      '--allow_handlers_outside_root_dir',
                      dest='allow_handlers_outside_root_dir',
                      action='store_true',
                      default=False,
                      help=('Scans WebSocket handlers even if their canonical '
                            'path is not under --websock-handlers.'))
    parser.add_option('-d', '--document-root', '--document_root',
                      dest='document_root', default='.',
                      help='Document root directory.')
    parser.add_option('-x', '--cgi-paths', '--cgi_paths', dest='cgi_paths',
                      default=None,
                      help=('CGI paths relative to document_root.'
                            'Comma-separated. (e.g -x /cgi,/htbin) '
                            'Files under document_root/cgi_path are handled '
                            'as CGI programs. Must be executable.'))
    parser.add_option('-t', '--tls', dest='use_tls', action='store_true',
                      default=False, help='use TLS (wss://)')
    parser.add_option('--tls-module', '--tls_module', dest='tls_module',
                      type='choice',
                      choices = [_TLS_BY_STANDARD_MODULE, _TLS_BY_PYOPENSSL],
                      help='Use ssl module if "%s" is specified. '
                      'Use pyOpenSSL module if "%s" is specified' %
                      (_TLS_BY_STANDARD_MODULE, _TLS_BY_PYOPENSSL))
    parser.add_option('-k', '--private-key', '--private_key',
                      dest='private_key',
                      default='', help='TLS private key file.')
    parser.add_option('-c', '--certificate', dest='certificate',
                      default='', help='TLS certificate file.')
    parser.add_option('--tls-client-auth', dest='tls_client_auth',
                      action='store_true', default=False,
                      help='Requests TLS client auth on every connection.')
    parser.add_option('--tls-client-cert-optional',
                      dest='tls_client_cert_optional',
                      action='store_true', default=False,
                      help=('Makes client certificate optional even though '
                            'TLS client auth is enabled.'))
    parser.add_option('--tls-client-ca', dest='tls_client_ca', default='',
                      help=('Specifies a pem file which contains a set of '
                            'concatenated CA certificates which are used to '
                            'validate certificates passed from clients'))
    parser.add_option('--basic-auth', dest='use_basic_auth',
                      action='store_true', default=False,
                      help='Requires Basic authentication.')
    parser.add_option('--basic-auth-credential',
                      dest='basic_auth_credential', default='test:test',
                      help='Specifies the credential of basic authentication '
                      'by username:password pair (e.g. test:test).')
    parser.add_option('-l', '--log-file', '--log_file', dest='log_file',
                      default='', help='Log file.')
    # Custom log level:
    # - FINE: Prints status of each frame processing step
    parser.add_option('--log-level', '--log_level', type='choice',
                      dest='log_level', default='warn',
                      choices=['fine',
                               'debug', 'info', 'warning', 'warn', 'error',
                               'critical'],
                      help='Log level.')
    parser.add_option('--deflate-log-level', '--deflate_log_level',
                      type='choice',
                      dest='deflate_log_level', default='warn',
                      choices=['debug', 'info', 'warning', 'warn', 'error',
                               'critical'],
                      help='Log level for _Deflater and _Inflater.')
    parser.add_option('--thread-monitor-interval-in-sec',
                      '--thread_monitor_interval_in_sec',
                      dest='thread_monitor_interval_in_sec',
                      type='int', default=-1,
                      help=('If positive integer is specified, run a thread '
                            'monitor to show the status of server threads '
                            'periodically in the specified inteval in '
                            'second. If non-positive integer is specified, '
                            'disable the thread monitor.'))
    parser.add_option('--log-max', '--log_max', dest='log_max', type='int',
                      default=_DEFAULT_LOG_MAX_BYTES,
                      help='Log maximum bytes')
    parser.add_option('--log-count', '--log_count', dest='log_count',
                      type='int', default=_DEFAULT_LOG_BACKUP_COUNT,
                      help='Log backup count')
    parser.add_option('--allow-draft75', dest='allow_draft75',
                      action='store_true', default=False,
                      help='Obsolete option. Ignored.')
    parser.add_option('--strict', dest='strict', action='store_true',
                      default=False, help='Obsolete option. Ignored.')
    parser.add_option('-q', '--queue', dest='request_queue_size', type='int',
                      default=_DEFAULT_REQUEST_QUEUE_SIZE,
                      help='request queue size')

    return parser


class ThreadMonitor(threading.Thread):
    daemon = True

    def __init__(self, interval_in_sec):
        threading.Thread.__init__(self, name='ThreadMonitor')

        self._logger = util.get_class_logger(self)

        self._interval_in_sec = interval_in_sec

    def run(self):
        while True:
            thread_name_list = []
            for thread in threading.enumerate():
                thread_name_list.append(thread.name)
            self._logger.info(
                "%d active threads: %s",
                threading.active_count(),
                ', '.join(thread_name_list))
            time.sleep(self._interval_in_sec)


def _parse_args_and_config(args):
    parser = _build_option_parser()

    # First, parse options without configuration file.
    temporary_options, temporary_args = parser.parse_args(args=args)
    if temporary_args:
        logging.critical(
            'Unrecognized positional arguments: %r', temporary_args)
        sys.exit(1)

    if temporary_options.config_file:
        try:
            config_fp = open(temporary_options.config_file, 'r')
        except IOError, e:
            logging.critical(
                'Failed to open configuration file %r: %r',
                temporary_options.config_file,
                e)
            sys.exit(1)

        config_parser = ConfigParser.SafeConfigParser()
        config_parser.readfp(config_fp)
        config_fp.close()

        args_from_config = []
        for name, value in config_parser.items('pywebsocket'):
            args_from_config.append('--' + name)
            args_from_config.append(value)
        if args is None:
            args = args_from_config
        else:
            args = args_from_config + args
        return parser.parse_args(args=args)
    else:
        return temporary_options, temporary_args


def _main(args=None):
    """You can call this function from your own program, but please note that
    this function has some side-effects that might affect your program. For
    example, util.wrap_popen3_for_win use in this method replaces implementation
    of os.popen3.
    """

    options, args = _parse_args_and_config(args=args)

    os.chdir(options.document_root)

    _configure_logging(options)

    if options.allow_draft75:
        logging.warning('--allow_draft75 option is obsolete.')

    if options.strict:
        logging.warning('--strict option is obsolete.')

    # TODO(tyoshino): Clean up initialization of CGI related values. Move some
    # of code here to WebSocketRequestHandler class if it's better.
    options.cgi_directories = []
    options.is_executable_method = None
    if options.cgi_paths:
        options.cgi_directories = options.cgi_paths.split(',')
        if sys.platform in ('cygwin', 'win32'):
            cygwin_path = None
            # For Win32 Python, it is expected that CYGWIN_PATH
            # is set to a directory of cygwin binaries.
            # For example, websocket_server.py in Chromium sets CYGWIN_PATH to
            # full path of third_party/cygwin/bin.
            if 'CYGWIN_PATH' in os.environ:
                cygwin_path = os.environ['CYGWIN_PATH']
            util.wrap_popen3_for_win(cygwin_path)

            def __check_script(scriptpath):
                return util.get_script_interp(scriptpath, cygwin_path)

            options.is_executable_method = __check_script

    if options.use_tls:
        if options.tls_module is None:
            if _import_ssl():
                options.tls_module = _TLS_BY_STANDARD_MODULE
                logging.debug('Using ssl module')
            elif _import_pyopenssl():
                options.tls_module = _TLS_BY_PYOPENSSL
                logging.debug('Using pyOpenSSL module')
            else:
                logging.critical(
                        'TLS support requires ssl or pyOpenSSL module.')
                sys.exit(1)
        elif options.tls_module == _TLS_BY_STANDARD_MODULE:
            if not _import_ssl():
                logging.critical('ssl module is not available')
                sys.exit(1)
        elif options.tls_module == _TLS_BY_PYOPENSSL:
            if not _import_pyopenssl():
                logging.critical('pyOpenSSL module is not available')
                sys.exit(1)
        else:
            logging.critical('Invalid --tls-module option: %r',
                             options.tls_module)
            sys.exit(1)

        if not options.private_key or not options.certificate:
            logging.critical(
                    'To use TLS, specify private_key and certificate.')
            sys.exit(1)

        if (options.tls_client_cert_optional and
            not options.tls_client_auth):
            logging.critical('Client authentication must be enabled to '
                             'specify tls_client_cert_optional')
            sys.exit(1)
    else:
        if options.tls_module is not None:
            logging.critical('Use --tls-module option only together with '
                             '--use-tls option.')
            sys.exit(1)

        if options.tls_client_auth:
            logging.critical('TLS must be enabled for client authentication.')
            sys.exit(1)

        if options.tls_client_cert_optional:
            logging.critical('TLS must be enabled for client authentication.')
            sys.exit(1)

    if not options.scan_dir:
        options.scan_dir = options.websock_handlers

    if options.use_basic_auth:
        options.basic_auth_credential = 'Basic ' + base64.b64encode(
            options.basic_auth_credential)

    try:
        if options.thread_monitor_interval_in_sec > 0:
            # Run a thread monitor to show the status of server threads for
            # debugging.
            ThreadMonitor(options.thread_monitor_interval_in_sec).start()

        server = WebSocketServer(options)
        server.serve_forever()
    except Exception, e:
        logging.critical('mod_pywebsocket: %s' % e)
        logging.critical('mod_pywebsocket: %s' % util.get_stack_trace())
        sys.exit(1)


if __name__ == '__main__':
    _main(sys.argv[1:])


# vi:sts=4 sw=4 et
