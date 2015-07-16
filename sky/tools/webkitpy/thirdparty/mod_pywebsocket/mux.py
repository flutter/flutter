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


"""This file provides classes and helper functions for multiplexing extension.

Specification:
http://tools.ietf.org/html/draft-ietf-hybi-websocket-multiplexing-06
"""


import collections
import copy
import email
import email.parser
import logging
import math
import struct
import threading
import traceback

from mod_pywebsocket import common
from mod_pywebsocket import handshake
from mod_pywebsocket import util
from mod_pywebsocket._stream_base import BadOperationException
from mod_pywebsocket._stream_base import ConnectionTerminatedException
from mod_pywebsocket._stream_base import InvalidFrameException
from mod_pywebsocket._stream_hybi import Frame
from mod_pywebsocket._stream_hybi import Stream
from mod_pywebsocket._stream_hybi import StreamOptions
from mod_pywebsocket._stream_hybi import create_binary_frame
from mod_pywebsocket._stream_hybi import create_closing_handshake_body
from mod_pywebsocket._stream_hybi import create_header
from mod_pywebsocket._stream_hybi import create_length_header
from mod_pywebsocket._stream_hybi import parse_frame
from mod_pywebsocket.handshake import hybi


_CONTROL_CHANNEL_ID = 0
_DEFAULT_CHANNEL_ID = 1

_MUX_OPCODE_ADD_CHANNEL_REQUEST = 0
_MUX_OPCODE_ADD_CHANNEL_RESPONSE = 1
_MUX_OPCODE_FLOW_CONTROL = 2
_MUX_OPCODE_DROP_CHANNEL = 3
_MUX_OPCODE_NEW_CHANNEL_SLOT = 4

_MAX_CHANNEL_ID = 2 ** 29 - 1

_INITIAL_NUMBER_OF_CHANNEL_SLOTS = 64
_INITIAL_QUOTA_FOR_CLIENT = 8 * 1024

_HANDSHAKE_ENCODING_IDENTITY = 0
_HANDSHAKE_ENCODING_DELTA = 1

# We need only these status code for now.
_HTTP_BAD_RESPONSE_MESSAGES = {
    common.HTTP_STATUS_BAD_REQUEST: 'Bad Request',
}

# DropChannel reason code
# TODO(bashi): Define all reason code defined in -05 draft.
_DROP_CODE_NORMAL_CLOSURE = 1000

_DROP_CODE_INVALID_ENCAPSULATING_MESSAGE = 2001
_DROP_CODE_CHANNEL_ID_TRUNCATED = 2002
_DROP_CODE_ENCAPSULATED_FRAME_IS_TRUNCATED = 2003
_DROP_CODE_UNKNOWN_MUX_OPCODE = 2004
_DROP_CODE_INVALID_MUX_CONTROL_BLOCK = 2005
_DROP_CODE_CHANNEL_ALREADY_EXISTS = 2006
_DROP_CODE_NEW_CHANNEL_SLOT_VIOLATION = 2007
_DROP_CODE_UNKNOWN_REQUEST_ENCODING = 2010

_DROP_CODE_SEND_QUOTA_VIOLATION = 3005
_DROP_CODE_SEND_QUOTA_OVERFLOW = 3006
_DROP_CODE_ACKNOWLEDGED = 3008
_DROP_CODE_BAD_FRAGMENTATION = 3009


class MuxUnexpectedException(Exception):
    """Exception in handling multiplexing extension."""
    pass


# Temporary
class MuxNotImplementedException(Exception):
    """Raised when a flow enters unimplemented code path."""
    pass


class LogicalConnectionClosedException(Exception):
    """Raised when logical connection is gracefully closed."""
    pass


class PhysicalConnectionError(Exception):
    """Raised when there is a physical connection error."""
    def __init__(self, drop_code, message=''):
        super(PhysicalConnectionError, self).__init__(
            'code=%d, message=%r' % (drop_code, message))
        self.drop_code = drop_code
        self.message = message


class LogicalChannelError(Exception):
    """Raised when there is a logical channel error."""
    def __init__(self, channel_id, drop_code, message=''):
        super(LogicalChannelError, self).__init__(
            'channel_id=%d, code=%d, message=%r' % (
                channel_id, drop_code, message))
        self.channel_id = channel_id
        self.drop_code = drop_code
        self.message = message


def _encode_channel_id(channel_id):
    if channel_id < 0:
        raise ValueError('Channel id %d must not be negative' % channel_id)

    if channel_id < 2 ** 7:
        return chr(channel_id)
    if channel_id < 2 ** 14:
        return struct.pack('!H', 0x8000 + channel_id)
    if channel_id < 2 ** 21:
        first = chr(0xc0 + (channel_id >> 16))
        return first + struct.pack('!H', channel_id & 0xffff)
    if channel_id < 2 ** 29:
        return struct.pack('!L', 0xe0000000 + channel_id)

    raise ValueError('Channel id %d is too large' % channel_id)


def _encode_number(number):
    return create_length_header(number, False)


def _create_add_channel_response(channel_id, encoded_handshake,
                                 encoding=0, rejected=False):
    if encoding != 0 and encoding != 1:
        raise ValueError('Invalid encoding %d' % encoding)

    first_byte = ((_MUX_OPCODE_ADD_CHANNEL_RESPONSE << 5) |
                  (rejected << 4) | encoding)
    block = (chr(first_byte) +
             _encode_channel_id(channel_id) +
             _encode_number(len(encoded_handshake)) +
             encoded_handshake)
    return block


def _create_drop_channel(channel_id, code=None, message=''):
    if len(message) > 0 and code is None:
        raise ValueError('Code must be specified if message is specified')

    first_byte = _MUX_OPCODE_DROP_CHANNEL << 5
    block = chr(first_byte) + _encode_channel_id(channel_id)
    if code is None:
        block += _encode_number(0) # Reason size
    else:
        reason = struct.pack('!H', code) + message
        reason_size = _encode_number(len(reason))
        block += reason_size + reason

    return block


def _create_flow_control(channel_id, replenished_quota):
    first_byte = _MUX_OPCODE_FLOW_CONTROL << 5
    block = (chr(first_byte) +
             _encode_channel_id(channel_id) +
             _encode_number(replenished_quota))
    return block


def _create_new_channel_slot(slots, send_quota):
    if slots < 0 or send_quota < 0:
        raise ValueError('slots and send_quota must be non-negative.')
    first_byte = _MUX_OPCODE_NEW_CHANNEL_SLOT << 5
    block = (chr(first_byte) +
             _encode_number(slots) +
             _encode_number(send_quota))
    return block


def _create_fallback_new_channel_slot():
    first_byte = (_MUX_OPCODE_NEW_CHANNEL_SLOT << 5) | 1 # Set the F flag
    block = (chr(first_byte) + _encode_number(0) + _encode_number(0))
    return block


def _parse_request_text(request_text):
    request_line, header_lines = request_text.split('\r\n', 1)

    words = request_line.split(' ')
    if len(words) != 3:
        raise ValueError('Bad Request-Line syntax %r' % request_line)
    [command, path, version] = words
    if version != 'HTTP/1.1':
        raise ValueError('Bad request version %r' % version)

    # email.parser.Parser() parses RFC 2822 (RFC 822) style headers.
    # RFC 6455 refers RFC 2616 for handshake parsing, and RFC 2616 refers
    # RFC 822.
    headers = email.parser.Parser().parsestr(header_lines)
    return command, path, version, headers


