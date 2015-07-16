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


"""Common functions and exceptions used by WebSocket opening handshake
processors.
"""


from mod_pywebsocket import common
from mod_pywebsocket import http_header_util


class AbortedByUserException(Exception):
    """Exception for aborting a connection intentionally.

    If this exception is raised in do_extra_handshake handler, the connection
    will be abandoned. No other WebSocket or HTTP(S) handler will be invoked.

    If this exception is raised in transfer_data_handler, the connection will
    be closed without closing handshake. No other WebSocket or HTTP(S) handler
    will be invoked.
    """

    pass


class HandshakeException(Exception):
    """This exception will be raised when an error occurred while processing
    WebSocket initial handshake.
    """

    def __init__(self, name, status=None):
        super(HandshakeException, self).__init__(name)
        self.status = status


class VersionException(Exception):
    """This exception will be raised when a version of client request does not
    match with version the server supports.
    """

    def __init__(self, name, supported_versions=''):
        """Construct an instance.

        Args:
            supported_version: a str object to show supported hybi versions.
                               (e.g. '8, 13')
        """
        super(VersionException, self).__init__(name)
        self.supported_versions = supported_versions


def get_default_port(is_secure):
    if is_secure:
        return common.DEFAULT_WEB_SOCKET_SECURE_PORT
    else:
        return common.DEFAULT_WEB_SOCKET_PORT


def validate_subprotocol(subprotocol):
    """Validate a value in the Sec-WebSocket-Protocol field.

    See the Section 4.1., 4.2.2., and 4.3. of RFC 6455.
    """

    if not subprotocol:
        raise HandshakeException('Invalid subprotocol name: empty')

    # Parameter should be encoded HTTP token.
    state = http_header_util.ParsingState(subprotocol)
    token = http_header_util.consume_token(state)
    rest = http_header_util.peek(state)
    # If |rest| is not None, |subprotocol| is not one token or invalid. If
    # |rest| is None, |token| must not be None because |subprotocol| is
    # concatenation of |token| and |rest| and is not None.
    if rest is not None:
        raise HandshakeException('Invalid non-token string in subprotocol '
                                 'name: %r' % rest)


def parse_host_header(request):
    fields = request.headers_in[common.HOST_HEADER].split(':', 1)
    if len(fields) == 1:
        return fields[0], get_default_port(request.is_https())
    try:
        return fields[0], int(fields[1])
    except ValueError, e:
        raise HandshakeException('Invalid port number format: %r' % e)


def format_header(name, value):
    return '%s: %s\r\n' % (name, value)


def get_mandatory_header(request, key):
    value = request.headers_in.get(key)
    if value is None:
        raise HandshakeException('Header %s is not defined' % key)
    return value


def validate_mandatory_header(request, key, expected_value, fail_status=None):
    value = get_mandatory_header(request, key)

    if value.lower() != expected_value.lower():
        raise HandshakeException(
            'Expected %r for header %s but found %r (case-insensitive)' %
            (expected_value, key, value), status=fail_status)


def check_request_line(request):
    # 5.1 1. The three character UTF-8 string "GET".
    # 5.1 2. A UTF-8-encoded U+0020 SPACE character (0x20 byte).
    if request.method != 'GET':
        raise HandshakeException('Method is not GET: %r' % request.method)

    if request.protocol != 'HTTP/1.1':
        raise HandshakeException('Version is not HTTP/1.1: %r' %
                                 request.protocol)


def parse_token_list(data):
    """Parses a header value which follows 1#token and returns parsed elements
    as a list of strings.

    Leading LWSes must be trimmed.
    """

    state = http_header_util.ParsingState(data)

    token_list = []

    while True:
        token = http_header_util.consume_token(state)
        if token is not None:
            token_list.append(token)

        http_header_util.consume_lwses(state)

        if http_header_util.peek(state) is None:
            break

        if not http_header_util.consume_string(state, ','):
            raise HandshakeException(
                'Expected a comma but found %r' % http_header_util.peek(state))

        http_header_util.consume_lwses(state)

    if len(token_list) == 0:
        raise HandshakeException('No valid token found')

    return token_list


# vi:sts=4 sw=4 et
