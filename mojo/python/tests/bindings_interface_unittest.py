# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import gc
import weakref

# pylint: disable=F0401,E0611
import mojo_bindings.promise as promise
import mojo_system as system
import mojo_unittest
import regression_tests_mojom
import sample_factory_mojom
import sample_service_mojom


def _BuildProxy(impl):
  pipe = system.MessagePipe()
  impl.__class__.manager.Bind(impl, pipe.handle0)
  return impl.__class__.manager.Proxy(pipe.handle1)


def _ExtractValue(p):
  container = []
  @promise.async
  def GetValue(value):
    container.append(value)
  GetValue(p)
  assert len(container)
  return container[0]


class EmptyServiceImpl(sample_service_mojom.Service):

  def __init__(self):
    pass


class ServiceImpl(sample_service_mojom.Service):

  def __init__(self):
    pass

  # pylint: disable=C0102,W0613
  def Frobinate(self, foo, baz, port):
    return baz


class NamedObjectImpl(sample_factory_mojom.NamedObject):

  def __init__(self):
    self.name = 'name'

  def SetName(self, name):
    self.name = name

  def GetName(self):
    return self.name


class DelegatingNamedObject(sample_factory_mojom.NamedObject):

  def __init__(self):
    self.proxy = _BuildProxy(NamedObjectImpl())

  def SetName(self, name):
    self.proxy.SetName(name)

  def GetName(self):
    return self.proxy.GetName()

class InterfaceTest(mojo_unittest.MojoTestCase):

  def testBaseInterface(self):
    service = sample_service_mojom.Service()
    with self.assertRaises(AttributeError):
      service.NotExisting()
    with self.assertRaises(NotImplementedError):
      service.Frobinate()

  def testEmpty(self):
    service = EmptyServiceImpl()
    with self.assertRaises(NotImplementedError):
      service.Frobinate()

  def testServiceWithReturnValue(self):
    proxy = _BuildProxy(DelegatingNamedObject())
    p1 = proxy.GetName()

    self.assertEquals(p1.state, promise.Promise.STATE_PENDING)
    self.loop.RunUntilIdle()
    self.assertEquals(p1.state, promise.Promise.STATE_FULLFILLED)
    name = _ExtractValue(p1)
    self.assertEquals(name, 'name')

    proxy.SetName('hello')
    p2 = proxy.GetName()

    self.assertEquals(p2.state, promise.Promise.STATE_PENDING)
    self.loop.RunUntilIdle()
    self.assertEquals(p2.state, promise.Promise.STATE_FULLFILLED)
    name = _ExtractValue(p2)
    self.assertEquals(name, 'hello')

  def testCloseProxy(self):
    named_object_impl = NamedObjectImpl()
    proxy = _BuildProxy(named_object_impl)
    response = proxy.GetName()
    proxy.manager.Close()

    self.assertEquals(response.state, promise.Promise.STATE_REJECTED)

  def testCloseImplementationWithResponse(self):
    impl = DelegatingNamedObject()
    proxy = _BuildProxy(impl)
    p1 = proxy.GetName()

    self.assertEquals(p1.state, promise.Promise.STATE_PENDING)

    impl.manager.Close()
    self.loop.RunUntilIdle()

    self.assertEquals(p1.state, promise.Promise.STATE_REJECTED)