class _ControlBlock(object):
    """A structure that holds parsing result of multiplexing control block.
    Control block specific attributes will be added by _MuxFramePayloadParser.
    (e.g. encoded_handshake will be added for AddChannelRequest and
    AddChannelResponse)
    """

    def __init__(self, opcode):
        self.opcode = opcode


class _MuxFramePayloadParser(object):
    """A class that parses multiplexed frame payload."""

    def __init__(self, payload):
        self._data = payload
        self._read_position = 0
        self._logger = util.get_class_logger(self)

    def read_channel_id(self):
        """Reads channel id.

        Raises:
            ValueError: when the payload doesn't contain
                valid channel id.
        """

        remaining_length = len(self._data) - self._read_position
        pos = self._read_position
        if remaining_length == 0:
            raise ValueError('Invalid channel id format')

        channel_id = ord(self._data[pos])
        channel_id_length = 1
        if channel_id & 0xe0 == 0xe0:
            if remaining_length < 4:
                raise ValueError('Invalid channel id format')
            channel_id = struct.unpack('!L',
                                       self._data[pos:pos+4])[0] & 0x1fffffff
            channel_id_length = 4
        elif channel_id & 0xc0 == 0xc0:
            if remaining_length < 3:
                raise ValueError('Invalid channel id format')
            channel_id = (((channel_id & 0x1f) << 16) +
                          struct.unpack('!H', self._data[pos+1:pos+3])[0])
            channel_id_length = 3
        elif channel_id & 0x80 == 0x80:
            if remaining_length < 2:
                raise ValueError('Invalid channel id format')
            channel_id = struct.unpack('!H',
                                       self._data[pos:pos+2])[0] & 0x3fff
            channel_id_length = 2
        self._read_position += channel_id_length

        return channel_id

    def read_inner_frame(self):
        """Reads an inner frame.

        Raises:
            PhysicalConnectionError: when the inner frame is invalid.
        """

        if len(self._data) == self._read_position:
            raise PhysicalConnectionError(
                _DROP_CODE_ENCAPSULATED_FRAME_IS_TRUNCATED)

        bits = ord(self._data[self._read_position])
        self._read_position += 1
        fin = (bits & 0x80) == 0x80
        rsv1 = (bits & 0x40) == 0x40
        rsv2 = (bits & 0x20) == 0x20
        rsv3 = (bits & 0x10) == 0x10
        opcode = bits & 0xf
        payload = self.remaining_data()
        # Consume rest of the message which is payload data of the original
        # frame.
        self._read_position = len(self._data)
        return fin, rsv1, rsv2, rsv3, opcode, payload

    def _read_number(self):
        if self._read_position + 1 > len(self._data):
            raise ValueError(
                'Cannot read the first byte of number field')

        number = ord(self._data[self._read_position])
        if number & 0x80 == 0x80:
            raise ValueError(
                'The most significant bit of the first byte of number should '
                'be unset')
        self._read_position += 1
        pos = self._read_position
        if number == 127:
            if pos + 8 > len(self._data):
                raise ValueError('Invalid number field')
            self._read_position += 8
            number = struct.unpack('!Q', self._data[pos:pos+8])[0]
            if number > 0x7FFFFFFFFFFFFFFF:
                raise ValueError('Encoded number(%d) >= 2^63' % number)
            if number <= 0xFFFF:
                raise ValueError(
                    '%d should not be encoded by 9 bytes encoding' % number)
            return number
        if number == 126:
            if pos + 2 > len(self._data):
                raise ValueError('Invalid number field')
            self._read_position += 2
            number = struct.unpack('!H', self._data[pos:pos+2])[0]
            if number <= 125:
                raise ValueError(
                    '%d should not be encoded by 3 bytes encoding' % number)
        return number

    def _read_size_and_contents(self):
        """Reads data that consists of followings:
            - the size of the contents encoded the same way as payload length
              of the WebSocket Protocol with 1 bit padding at the head.
            - the contents.
        """

        try:
            size = self._read_number()
        except ValueError, e:
            raise PhysicalConnectionError(_DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                                          str(e))
        pos = self._read_position
        if pos + size > len(self._data):
            raise PhysicalConnectionError(
                _DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                'Cannot read %d bytes data' % size)

        self._read_position += size
        return self._data[pos:pos+size]

    def _read_add_channel_request(self, first_byte, control_block):
        reserved = (first_byte >> 2) & 0x7
        if reserved != 0:
            raise PhysicalConnectionError(
                _DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                'Reserved bits must be unset')

        # Invalid encoding will be handled by MuxHandler.
        encoding = first_byte & 0x3
        try:
            control_block.channel_id = self.read_channel_id()
        except ValueError, e:
            raise PhysicalConnectionError(_DROP_CODE_INVALID_MUX_CONTROL_BLOCK)
        control_block.encoding = encoding
        encoded_handshake = self._read_size_and_contents()
        control_block.encoded_handshake = encoded_handshake
        return control_block

    def _read_add_channel_response(self, first_byte, control_block):
        reserved = (first_byte >> 2) & 0x3
        if reserved != 0:
            raise PhysicalConnectionError(
                _DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                'Reserved bits must be unset')

        control_block.accepted = (first_byte >> 4) & 1
        control_block.encoding = first_byte & 0x3
        try:
            control_block.channel_id = self.read_channel_id()
        except ValueError, e:
            raise PhysicalConnectionError(_DROP_CODE_INVALID_MUX_CONTROL_BLOCK)
        control_block.encoded_handshake = self._read_size_and_contents()
        return control_block

    def _read_flow_control(self, first_byte, control_block):
        reserved = first_byte & 0x1f
        if reserved != 0:
            raise PhysicalConnectionError(
                _DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                'Reserved bits must be unset')

        try:
            control_block.channel_id = self.read_channel_id()
            control_block.send_quota = self._read_number()
        except ValueError, e:
            raise PhysicalConnectionError(_DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                                          str(e))

        return control_block

    def _read_drop_channel(self, first_byte, control_block):
        reserved = first_byte & 0x1f
        if reserved != 0:
            raise PhysicalConnectionError(
                _DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                'Reserved bits must be unset')

        try:
            control_block.channel_id = self.read_channel_id()
        except ValueError, e:
            raise PhysicalConnectionError(_DROP_CODE_INVALID_MUX_CONTROL_BLOCK)
        reason = self._read_size_and_contents()
        if len(reason) == 0:
            control_block.drop_code = None
            control_block.drop_message = ''
        elif len(reason) >= 2:
            control_block.drop_code = struct.unpack('!H', reason[:2])[0]
            control_block.drop_message = reason[2:]
        else:
            raise PhysicalConnectionError(
                _DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                'Received DropChannel that conains only 1-byte reason')
        return control_block

    def _read_new_channel_slot(self, first_byte, control_block):
        reserved = first_byte & 0x1e
        if reserved != 0:
            raise PhysicalConnectionError(
                _DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                'Reserved bits must be unset')
        control_block.fallback = first_byte & 1
        try:
            control_block.slots = self._read_number()
            control_block.send_quota = self._read_number()
        except ValueError, e:
            raise PhysicalConnectionError(_DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                                          str(e))
        return control_block

    def read_control_blocks(self):
        """Reads control block(s).

        Raises:
           PhysicalConnectionError: when the payload contains invalid control
               block(s).
           StopIteration: when no control blocks left.
        """

        while self._read_position < len(self._data):
            first_byte = ord(self._data[self._read_position])
            self._read_position += 1
            opcode = (first_byte >> 5) & 0x7
            control_block = _ControlBlock(opcode=opcode)
            if opcode == _MUX_OPCODE_ADD_CHANNEL_REQUEST:
                yield self._read_add_channel_request(first_byte, control_block)
            elif opcode == _MUX_OPCODE_ADD_CHANNEL_RESPONSE:
                yield self._read_add_channel_response(
                    first_byte, control_block)
            elif opcode == _MUX_OPCODE_FLOW_CONTROL:
                yield self._read_flow_control(first_byte, control_block)
            elif opcode == _MUX_OPCODE_DROP_CHANNEL:
                yield self._read_drop_channel(first_byte, control_block)
            elif opcode == _MUX_OPCODE_NEW_CHANNEL_SLOT:
                yield self._read_new_channel_slot(first_byte, control_block)
            else:
                raise PhysicalConnectionError(
                    _DROP_CODE_UNKNOWN_MUX_OPCODE,
                    'Invalid opcode %d' % opcode)

        assert self._read_position == len(self._data)
        raise StopIteration

    def remaining_data(self):
        """Returns remaining data."""

        return self._data[self._read_position:]


