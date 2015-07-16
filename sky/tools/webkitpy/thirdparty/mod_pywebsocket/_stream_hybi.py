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


"""This file provides classes and helper functions for parsing/building frames
of the WebSocket protocol (RFC 6455).

Specification:
http://tools.ietf.org/html/rfc6455
"""


from collections import deque
import logging
import os
import struct
import time

from mod_pywebsocket import common
from mod_pywebsocket import util
from mod_pywebsocket._stream_base import BadOperationException
from mod_pywebsocket._stream_base import ConnectionTerminatedException
from mod_pywebsocket._stream_base import InvalidFrameException
from mod_pywebsocket._stream_base import InvalidUTF8Exception
from mod_pywebsocket._stream_base import StreamBase
from mod_pywebsocket._stream_base import UnsupportedFrameException


_NOOP_MASKER = util.NoopMasker()


class Frame(object):

    def __init__(self, fin=1, rsv1=0, rsv2=0, rsv3=0,
                 opcode=None, payload=''):
        self.fin = fin
        self.rsv1 = rsv1
        self.rsv2 = rsv2
        self.rsv3 = rsv3
        self.opcode = opcode
        self.payload = payload


# Helper functions made public to be used for writing unittests for WebSocket
# clients.


def create_length_header(length, mask):
    """Creates a length header.

    Args:
        length: Frame length. Must be less than 2^63.
        mask: Mask bit. Must be boolean.

    Raises:
        ValueError: when bad data is given.
    """

    if mask:
        mask_bit = 1 << 7
    else:
        mask_bit = 0

    if length < 0:
        raise ValueError('length must be non negative integer')
    elif length <= 125:
        return chr(mask_bit | length)
    elif length < (1 << 16):
        return chr(mask_bit | 126) + struct.pack('!H', length)
    elif length < (1 << 63):
        return chr(mask_bit | 127) + struct.pack('!Q', length)
    else:
        raise ValueError('Payload is too big for one frame')


def create_header(opcode, payload_length, fin, rsv1, rsv2, rsv3, mask):
    """Creates a frame header.

    Raises:
        Exception: when bad data is given.
    """

    if opcode < 0 or 0xf < opcode:
        raise ValueError('Opcode out of range')

    if payload_length < 0 or (1 << 63) <= payload_length:
        raise ValueError('payload_length out of range')

    if (fin | rsv1 | rsv2 | rsv3) & ~1:
        raise ValueError('FIN bit and Reserved bit parameter must be 0 or 1')

    header = ''

    first_byte = ((fin << 7)
                  | (rsv1 << 6) | (rsv2 << 5) | (rsv3 << 4)
                  | opcode)
    header += chr(first_byte)
    header += create_length_header(payload_length, mask)

    return header


def _build_frame(header, body, mask):
    if not mask:
        return header + body

    masking_nonce = os.urandom(4)
    masker = util.RepeatedXorMasker(masking_nonce)

    return header + masking_nonce + masker.mask(body)


def _filter_and_format_frame_object(frame, mask, frame_filters):
    for frame_filter in frame_filters:
        frame_filter.filter(frame)

    header = create_header(
        frame.opcode, len(frame.payload), frame.fin,
        frame.rsv1, frame.rsv2, frame.rsv3, mask)
    return _build_frame(header, frame.payload, mask)


def create_binary_frame(
    message, opcode=common.OPCODE_BINARY, fin=1, mask=False, frame_filters=[]):
    """Creates a simple binary frame with no extension, reserved bit."""

    frame = Frame(fin=fin, opcode=opcode, payload=message)
    return _filter_and_format_frame_object(frame, mask, frame_filters)


def create_text_frame(
    message, opcode=common.OPCODE_TEXT, fin=1, mask=False, frame_filters=[]):
    """Creates a simple text frame with no extension, reserved bit."""

    encoded_message = message.encode('utf-8')
    return create_binary_frame(encoded_message, opcode, fin, mask,
                               frame_filters)


