# Copyright 2011, Google Inc.
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


"""This file provides the opening handshake processor for the WebSocket
protocol version HyBi 00.

Specification:
http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-00
"""


# Note: request.connection.write/read are used in this module, even though
# mod_python document says that they should be used only in connection
# handlers. Unfortunately, we have no other options. For example,
# request.write/read are not suitable because they don't allow direct raw bytes
# writing/reading.


import logging
import re
import struct

from mod_pywebsocket import common
from mod_pywebsocket.stream import StreamHixie75
from mod_pywebsocket import util
from mod_pywebsocket.handshake._base import HandshakeException
from mod_pywebsocket.handshake._base import check_request_line
from mod_pywebsocket.handshake._base import format_header
from mod_pywebsocket.handshake._base import get_default_port
from mod_pywebsocket.handshake._base import get_mandatory_header
from mod_pywebsocket.handshake._base import parse_host_header
from mod_pywebsocket.handshake._base import validate_mandatory_header


_MANDATORY_HEADERS = [
    # key, expected value or None
    [common.UPGRADE_HEADER, common.WEBSOCKET_UPGRADE_TYPE_HIXIE75],
    [common.CONNECTION_HEADER, common.UPGRADE_CONNECTION_TYPE],
]


def _validate_subprotocol(subprotocol):
    """Checks if characters in subprotocol are in range between U+0020 and
    U+007E. A value in the Sec-WebSocket-Protocol field need to satisfy this
    requirement.

    See the Section 4.1. Opening handshake of the spec.
    """

    if not subprotocol:
        raise HandshakeException('Invalid subprotocol name: empty')

    # Parameter should be in the range U+0020 to U+007E.
    for c in subprotocol:
        if not 0x20 <= ord(c) <= 0x7e:
            raise HandshakeException(
                'Illegal character in subprotocol name: %r' % c)


def _check_header_lines(request, mandatory_headers):
    check_request_line(request)

    # The expected field names, and the meaning of their corresponding
    # values, are as follows.
    #  |Upgrade| and |Connection|
    for key, expected_value in mandatory_headers:
        validate_mandatory_header(request, key, expected_value)


def _build_location(request):
    """Build WebSocket location for request."""

    location_parts = []
    if request.is_https():
        location_parts.append(common.WEB_SOCKET_SECURE_SCHEME)
    else:
        location_parts.append(common.WEB_SOCKET_SCHEME)
    location_parts.append('://')
    host, port = parse_host_header(request)
    connection_port = request.connection.local_addr[1]
    if port != connection_port:
        raise HandshakeException('Header/connection port mismatch: %d/%d' %
                                 (port, connection_port))
    location_parts.append(host)
    if (port != get_default_port(request.is_https())):
        location_parts.append(':')
        location_parts.append(str(port))
    location_parts.append(request.unparsed_uri)
    return ''.join(location_parts)