class _LogicalRequest(object):
    """Mimics mod_python request."""

    def __init__(self, channel_id, command, path, protocol, headers,
                 connection):
        """Constructs an instance.

        Args:
            channel_id: the channel id of the logical channel.
            command: HTTP request command.
            path: HTTP request path.
            headers: HTTP headers.
            connection: _LogicalConnection instance.
        """

        self.channel_id = channel_id
        self.method = command
        self.uri = path
        self.protocol = protocol
        self.headers_in = headers
        self.connection = connection
        self.server_terminated = False
        self.client_terminated = False

    def is_https(self):
        """Mimics request.is_https(). Returns False because this method is
        used only by old protocols (hixie and hybi00).
        """

        return False


class _LogicalConnection(object):
    """Mimics mod_python mp_conn."""

    # For details, see the comment of set_read_state().
    STATE_ACTIVE = 1
    STATE_GRACEFULLY_CLOSED = 2
    STATE_TERMINATED = 3

    def __init__(self, mux_handler, channel_id):
        """Constructs an instance.

        Args:
            mux_handler: _MuxHandler instance.
            channel_id: channel id of this connection.
        """

        self._mux_handler = mux_handler
        self._channel_id = channel_id
        self._incoming_data = ''

        # - Protects _waiting_write_completion
        # - Signals the thread waiting for completion of write by mux handler
        self._write_condition = threading.Condition()
        self._waiting_write_completion = False

        self._read_condition = threading.Condition()
        self._read_state = self.STATE_ACTIVE

    def get_local_addr(self):
        """Getter to mimic mp_conn.local_addr."""

        return self._mux_handler.physical_connection.get_local_addr()
    local_addr = property(get_local_addr)

    def get_remote_addr(self):
        """Getter to mimic mp_conn.remote_addr."""

        return self._mux_handler.physical_connection.get_remote_addr()
    remote_addr = property(get_remote_addr)

    def get_memorized_lines(self):
        """Gets memorized lines. Not supported."""

        raise MuxUnexpectedException('_LogicalConnection does not support '
                                     'get_memorized_lines')

    def write(self, data):
        """Writes data. mux_handler sends data asynchronously. The caller will
        be suspended until write done.

        Args:
            data: data to be written.

        Raises:
            MuxUnexpectedException: when called before finishing the previous
                write.
        """

        try:
            self._write_condition.acquire()
            if self._waiting_write_completion:
                raise MuxUnexpectedException(
                    'Logical connection %d is already waiting the completion '
                    'of write' % self._channel_id)

            self._waiting_write_completion = True
            self._mux_handler.send_data(self._channel_id, data)
            self._write_condition.wait()
            # TODO(tyoshino): Raise an exception if woke up by on_writer_done.
        finally:
            self._write_condition.release()

    def write_control_data(self, data):
        """Writes data via the control channel. Don't wait finishing write
        because this method can be called by mux dispatcher.

        Args:
            data: data to be written.
        """

        self._mux_handler.send_control_data(data)

    def on_write_data_done(self):
        """Called when sending data is completed."""

        try:
            self._write_condition.acquire()
            if not self._waiting_write_completion:
                raise MuxUnexpectedException(
                    'Invalid call of on_write_data_done for logical '
                    'connection %d' % self._channel_id)
            self._waiting_write_completion = False
            self._write_condition.notify()
        finally:
            self._write_condition.release()

    def on_writer_done(self):
        """Called by the mux handler when the writer thread has finished."""

        try:
            self._write_condition.acquire()
            self._waiting_write_completion = False
            self._write_condition.notify()
        finally:
            self._write_condition.release()


    def append_frame_data(self, frame_data):
        """Appends incoming frame data. Called when mux_handler dispatches
        frame data to the corresponding application.

        Args:
            frame_data: incoming frame data.
        """

        self._read_condition.acquire()
        self._incoming_data += frame_data
        self._read_condition.notify()
        self._read_condition.release()

    def read(self, length):
        """Reads data. Blocks until enough data has arrived via physical
        connection.

        Args:
            length: length of data to be read.
        Raises:
            LogicalConnectionClosedException: when closing handshake for this
                logical channel has been received.
            ConnectionTerminatedException: when the physical connection has
                closed, or an error is caused on the reader thread.
        """

        self._read_condition.acquire()
        while (self._read_state == self.STATE_ACTIVE and
               len(self._incoming_data) < length):
            self._read_condition.wait()

        try:
            if self._read_state == self.STATE_GRACEFULLY_CLOSED:
                raise LogicalConnectionClosedException(
                    'Logical channel %d has closed.' % self._channel_id)
            elif self._read_state == self.STATE_TERMINATED:
                raise ConnectionTerminatedException(
                    'Receiving %d byte failed. Logical channel (%d) closed' %
                    (length, self._channel_id))

            value = self._incoming_data[:length]
            self._incoming_data = self._incoming_data[length:]
        finally:
            self._read_condition.release()

        return value

    def set_read_state(self, new_state):
        """Sets the state of this connection. Called when an event for this
        connection has occurred.

        Args:
            new_state: state to be set. new_state must be one of followings:
            - STATE_GRACEFULLY_CLOSED: when closing handshake for this
                connection has been received.
            - STATE_TERMINATED: when the physical connection has closed or
                DropChannel of this connection has received.
        """

        self._read_condition.acquire()
        self._read_state = new_state
        self._read_condition.notify()
        self._read_condition.release()


class _InnerMessage(object):
    """Holds the result of _InnerMessageBuilder.build().
    """

    def __init__(self, opcode, payload):
        self.opcode = opcode
        self.payload = payload


