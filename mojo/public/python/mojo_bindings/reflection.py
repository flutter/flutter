# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The metaclasses used by the mojo python bindings."""

import itertools

# pylint: disable=F0401
import mojo_bindings.serialization as serialization


class MojoEnumType(type):
  """Meta class for enumerations.

  Usage:
    class MyEnum(object):
      __metaclass__ = MojoEnumType
      VALUES = [
        ('A', 0),
        'B',
        ('C', 5),
      ]

      This will define a enum with 3 values, 'A' = 0, 'B' = 1 and 'C' = 5.
  """

  def __new__(mcs, name, bases, dictionary):
    dictionary['__slots__'] = ()
    dictionary['__new__'] = None
    for value in dictionary.pop('VALUES', []):
      if not isinstance(value, tuple):
        raise ValueError('incorrect value: %r' % value)
      key, enum_value = value
      if isinstance(key, str) and isinstance(enum_value, int):
        dictionary[key] = enum_value
      else:
        raise ValueError('incorrect value: %r' % value)
    return type.__new__(mcs, name, bases, dictionary)

  def __setattr__(cls, key, value):
    raise AttributeError('can\'t set attribute')

  def __delattr__(cls, key):
    raise AttributeError('can\'t delete attribute')


class MojoStructType(type):
  """Meta class for structs.

  Usage:
    class MyStruct(object):
      __metaclass__ = MojoStructType
      DESCRIPTOR = {
        'constants': {
          'C1': 1,
          'C2': 2,
        },
        'enums': {
          'ENUM1': [
            ('V1', 1),
            'V2',
          ],
          'ENUM2': [
            ('V1', 1),
            'V2',
          ],
        },
        'fields': [
           SingleFieldGroup('x', _descriptor.TYPE_INT32, 0, 0),
        ],
      }

      This will define an struct, with:
      - 2 constants 'C1' and 'C2';
      - 2 enums 'ENUM1' and 'ENUM2', each of those having 2 values, 'V1' and
        'V2';
      - 1 int32 field named 'x'.
  """

  def __new__(mcs, name, bases, dictionary):
    dictionary['__slots__'] = ('_fields')
    descriptor = dictionary.pop('DESCRIPTOR', {})

    # Add constants
    dictionary.update(descriptor.get('constants', {}))

    # Add enums
    enums = descriptor.get('enums', {})
    for key in enums:
      dictionary[key] = MojoEnumType(key, (object,), { 'VALUES': enums[key] })

    # Add fields
    groups = descriptor.get('fields', [])

    fields = list(
        itertools.chain.from_iterable([group.descriptors for group in groups]))
    fields.sort(key=lambda f: f.index)
    for field in fields:
      dictionary[field.name] = _BuildProperty(field)

    # Add init
    dictionary['__init__'] = _StructInit(fields)

    # Add serialization method
    serialization_object = serialization.Serialization(groups)
    def Serialize(self, handle_offset=0):
      return serialization_object.Serialize(self, handle_offset)
    dictionary['Serialize'] = Serialize

    # pylint: disable=W0212
    def AsDict(self):
      return self._fields
    dictionary['AsDict'] = AsDict

    def Deserialize(cls, context):
      result = cls.__new__(cls)
      fields = {}
      serialization_object.Deserialize(fields, context)
      result._fields = fields
      return result
    dictionary['Deserialize'] = classmethod(Deserialize)

    dictionary['__eq__'] = _StructEq(fields)
    dictionary['__ne__'] = _StructNe

    return type.__new__(mcs, name, bases, dictionary)

  # Prevent adding new attributes, or mutating constants.
  def __setattr__(cls, key, value):
    raise AttributeError('can\'t set attribute')

  # Prevent deleting constants.
  def __delattr__(cls, key):
    raise AttributeError('can\'t delete attribute')


class InterfaceRequest(object):
  """
  An interface request allows to send a request for an interface to a remote
  object and start using it immediately.
  """

  def __init__(self, handle):
    self._handle = handle

  def IsPending(self):
    return self._handle.IsValid()

  def PassMessagePipe(self):
    result = self._handle
    self._handle = None
    return result

  def Bind(self, impl):
    type(impl).manager.Bind(impl, self.PassMessagePipe())


class InterfaceProxy(object):
  """
  A proxy allows to access a remote interface through a message pipe.
  """
  pass


def _StructInit(fields):
  def _Init(self, *args, **kwargs):
    if len(args) + len(kwargs) > len(fields):
      raise TypeError('__init__() takes %d argument (%d given)' %
                      (len(fields), len(args) + len(kwargs)))
    self._fields = {}
    for f, a in zip(fields, args):
      self.__setattr__(f.name, a)
    remaining_fields = set(x.name for x in fields[len(args):])
    for name in kwargs:
      if not name in remaining_fields:
        if name in (x.name for x in fields[:len(args)]):
          raise TypeError(
              '__init__() got multiple values for keyword argument %r' % name)
        raise TypeError('__init__() got an unexpected keyword argument %r' %
                        name)
      self.__setattr__(name, kwargs[name])
  return _Init


def _BuildProperty(field):
  """Build the property for the given field."""

  # pylint: disable=W0212
  def Get(self):
    if field.name not in self._fields:
      self._fields[field.name] = field.GetDefaultValue()
    return self._fields[field.name]

  # pylint: disable=W0212
  def Set(self, value):
    self._fields[field.name] = field.field_type.Convert(value)

  return property(Get, Set)


def _StructEq(fields):
  def _Eq(self, other):
    if type(self) is not type(other):
      return False
    for field in fields:
      if getattr(self, field.name) != getattr(other, field.name):
        return False
    return True
  return _Eq

def _StructNe(self, other):
  return not self.__eq__(other)
