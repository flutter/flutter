# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility classes to handle sending and receiving messages."""


import struct
import sys
import weakref

import mojo_bindings.serialization as serialization

# pylint: disable=E0611,F0401
import mojo_system as system


# The flag values for a message header.
NO_FLAG = 0
MESSAGE_EXPECTS_RESPONSE_FLAG = 1 << 0
MESSAGE_IS_RESPONSE_FLAG = 1 << 1


class MessagingException(Exception):
  def __init__(self, *args, **kwargs):
    Exception.__init__(self, *args, **kwargs)
    self.__traceback__ = sys.exc_info()[2]


class MessageHeader(object):
  """The header of a mojo message."""

  _SIMPLE_MESSAGE_VERSION = 0
  _SIMPLE_MESSAGE_STRUCT = struct.Struct("<IIII")

  _REQUEST_ID_STRUCT = struct.Struct("<Q")
  _REQUEST_ID_OFFSET = _SIMPLE_MESSAGE_STRUCT.size

  _MESSAGE_WITH_REQUEST_ID_VERSION = 1
  _MESSAGE_WITH_REQUEST_ID_SIZE = (
      _SIMPLE_MESSAGE_STRUCT.size + _REQUEST_ID_STRUCT.size)

  def __init__(self, message_type, flags, request_id=0, data=None):
    self._message_type = message_type
    self._flags = flags
    self._request_id = request_id
    self._data = data

  @classmethod
  def Deserialize(cls, data):
    buf = buffer(data)
    if len(data) < cls._SIMPLE_MESSAGE_STRUCT.size:
      raise serialization.DeserializationException('Header is too short.')
    (size, version, message_type, flags) = (
        cls._SIMPLE_MESSAGE_STRUCT.unpack_from(buf))
    if (version < cls._SIMPLE_MESSAGE_VERSION):
      raise serialization.DeserializationException('Incorrect version.')
    request_id = 0
    if _HasRequestId(flags):
      if version < cls._MESSAGE_WITH_REQUEST_ID_VERSION:
        raise serialization.DeserializationException('Incorrect version.')
      if (size < cls._MESSAGE_WITH_REQUEST_ID_SIZE or
          len(data) < cls._MESSAGE_WITH_REQUEST_ID_SIZE):
        raise serialization.DeserializationException('Header is too short.')
      (request_id, ) = cls._REQUEST_ID_STRUCT.unpack_from(
          buf, cls._REQUEST_ID_OFFSET)
    return MessageHeader(message_type, flags, request_id, data)

  @property
  def message_type(self):
    return self._message_type

  # pylint: disable=E0202
  @property
  def request_id(self):
    assert self.has_request_id
    return self._request_id

  # pylint: disable=E0202
  @request_id.setter
  def request_id(self, request_id):
    assert self.has_request_id
    self._request_id = request_id
    self._REQUEST_ID_STRUCT.pack_into(self._data, self._REQUEST_ID_OFFSET,
                                      request_id)

  @property
  def has_request_id(self):
    return _HasRequestId(self._flags)

  @property
  def expects_response(self):
    return self._HasFlag(MESSAGE_EXPECTS_RESPONSE_FLAG)

  @property
  def is_response(self):
    return self._HasFlag(MESSAGE_IS_RESPONSE_FLAG)

  @property
  def size(self):
    if self.has_request_id:
      return self._MESSAGE_WITH_REQUEST_ID_SIZE
    return self._SIMPLE_MESSAGE_STRUCT.size

  def Serialize(self):
    if not self._data:
      self._data = bytearray(self.size)
      version = self._SIMPLE_MESSAGE_VERSION
      size = self._SIMPLE_MESSAGE_STRUCT.size
      if self.has_request_id:
        version = self._MESSAGE_WITH_REQUEST_ID_VERSION
        size = self._MESSAGE_WITH_REQUEST_ID_SIZE
      self._SIMPLE_MESSAGE_STRUCT.pack_into(self._data, 0, size, version,
                                            self._message_type, self._flags)
      if self.has_request_id:
        self._REQUEST_ID_STRUCT.pack_into(self._data, self._REQUEST_ID_OFFSET,
                                          self._request_id)
    return self._data

  def _HasFlag(self, flag):
    return self._flags & flag != 0