class _InnerMessageBuilder(object):
    """A class that holds the context of inner message fragmentation and
    builds a message from fragmented inner frame(s).
    """

    def __init__(self):
        self._control_opcode = None
        self._pending_control_fragments = []
        self._message_opcode = None
        self._pending_message_fragments = []
        self._frame_handler = self._handle_first

    def _handle_first(self, frame):
        if frame.opcode == common.OPCODE_CONTINUATION:
            raise InvalidFrameException('Sending invalid continuation opcode')

        if common.is_control_opcode(frame.opcode):
            return self._process_first_fragmented_control(frame)
        else:
            return self._process_first_fragmented_message(frame)

    def _process_first_fragmented_control(self, frame):
        self._control_opcode = frame.opcode
        self._pending_control_fragments.append(frame.payload)
        if not frame.fin:
            self._frame_handler = self._handle_fragmented_control
            return None
        return self._reassemble_fragmented_control()

    def _process_first_fragmented_message(self, frame):
        self._message_opcode = frame.opcode
        self._pending_message_fragments.append(frame.payload)
        if not frame.fin:
            self._frame_handler = self._handle_fragmented_message
            return None
        return self._reassemble_fragmented_message()

    def _handle_fragmented_control(self, frame):
        if frame.opcode != common.OPCODE_CONTINUATION:
            raise InvalidFrameException(
                'Sending invalid opcode %d while sending fragmented control '
                'message' % frame.opcode)
        self._pending_control_fragments.append(frame.payload)
        if not frame.fin:
            return None
        return self._reassemble_fragmented_control()

    def _reassemble_fragmented_control(self):
        opcode = self._control_opcode
        payload = ''.join(self._pending_control_fragments)
        self._control_opcode = None
        self._pending_control_fragments = []
        if self._message_opcode is not None:
            self._frame_handler = self._handle_fragmented_message
        else:
            self._frame_handler = self._handle_first
        return _InnerMessage(opcode, payload)

    def _handle_fragmented_message(self, frame):
        # Sender can interleave a control message while sending fragmented
        # messages.
        if common.is_control_opcode(frame.opcode):
            if self._control_opcode is not None:
                raise MuxUnexpectedException(
                    'Should not reach here(Bug in builder)')
            return self._process_first_fragmented_control(frame)

        if frame.opcode != common.OPCODE_CONTINUATION:
            raise InvalidFrameException(
                'Sending invalid opcode %d while sending fragmented message' %
                frame.opcode)
        self._pending_message_fragments.append(frame.payload)
        if not frame.fin:
            return None
        return self._reassemble_fragmented_message()

    def _reassemble_fragmented_message(self):
        opcode = self._message_opcode
        payload = ''.join(self._pending_message_fragments)
        self._message_opcode = None
        self._pending_message_fragments = []
        self._frame_handler = self._handle_first
        return _InnerMessage(opcode, payload)

    def build(self, frame):
        """Build an inner message. Returns an _InnerMessage instance when
        the given frame is the last fragmented frame. Returns None otherwise.

        Args:
            frame: an inner frame.
        Raises:
            InvalidFrameException: when received invalid opcode. (e.g.
                receiving non continuation data opcode but the fin flag of
                the previous inner frame was not set.)
        """

        return self._frame_handler(frame)


class _LogicalStream(Stream):
    """Mimics the Stream class. This class interprets multiplexed WebSocket
    frames.
    """

    def __init__(self, request, stream_options, send_quota, receive_quota):
        """Constructs an instance.

        Args:
            request: _LogicalRequest instance.
            stream_options: StreamOptions instance.
            send_quota: Initial send quota.
            receive_quota: Initial receive quota.
        """

        # Physical stream is responsible for masking.
        stream_options.unmask_receive = False
        Stream.__init__(self, request, stream_options)

        self._send_closed = False
        self._send_quota = send_quota
        # - Protects _send_closed and _send_quota
        # - Signals the thread waiting for send quota replenished
        self._send_condition = threading.Condition()

        # The opcode of the first frame in messages.
        self._message_opcode = common.OPCODE_TEXT
        # True when the last message was fragmented.
        self._last_message_was_fragmented = False

        self._receive_quota = receive_quota
        self._write_inner_frame_semaphore = threading.Semaphore()

        self._inner_message_builder = _InnerMessageBuilder()

    def _create_inner_frame(self, opcode, payload, end=True):
        frame = Frame(fin=end, opcode=opcode, payload=payload)
        for frame_filter in self._options.outgoing_frame_filters:
            frame_filter.filter(frame)

        if len(payload) != len(frame.payload):
            raise MuxUnexpectedException(
                'Mux extension must not be used after extensions which change '
                ' frame boundary')

        first_byte = ((frame.fin << 7) | (frame.rsv1 << 6) |
                      (frame.rsv2 << 5) | (frame.rsv3 << 4) | frame.opcode)
        return chr(first_byte) + frame.payload

    def _write_inner_frame(self, opcode, payload, end=True):
        payload_length = len(payload)
        write_position = 0

        try:
            # An inner frame will be fragmented if there is no enough send
            # quota. This semaphore ensures that fragmented inner frames are
            # sent in order on the logical channel.
            # Note that frames that come from other logical channels or
            # multiplexing control blocks can be inserted between fragmented
            # inner frames on the physical channel.
            self._write_inner_frame_semaphore.acquire()

            # Consume an octet quota when this is the first fragmented frame.
            if opcode != common.OPCODE_CONTINUATION:
                try:
                    self._send_condition.acquire()
                    while (not self._send_closed) and self._send_quota == 0:
                        self._send_condition.wait()

                    if self._send_closed:
                        raise BadOperationException(
                            'Logical connection %d is closed' %
                            self._request.channel_id)

                    self._send_quota -= 1
                finally:
                    self._send_condition.release()

            while write_position < payload_length:
                try:
                    self._send_condition.acquire()
                    while (not self._send_closed) and self._send_quota == 0:
                        self._logger.debug(
                            'No quota. Waiting FlowControl message for %d.' %
                            self._request.channel_id)
                        self._send_condition.wait()

                    if self._send_closed:
                        raise BadOperationException(
                            'Logical connection %d is closed' %
                            self.request._channel_id)

                    remaining = payload_length - write_position
                    write_length = min(self._send_quota, remaining)
                    inner_frame_end = (
                        end and
                        (write_position + write_length == payload_length))

                    inner_frame = self._create_inner_frame(
                        opcode,
                        payload[write_position:write_position+write_length],
                        inner_frame_end)
                    self._send_quota -= write_length
                    self._logger.debug('Consumed quota=%d, remaining=%d' %
                                       (write_length, self._send_quota))
                finally:
                    self._send_condition.release()

                # Writing data will block the worker so we need to release
                # _send_condition before writing.
                self._logger.debug('Sending inner frame: %r' % inner_frame)
                self._request.connection.write(inner_frame)
                write_position += write_length

                opcode = common.OPCODE_CONTINUATION

        except ValueError, e:
            raise BadOperationException(e)
        finally:
            self._write_inner_frame_semaphore.release()

    def replenish_send_quota(self, send_quota):
        """Replenish send quota."""

        try:
            self._send_condition.acquire()
            if self._send_quota + send_quota > 0x7FFFFFFFFFFFFFFF:
                self._send_quota = 0
                raise LogicalChannelError(
                    self._request.channel_id, _DROP_CODE_SEND_QUOTA_OVERFLOW)
            self._send_quota += send_quota
            self._logger.debug('Replenished send quota for channel id %d: %d' %
                               (self._request.channel_id, self._send_quota))
        finally:
            self._send_condition.notify()
            self._send_condition.release()

    def consume_receive_quota(self, amount):
        """Consumes receive quota. Returns False on failure."""

        if self._receive_quota < amount:
            self._logger.debug('Violate quota on channel id %d: %d < %d' %
                               (self._request.channel_id,
                                self._receive_quota, amount))
            return False
        self._receive_quota -= amount
        return True

    def send_message(self, message, end=True, binary=False):
        """Override Stream.send_message."""

        if self._request.server_terminated:
            raise BadOperationException(
                'Requested send_message after sending out a closing handshake')

        if binary and isinstance(message, unicode):
            raise BadOperationException(
                'Message for binary frame must be instance of str')

        if binary:
            opcode = common.OPCODE_BINARY
        else:
            opcode = common.OPCODE_TEXT
            message = message.encode('utf-8')

        for message_filter in self._options.outgoing_message_filters:
            message = message_filter.filter(message, end, binary)

        if self._last_message_was_fragmented:
            if opcode != self._message_opcode:
                raise BadOperationException('Message types are different in '
                                            'frames for the same message')
            opcode = common.OPCODE_CONTINUATION
        else:
            self._message_opcode = opcode

        self._write_inner_frame(opcode, message, end)
        self._last_message_was_fragmented = not end

    def _receive_frame(self):
        """Overrides Stream._receive_frame.

        In addition to call Stream._receive_frame, this method adds the amount
        of payload to receiving quota and sends FlowControl to the client.
        We need to do it here because Stream.receive_message() handles
        control frames internally.
        """

        opcode, payload, fin, rsv1, rsv2, rsv3 = Stream._receive_frame(self)
        amount = len(payload)
        # Replenish extra one octet when receiving the first fragmented frame.
        if opcode != common.OPCODE_CONTINUATION:
            amount += 1
        self._receive_quota += amount
        frame_data = _create_flow_control(self._request.channel_id,
                                          amount)
        self._logger.debug('Sending flow control for %d, replenished=%d' %
                           (self._request.channel_id, amount))
        self._request.connection.write_control_data(frame_data)
        return opcode, payload, fin, rsv1, rsv2, rsv3

    def _get_message_from_frame(self, frame):
        """Overrides Stream._get_message_from_frame.
        """

        try:
            inner_message = self._inner_message_builder.build(frame)
        except InvalidFrameException:
            raise LogicalChannelError(
                self._request.channel_id, _DROP_CODE_BAD_FRAGMENTATION)

        if inner_message is None:
            return None
        self._original_opcode = inner_message.opcode
        return inner_message.payload

    def receive_message(self):
        """Overrides Stream.receive_message."""

        # Just call Stream.receive_message(), but catch
        # LogicalConnectionClosedException, which is raised when the logical
        # connection has closed gracefully.
        try:
            return Stream.receive_message(self)
        except LogicalConnectionClosedException, e:
            self._logger.debug('%s', e)
            return None

    def _send_closing_handshake(self, code, reason):
        """Overrides Stream._send_closing_handshake."""

        body = create_closing_handshake_body(code, reason)
        self._logger.debug('Sending closing handshake for %d: (%r, %r)' %
                           (self._request.channel_id, code, reason))
        self._write_inner_frame(common.OPCODE_CLOSE, body, end=True)

        self._request.server_terminated = True

    def send_ping(self, body=''):
        """Overrides Stream.send_ping"""

        self._logger.debug('Sending ping on logical channel %d: %r' %
                           (self._request.channel_id, body))
        self._write_inner_frame(common.OPCODE_PING, body, end=True)

        self._ping_queue.append(body)

    def _send_pong(self, body):
        """Overrides Stream._send_pong"""

        self._logger.debug('Sending pong on logical channel %d: %r' %
                           (self._request.channel_id, body))
        self._write_inner_frame(common.OPCODE_PONG, body, end=True)

    def close_connection(self, code=common.STATUS_NORMAL_CLOSURE, reason=''):
        """Overrides Stream.close_connection."""

        # TODO(bashi): Implement
        self._logger.debug('Closing logical connection %d' %
                           self._request.channel_id)
        self._request.server_terminated = True

    def stop_sending(self):
        """Stops accepting new send operation (_write_inner_frame)."""

        self._send_condition.acquire()
        self._send_closed = True
        self._send_condition.notify()
        self._send_condition.release()