def parse_frame(receive_bytes, logger=None,
                ws_version=common.VERSION_HYBI_LATEST,
                unmask_receive=True):
    """Parses a frame. Returns a tuple containing each header field and
    payload.

    Args:
        receive_bytes: a function that reads frame data from a stream or
            something similar. The function takes length of the bytes to be
            read. The function must raise ConnectionTerminatedException if
            there is not enough data to be read.
        logger: a logging object.
        ws_version: the version of WebSocket protocol.
        unmask_receive: unmask received frames. When received unmasked
            frame, raises InvalidFrameException.

    Raises:
        ConnectionTerminatedException: when receive_bytes raises it.
        InvalidFrameException: when the frame contains invalid data.
    """

    if not logger:
        logger = logging.getLogger()

    logger.log(common.LOGLEVEL_FINE, 'Receive the first 2 octets of a frame')

    received = receive_bytes(2)

    first_byte = ord(received[0])
    fin = (first_byte >> 7) & 1
    rsv1 = (first_byte >> 6) & 1
    rsv2 = (first_byte >> 5) & 1
    rsv3 = (first_byte >> 4) & 1
    opcode = first_byte & 0xf

    second_byte = ord(received[1])
    mask = (second_byte >> 7) & 1
    payload_length = second_byte & 0x7f

    logger.log(common.LOGLEVEL_FINE,
               'FIN=%s, RSV1=%s, RSV2=%s, RSV3=%s, opcode=%s, '
               'Mask=%s, Payload_length=%s',
               fin, rsv1, rsv2, rsv3, opcode, mask, payload_length)

    if (mask == 1) != unmask_receive:
        raise InvalidFrameException(
            'Mask bit on the received frame did\'nt match masking '
            'configuration for received frames')

    # The HyBi and later specs disallow putting a value in 0x0-0xFFFF
    # into the 8-octet extended payload length field (or 0x0-0xFD in
    # 2-octet field).
    valid_length_encoding = True
    length_encoding_bytes = 1
    if payload_length == 127:
        logger.log(common.LOGLEVEL_FINE,
                   'Receive 8-octet extended payload length')

        extended_payload_length = receive_bytes(8)
        payload_length = struct.unpack(
            '!Q', extended_payload_length)[0]
        if payload_length > 0x7FFFFFFFFFFFFFFF:
            raise InvalidFrameException(
                'Extended payload length >= 2^63')
        if ws_version >= 13 and payload_length < 0x10000:
            valid_length_encoding = False
            length_encoding_bytes = 8

        logger.log(common.LOGLEVEL_FINE,
                   'Decoded_payload_length=%s', payload_length)
    elif payload_length == 126:
        logger.log(common.LOGLEVEL_FINE,
                   'Receive 2-octet extended payload length')

        extended_payload_length = receive_bytes(2)
        payload_length = struct.unpack(
            '!H', extended_payload_length)[0]
        if ws_version >= 13 and payload_length < 126:
            valid_length_encoding = False
            length_encoding_bytes = 2

        logger.log(common.LOGLEVEL_FINE,
                   'Decoded_payload_length=%s', payload_length)

    if not valid_length_encoding:
        logger.warning(
            'Payload length is not encoded using the minimal number of '
            'bytes (%d is encoded using %d bytes)',
            payload_length,
            length_encoding_bytes)

    if mask == 1:
        logger.log(common.LOGLEVEL_FINE, 'Receive mask')

        masking_nonce = receive_bytes(4)
        masker = util.RepeatedXorMasker(masking_nonce)

        logger.log(common.LOGLEVEL_FINE, 'Mask=%r', masking_nonce)
    else:
        masker = _NOOP_MASKER

    logger.log(common.LOGLEVEL_FINE, 'Receive payload data')
    if logger.isEnabledFor(common.LOGLEVEL_FINE):
        receive_start = time.time()

    raw_payload_bytes = receive_bytes(payload_length)

    if logger.isEnabledFor(common.LOGLEVEL_FINE):
        logger.log(
            common.LOGLEVEL_FINE,
            'Done receiving payload data at %s MB/s',
            payload_length / (time.time() - receive_start) / 1000 / 1000)
    logger.log(common.LOGLEVEL_FINE, 'Unmask payload data')

    if logger.isEnabledFor(common.LOGLEVEL_FINE):
        unmask_start = time.time()

    unmasked_bytes = masker.mask(raw_payload_bytes)

    if logger.isEnabledFor(common.LOGLEVEL_FINE):
        logger.log(
            common.LOGLEVEL_FINE,
            'Done unmasking payload data at %s MB/s',
            payload_length / (time.time() - unmask_start) / 1000 / 1000)

    return opcode, unmasked_bytes, fin, rsv1, rsv2, rsv3