class Message(object):
  """A message for a message pipe. This contains data and handles."""

  def __init__(self, data=None, handles=None, header=None):
    self.data = data
    self.handles = handles
    self._header = header
    self._payload = None

  @property
  def header(self):
    if self._header is None:
      self._header = MessageHeader.Deserialize(self.data)
    return self._header

  @property
  def payload(self):
    if self._payload is None:
      self._payload = Message(self.data[self.header.size:], self.handles)
    return self._payload

  def SetRequestId(self, request_id):
    header = self.header
    header.request_id = request_id
    (data, _) = header.Serialize()
    self.data[:header.Size] = data[:header.Size]


class MessageReceiver(object):
  """A class which implements this interface can receive Message objects."""

  def Accept(self, message):
    """
    Receive a Message. The MessageReceiver is allowed to mutate the message.

    Args:
      message: the received message.

    Returns:
      True if the message has been handled, False otherwise.
    """
    raise NotImplementedError()


class MessageReceiverWithResponder(MessageReceiver):
  """
  A MessageReceiver that can also handle the response message generated from the
  given message.
  """

  def AcceptWithResponder(self, message, responder):
    """
    A variant on Accept that registers a MessageReceiver (known as the
    responder) to handle the response message generated from the given message.
    The responder's Accept method may be called as part of the call to
    AcceptWithResponder, or some time after its return.

    Args:
      message: the received message.
      responder: the responder that will receive the response.

    Returns:
      True if the message has been handled, False otherwise.
    """
    raise NotImplementedError()


class ConnectionErrorHandler(object):
  """
  A ConnectionErrorHandler is notified of an error happening while using the
  bindings over message pipes.
  """

  def OnError(self, result):
    raise NotImplementedError()


class Connector(MessageReceiver):
  """
  A Connector owns a message pipe and will send any received messages to the
  registered MessageReceiver. It also acts as a MessageReceiver and will send
  any message through the handle.

  The method Start must be called before the Connector will start listening to
  incoming messages.
  """

  def __init__(self, handle):
    MessageReceiver.__init__(self)
    self._handle = handle
    self._cancellable = None
    self._incoming_message_receiver = None
    self._error_handler = None

  def __del__(self):
    if self._cancellable:
      self._cancellable()

  def SetIncomingMessageReceiver(self, message_receiver):
    """
    Set the MessageReceiver that will receive message from the owned message
    pipe.
    """
    self._incoming_message_receiver = message_receiver

  def SetErrorHandler(self, error_handler):
    """
    Set the ConnectionErrorHandler that will be notified of errors on the owned
    message pipe.
    """
    self._error_handler = error_handler

  def Start(self):
    assert not self._cancellable
    self._RegisterAsyncWaiterForRead()

  def Accept(self, message):
    result = self._handle.WriteMessage(message.data, message.handles)
    return result == system.RESULT_OK

  def Close(self):
    if self._cancellable:
      self._cancellable()
      self._cancellable = None
    self._handle.Close()

  def PassMessagePipe(self):
    if self._cancellable:
      self._cancellable()
      self._cancellable = None
    result = self._handle
    self._handle = system.Handle()
    return result

  def _OnAsyncWaiterResult(self, result):
    self._cancellable = None
    if result == system.RESULT_OK:
      self._ReadOutstandingMessages()
    else:
      self._OnError(result)

  def _OnError(self, result):
    assert not self._cancellable
    if self._error_handler:
      self._error_handler.OnError(result)
    self._handle.Close()

  def _RegisterAsyncWaiterForRead(self) :
    assert not self._cancellable
    self._cancellable = self._handle.AsyncWait(
        system.HANDLE_SIGNAL_READABLE,
        system.DEADLINE_INDEFINITE,
        _WeakCallback(self._OnAsyncWaiterResult))

  def _ReadOutstandingMessages(self):
    result = None
    dispatched = True
    while dispatched:
      result, dispatched = _ReadAndDispatchMessage(
          self._handle, self._incoming_message_receiver)
    if result == system.RESULT_SHOULD_WAIT:
      self._RegisterAsyncWaiterForRead()
      return
    self._OnError(result)