class Handshaker(object):
    """Opening handshake processor for the WebSocket protocol version HyBi 00.
    """

    def __init__(self, request, dispatcher):
        """Construct an instance.

        Args:
            request: mod_python request.
            dispatcher: Dispatcher (dispatch.Dispatcher).

        Handshaker will add attributes such as ws_resource in performing
        handshake.
        """

        self._logger = util.get_class_logger(self)

        self._request = request
        self._dispatcher = dispatcher

    def do_handshake(self):
        """Perform WebSocket Handshake.

        On _request, we set
            ws_resource, ws_protocol, ws_location, ws_origin, ws_challenge,
            ws_challenge_md5: WebSocket handshake information.
            ws_stream: Frame generation/parsing class.
            ws_version: Protocol version.

        Raises:
            HandshakeException: when any error happened in parsing the opening
                                handshake request.
        """

        # 5.1 Reading the client's opening handshake.
        # dispatcher sets it in self._request.
        _check_header_lines(self._request, _MANDATORY_HEADERS)
        self._set_resource()
        self._set_subprotocol()
        self._set_location()
        self._set_origin()
        self._set_challenge_response()
        self._set_protocol_version()

        self._dispatcher.do_extra_handshake(self._request)

        self._send_handshake()

    def _set_resource(self):
        self._request.ws_resource = self._request.uri

    def _set_subprotocol(self):
        # |Sec-WebSocket-Protocol|
        subprotocol = self._request.headers_in.get(
            common.SEC_WEBSOCKET_PROTOCOL_HEADER)
        if subprotocol is not None:
            _validate_subprotocol(subprotocol)
        self._request.ws_protocol = subprotocol

    def _set_location(self):
        # |Host|
        host = self._request.headers_in.get(common.HOST_HEADER)
        if host is not None:
            self._request.ws_location = _build_location(self._request)
        # TODO(ukai): check host is this host.

    def _set_origin(self):
        # |Origin|
        origin = self._request.headers_in.get(common.ORIGIN_HEADER)
        if origin is not None:
            self._request.ws_origin = origin

    def _set_protocol_version(self):
        # |Sec-WebSocket-Draft|
        draft = self._request.headers_in.get(common.SEC_WEBSOCKET_DRAFT_HEADER)
        if draft is not None and draft != '0':
            raise HandshakeException('Illegal value for %s: %s' %
                                     (common.SEC_WEBSOCKET_DRAFT_HEADER,
                                      draft))

        self._logger.debug('Protocol version is HyBi 00')
        self._request.ws_version = common.VERSION_HYBI00
        self._request.ws_stream = StreamHixie75(self._request, True)

    def _set_challenge_response(self):
        # 5.2 4-8.
        self._request.ws_challenge = self._get_challenge()
        # 5.2 9. let /response/ be the MD5 finterprint of /challenge/
        self._request.ws_challenge_md5 = util.md5_hash(
            self._request.ws_challenge).digest()
        self._logger.debug(
            'Challenge: %r (%s)',
            self._request.ws_challenge,
            util.hexify(self._request.ws_challenge))
        self._logger.debug(
            'Challenge response: %r (%s)',
            self._request.ws_challenge_md5,
            util.hexify(self._request.ws_challenge_md5))

    def _get_key_value(self, key_field):
        key_value = get_mandatory_header(self._request, key_field)

        self._logger.debug('%s: %r', key_field, key_value)

        # 5.2 4. let /key-number_n/ be the digits (characters in the range
        # U+0030 DIGIT ZERO (0) to U+0039 DIGIT NINE (9)) in /key_n/,
        # interpreted as a base ten integer, ignoring all other characters
        # in /key_n/.
        try:
            key_number = int(re.sub("\\D", "", key_value))
        except:
            raise HandshakeException('%s field contains no digit' % key_field)
        # 5.2 5. let /spaces_n/ be the number of U+0020 SPACE characters
        # in /key_n/.
        spaces = re.subn(" ", "", key_value)[1]
        if spaces == 0:
            raise HandshakeException('%s field contains no space' % key_field)

        self._logger.debug(
            '%s: Key-number is %d and number of spaces is %d',
            key_field, key_number, spaces)

        # 5.2 6. if /key-number_n/ is not an integral multiple of /spaces_n/
        # then abort the WebSocket connection.
        if key_number % spaces != 0:
            raise HandshakeException(
                '%s: Key-number (%d) is not an integral multiple of spaces '
                '(%d)' % (key_field, key_number, spaces))
        # 5.2 7. let /part_n/ be /key-number_n/ divided by /spaces_n/.
        part = key_number / spaces
        self._logger.debug('%s: Part is %d', key_field, part)
        return part

    def _get_challenge(self):
        # 5.2 4-7.
        key1 = self._get_key_value(common.SEC_WEBSOCKET_KEY1_HEADER)
        key2 = self._get_key_value(common.SEC_WEBSOCKET_KEY2_HEADER)
        # 5.2 8. let /challenge/ be the concatenation of /part_1/,
        challenge = ''
        challenge += struct.pack('!I', key1)  # network byteorder int
        challenge += struct.pack('!I', key2)  # network byteorder int
        challenge += self._request.connection.read(8)
        return challenge

    def _send_handshake(self):
        response = []

        # 5.2 10. send the following line.
        response.append('HTTP/1.1 101 WebSocket Protocol Handshake\r\n')

        # 5.2 11. send the following fields to the client.
        response.append(format_header(
            common.UPGRADE_HEADER, common.WEBSOCKET_UPGRADE_TYPE_HIXIE75))
        response.append(format_header(
            common.CONNECTION_HEADER, common.UPGRADE_CONNECTION_TYPE))
        response.append(format_header(
            common.SEC_WEBSOCKET_LOCATION_HEADER, self._request.ws_location))
        response.append(format_header(
            common.SEC_WEBSOCKET_ORIGIN_HEADER, self._request.ws_origin))
        if self._request.ws_protocol:
            response.append(format_header(
                common.SEC_WEBSOCKET_PROTOCOL_HEADER,
                self._request.ws_protocol))
        # 5.2 12. send two bytes 0x0D 0x0A.
        response.append('\r\n')
        # 5.2 13. send /response/
        response.append(self._request.ws_challenge_md5)

        raw_response = ''.join(response)
        self._request.connection.write(raw_response)
        self._logger.debug('Sent server\'s opening handshake: %r',
                           raw_response)


# vi:sts=4 sw=4 et