class _OutgoingData(object):
    """A structure that holds data to be sent via physical connection and
    origin of the data.
    """

    def __init__(self, channel_id, data):
        self.channel_id = channel_id
        self.data = data


class _PhysicalConnectionWriter(threading.Thread):
    """A thread that is responsible for writing data to physical connection.

    TODO(bashi): Make sure there is no thread-safety problem when the reader
    thread reads data from the same socket at a time.
    """

    def __init__(self, mux_handler):
        """Constructs an instance.

        Args:
            mux_handler: _MuxHandler instance.
        """

        threading.Thread.__init__(self)
        self._logger = util.get_class_logger(self)
        self._mux_handler = mux_handler
        self.setDaemon(True)

        # When set, make this thread stop accepting new data, flush pending
        # data and exit.
        self._stop_requested = False
        # The close code of the physical connection.
        self._close_code = common.STATUS_NORMAL_CLOSURE
        # Deque for passing write data. It's protected by _deque_condition
        # until _stop_requested is set.
        self._deque = collections.deque()
        # - Protects _deque, _stop_requested and _close_code
        # - Signals threads waiting for them to be available
        self._deque_condition = threading.Condition()

    def put_outgoing_data(self, data):
        """Puts outgoing data.

        Args:
            data: _OutgoingData instance.

        Raises:
            BadOperationException: when the thread has been requested to
                terminate.
        """

        try:
            self._deque_condition.acquire()
            if self._stop_requested:
                raise BadOperationException('Cannot write data anymore')

            self._deque.append(data)
            self._deque_condition.notify()
        finally:
            self._deque_condition.release()

    def _write_data(self, outgoing_data):
        message = (_encode_channel_id(outgoing_data.channel_id) +
                   outgoing_data.data)
        try:
            self._mux_handler.physical_stream.send_message(
                message=message, end=True, binary=True)
        except Exception, e:
            util.prepend_message_to_exception(
                'Failed to send message to %r: ' %
                (self._mux_handler.physical_connection.remote_addr,), e)
            raise

        # TODO(bashi): It would be better to block the thread that sends
        # control data as well.
        if outgoing_data.channel_id != _CONTROL_CHANNEL_ID:
            self._mux_handler.notify_write_data_done(outgoing_data.channel_id)

    def run(self):
        try:
            self._deque_condition.acquire()
            while not self._stop_requested:
                if len(self._deque) == 0:
                    self._deque_condition.wait()
                    continue

                outgoing_data = self._deque.popleft()

                self._deque_condition.release()
                self._write_data(outgoing_data)
                self._deque_condition.acquire()

            # Flush deque.
            #
            # At this point, self._deque_condition is always acquired.
            try:
                while len(self._deque) > 0:
                    outgoing_data = self._deque.popleft()
                    self._write_data(outgoing_data)
            finally:
                self._deque_condition.release()

            # Close physical connection.
            try:
                # Don't wait the response here. The response will be read
                # by the reader thread.
                self._mux_handler.physical_stream.close_connection(
                    self._close_code, wait_response=False)
            except Exception, e:
                util.prepend_message_to_exception(
                    'Failed to close the physical connection: %r' % e)
                raise
        finally:
            self._mux_handler.notify_writer_done()

    def stop(self, close_code=common.STATUS_NORMAL_CLOSURE):
        """Stops the writer thread."""

        self._deque_condition.acquire()
        self._stop_requested = True
        self._close_code = close_code
        self._deque_condition.notify()
        self._deque_condition.release()