class FragmentedFrameBuilder(object):
    """A stateful class to send a message as fragments."""

    def __init__(self, mask, frame_filters=[], encode_utf8=True):
        """Constructs an instance."""

        self._mask = mask
        self._frame_filters = frame_filters
        # This is for skipping UTF-8 encoding when building text type frames
        # from compressed data.
        self._encode_utf8 = encode_utf8

        self._started = False

        # Hold opcode of the first frame in messages to verify types of other
        # frames in the message are all the same.
        self._opcode = common.OPCODE_TEXT

    def build(self, payload_data, end, binary):
        if binary:
            frame_type = common.OPCODE_BINARY
        else:
            frame_type = common.OPCODE_TEXT
        if self._started:
            if self._opcode != frame_type:
                raise ValueError('Message types are different in frames for '
                                 'the same message')
            opcode = common.OPCODE_CONTINUATION
        else:
            opcode = frame_type
            self._opcode = frame_type

        if end:
            self._started = False
            fin = 1
        else:
            self._started = True
            fin = 0

        if binary or not self._encode_utf8:
            return create_binary_frame(
                payload_data, opcode, fin, self._mask, self._frame_filters)
        else:
            return create_text_frame(
                payload_data, opcode, fin, self._mask, self._frame_filters)


def _create_control_frame(opcode, body, mask, frame_filters):
    frame = Frame(opcode=opcode, payload=body)

    for frame_filter in frame_filters:
        frame_filter.filter(frame)

    if len(frame.payload) > 125:
        raise BadOperationException(
            'Payload data size of control frames must be 125 bytes or less')

    header = create_header(
        frame.opcode, len(frame.payload), frame.fin,
        frame.rsv1, frame.rsv2, frame.rsv3, mask)
    return _build_frame(header, frame.payload, mask)


def create_ping_frame(body, mask=False, frame_filters=[]):
    return _create_control_frame(common.OPCODE_PING, body, mask, frame_filters)


def create_pong_frame(body, mask=False, frame_filters=[]):
    return _create_control_frame(common.OPCODE_PONG, body, mask, frame_filters)


def create_close_frame(body, mask=False, frame_filters=[]):
    return _create_control_frame(
        common.OPCODE_CLOSE, body, mask, frame_filters)


def create_closing_handshake_body(code, reason):
    body = ''
    if code is not None:
        if (code > common.STATUS_USER_PRIVATE_MAX or
            code < common.STATUS_NORMAL_CLOSURE):
            raise BadOperationException('Status code is out of range')
        if (code == common.STATUS_NO_STATUS_RECEIVED or
            code == common.STATUS_ABNORMAL_CLOSURE or
            code == common.STATUS_TLS_HANDSHAKE):
            raise BadOperationException('Status code is reserved pseudo '
                'code')
        encoded_reason = reason.encode('utf-8')
        body = struct.pack('!H', code) + encoded_reason
    return body


class StreamOptions(object):
    """Holds option values to configure Stream objects."""

    def __init__(self):
        """Constructs StreamOptions."""

        # Filters applied to frames.
        self.outgoing_frame_filters = []
        self.incoming_frame_filters = []

        # Filters applied to messages. Control frames are not affected by them.
        self.outgoing_message_filters = []
        self.incoming_message_filters = []

        self.encode_text_message_to_utf8 = True
        self.mask_send = False
        self.unmask_receive = True


