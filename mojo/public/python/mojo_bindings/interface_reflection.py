# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
The metaclasses used by the mojo python bindings for interfaces.

It is splitted from mojo_bindings.reflection because it uses some generated code
that would create a cyclic dependency.
"""

import logging
import sys

# pylint: disable=F0401
import interface_control_messages_mojom
import mojo_bindings.messaging as messaging
import mojo_bindings.promise as promise
import mojo_bindings.reflection as reflection
import mojo_bindings.serialization as serialization
import mojo_system


class MojoInterfaceType(type):
  """Meta class for interfaces.

  Usage:
    class MyInterface(object):
      __metaclass__ = MojoInterfaceType
      DESCRIPTOR = {
        'fully_qualified_name': 'service::MyInterface'
        'version': 3,
        'methods': [
          {
            'name': 'FireAndForget',
            'ordinal': 0,
            'parameters': [
              SingleFieldGroup('x', _descriptor.TYPE_INT32, 0, 0),
            ]
          },
          {
            'name': 'Ping',
            'ordinal': 1,
            'parameters': [
              SingleFieldGroup('x', _descriptor.TYPE_INT32, 0, 0),
            ],
            'responses': [
              SingleFieldGroup('x', _descriptor.TYPE_INT32, 0, 0),
            ],
          },
        ],
      }
  """

  def __new__(mcs, name, bases, dictionary):
    # If one of the base class is already an interface type, do not edit the
    # class.
    for base in bases:
      if isinstance(base, mcs):
        return type.__new__(mcs, name, bases, dictionary)

    descriptor = dictionary.pop('DESCRIPTOR', {})

    methods = [_MethodDescriptor(x) for x in descriptor.get('methods', [])]
    for method in methods:
      dictionary[method.name] = _NotImplemented
    fully_qualified_name = descriptor['fully_qualified_name']

    interface_manager = InterfaceManager(
        fully_qualified_name, descriptor['version'], methods)
    dictionary.update({
        'manager': None,
        '_interface_manager': interface_manager,
    })

    interface_class = type.__new__(mcs, name, bases, dictionary)
    interface_manager.interface_class = interface_class
    return interface_class

  @property
  def manager(cls):
    return cls._interface_manager

  # Prevent adding new attributes, or mutating constants.
  def __setattr__(cls, key, value):
    raise AttributeError('can\'t set attribute')

  # Prevent deleting constants.
  def __delattr__(cls, key):
    raise AttributeError('can\'t delete attribute')


class InterfaceManager(object):
  """
  Manager for an interface class. The manager contains the operation that allows
  to bind an implementation to a pipe, or to generate a proxy for an interface
  over a pipe.
  """

  def __init__(self, name, version, methods):
    self.name = name
    self.version = version
    self.methods = methods
    self.interface_class = None
    self._proxy_class = None
    self._stub_class = None

  def Proxy(self, handle, version=0):
    router = messaging.Router(handle)
    error_handler = _ProxyErrorHandler()
    router.SetErrorHandler(error_handler)
    router.Start()
    return self._InternalProxy(router, error_handler, version)

  # pylint: disable=W0212
  def Bind(self, impl, handle):
    router = messaging.Router(handle)
    router.SetIncomingMessageReceiver(self._Stub(impl))
    error_handler = _ProxyErrorHandler()
    router.SetErrorHandler(error_handler)

    # Retain the router, until an error happen.
    retainer = _Retainer(router)
    def Cleanup(_):
      retainer.release()
    error_handler.AddCallback(Cleanup)

    # Give an instance manager to the implementation to allow it to close
    # the connection.
    impl.manager = InstanceManager(self, router, error_handler)

    router.Start()

  def NewRequest(self):
    pipe = mojo_system.MessagePipe()
    return (self.Proxy(pipe.handle0), reflection.InterfaceRequest(pipe.handle1))

  def _InternalProxy(self, router, error_handler, version):
    if error_handler is None:
      error_handler = _ProxyErrorHandler()

    if not self._proxy_class:
      dictionary = {
        '__module__': __name__,
        '__init__': _ProxyInit,
      }
      for method in self.methods:
        dictionary[method.name] = _ProxyMethodCall(method)
      self._proxy_class = type(
          '%sProxy' % self.name,
          (self.interface_class, reflection.InterfaceProxy),
          dictionary)

    proxy = self._proxy_class(router, error_handler)
    # Give an instance manager to the proxy to allow to close the connection.
    proxy.manager = ProxyInstanceManager(
        self, proxy, router, error_handler, version)
    return proxy

  def _Stub(self, impl):
    if not self._stub_class:
      accept_method = _StubAccept(self.methods)
      dictionary = {
        '__module__': __name__,
        '__init__': _StubInit,
        'Accept': accept_method,
        'AcceptWithResponder': accept_method,
      }
      self._stub_class = type('%sStub' % self.name,
                              (messaging.MessageReceiverWithResponder,),
                              dictionary)
    return self._stub_class(impl)


class InstanceManager(object):
  """
  Manager for the implementation of an interface or a proxy. The manager allows
  to control the connection over the pipe.
  """
  def __init__(self, interface_manager, router, error_handler):
    self.interface_manager = interface_manager
    self._router = router
    self._error_handler = error_handler
    assert self._error_handler is not None

  def Close(self):
    self._error_handler.OnClose()
    self._router.Close()

  def PassMessagePipe(self):
    self._error_handler.OnClose()
    return self._router.PassMessagePipe()

  def AddOnErrorCallback(self, callback):
    self._error_handler.AddCallback(lambda _: callback(), False)


class ProxyInstanceManager(InstanceManager):
  """
  Manager for the implementation of a proxy. The manager allows to control the
  connection over the pipe.
  """
  def __init__(self, interface_manager, proxy, router, error_handler, version):
    super(ProxyInstanceManager, self).__init__(
        interface_manager, router, error_handler)
    self.proxy = proxy
    self.version = version
    self._run_method = _ProxyMethodCall(_BaseMethodDescriptor(
        'Run',
        interface_control_messages_mojom.RUN_MESSAGE_ID,
        interface_control_messages_mojom.RunMessageParams,
        interface_control_messages_mojom.RunResponseMessageParams))
    self._run_or_close_pipe_method = _ProxyMethodCall(_BaseMethodDescriptor(
        'RunOrClosePipe',
        interface_control_messages_mojom.RUN_OR_CLOSE_PIPE_MESSAGE_ID,
        interface_control_messages_mojom.RunOrClosePipeMessageParams,
        None))

  def QueryVersion(self):
    params = interface_control_messages_mojom.RunMessageParams()
    params.reserved0 = 16
    params.reserved1 = 0
    params.query_version = (
        interface_control_messages_mojom.QueryVersion())
    def ToVersion(r):
      self.version = r.query_version_result.version
      return self.version
    return self._run_method(self.proxy, **params.AsDict()).Then(ToVersion)

  def RequireVersion(self, version):
    if self.version >= version:
      return
    self.version = version
    params = interface_control_messages_mojom.RunOrClosePipeMessageParams()
    params.reserved0 = 16
    params.reserved1 = 0
    params.require_version = interface_control_messages_mojom.RequireVersion()
    params.require_version.version = version
    return self._run_or_close_pipe_method(self.proxy, **params.AsDict())


class _BaseMethodDescriptor(object):
  def __init__(self, name, ordinal, parameters_struct, response_struct):
    self.name = name
    self.ordinal = ordinal
    self.parameters_struct = parameters_struct
    self.response_struct = response_struct


class _MethodDescriptor(_BaseMethodDescriptor):
  def __init__(self, descriptor):
    name = descriptor['name']
    super(_MethodDescriptor, self).__init__(
        name,
        descriptor['ordinal'],
        _ConstructParameterStruct(
            descriptor['parameters'], name, "Parameters"),
        _ConstructParameterStruct(
            descriptor.get('responses'), name, "Responses"))


def _ConstructParameterStruct(descriptor, name, suffix):
  if descriptor is None:
    return None
  parameter_dictionary = {
    '__metaclass__': reflection.MojoStructType,
    '__module__': __name__,
    'DESCRIPTOR': descriptor,
  }
  return reflection.MojoStructType(
      '%s%s' % (name, suffix),
      (object,),
      parameter_dictionary)


class _ProxyErrorHandler(messaging.ConnectionErrorHandler):
  def __init__(self):
    messaging.ConnectionErrorHandler.__init__(self)
    self._callbacks = dict()

  def OnError(self, result):
    if self._callbacks is None:
      return
    exception = messaging.MessagingException('Mojo error: %d' % result)
    for (callback, _) in self._callbacks.iteritems():
      callback(exception)
    self._callbacks = None

  def OnClose(self):
    if self._callbacks is None:
      return
    exception = messaging.MessagingException('Router has been closed.')
    for (callback, call_on_close) in self._callbacks.iteritems():
      if call_on_close:
        callback(exception)
    self._callbacks = None

  def AddCallback(self, callback, call_on_close=True):
    if self._callbacks is not None:
      self._callbacks[callback] = call_on_close

  def RemoveCallback(self, callback):
    if self._callbacks:
      del self._callbacks[callback]


class _Retainer(object):

  # Set to force instances to be retained.
  _RETAINED = set()

  def __init__(self, retained):
    self._retained = retained
    _Retainer._RETAINED.add(self)

  def release(self):
    self._retained = None
    _Retainer._RETAINED.remove(self)


def _ProxyInit(self, router, error_handler):
  self._router = router
  self._error_handler = error_handler


# pylint: disable=W0212
def _ProxyMethodCall(method):
  flags = messaging.NO_FLAG
  if method.response_struct:
    flags = messaging.MESSAGE_EXPECTS_RESPONSE_FLAG
  def _Call(self, *args, **kwargs):
    def GenerationMethod(resolve, reject):
      message = _GetMessage(method, flags, None, *args, **kwargs)
      if method.response_struct:
        def Accept(message):
          try:
            assert message.header.message_type == method.ordinal
            payload = message.payload
            response = method.response_struct.Deserialize(
                serialization.RootDeserializationContext(payload.data,
                                                         payload.handles))
            as_dict = response.AsDict()
            if len(as_dict) == 1:
              value = as_dict.values()[0]
              if not isinstance(value, dict):
                response = value
            resolve(response)
            return True
          except Exception as e:
            # Adding traceback similarly to python 3.0 (pep-3134)
            e.__traceback__ = sys.exc_info()[2]
            reject(e)
            return False
          finally:
            self._error_handler.RemoveCallback(reject)

        self._error_handler.AddCallback(reject)
        if not self._router.AcceptWithResponder(
            message, messaging.ForwardingMessageReceiver(Accept)):
          self._error_handler.RemoveCallback(reject)
          reject(messaging.MessagingException("Unable to send message."))
      else:
        if (self._router.Accept(message)):
          resolve(None)
        else:
          reject(messaging.MessagingException("Unable to send message."))
    return promise.Promise(GenerationMethod)
  return _Call


def _GetMessageWithStruct(struct, ordinal, flags, request_id):
  header = messaging.MessageHeader(
      ordinal, flags, 0 if request_id is None else request_id)
  data = header.Serialize()
  (payload, handles) = struct.Serialize()
  data.extend(payload)
  return messaging.Message(data, handles, header)


def _GetMessage(method, flags, request_id, *args, **kwargs):
  if flags == messaging.MESSAGE_IS_RESPONSE_FLAG:
    struct = method.response_struct(*args, **kwargs)
  else:
    struct = method.parameters_struct(*args, **kwargs)
  return _GetMessageWithStruct(struct, method.ordinal, flags, request_id)


def _StubInit(self, impl):
  self.impl = impl


def _StubAccept(methods):
  methods_by_ordinal = dict((m.ordinal, m) for m in methods)
  def Accept(self, message, responder=None):
    try:
      header = message.header
      assert header.expects_response == bool(responder)
      if header.message_type == interface_control_messages_mojom.RUN_MESSAGE_ID:
        return _RunMessage(self.impl.manager, message, responder)
      if (header.message_type ==
          interface_control_messages_mojom.RUN_OR_CLOSE_PIPE_MESSAGE_ID):
        return _RunMessageOrClosePipe(self.impl.manager, message)
      assert header.message_type in methods_by_ordinal
      method = methods_by_ordinal[header.message_type]
      payload = message.payload
      parameters = method.parameters_struct.Deserialize(
          serialization.RootDeserializationContext(
              payload.data, payload.handles)).AsDict()
      response = getattr(self.impl, method.name)(**parameters)
      if header.expects_response:
        @promise.async
        def SendResponse(response):
          if isinstance(response, dict):
            response_message = _GetMessage(method,
                                           messaging.MESSAGE_IS_RESPONSE_FLAG,
                                           header.request_id,
                                           **response)
          else:
            response_message = _GetMessage(method,
                                           messaging.MESSAGE_IS_RESPONSE_FLAG,
                                           header.request_id,
                                           response)
          return responder.Accept(response_message)
        p = SendResponse(response)
        if self.impl.manager:
          # Close the connection in case of error.
          p.Catch(lambda _: self.impl.manager.Close())
      return True
    # pylint: disable=W0702
    except:
      # Close the connection in case of error.
      logging.warning(
          'Error occured in accept method. Connection will be closed.')
      logging.debug("Exception", exc_info=True)
      if self.impl.manager:
        self.impl.manager.Close()
      return False
  return Accept


def _RunMessage(manager, message, responder):
  response = interface_control_messages_mojom.RunResponseMessageParams()
  response.reserved0 = 16
  response.reserved1 = 0
  response.query_version_result = (
      interface_control_messages_mojom.QueryVersionResult())
  response.query_version_result.version = manager.interface_manager.version
  response_message = _GetMessageWithStruct(
      response,
      interface_control_messages_mojom.RUN_MESSAGE_ID,
      messaging.MESSAGE_IS_RESPONSE_FLAG,
      message.header.request_id)
  return responder.Accept(response_message)


def _RunMessageOrClosePipe(manager, message):
  payload = message.payload
  query = (
      interface_control_messages_mojom.RunOrClosePipeMessageParams.Deserialize(
          serialization.RootDeserializationContext(payload.data,
                                                   payload.handles)))
  return query.require_version.version <= manager.interface_manager.version


def _NotImplemented(*_1, **_2):
  raise NotImplementedError()
