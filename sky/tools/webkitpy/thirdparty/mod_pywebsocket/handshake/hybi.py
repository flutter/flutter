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


"""This file provides the opening handshake processor for the WebSocket
protocol (RFC 6455).

Specification:
http://tools.ietf.org/html/rfc6455
"""


# Note: request.connection.write is used in this module, even though mod_python
# document says that it should be used only in connection handlers.
# Unfortunately, we have no other options. For example, request.write is not
# suitable because it doesn't allow direct raw bytes writing.


import base64
import logging
import os
import re

from mod_pywebsocket import common
from mod_pywebsocket.extensions import get_extension_processor
from mod_pywebsocket.extensions import is_compression_extension
from mod_pywebsocket.handshake._base import check_request_line
from mod_pywebsocket.handshake._base import format_header
from mod_pywebsocket.handshake._base import get_mandatory_header
from mod_pywebsocket.handshake._base import HandshakeException
from mod_pywebsocket.handshake._base import parse_token_list
from mod_pywebsocket.handshake._base import validate_mandatory_header
from mod_pywebsocket.handshake._base import validate_subprotocol
from mod_pywebsocket.handshake._base import VersionException
from mod_pywebsocket.stream import Stream
from mod_pywebsocket.stream import StreamOptions
from mod_pywebsocket import util


# Used to validate the value in the Sec-WebSocket-Key header strictly. RFC 4648
# disallows non-zero padding, so the character right before == must be any of
# A, Q, g and w.
_SEC_WEBSOCKET_KEY_REGEX = re.compile('^[+/0-9A-Za-z]{21}[AQgw]==$')

# Defining aliases for values used frequently.
_VERSION_LATEST = common.VERSION_HYBI_LATEST
_VERSION_LATEST_STRING = str(_VERSION_LATEST)
_SUPPORTED_VERSIONS = [
    _VERSION_LATEST,
]


def compute_accept(key):
    """Computes value for the Sec-WebSocket-Accept header from value of the
    Sec-WebSocket-Key header.
    """

    accept_binary = util.sha1_hash(
        key + common.WEBSOCKET_ACCEPT_UUID).digest()
    accept = base64.b64encode(accept_binary)

    return (accept, accept_binary)