class Router(MessageReceiverWithResponder):
  """
  A Router will handle mojo message and forward those to a Connector. It deals
  with parsing of headers and adding of request ids in order to be able to match
  a response to a request.
  """

  def __init__(self, handle):
    MessageReceiverWithResponder.__init__(self)
    self._incoming_message_receiver = None
    self._next_request_id = 1
    self._responders = {}
    self._connector = Connector(handle)
    self._connector.SetIncomingMessageReceiver(
        ForwardingMessageReceiver(_WeakCallback(self._HandleIncomingMessage)))

  def Start(self):
    self._connector.Start()

  def SetIncomingMessageReceiver(self, message_receiver):
    """
    Set the MessageReceiver that will receive message from the owned message
    pipe.
    """
    self._incoming_message_receiver = message_receiver

  def SetErrorHandler(self, error_handler):
    """
    Set the ConnectionErrorHandler that will be notified of errors on the owned
    message pipe.
    """
    self._connector.SetErrorHandler(error_handler)

  def Accept(self, message):
    # A message without responder is directly forwarded to the connector.
    return self._connector.Accept(message)

  def AcceptWithResponder(self, message, responder):
    # The message must have a header.
    header = message.header
    assert header.expects_response
    request_id = self._NextRequestId()
    header.request_id = request_id
    if not self._connector.Accept(message):
      return False
    self._responders[request_id] = responder
    return True

  def Close(self):
    self._connector.Close()

  def PassMessagePipe(self):
    return self._connector.PassMessagePipe()

  def _HandleIncomingMessage(self, message):
    header = message.header
    if header.expects_response:
      if self._incoming_message_receiver:
        return self._incoming_message_receiver.AcceptWithResponder(
            message, self)
      # If we receive a request expecting a response when the client is not
      # listening, then we have no choice but to tear down the pipe.
      self.Close()
      return False
    if header.is_response:
      request_id = header.request_id
      responder = self._responders.pop(request_id, None)
      if responder is None:
        return False
      return responder.Accept(message)
    if self._incoming_message_receiver:
      return self._incoming_message_receiver.Accept(message)
    # Ok to drop the message
    return False

  def _NextRequestId(self):
    request_id = self._next_request_id
    while request_id == 0 or request_id in self._responders:
      request_id = (request_id + 1) % (1 << 64)
    self._next_request_id = (request_id + 1) % (1 << 64)
    return request_id

class ForwardingMessageReceiver(MessageReceiver):
  """A MessageReceiver that forward calls to |Accept| to a callable."""

  def __init__(self, callback):
    MessageReceiver.__init__(self)
    self._callback = callback

  def Accept(self, message):
    return self._callback(message)


def _WeakCallback(callback):
  func = callback.im_func
  self = callback.im_self
  if not self:
    return callback
  weak_self = weakref.ref(self)
  def Callback(*args, **kwargs):
    self = weak_self()
    if self:
      return func(self, *args, **kwargs)
  return Callback


def _ReadAndDispatchMessage(handle, message_receiver):
  dispatched = False
  (result, _, sizes) = handle.ReadMessage()
  if result == system.RESULT_OK and message_receiver:
    dispatched = message_receiver.Accept(Message(bytearray(), []))
  if result != system.RESULT_RESOURCE_EXHAUSTED:
    return (result, dispatched)
  (result, data, _) = handle.ReadMessage(bytearray(sizes[0]), sizes[1])
  if result == system.RESULT_OK and message_receiver:
    dispatched = message_receiver.Accept(Message(data[0], data[1]))
  return (result, dispatched)

def _HasRequestId(flags):
  return flags & (MESSAGE_EXPECTS_RESPONSE_FLAG|MESSAGE_IS_RESPONSE_FLAG) != 0