class _PhysicalConnectionReader(threading.Thread):
    """A thread that is responsible for reading data from physical connection.
    """

    def __init__(self, mux_handler):
        """Constructs an instance.

        Args:
            mux_handler: _MuxHandler instance.
        """

        threading.Thread.__init__(self)
        self._logger = util.get_class_logger(self)
        self._mux_handler = mux_handler
        self.setDaemon(True)

    def run(self):
        while True:
            try:
                physical_stream = self._mux_handler.physical_stream
                message = physical_stream.receive_message()
                if message is None:
                    break
                # Below happens only when a data message is received.
                opcode = physical_stream.get_last_received_opcode()
                if opcode != common.OPCODE_BINARY:
                    self._mux_handler.fail_physical_connection(
                        _DROP_CODE_INVALID_ENCAPSULATING_MESSAGE,
                        'Received a text message on physical connection')
                    break

            except ConnectionTerminatedException, e:
                self._logger.debug('%s', e)
                break

            try:
                self._mux_handler.dispatch_message(message)
            except PhysicalConnectionError, e:
                self._mux_handler.fail_physical_connection(
                    e.drop_code, e.message)
                break
            except LogicalChannelError, e:
                self._mux_handler.fail_logical_channel(
                    e.channel_id, e.drop_code, e.message)
            except Exception, e:
                self._logger.debug(traceback.format_exc())
                break

        self._mux_handler.notify_reader_done()


class _Worker(threading.Thread):
    """A thread that is responsible for running the corresponding application
    handler.
    """

    def __init__(self, mux_handler, request):
        """Constructs an instance.

        Args:
            mux_handler: _MuxHandler instance.
            request: _LogicalRequest instance.
        """

        threading.Thread.__init__(self)
        self._logger = util.get_class_logger(self)
        self._mux_handler = mux_handler
        self._request = request
        self.setDaemon(True)

    def run(self):
        self._logger.debug('Logical channel worker started. (id=%d)' %
                           self._request.channel_id)
        try:
            # Non-critical exceptions will be handled by dispatcher.
            self._mux_handler.dispatcher.transfer_data(self._request)
        except LogicalChannelError, e:
            self._mux_handler.fail_logical_channel(
                e.channel_id, e.drop_code, e.message)
        finally:
            self._mux_handler.notify_worker_done(self._request.channel_id)


class _MuxHandshaker(hybi.Handshaker):
    """Opening handshake processor for multiplexing."""

    _DUMMY_WEBSOCKET_KEY = 'dGhlIHNhbXBsZSBub25jZQ=='

    def __init__(self, request, dispatcher, send_quota, receive_quota):
        """Constructs an instance.
        Args:
            request: _LogicalRequest instance.
            dispatcher: Dispatcher instance (dispatch.Dispatcher).
            send_quota: Initial send quota.
            receive_quota: Initial receive quota.
        """

        hybi.Handshaker.__init__(self, request, dispatcher)
        self._send_quota = send_quota
        self._receive_quota = receive_quota

        # Append headers which should not be included in handshake field of
        # AddChannelRequest.
        # TODO(bashi): Make sure whether we should raise exception when
        #     these headers are included already.
        request.headers_in[common.UPGRADE_HEADER] = (
            common.WEBSOCKET_UPGRADE_TYPE)
        request.headers_in[common.SEC_WEBSOCKET_VERSION_HEADER] = (
            str(common.VERSION_HYBI_LATEST))
        request.headers_in[common.SEC_WEBSOCKET_KEY_HEADER] = (
            self._DUMMY_WEBSOCKET_KEY)

    def _create_stream(self, stream_options):
        """Override hybi.Handshaker._create_stream."""

        self._logger.debug('Creating logical stream for %d' %
                           self._request.channel_id)
        return _LogicalStream(
            self._request, stream_options, self._send_quota,
            self._receive_quota)

    def _create_handshake_response(self, accept):
        """Override hybi._create_handshake_response."""

        response = []

        response.append('HTTP/1.1 101 Switching Protocols\r\n')

        # Upgrade and Sec-WebSocket-Accept should be excluded.
        response.append('%s: %s\r\n' % (
            common.CONNECTION_HEADER, common.UPGRADE_CONNECTION_TYPE))
        if self._request.ws_protocol is not None:
            response.append('%s: %s\r\n' % (
                common.SEC_WEBSOCKET_PROTOCOL_HEADER,
                self._request.ws_protocol))
        if (self._request.ws_extensions is not None and
            len(self._request.ws_extensions) != 0):
            response.append('%s: %s\r\n' % (
                common.SEC_WEBSOCKET_EXTENSIONS_HEADER,
                common.format_extensions(self._request.ws_extensions)))
        response.append('\r\n')

        return ''.join(response)

    def _send_handshake(self, accept):
        """Override hybi.Handshaker._send_handshake."""

        # Don't send handshake response for the default channel
        if self._request.channel_id == _DEFAULT_CHANNEL_ID:
            return

        handshake_response = self._create_handshake_response(accept)
        frame_data = _create_add_channel_response(
                         self._request.channel_id,
                         handshake_response)
        self._logger.debug('Sending handshake response for %d: %r' %
                           (self._request.channel_id, frame_data))
        self._request.connection.write_control_data(frame_data)


class _LogicalChannelData(object):
    """A structure that holds information about logical channel.
    """

    def __init__(self, request, worker):
        self.request = request
        self.worker = worker
        self.drop_code = _DROP_CODE_NORMAL_CLOSURE
        self.drop_message = ''


class _HandshakeDeltaBase(object):
    """A class that holds information for delta-encoded handshake."""

    def __init__(self, headers):
        self._headers = headers

    def create_headers(self, delta=None):
        """Creates request headers for an AddChannelRequest that has
        delta-encoded handshake.

        Args:
            delta: headers should be overridden.
        """

        headers = copy.copy(self._headers)
        if delta:
            for key, value in delta.items():
                # The spec requires that a header with an empty value is
                # removed from the delta base.
                if len(value) == 0 and headers.has_key(key):
                    del headers[key]
                else:
                    headers[key] = value
        return headers