class Handshaker(object):
    """Opening handshake processor for the WebSocket protocol (RFC 6455)."""

    def __init__(self, request, dispatcher):
        """Construct an instance.

        Args:
            request: mod_python request.
            dispatcher: Dispatcher (dispatch.Dispatcher).

        Handshaker will add attributes such as ws_resource during handshake.
        """

        self._logger = util.get_class_logger(self)

        self._request = request
        self._dispatcher = dispatcher

    def _validate_connection_header(self):
        connection = get_mandatory_header(
            self._request, common.CONNECTION_HEADER)

        try:
            connection_tokens = parse_token_list(connection)
        except HandshakeException, e:
            raise HandshakeException(
                'Failed to parse %s: %s' % (common.CONNECTION_HEADER, e))

        connection_is_valid = False
        for token in connection_tokens:
            if token.lower() == common.UPGRADE_CONNECTION_TYPE.lower():
                connection_is_valid = True
                break
        if not connection_is_valid:
            raise HandshakeException(
                '%s header doesn\'t contain "%s"' %
                (common.CONNECTION_HEADER, common.UPGRADE_CONNECTION_TYPE))

    def do_handshake(self):
        self._request.ws_close_code = None
        self._request.ws_close_reason = None

        # Parsing.

        check_request_line(self._request)

        validate_mandatory_header(
            self._request,
            common.UPGRADE_HEADER,
            common.WEBSOCKET_UPGRADE_TYPE)

        self._validate_connection_header()

        self._request.ws_resource = self._request.uri

        unused_host = get_mandatory_header(self._request, common.HOST_HEADER)

        self._request.ws_version = self._check_version()

        try:
            self._get_origin()
            self._set_protocol()
            self._parse_extensions()

            # Key validation, response generation.

            key = self._get_key()
            (accept, accept_binary) = compute_accept(key)
            self._logger.debug(
                '%s: %r (%s)',
                common.SEC_WEBSOCKET_ACCEPT_HEADER,
                accept,
                util.hexify(accept_binary))

            self._logger.debug('Protocol version is RFC 6455')

            # Setup extension processors.

            processors = []
            if self._request.ws_requested_extensions is not None:
                for extension_request in self._request.ws_requested_extensions:
                    processor = get_extension_processor(extension_request)
                    # Unknown extension requests are just ignored.
                    if processor is not None:
                        processors.append(processor)
            self._request.ws_extension_processors = processors

            # List of extra headers. The extra handshake handler may add header
            # data as name/value pairs to this list and pywebsocket appends
            # them to the WebSocket handshake.
            self._request.extra_headers = []

            # Extra handshake handler may modify/remove processors.
            self._dispatcher.do_extra_handshake(self._request)
            processors = filter(lambda processor: processor is not None,
                                self._request.ws_extension_processors)

            # Ask each processor if there are extensions on the request which
            # cannot co-exist. When processor decided other processors cannot
            # co-exist with it, the processor marks them (or itself) as
            # "inactive". The first extension processor has the right to
            # make the final call.
            for processor in reversed(processors):
                if processor.is_active():
                    processor.check_consistency_with_other_processors(
                        processors)
            processors = filter(lambda processor: processor.is_active(),
                                processors)

            accepted_extensions = []

            # We need to take into account of mux extension here.
            # If mux extension exists:
            # - Remove processors of extensions for logical channel,
            #   which are processors located before the mux processor
            # - Pass extension requests for logical channel to mux processor
            # - Attach the mux processor to the request. It will be referred
            #   by dispatcher to see whether the dispatcher should use mux
            #   handler or not.
            mux_index = -1
            for i, processor in enumerate(processors):
                if processor.name() == common.MUX_EXTENSION:
                    mux_index = i
                    break
            if mux_index >= 0:
                logical_channel_extensions = []
                for processor in processors[:mux_index]:
                    logical_channel_extensions.append(processor.request())
                    processor.set_active(False)
                self._request.mux_processor = processors[mux_index]
                self._request.mux_processor.set_extensions(
                    logical_channel_extensions)
                processors = filter(lambda processor: processor.is_active(),
                                    processors)

            stream_options = StreamOptions()

            for index, processor in enumerate(processors):
                if not processor.is_active():
                    continue

                extension_response = processor.get_extension_response()
                if extension_response is None:
                    # Rejected.
                    continue

                accepted_extensions.append(extension_response)

                processor.setup_stream_options(stream_options)

                if not is_compression_extension(processor.name()):
                    continue

                # Inactivate all of the following compression extensions.
                for j in xrange(index + 1, len(processors)):
                    if is_compression_extension(processors[j].name()):
                        processors[j].set_active(False)

            if len(accepted_extensions) > 0:
                self._request.ws_extensions = accepted_extensions
                self._logger.debug(
                    'Extensions accepted: %r',
                    map(common.ExtensionParameter.name, accepted_extensions))
            else:
                self._request.ws_extensions = None

            self._request.ws_stream = self._create_stream(stream_options)

            if self._request.ws_requested_protocols is not None:
                if self._request.ws_protocol is None:
                    raise HandshakeException(
                        'do_extra_handshake must choose one subprotocol from '
                        'ws_requested_protocols and set it to ws_protocol')
                validate_subprotocol(self._request.ws_protocol)

                self._logger.debug(
                    'Subprotocol accepted: %r',
                    self._request.ws_protocol)
            else:
                if self._request.ws_protocol is not None:
                    raise HandshakeException(
                        'ws_protocol must be None when the client didn\'t '
                        'request any subprotocol')

            self._send_handshake(accept)
        except HandshakeException, e:
            if not e.status:
                # Fallback to 400 bad request by default.
                e.status = common.HTTP_STATUS_BAD_REQUEST
            raise e

    def _get_origin(self):
        origin_header = common.ORIGIN_HEADER
        origin = self._request.headers_in.get(origin_header)
        if origin is None:
            self._logger.debug('Client request does not have origin header')
        self._request.ws_origin = origin

    def _check_version(self):
        version = get_mandatory_header(self._request,
                                       common.SEC_WEBSOCKET_VERSION_HEADER)
        if version == _VERSION_LATEST_STRING:
            return _VERSION_LATEST

        if version.find(',') >= 0:
            raise HandshakeException(
                'Multiple versions (%r) are not allowed for header %s' %
                (version, common.SEC_WEBSOCKET_VERSION_HEADER),
                status=common.HTTP_STATUS_BAD_REQUEST)
        raise VersionException(
            'Unsupported version %r for header %s' %
            (version, common.SEC_WEBSOCKET_VERSION_HEADER),
            supported_versions=', '.join(map(str, _SUPPORTED_VERSIONS)))

    def _set_protocol(self):
        self._request.ws_protocol = None

        protocol_header = self._request.headers_in.get(
            common.SEC_WEBSOCKET_PROTOCOL_HEADER)

        if protocol_header is None:
            self._request.ws_requested_protocols = None
            return

        self._request.ws_requested_protocols = parse_token_list(
            protocol_header)
        self._logger.debug('Subprotocols requested: %r',
                           self._request.ws_requested_protocols)

    def _parse_extensions(self):
        extensions_header = self._request.headers_in.get(
            common.SEC_WEBSOCKET_EXTENSIONS_HEADER)
        if not extensions_header:
            self._request.ws_requested_extensions = None
            return

        try:
            self._request.ws_requested_extensions = common.parse_extensions(
                extensions_header)
        except common.ExtensionParsingException, e:
            raise HandshakeException(
                'Failed to parse Sec-WebSocket-Extensions header: %r' % e)

        self._logger.debug(
            'Extensions requested: %r',
            map(common.ExtensionParameter.name,
                self._request.ws_requested_extensions))

    def _validate_key(self, key):
        if key.find(',') >= 0:
            raise HandshakeException('Request has multiple %s header lines or '
                                     'contains illegal character \',\': %r' %
                                     (common.SEC_WEBSOCKET_KEY_HEADER, key))

        # Validate
        key_is_valid = False
        try:
            # Validate key by quick regex match before parsing by base64
            # module. Because base64 module skips invalid characters, we have
            # to do this in advance to make this server strictly reject illegal
            # keys.
            if _SEC_WEBSOCKET_KEY_REGEX.match(key):
                decoded_key = base64.b64decode(key)
                if len(decoded_key) == 16:
                    key_is_valid = True
        except TypeError, e:
            pass

        if not key_is_valid:
            raise HandshakeException(
                'Illegal value for header %s: %r' %
                (common.SEC_WEBSOCKET_KEY_HEADER, key))

        return decoded_key

    def _get_key(self):
        key = get_mandatory_header(
            self._request, common.SEC_WEBSOCKET_KEY_HEADER)

        decoded_key = self._validate_key(key)

        self._logger.debug(
            '%s: %r (%s)',
            common.SEC_WEBSOCKET_KEY_HEADER,
            key,
            util.hexify(decoded_key))

        return key

    def _create_stream(self, stream_options):
        return Stream(self._request, stream_options)

    def _create_handshake_response(self, accept):
        response = []

        response.append('HTTP/1.1 101 Switching Protocols\r\n')

        # WebSocket headers
        response.append(format_header(
            common.UPGRADE_HEADER, common.WEBSOCKET_UPGRADE_TYPE))
        response.append(format_header(
            common.CONNECTION_HEADER, common.UPGRADE_CONNECTION_TYPE))
        response.append(format_header(
            common.SEC_WEBSOCKET_ACCEPT_HEADER, accept))
        if self._request.ws_protocol is not None:
            response.append(format_header(
                common.SEC_WEBSOCKET_PROTOCOL_HEADER,
                self._request.ws_protocol))
        if (self._request.ws_extensions is not None and
            len(self._request.ws_extensions) != 0):
            response.append(format_header(
                common.SEC_WEBSOCKET_EXTENSIONS_HEADER,
                common.format_extensions(self._request.ws_extensions)))

        # Headers not specific for WebSocket
        for name, value in self._request.extra_headers:
            response.append(format_header(name, value))

        response.append('\r\n')

        return ''.join(response)

    def _send_handshake(self, accept):
        raw_response = self._create_handshake_response(accept)
        self._request.connection.write(raw_response)
        self._logger.debug('Sent server\'s opening handshake: %r',
                           raw_response)


# vi:sts=4 sw=4 et
