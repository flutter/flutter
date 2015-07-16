# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# pylint: disable=F0401,E0611
import mojo_bindings.promise as promise
import mojo_system as system
import mojo_unittest
import sample_interfaces_mojom


def _BuildProxy(impl):
  pipe = system.MessagePipe()
  impl.__class__.manager.Bind(impl, pipe.handle0)
  return impl.__class__.manager.Proxy(pipe.handle1)


def _ExtractValue(v_promise):
  container = []
  @promise.async
  def GetInternalValue(value):
    container.append(value)
  GetInternalValue(v_promise)
  assert len(container)
  return container[0]


class IntegerAccessorImpl(sample_interfaces_mojom.IntegerAccessor):
  """
  Interface definition is in
  mojo/public/interfaces/bindings/tests/sample_interfaces.mojom
  """
  def __init__(self):
    self.values = {
      'data': 0,
      'type': 0,
    }

  def GetInteger(self):
    return self.values;

  def SetInteger(self, **values):
    self.values = values

  def GetInternalValue(self):
    return self.values['data']


class ControlMessagesTest(mojo_unittest.MojoTestCase):

  def testQueryVersion(self):
    p = _BuildProxy(IntegerAccessorImpl())
    self.assertEquals(p.manager.version, 0)
    v_promise = p.manager.QueryVersion()
    self.loop.RunUntilIdle()
    self.assertEquals(v_promise.state, promise.Promise.STATE_FULLFILLED)
    self.assertEquals(_ExtractValue(v_promise), 3)
    self.assertEquals(p.manager.version, 3)

  def testRequireVersion(self):
    impl = IntegerAccessorImpl()
    errors = []
    p = _BuildProxy(impl)
    p.manager.AddOnErrorCallback(lambda: errors.append(0))

    self.assertEquals(p.manager.version, 0)

    p.manager.RequireVersion(1)
    self.assertEquals(p.manager.version, 1)
    p.SetInteger(123, sample_interfaces_mojom.Enum.VALUE)
    self.loop.RunUntilIdle()
    self.assertEquals(len(errors), 0)
    self.assertEquals(impl.GetInternalValue(), 123)

    p.manager.RequireVersion(3)
    self.assertEquals(p.manager.version, 3)
    p.SetInteger(456, sample_interfaces_mojom.Enum.VALUE)
    self.loop.RunUntilIdle()
    self.assertEquals(len(errors), 0)
    self.assertEquals(impl.GetInternalValue(), 456)

    # Require a version that is not supported by the implementation side.
    p.manager.RequireVersion(4)
    # version is updated synchronously.
    self.assertEquals(p.manager.version, 4)
    p.SetInteger(789, sample_interfaces_mojom.Enum.VALUE)
    self.loop.RunUntilIdle()
    self.assertEquals(len(errors), 1)
    # The call to SetInteger() after RequireVersion() is ignored.
    self.assertEquals(impl.GetInternalValue(), 456)