class _MuxHandler(object):
    """Multiplexing handler. When a handler starts, it launches three
    threads; the reader thread, the writer thread, and a worker thread.

    The reader thread reads data from the physical stream, i.e., the
    ws_stream object of the underlying websocket connection. The reader
    thread interprets multiplexed frames and dispatches them to logical
    channels. Methods of this class are mostly called by the reader thread.

    The writer thread sends multiplexed frames which are created by
    logical channels via the physical connection.

    The worker thread launched at the starting point handles the
    "Implicitly Opened Connection". If multiplexing handler receives
    an AddChannelRequest and accepts it, the handler will launch a new worker
    thread and dispatch the request to it.
    """

    def __init__(self, request, dispatcher):
        """Constructs an instance.

        Args:
            request: mod_python request of the physical connection.
            dispatcher: Dispatcher instance (dispatch.Dispatcher).
        """

        self.original_request = request
        self.dispatcher = dispatcher
        self.physical_connection = request.connection
        self.physical_stream = request.ws_stream
        self._logger = util.get_class_logger(self)
        self._logical_channels = {}
        self._logical_channels_condition = threading.Condition()
        # Holds client's initial quota
        self._channel_slots = collections.deque()
        self._handshake_base = None
        self._worker_done_notify_received = False
        self._reader = None
        self._writer = None

    def start(self):
        """Starts the handler.

        Raises:
            MuxUnexpectedException: when the handler already started, or when
                opening handshake of the default channel fails.
        """

        if self._reader or self._writer:
            raise MuxUnexpectedException('MuxHandler already started')

        self._reader = _PhysicalConnectionReader(self)
        self._writer = _PhysicalConnectionWriter(self)
        self._reader.start()
        self._writer.start()

        # Create "Implicitly Opened Connection".
        logical_connection = _LogicalConnection(self, _DEFAULT_CHANNEL_ID)
        headers = copy.copy(self.original_request.headers_in)
        # Add extensions for logical channel.
        headers[common.SEC_WEBSOCKET_EXTENSIONS_HEADER] = (
            common.format_extensions(
                self.original_request.mux_processor.extensions()))
        self._handshake_base = _HandshakeDeltaBase(headers)
        logical_request = _LogicalRequest(
            _DEFAULT_CHANNEL_ID,
            self.original_request.method,
            self.original_request.uri,
            self.original_request.protocol,
            self._handshake_base.create_headers(),
            logical_connection)
        # Client's send quota for the implicitly opened connection is zero,
        # but we will send FlowControl later so set the initial quota to
        # _INITIAL_QUOTA_FOR_CLIENT.
        self._channel_slots.append(_INITIAL_QUOTA_FOR_CLIENT)
        send_quota = self.original_request.mux_processor.quota()
        if not self._do_handshake_for_logical_request(
            logical_request, send_quota=send_quota):
            raise MuxUnexpectedException(
                'Failed handshake on the default channel id')
        self._add_logical_channel(logical_request)

        # Send FlowControl for the implicitly opened connection.
        frame_data = _create_flow_control(_DEFAULT_CHANNEL_ID,
                                          _INITIAL_QUOTA_FOR_CLIENT)
        logical_request.connection.write_control_data(frame_data)

    def add_channel_slots(self, slots, send_quota):
        """Adds channel slots.

        Args:
            slots: number of slots to be added.
            send_quota: initial send quota for slots.
        """

        self._channel_slots.extend([send_quota] * slots)
        # Send NewChannelSlot to client.
        frame_data = _create_new_channel_slot(slots, send_quota)
        self.send_control_data(frame_data)

    def wait_until_done(self, timeout=None):
        """Waits until all workers are done. Returns False when timeout has
        occurred. Returns True on success.

        Args:
            timeout: timeout in sec.
        """

        self._logical_channels_condition.acquire()
        try:
            while len(self._logical_channels) > 0:
                self._logger.debug('Waiting workers(%d)...' %
                                   len(self._logical_channels))
                self._worker_done_notify_received = False
                self._logical_channels_condition.wait(timeout)
                if not self._worker_done_notify_received:
                    self._logger.debug('Waiting worker(s) timed out')
                    return False
        finally:
            self._logical_channels_condition.release()

        # Flush pending outgoing data
        self._writer.stop()
        self._writer.join()

        return True

    def notify_write_data_done(self, channel_id):
        """Called by the writer thread when a write operation has done.

        Args:
            channel_id: objective channel id.
        """

        try:
            self._logical_channels_condition.acquire()
            if channel_id in self._logical_channels:
                channel_data = self._logical_channels[channel_id]
                channel_data.request.connection.on_write_data_done()
            else:
                self._logger.debug('Seems that logical channel for %d has gone'
                                   % channel_id)
        finally:
            self._logical_channels_condition.release()

    def send_control_data(self, data):
        """Sends data via the control channel.

        Args:
            data: data to be sent.
        """

        self._writer.put_outgoing_data(_OutgoingData(
                channel_id=_CONTROL_CHANNEL_ID, data=data))

    def send_data(self, channel_id, data):
        """Sends data via given logical channel. This method is called by
        worker threads.

        Args:
            channel_id: objective channel id.
            data: data to be sent.
        """

        self._writer.put_outgoing_data(_OutgoingData(
                channel_id=channel_id, data=data))

    def _send_drop_channel(self, channel_id, code=None, message=''):
        frame_data = _create_drop_channel(channel_id, code, message)
        self._logger.debug(
            'Sending drop channel for channel id %d' % channel_id)
        self.send_control_data(frame_data)

    def _send_error_add_channel_response(self, channel_id, status=None):
        if status is None:
            status = common.HTTP_STATUS_BAD_REQUEST

        if status in _HTTP_BAD_RESPONSE_MESSAGES:
            message = _HTTP_BAD_RESPONSE_MESSAGES[status]
        else:
            self._logger.debug('Response message for %d is not found' % status)
            message = '???'

        response = 'HTTP/1.1 %d %s\r\n\r\n' % (status, message)
        frame_data = _create_add_channel_response(channel_id,
                                                  encoded_handshake=response,
                                                  encoding=0, rejected=True)
        self.send_control_data(frame_data)

    def _create_logical_request(self, block):
        if block.channel_id == _CONTROL_CHANNEL_ID:
            # TODO(bashi): Raise PhysicalConnectionError with code 2006
            # instead of MuxUnexpectedException.
            raise MuxUnexpectedException(
                'Received the control channel id (0) as objective channel '
                'id for AddChannel')

        if block.encoding > _HANDSHAKE_ENCODING_DELTA:
            raise PhysicalConnectionError(
                _DROP_CODE_UNKNOWN_REQUEST_ENCODING)

        method, path, version, headers = _parse_request_text(
            block.encoded_handshake)
        if block.encoding == _HANDSHAKE_ENCODING_DELTA:
            headers = self._handshake_base.create_headers(headers)

        connection = _LogicalConnection(self, block.channel_id)
        request = _LogicalRequest(block.channel_id, method, path, version,
                                  headers, connection)
        return request

    def _do_handshake_for_logical_request(self, request, send_quota=0):
        try:
            receive_quota = self._channel_slots.popleft()
        except IndexError:
            raise LogicalChannelError(
                request.channel_id, _DROP_CODE_NEW_CHANNEL_SLOT_VIOLATION)

        handshaker = _MuxHandshaker(request, self.dispatcher,
                                    send_quota, receive_quota)
        try:
            handshaker.do_handshake()
        except handshake.VersionException, e:
            self._logger.info('%s', e)
            self._send_error_add_channel_response(
                request.channel_id, status=common.HTTP_STATUS_BAD_REQUEST)
            return False
        except handshake.HandshakeException, e:
            # TODO(bashi): Should we _Fail the Logical Channel_ with 3001
            # instead?
            self._logger.info('%s', e)
            self._send_error_add_channel_response(request.channel_id,
                                                  status=e.status)
            return False
        except handshake.AbortedByUserException, e:
            self._logger.info('%s', e)
            self._send_error_add_channel_response(request.channel_id)
            return False

        return True

    def _add_logical_channel(self, logical_request):
        try:
            self._logical_channels_condition.acquire()
            if logical_request.channel_id in self._logical_channels:
                self._logger.debug('Channel id %d already exists' %
                                   logical_request.channel_id)
                raise PhysicalConnectionError(
                    _DROP_CODE_CHANNEL_ALREADY_EXISTS,
                    'Channel id %d already exists' %
                    logical_request.channel_id)
            worker = _Worker(self, logical_request)
            channel_data = _LogicalChannelData(logical_request, worker)
            self._logical_channels[logical_request.channel_id] = channel_data
            worker.start()
        finally:
            self._logical_channels_condition.release()

    def _process_add_channel_request(self, block):
        try:
            logical_request = self._create_logical_request(block)
        except ValueError, e:
            self._logger.debug('Failed to create logical request: %r' % e)
            self._send_error_add_channel_response(
                block.channel_id, status=common.HTTP_STATUS_BAD_REQUEST)
            return
        if self._do_handshake_for_logical_request(logical_request):
            if block.encoding == _HANDSHAKE_ENCODING_IDENTITY:
                # Update handshake base.
                # TODO(bashi): Make sure this is the right place to update
                # handshake base.
                self._handshake_base = _HandshakeDeltaBase(
                    logical_request.headers_in)
            self._add_logical_channel(logical_request)
        else:
            self._send_error_add_channel_response(
                block.channel_id, status=common.HTTP_STATUS_BAD_REQUEST)

    def _process_flow_control(self, block):
        try:
            self._logical_channels_condition.acquire()
            if not block.channel_id in self._logical_channels:
                return
            channel_data = self._logical_channels[block.channel_id]
            channel_data.request.ws_stream.replenish_send_quota(
                block.send_quota)
        finally:
            self._logical_channels_condition.release()

    def _process_drop_channel(self, block):
        self._logger.debug(
            'DropChannel received for %d: code=%r, reason=%r' %
            (block.channel_id, block.drop_code, block.drop_message))
        try:
            self._logical_channels_condition.acquire()
            if not block.channel_id in self._logical_channels:
                return
            channel_data = self._logical_channels[block.channel_id]
            channel_data.drop_code = _DROP_CODE_ACKNOWLEDGED

            # Close the logical channel
            channel_data.request.connection.set_read_state(
                _LogicalConnection.STATE_TERMINATED)
            channel_data.request.ws_stream.stop_sending()
        finally:
            self._logical_channels_condition.release()

    def _process_control_blocks(self, parser):
        for control_block in parser.read_control_blocks():
            opcode = control_block.opcode
            self._logger.debug('control block received, opcode: %d' % opcode)
            if opcode == _MUX_OPCODE_ADD_CHANNEL_REQUEST:
                self._process_add_channel_request(control_block)
            elif opcode == _MUX_OPCODE_ADD_CHANNEL_RESPONSE:
                raise PhysicalConnectionError(
                    _DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                    'Received AddChannelResponse')
            elif opcode == _MUX_OPCODE_FLOW_CONTROL:
                self._process_flow_control(control_block)
            elif opcode == _MUX_OPCODE_DROP_CHANNEL:
                self._process_drop_channel(control_block)
            elif opcode == _MUX_OPCODE_NEW_CHANNEL_SLOT:
                raise PhysicalConnectionError(
                    _DROP_CODE_INVALID_MUX_CONTROL_BLOCK,
                    'Received NewChannelSlot')
            else:
                raise MuxUnexpectedException(
                    'Unexpected opcode %r' % opcode)

    def _process_logical_frame(self, channel_id, parser):
        self._logger.debug('Received a frame. channel id=%d' % channel_id)
        try:
            self._logical_channels_condition.acquire()
            if not channel_id in self._logical_channels:
                # We must ignore the message for an inactive channel.
                return
            channel_data = self._logical_channels[channel_id]
            fin, rsv1, rsv2, rsv3, opcode, payload = parser.read_inner_frame()
            consuming_byte = len(payload)
            if opcode != common.OPCODE_CONTINUATION:
                consuming_byte += 1
            if not channel_data.request.ws_stream.consume_receive_quota(
                consuming_byte):
                # The client violates quota. Close logical channel.
                raise LogicalChannelError(
                    channel_id, _DROP_CODE_SEND_QUOTA_VIOLATION)
            header = create_header(opcode, len(payload), fin, rsv1, rsv2, rsv3,
                                   mask=False)
            frame_data = header + payload
            channel_data.request.connection.append_frame_data(frame_data)
        finally:
            self._logical_channels_condition.release()

    def dispatch_message(self, message):
        """Dispatches message. The reader thread calls this method.

        Args:
            message: a message that contains encapsulated frame.
        Raises:
            PhysicalConnectionError: if the message contains physical
                connection level errors.
            LogicalChannelError: if the message contains logical channel
                level errors.
        """

        parser = _MuxFramePayloadParser(message)
        try:
            channel_id = parser.read_channel_id()
        except ValueError, e:
            raise PhysicalConnectionError(_DROP_CODE_CHANNEL_ID_TRUNCATED)
        if channel_id == _CONTROL_CHANNEL_ID:
            self._process_control_blocks(parser)
        else:
            self._process_logical_frame(channel_id, parser)

    def notify_worker_done(self, channel_id):
        """Called when a worker has finished.

        Args:
            channel_id: channel id corresponded with the worker.
        """

        self._logger.debug('Worker for channel id %d terminated' % channel_id)
        try:
            self._logical_channels_condition.acquire()
            if not channel_id in self._logical_channels:
                raise MuxUnexpectedException(
                    'Channel id %d not found' % channel_id)
            channel_data = self._logical_channels.pop(channel_id)
        finally:
            self._worker_done_notify_received = True
            self._logical_channels_condition.notify()
            self._logical_channels_condition.release()

        if not channel_data.request.server_terminated:
            self._send_drop_channel(
                channel_id, code=channel_data.drop_code,
                message=channel_data.drop_message)

    def notify_reader_done(self):
        """This method is called by the reader thread when the reader has
        finished.
        """

        self._logger.debug(
            'Termiating all logical connections waiting for incoming data '
            '...')
        self._logical_channels_condition.acquire()
        for channel_data in self._logical_channels.values():
            try:
                channel_data.request.connection.set_read_state(
                    _LogicalConnection.STATE_TERMINATED)
            except Exception:
                self._logger.debug(traceback.format_exc())
        self._logical_channels_condition.release()

    def notify_writer_done(self):
        """This method is called by the writer thread when the writer has
        finished.
        """

        self._logger.debug(
            'Termiating all logical connections waiting for write '
            'completion ...')
        self._logical_channels_condition.acquire()
        for channel_data in self._logical_channels.values():
            try:
                channel_data.request.connection.on_writer_done()
            except Exception:
                self._logger.debug(traceback.format_exc())
        self._logical_channels_condition.release()

    def fail_physical_connection(self, code, message):
        """Fail the physical connection.

        Args:
            code: drop reason code.
            message: drop message.
        """

        self._logger.debug('Failing the physical connection...')
        self._send_drop_channel(_CONTROL_CHANNEL_ID, code, message)
        self._writer.stop(common.STATUS_INTERNAL_ENDPOINT_ERROR)

    def fail_logical_channel(self, channel_id, code, message):
        """Fail a logical channel.

        Args:
            channel_id: channel id.
            code: drop reason code.
            message: drop message.
        """

        self._logger.debug('Failing logical channel %d...' % channel_id)
        try:
            self._logical_channels_condition.acquire()
            if channel_id in self._logical_channels:
                channel_data = self._logical_channels[channel_id]
                # Close the logical channel. notify_worker_done() will be
                # called later and it will send DropChannel.
                channel_data.drop_code = code
                channel_data.drop_message = message

                channel_data.request.connection.set_read_state(
                    _LogicalConnection.STATE_TERMINATED)
                channel_data.request.ws_stream.stop_sending()
            else:
                self._send_drop_channel(channel_id, code, message)
        finally:
            self._logical_channels_condition.release()


def use_mux(request):
    return hasattr(request, 'mux_processor') and (
        request.mux_processor.is_active())


def start(request, dispatcher):
    mux_handler = _MuxHandler(request, dispatcher)
    mux_handler.start()

    mux_handler.add_channel_slots(_INITIAL_NUMBER_OF_CHANNEL_SLOTS,
                                  _INITIAL_QUOTA_FOR_CLIENT)

    mux_handler.wait_until_done()


# vi:sts=4 sw=4 et