class Stream(StreamBase):
    """A class for parsing/building frames of the WebSocket protocol
    (RFC 6455).
    """

    def __init__(self, request, options):
        """Constructs an instance.

        Args:
            request: mod_python request.
        """

        StreamBase.__init__(self, request)

        self._logger = util.get_class_logger(self)

        self._options = options

        self._request.client_terminated = False
        self._request.server_terminated = False

        # Holds body of received fragments.
        self._received_fragments = []
        # Holds the opcode of the first fragment.
        self._original_opcode = None

        self._writer = FragmentedFrameBuilder(
            self._options.mask_send, self._options.outgoing_frame_filters,
            self._options.encode_text_message_to_utf8)

        self._ping_queue = deque()

    def _receive_frame(self):
        """Receives a frame and return data in the frame as a tuple containing
        each header field and payload separately.

        Raises:
            ConnectionTerminatedException: when read returns empty
                string.
            InvalidFrameException: when the frame contains invalid data.
        """

        def _receive_bytes(length):
            return self.receive_bytes(length)

        return parse_frame(receive_bytes=_receive_bytes,
                           logger=self._logger,
                           ws_version=self._request.ws_version,
                           unmask_receive=self._options.unmask_receive)

    def _receive_frame_as_frame_object(self):
        opcode, unmasked_bytes, fin, rsv1, rsv2, rsv3 = self._receive_frame()

        return Frame(fin=fin, rsv1=rsv1, rsv2=rsv2, rsv3=rsv3,
                     opcode=opcode, payload=unmasked_bytes)

    def receive_filtered_frame(self):
        """Receives a frame and applies frame filters and message filters.
        The frame to be received must satisfy following conditions:
        - The frame is not fragmented.
        - The opcode of the frame is TEXT or BINARY.

        DO NOT USE this method except for testing purpose.
        """

        frame = self._receive_frame_as_frame_object()
        if not frame.fin:
            raise InvalidFrameException(
                'Segmented frames must not be received via '
                'receive_filtered_frame()')
        if (frame.opcode != common.OPCODE_TEXT and
            frame.opcode != common.OPCODE_BINARY):
            raise InvalidFrameException(
                'Control frames must not be received via '
                'receive_filtered_frame()')

        for frame_filter in self._options.incoming_frame_filters:
            frame_filter.filter(frame)
        for message_filter in self._options.incoming_message_filters:
            frame.payload = message_filter.filter(frame.payload)
        return frame

    def send_message(self, message, end=True, binary=False):
        """Send message.

        Args:
            message: text in unicode or binary in str to send.
            binary: send message as binary frame.

        Raises:
            BadOperationException: when called on a server-terminated
                connection or called with inconsistent message type or
                binary parameter.
        """

        if self._request.server_terminated:
            raise BadOperationException(
                'Requested send_message after sending out a closing handshake')

        if binary and isinstance(message, unicode):
            raise BadOperationException(
                'Message for binary frame must be instance of str')

        for message_filter in self._options.outgoing_message_filters:
            message = message_filter.filter(message, end, binary)

        try:
            # Set this to any positive integer to limit maximum size of data in
            # payload data of each frame.
            MAX_PAYLOAD_DATA_SIZE = -1

            if MAX_PAYLOAD_DATA_SIZE <= 0:
                self._write(self._writer.build(message, end, binary))
                return

            bytes_written = 0
            while True:
                end_for_this_frame = end
                bytes_to_write = len(message) - bytes_written
                if (MAX_PAYLOAD_DATA_SIZE > 0 and
                    bytes_to_write > MAX_PAYLOAD_DATA_SIZE):
                    end_for_this_frame = False
                    bytes_to_write = MAX_PAYLOAD_DATA_SIZE

                frame = self._writer.build(
                    message[bytes_written:bytes_written + bytes_to_write],
                    end_for_this_frame,
                    binary)
                self._write(frame)

                bytes_written += bytes_to_write

                # This if must be placed here (the end of while block) so that
                # at least one frame is sent.
                if len(message) <= bytes_written:
                    break
        except ValueError, e:
            raise BadOperationException(e)

    def _get_message_from_frame(self, frame):
        """Gets a message from frame. If the message is composed of fragmented
        frames and the frame is not the last fragmented frame, this method
        returns None. The whole message will be returned when the last
        fragmented frame is passed to this method.

        Raises:
            InvalidFrameException: when the frame doesn't match defragmentation
                context, or the frame contains invalid data.
        """

        if frame.opcode == common.OPCODE_CONTINUATION:
            if not self._received_fragments:
                if frame.fin:
                    raise InvalidFrameException(
                        'Received a termination frame but fragmentation '
                        'not started')
                else:
                    raise InvalidFrameException(
                        'Received an intermediate frame but '
                        'fragmentation not started')

            if frame.fin:
                # End of fragmentation frame
                self._received_fragments.append(frame.payload)
                message = ''.join(self._received_fragments)
                self._received_fragments = []
                return message
            else:
                # Intermediate frame
                self._received_fragments.append(frame.payload)
                return None
        else:
            if self._received_fragments:
                if frame.fin:
                    raise InvalidFrameException(
                        'Received an unfragmented frame without '
                        'terminating existing fragmentation')
                else:
                    raise InvalidFrameException(
                        'New fragmentation started without terminating '
                        'existing fragmentation')

            if frame.fin:
                # Unfragmented frame

                self._original_opcode = frame.opcode
                return frame.payload
            else:
                # Start of fragmentation frame

                if common.is_control_opcode(frame.opcode):
                    raise InvalidFrameException(
                        'Control frames must not be fragmented')

                self._original_opcode = frame.opcode
                self._received_fragments.append(frame.payload)
                return None

    def _process_close_message(self, message):
        """Processes close message.

        Args:
            message: close message.

        Raises:
            InvalidFrameException: when the message is invalid.
        """

        self._request.client_terminated = True

        # Status code is optional. We can have status reason only if we
        # have status code. Status reason can be empty string. So,
        # allowed cases are
        # - no application data: no code no reason
        # - 2 octet of application data: has code but no reason
        # - 3 or more octet of application data: both code and reason
        if len(message) == 0:
            self._logger.debug('Received close frame (empty body)')
            self._request.ws_close_code = (
                common.STATUS_NO_STATUS_RECEIVED)
        elif len(message) == 1:
            raise InvalidFrameException(
                'If a close frame has status code, the length of '
                'status code must be 2 octet')
        elif len(message) >= 2:
            self._request.ws_close_code = struct.unpack(
                '!H', message[0:2])[0]
            self._request.ws_close_reason = message[2:].decode(
                'utf-8', 'replace')
            self._logger.debug(
                'Received close frame (code=%d, reason=%r)',
                self._request.ws_close_code,
                self._request.ws_close_reason)

        # As we've received a close frame, no more data is coming over the
        # socket. We can now safely close the socket without worrying about
        # RST sending.

        if self._request.server_terminated:
            self._logger.debug(
                'Received ack for server-initiated closing handshake')
            return

        self._logger.debug(
            'Received client-initiated closing handshake')

        code = common.STATUS_NORMAL_CLOSURE
        reason = ''
        if hasattr(self._request, '_dispatcher'):
            dispatcher = self._request._dispatcher
            code, reason = dispatcher.passive_closing_handshake(
                self._request)
            if code is None and reason is not None and len(reason) > 0:
                self._logger.warning(
                    'Handler specified reason despite code being None')
                reason = ''
            if reason is None:
                reason = ''
        self._send_closing_handshake(code, reason)
        self._logger.debug(
            'Acknowledged closing handshake initiated by the peer '
            '(code=%r, reason=%r)', code, reason)

    def _process_ping_message(self, message):
        """Processes ping message.

        Args:
            message: ping message.
        """

        try:
            handler = self._request.on_ping_handler
            if handler:
                handler(self._request, message)
                return
        except AttributeError, e:
            pass
        self._send_pong(message)

    def _process_pong_message(self, message):
        """Processes pong message.

        Args:
            message: pong message.
        """

        # TODO(tyoshino): Add ping timeout handling.

        inflight_pings = deque()

        while True:
            try:
                expected_body = self._ping_queue.popleft()
                if expected_body == message:
                    # inflight_pings contains pings ignored by the
                    # other peer. Just forget them.
                    self._logger.debug(
                        'Ping %r is acked (%d pings were ignored)',
                        expected_body, len(inflight_pings))
                    break
                else:
                    inflight_pings.append(expected_body)
            except IndexError, e:
                # The received pong was unsolicited pong. Keep the
                # ping queue as is.
                self._ping_queue = inflight_pings
                self._logger.debug('Received a unsolicited pong')
                break

        try:
            handler = self._request.on_pong_handler
            if handler:
                handler(self._request, message)
        except AttributeError, e:
            pass

    def receive_message(self):
        """Receive a WebSocket frame and return its payload as a text in
        unicode or a binary in str.

        Returns:
            payload data of the frame
            - as unicode instance if received text frame
            - as str instance if received binary frame
            or None iff received closing handshake.
        Raises:
            BadOperationException: when called on a client-terminated
                connection.
            ConnectionTerminatedException: when read returns empty
                string.
            InvalidFrameException: when the frame contains invalid
                data.
            UnsupportedFrameException: when the received frame has
                flags, opcode we cannot handle. You can ignore this
                exception and continue receiving the next frame.
        """

        if self._request.client_terminated:
            raise BadOperationException(
                'Requested receive_message after receiving a closing '
                'handshake')

        while True:
            # mp_conn.read will block if no bytes are available.
            # Timeout is controlled by TimeOut directive of Apache.

            frame = self._receive_frame_as_frame_object()

            # Check the constraint on the payload size for control frames
            # before extension processes the frame.
            # See also http://tools.ietf.org/html/rfc6455#section-5.5
            if (common.is_control_opcode(frame.opcode) and
                len(frame.payload) > 125):
                raise InvalidFrameException(
                    'Payload data size of control frames must be 125 bytes or '
                    'less')

            for frame_filter in self._options.incoming_frame_filters:
                frame_filter.filter(frame)

            if frame.rsv1 or frame.rsv2 or frame.rsv3:
                raise UnsupportedFrameException(
                    'Unsupported flag is set (rsv = %d%d%d)' %
                    (frame.rsv1, frame.rsv2, frame.rsv3))

            message = self._get_message_from_frame(frame)
            if message is None:
                continue

            for message_filter in self._options.incoming_message_filters:
                message = message_filter.filter(message)

            if self._original_opcode == common.OPCODE_TEXT:
                # The WebSocket protocol section 4.4 specifies that invalid
                # characters must be replaced with U+fffd REPLACEMENT
                # CHARACTER.
                try:
                    return message.decode('utf-8')
                except UnicodeDecodeError, e:
                    raise InvalidUTF8Exception(e)
            elif self._original_opcode == common.OPCODE_BINARY:
                return message
            elif self._original_opcode == common.OPCODE_CLOSE:
                self._process_close_message(message)
                return None
            elif self._original_opcode == common.OPCODE_PING:
                self._process_ping_message(message)
            elif self._original_opcode == common.OPCODE_PONG:
                self._process_pong_message(message)
            else:
                raise UnsupportedFrameException(
                    'Opcode %d is not supported' % self._original_opcode)

    def _send_closing_handshake(self, code, reason):
        body = create_closing_handshake_body(code, reason)
        frame = create_close_frame(
            body, mask=self._options.mask_send,
            frame_filters=self._options.outgoing_frame_filters)

        self._request.server_terminated = True

        self._write(frame)

    def close_connection(self, code=common.STATUS_NORMAL_CLOSURE, reason='',
                         wait_response=True):
        """Closes a WebSocket connection.

        Args:
            code: Status code for close frame. If code is None, a close
                frame with empty body will be sent.
            reason: string representing close reason.
            wait_response: True when caller want to wait the response.
        Raises:
            BadOperationException: when reason is specified with code None
            or reason is not an instance of both str and unicode.
        """

        if self._request.server_terminated:
            self._logger.debug(
                'Requested close_connection but server is already terminated')
            return

        if code is None:
            if reason is not None and len(reason) > 0:
                raise BadOperationException(
                    'close reason must not be specified if code is None')
            reason = ''
        else:
            if not isinstance(reason, str) and not isinstance(reason, unicode):
                raise BadOperationException(
                    'close reason must be an instance of str or unicode')

        self._send_closing_handshake(code, reason)
        self._logger.debug(
            'Initiated closing handshake (code=%r, reason=%r)',
            code, reason)

        if (code == common.STATUS_GOING_AWAY or
            code == common.STATUS_PROTOCOL_ERROR) or not wait_response:
            # It doesn't make sense to wait for a close frame if the reason is
            # protocol error or that the server is going away. For some of
            # other reasons, it might not make sense to wait for a close frame,
            # but it's not clear, yet.
            return

        # TODO(ukai): 2. wait until the /client terminated/ flag has been set,
        # or until a server-defined timeout expires.
        #
        # For now, we expect receiving closing handshake right after sending
        # out closing handshake.
        message = self.receive_message()
        if message is not None:
            raise ConnectionTerminatedException(
                'Didn\'t receive valid ack for closing handshake')
        # TODO: 3. close the WebSocket connection.
        # note: mod_python Connection (mp_conn) doesn't have close method.

    def send_ping(self, body=''):
        frame = create_ping_frame(
            body,
            self._options.mask_send,
            self._options.outgoing_frame_filters)
        self._write(frame)

        self._ping_queue.append(body)

    def _send_pong(self, body):
        frame = create_pong_frame(
            body,
            self._options.mask_send,
            self._options.outgoing_frame_filters)
        self._write(frame)

    def get_last_received_opcode(self):
        """Returns the opcode of the WebSocket message which the last received
        frame belongs to. The return value is valid iff immediately after
        receive_message call.
        """

        return self._original_opcode


# vi:sts=4 sw=4 et
