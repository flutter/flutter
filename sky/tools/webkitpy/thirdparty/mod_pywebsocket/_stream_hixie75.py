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


"""This file provides a class for parsing/building frames of the WebSocket
protocol version HyBi 00 and Hixie 75.

Specification:
- HyBi 00 http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-00
- Hixie 75 http://tools.ietf.org/html/draft-hixie-thewebsocketprotocol-75
"""


from mod_pywebsocket import common
from mod_pywebsocket._stream_base import BadOperationException
from mod_pywebsocket._stream_base import ConnectionTerminatedException
from mod_pywebsocket._stream_base import InvalidFrameException
from mod_pywebsocket._stream_base import StreamBase
from mod_pywebsocket._stream_base import UnsupportedFrameException
from mod_pywebsocket import util


class StreamHixie75(StreamBase):
    """A class for parsing/building frames of the WebSocket protocol version
    HyBi 00 and Hixie 75.
    """

    def __init__(self, request, enable_closing_handshake=False):
        """Construct an instance.

        Args:
            request: mod_python request.
            enable_closing_handshake: to let StreamHixie75 perform closing
                                      handshake as specified in HyBi 00, set
                                      this option to True.
        """

        StreamBase.__init__(self, request)

        self._logger = util.get_class_logger(self)

        self._enable_closing_handshake = enable_closing_handshake

        self._request.client_terminated = False
        self._request.server_terminated = False

    def send_message(self, message, end=True, binary=False):
        """Send message.

        Args:
            message: unicode string to send.
            binary: not used in hixie75.

        Raises:
            BadOperationException: when called on a server-terminated
                connection.
        """

        if not end:
            raise BadOperationException(
                'StreamHixie75 doesn\'t support send_message with end=False')

        if binary:
            raise BadOperationException(
                'StreamHixie75 doesn\'t support send_message with binary=True')

        if self._request.server_terminated:
            raise BadOperationException(
                'Requested send_message after sending out a closing handshake')

        self._write(''.join(['\x00', message.encode('utf-8'), '\xff']))

    def _read_payload_length_hixie75(self):
        """Reads a length header in a Hixie75 version frame with length.

        Raises:
            ConnectionTerminatedException: when read returns empty string.
        """

        length = 0
        while True:
            b_str = self._read(1)
            b = ord(b_str)
            length = length * 128 + (b & 0x7f)
            if (b & 0x80) == 0:
                break
        return length

    def receive_message(self):
        """Receive a WebSocket frame and return its payload an unicode string.

        Returns:
            payload unicode string in a WebSocket frame.

        Raises:
            ConnectionTerminatedException: when read returns empty
                string.
            BadOperationException: when called on a client-terminated
                connection.
        """

        if self._request.client_terminated:
            raise BadOperationException(
                'Requested receive_message after receiving a closing '
                'handshake')

        while True:
            # Read 1 byte.
            # mp_conn.read will block if no bytes are available.
            # Timeout is controlled by TimeOut directive of Apache.
            frame_type_str = self.receive_bytes(1)
            frame_type = ord(frame_type_str)
            if (frame_type & 0x80) == 0x80:
                # The payload length is specified in the frame.
                # Read and discard.
                length = self._read_payload_length_hixie75()
                if length > 0:
                    _ = self.receive_bytes(length)
                # 5.3 3. 12. if /type/ is 0xFF and /length/ is 0, then set the
                # /client terminated/ flag and abort these steps.
                if not self._enable_closing_handshake:
                    continue

                if frame_type == 0xFF and length == 0:
                    self._request.client_terminated = True

                    if self._request.server_terminated:
                        self._logger.debug(
                            'Received ack for server-initiated closing '
                            'handshake')
                        return None

                    self._logger.debug(
                        'Received client-initiated closing handshake')

                    self._send_closing_handshake()
                    self._logger.debug(
                        'Sent ack for client-initiated closing handshake')
                    return None
            else:
                # The payload is delimited with \xff.
                bytes = self._read_until('\xff')
                # The WebSocket protocol section 4.4 specifies that invalid
                # characters must be replaced with U+fffd REPLACEMENT
                # CHARACTER.
                message = bytes.decode('utf-8', 'replace')
                if frame_type == 0x00:
                    return message
                # Discard data of other types.

    def _send_closing_handshake(self):
        if not self._enable_closing_handshake:
            raise BadOperationException(
                'Closing handshake is not supported in Hixie 75 protocol')

        self._request.server_terminated = True

        # 5.3 the server may decide to terminate the WebSocket connection by
        # running through the following steps:
        # 1. send a 0xFF byte and a 0x00 byte to the client to indicate the
        # start of the closing handshake.
        self._write('\xff\x00')

    def close_connection(self, unused_code='', unused_reason=''):
        """Closes a WebSocket connection.

        Raises:
            ConnectionTerminatedException: when closing handshake was
                not successfull.
        """

        if self._request.server_terminated:
            self._logger.debug(
                'Requested close_connection but server is already terminated')
            return

        if not self._enable_closing_handshake:
            self._request.server_terminated = True
            self._logger.debug('Connection closed')
            return

        self._send_closing_handshake()
        self._logger.debug('Sent server-initiated closing handshake')

        # TODO(ukai): 2. wait until the /client terminated/ flag has been set,
        # or until a server-defined timeout expires.
        #
        # For now, we expect receiving closing handshake right after sending
        # out closing handshake, and if we couldn't receive non-handshake
        # frame, we take it as ConnectionTerminatedException.
        message = self.receive_message()
        if message is not None:
            raise ConnectionTerminatedException(
                'Didn\'t receive valid ack for closing handshake')
        # TODO: 3. close the WebSocket connection.
        # note: mod_python Connection (mp_conn) doesn't have close method.

    def send_ping(self, body):
        raise BadOperationException(
            'StreamHixie75 doesn\'t support send_ping')


# vi:sts=4 sw=4 et
