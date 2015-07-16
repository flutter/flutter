# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
The descriptors used to define generated elements of the mojo python bindings.
"""

import array
import itertools
import struct

import mojo_bindings.reflection as reflection
import mojo_bindings.serialization as serialization

# pylint: disable=E0611,F0401
import mojo_system


class Type(object):
  """Describes the type of a struct field or a method parameter,"""

  def Convert(self, value): # pylint: disable=R0201
    """
    Convert the given value into its canonical representation, raising an
    exception if the value cannot be converted.
    """
    return value

  def GetDefaultValue(self, value):
    """
    Returns the default value for this type associated with the given value.
    This method must be able to correcly handle value being None.
    """
    return self.Convert(value)


class SerializableType(Type):
  """Describe a type that can be serialized by itself."""

  def __init__(self, typecode):
    Type.__init__(self)
    self.typecode = typecode
    self.byte_size = struct.calcsize('<%s' % self.GetTypeCode())

  def GetTypeCode(self):
    """
    Returns the type code (as defined by the struct module) used to encode
    this type.
    """
    return self.typecode

  def GetByteSize(self):
    """
    Returns the size of the encoding of this type.
    """
    return self.byte_size

  def GetAlignment(self):
    """
    Returns the alignment required by the encoding of this type. By default it
    is set to the byte size of the biggest packed value.
    """
    return max([struct.calcsize('<%s' % c) for c in self.GetTypeCode()])

  def Serialize(self, value, data_offset, data, handle_offset):
    """
    Serialize a value of this type.

    Args:
      value: the value to serialize.
      data_offset: the offset to the end of the data bytearray. Used to encode
                   pointers.
      data: the bytearray to append additional data to.
      handle_offset: the offset to use to encode handles.

    Returns a a tuple where the first element is the value to encode, and the
    second is the array of handles to add to the message.
    """
    raise NotImplementedError()

  def Deserialize(self, value, context):
    """
    Deserialize a value of this type.

    Args:
      value: the base value for this type. This is always a numeric type, and
             corresponds to the first element in the tuple returned by
             Serialize.
      data: the bytearray to retrieve additional data from.
      handles: the array of handles contained in the message to deserialize.

    Returns the deserialized value.
    """
    raise NotImplementedError()


class BooleanType(Type):
  """Type object for booleans"""

  def Convert(self, value):
    return bool(value)


class NumericType(SerializableType):
  """Base Type object for all numeric types"""

  def GetDefaultValue(self, value):
    if value is None:
      return self.Convert(0)
    return self.Convert(value)

  def Serialize(self, value, data_offset, data, handle_offset):
    return (value, [])

  def Deserialize(self, value, context):
    return value


class IntegerType(NumericType):
  """Type object for integer types."""

  def __init__(self, typecode):
    NumericType.__init__(self, typecode)
    size = 8 * self.byte_size
    signed = typecode.islower()
    if signed:
      self._min_value = -(1 << (size - 1))
      self._max_value = (1 << (size - 1)) - 1
    else:
      self._min_value = 0
      self._max_value = (1 << size) - 1

  def Convert(self, value):
    if value is None:
      raise TypeError('None is not an integer.')
    if not isinstance(value, (int, long)):
      raise TypeError('%r is not an integer type' % value)
    if value < self._min_value or value > self._max_value:
      raise OverflowError('%r is not in the range [%d, %d]' %
                          (value, self._min_value, self._max_value))
    return value


class FloatType(NumericType):
  """Type object for floating point number types."""

  def Convert(self, value):
    if value is None:
      raise TypeError('None is not an floating point number.')
    if not isinstance(value, (int, long, float)):
      raise TypeError('%r is not a numeric type' % value)
    return float(value)


class PointerType(SerializableType):
  """Base Type object for pointers."""

  def __init__(self, nullable=False):
    SerializableType.__init__(self, 'Q')
    self.nullable = nullable

  def Serialize(self, value, data_offset, data, handle_offset):
    if value is None and not self.nullable:
      raise serialization.SerializationException(
          'Trying to serialize null for non nullable type.')
    if value is None:
      return (0, [])
    return self.SerializePointer(value, data_offset, data, handle_offset)

  def Deserialize(self, value, context):
    if value == 0:
      if not self.nullable:
        raise serialization.DeserializationException(
            'Trying to deserialize null for non nullable type.')
      return None
    if value % 8 != 0:
      raise serialization.DeserializationException(
          'Pointer alignment is incorrect.')
    sub_context = context.GetSubContext(value)
    if len(sub_context.data) < serialization.HEADER_STRUCT.size:
      raise serialization.DeserializationException(
          'Available data too short to contain header.')
    (size, nb_elements) = serialization.HEADER_STRUCT.unpack_from(
        sub_context.data)
    if len(sub_context.data) < size or size < serialization.HEADER_STRUCT.size:
      raise serialization.DeserializationException('Header size is incorrect.')
    sub_context.ClaimMemory(0, size)
    return self.DeserializePointer(size, nb_elements, sub_context)

  def SerializePointer(self, value, data_offset, data, handle_offset):
    """Serialize the not null value."""
    raise NotImplementedError()

  def DeserializePointer(self, size, nb_elements, context):
    raise NotImplementedError()


class StringType(PointerType):
  """
  Type object for strings.

  Strings are represented as unicode, and the conversion is done using the
  default encoding if a string instance is used.
  """

  def __init__(self, nullable=False):
    PointerType.__init__(self, nullable)
    self._array_type = NativeArrayType('B', nullable)

  def Convert(self, value):
    if value is None or isinstance(value, unicode):
      return value
    if isinstance(value, str):
      return unicode(value)
    raise TypeError('%r is not a string' % value)

  def SerializePointer(self, value, data_offset, data, handle_offset):
    string_array = array.array('b')
    string_array.fromstring(value.encode('utf8'))
    return self._array_type.SerializeArray(
        string_array, data_offset, data, handle_offset)

  def DeserializePointer(self, size, nb_elements, context):
    string_array = self._array_type.DeserializeArray(size, nb_elements, context)
    return unicode(string_array.tostring(), 'utf8')


class BaseHandleType(SerializableType):
  """Type object for handles."""

  def __init__(self, nullable=False, type_code='i'):
    SerializableType.__init__(self, type_code)
    self.nullable = nullable

  def Serialize(self, value, data_offset, data, handle_offset):
    handle = self.ToHandle(value)
    if not handle.IsValid() and not self.nullable:
      raise serialization.SerializationException(
          'Trying to serialize null for non nullable type.')
    if not handle.IsValid():
      return (-1, [])
    return (handle_offset, [handle])

  def Deserialize(self, value, context):
    if value == -1:
      if not self.nullable:
        raise serialization.DeserializationException(
            'Trying to deserialize null for non nullable type.')
      return self.FromHandle(mojo_system.Handle())
    return self.FromHandle(context.ClaimHandle(value))

  def FromHandle(self, handle):
    raise NotImplementedError()

  def ToHandle(self, value):
    raise NotImplementedError()


class HandleType(BaseHandleType):
  """Type object for handles."""

  def Convert(self, value):
    if value is None:
      return mojo_system.Handle()
    if not isinstance(value, mojo_system.Handle):
      raise TypeError('%r is not a handle' % value)
    return value

  def FromHandle(self, handle):
    return handle

  def ToHandle(self, value):
    return value


class InterfaceRequestType(BaseHandleType):
  """Type object for interface requests."""

  def Convert(self, value):
    if value is None:
      return reflection.InterfaceRequest(mojo_system.Handle())
    if not isinstance(value, reflection.InterfaceRequest):
      raise TypeError('%r is not an interface request' % value)
    return value

  def FromHandle(self, handle):
    return reflection.InterfaceRequest(handle)

  def ToHandle(self, value):
    return value.PassMessagePipe()


class InterfaceType(BaseHandleType):
  """Type object for interfaces."""

  def __init__(self, interface_getter, nullable=False):
    # handle (4 bytes) + version (4 bytes)
    BaseHandleType.__init__(self, nullable, 'iI')
    self._interface_getter = interface_getter
    self._interface = None

  def Convert(self, value):
    if value is None or isinstance(value, self.interface):
      return value
    raise TypeError('%r is not an instance of ' % self.interface)

  @property
  def interface(self):
    if not self._interface:
      self._interface = self._interface_getter()
    return self._interface

  def Serialize(self, value, data_offset, data, handle_offset):
    (encoded_handle, handles) = super(InterfaceType, self).Serialize(
        value, data_offset, data, handle_offset)
    if encoded_handle == -1:
      version = 0
    else:
      version = self.interface.manager.version
      if value and isinstance(value, reflection.InterfaceProxy):
        version = value.manager.version
    return ((encoded_handle, version), handles)

  def Deserialize(self, value, context):
    proxy = super(InterfaceType, self).Deserialize(value[0], context)
    if proxy:
      proxy.manager.version = value[1]
    return proxy

  def FromHandle(self, handle):
    if handle.IsValid():
      return self.interface.manager.Proxy(handle)
    return None

  def ToHandle(self, value):
    if not value:
      return mojo_system.Handle()
    if isinstance(value, reflection.InterfaceProxy):
      return value.manager.PassMessagePipe()
    pipe = mojo_system.MessagePipe()
    self.interface.manager.Bind(value, pipe.handle0)
    return pipe.handle1


class BaseArrayType(PointerType):
  """Abstract Type object for arrays."""

  def __init__(self, nullable=False, length=0):
    PointerType.__init__(self, nullable)
    self.length = length

  def SerializePointer(self, value, data_offset, data, handle_offset):
    if self.length != 0 and len(value) != self.length:
      raise serialization.SerializationException('Incorrect array size')
    return self.SerializeArray(value, data_offset, data, handle_offset)

  def SerializeArray(self, value, data_offset, data, handle_offset):
    """Serialize the not null array."""
    raise NotImplementedError()

  def DeserializePointer(self, size, nb_elements, context):
    if self.length != 0 and nb_elements != self.length:
      raise serialization.DeserializationException('Incorrect array size')
    if (size <
        serialization.HEADER_STRUCT.size + self.SizeForLength(nb_elements)):
      raise serialization.DeserializationException('Incorrect array size')
    return self.DeserializeArray(size, nb_elements, context)

  def DeserializeArray(self, size, nb_elements, context):
    raise NotImplementedError()

  def SizeForLength(self, nb_elements):
    raise NotImplementedError()


class BooleanArrayType(BaseArrayType):

  def __init__(self, nullable=False, length=0):
    BaseArrayType.__init__(self, nullable, length)
    self._array_type = NativeArrayType('B', nullable)

  def Convert(self, value):
    if value is None:
      return value
    return [TYPE_BOOL.Convert(x) for x in value]

  def SerializeArray(self, value, data_offset, data, handle_offset):
    groups = [value[i:i+8] for i in range(0, len(value), 8)]
    converted = array.array('B', [_ConvertBooleansToByte(x) for x in groups])
    return _SerializeNativeArray(converted, data_offset, data, len(value))

  def DeserializeArray(self, size, nb_elements, context):
    converted = self._array_type.DeserializeArray(size, nb_elements, context)
    elements = list(itertools.islice(
        itertools.chain.from_iterable(
            [_ConvertByteToBooleans(x, 8) for x in converted]),
        0,
        nb_elements))
    return elements

  def SizeForLength(self, nb_elements):
    return (nb_elements + 7) // 8


class GenericArrayType(BaseArrayType):
  """Type object for arrays of pointers."""

  def __init__(self, sub_type, nullable=False, length=0):
    BaseArrayType.__init__(self, nullable, length)
    assert isinstance(sub_type, SerializableType)
    self.sub_type = sub_type

  def Convert(self, value):
    if value is None:
      return value
    return [self.sub_type.Convert(x) for x in value]

  def SerializeArray(self, value, data_offset, data, handle_offset):
    size = (serialization.HEADER_STRUCT.size +
            self.sub_type.GetByteSize() * len(value))
    data_end = len(data)
    position = len(data) + serialization.HEADER_STRUCT.size
    data.extend(bytearray(size +
                          serialization.NeededPaddingForAlignment(size)))
    returned_handles = []
    to_pack = []
    for item in value:
      (new_data, new_handles) = self.sub_type.Serialize(
          item,
          len(data) - position,
          data,
          handle_offset + len(returned_handles))
      to_pack.extend(serialization.Flatten(new_data))
      returned_handles.extend(new_handles)
      position = position + self.sub_type.GetByteSize()
    serialization.HEADER_STRUCT.pack_into(data, data_end, size, len(value))
    struct.pack_into('%d%s' % (len(value), self.sub_type.GetTypeCode()),
                     data,
                     data_end + serialization.HEADER_STRUCT.size,
                     *to_pack)
    return (data_offset, returned_handles)

  def DeserializeArray(self, size, nb_elements, context):
    values = struct.unpack_from(
        '%d%s' % (nb_elements, self.sub_type.GetTypeCode()),
        buffer(context.data, serialization.HEADER_STRUCT.size))
    values_per_element = len(self.sub_type.GetTypeCode())
    assert nb_elements * values_per_element == len(values)

    result = []
    sub_context = context.GetSubContext(serialization.HEADER_STRUCT.size)
    for index in xrange(nb_elements):
      if values_per_element == 1:
        value = values[index]
      else:
        value = tuple(values[index * values_per_element :
                             (index + 1) * values_per_element])
      result.append(self.sub_type.Deserialize(
          value,
          sub_context))
      sub_context = sub_context.GetSubContext(self.sub_type.GetByteSize())
    return result

  def SizeForLength(self, nb_elements):
    return nb_elements * self.sub_type.GetByteSize();


class NativeArrayType(BaseArrayType):
  """Type object for arrays of native types."""

  def __init__(self, typecode, nullable=False, length=0):
    BaseArrayType.__init__(self, nullable, length)
    self.array_typecode = typecode
    self.element_size = struct.calcsize('<%s' % self.array_typecode)

  def Convert(self, value):
    if value is None:
      return value
    if (isinstance(value, array.array) and
        value.array_typecode == self.array_typecode):
      return value
    return array.array(self.array_typecode, value)

  def SerializeArray(self, value, data_offset, data, handle_offset):
    return _SerializeNativeArray(value, data_offset, data, len(value))

  def DeserializeArray(self, size, nb_elements, context):
    result = array.array(self.array_typecode)
    result.fromstring(buffer(context.data,
                             serialization.HEADER_STRUCT.size,
                             size - serialization.HEADER_STRUCT.size))
    return result

  def SizeForLength(self, nb_elements):
    return nb_elements * self.element_size


class StructType(PointerType):
  """Type object for structs."""

  def __init__(self, struct_type_getter, nullable=False):
    PointerType.__init__(self)
    self._struct_type_getter = struct_type_getter
    self._struct_type = None
    self.nullable = nullable

  @property
  def struct_type(self):
    if not self._struct_type:
      self._struct_type = self._struct_type_getter()
    return self._struct_type

  def Convert(self, value):
    if value is None or isinstance(value, self.struct_type):
      return value
    raise TypeError('%r is not an instance of %r' % (value, self.struct_type))

  def GetDefaultValue(self, value):
    if value:
      return self.struct_type()
    return None

  def SerializePointer(self, value, data_offset, data, handle_offset):
    (new_data, new_handles) = value.Serialize(handle_offset)
    data.extend(new_data)
    return (data_offset, new_handles)

  def DeserializePointer(self, size, nb_elements, context):
    return self.struct_type.Deserialize(context)


class MapType(SerializableType):
  """Type objects for maps."""

  def __init__(self, key_type, value_type, nullable=False):
    self._key_type = key_type
    self._value_type = value_type
    dictionary = {
      '__metaclass__': reflection.MojoStructType,
      '__module__': __name__,
      'DESCRIPTOR': {
        'fields': [
          SingleFieldGroup('keys', MapType._GetArrayType(key_type), 0, 0),
          SingleFieldGroup('values', MapType._GetArrayType(value_type), 1, 0),
        ],
      }
    }
    self.struct = reflection.MojoStructType('MapStruct', (object,), dictionary)
    self.struct_type = StructType(lambda: self.struct, nullable)
    SerializableType.__init__(self, self.struct_type.typecode)

  def Convert(self, value):
    if value is None:
      return value
    if isinstance(value, dict):
      return dict([(self._key_type.Convert(x), self._value_type.Convert(y)) for
                   x, y in value.iteritems()])
    raise TypeError('%r is not a dictionary.')

  def Serialize(self, value, data_offset, data, handle_offset):
    s = None
    if value:
      keys, values = [], []
      for key, value in value.iteritems():
        keys.append(key)
        values.append(value)
      s = self.struct(keys=keys, values=values)
    return self.struct_type.Serialize(s, data_offset, data, handle_offset)

  def Deserialize(self, value, context):
    s = self.struct_type.Deserialize(value, context)
    if s:
      if len(s.keys) != len(s.values):
        raise serialization.DeserializationException(
            'keys and values do not have the same length.')
      return dict(zip(s.keys, s.values))
    return None

  @staticmethod
  def _GetArrayType(t):
    if t == TYPE_BOOL:
      return BooleanArrayType()
    else:
      return GenericArrayType(t)


TYPE_BOOL = BooleanType()

TYPE_INT8 = IntegerType('b')
TYPE_INT16 = IntegerType('h')
TYPE_INT32 = IntegerType('i')
TYPE_INT64 = IntegerType('q')

TYPE_UINT8 = IntegerType('B')
TYPE_UINT16 = IntegerType('H')
TYPE_UINT32 = IntegerType('I')
TYPE_UINT64 = IntegerType('Q')

TYPE_FLOAT = FloatType('f')
TYPE_DOUBLE = FloatType('d')

TYPE_STRING = StringType()
TYPE_NULLABLE_STRING = StringType(True)

TYPE_HANDLE = HandleType()
TYPE_NULLABLE_HANDLE = HandleType(True)

TYPE_INTERFACE_REQUEST = InterfaceRequestType()
TYPE_NULLABLE_INTERFACE_REQUEST = InterfaceRequestType(True)


class FieldDescriptor(object):
  """Describes a field in a generated struct."""

  def __init__(self, name, field_type, index, version, default_value=None):
    self.name = name
    self.field_type = field_type
    self.version = version
    self.index = index
    self._default_value = default_value

  def GetDefaultValue(self):
    return self.field_type.GetDefaultValue(self._default_value)


class FieldGroup(object):
  """
  Describe a list of field in the generated struct that must be
  serialized/deserialized together.
  """
  def __init__(self, descriptors):
    self.descriptors = descriptors

  def GetDescriptors(self):
    return self.descriptors

  def GetTypeCode(self):
    raise NotImplementedError()

  def GetByteSize(self):
    raise NotImplementedError()

  def GetAlignment(self):
    raise NotImplementedError()

  def GetMinVersion(self):
    raise NotImplementedError()

  def GetMaxVersion(self):
    raise NotImplementedError()

  def Serialize(self, obj, data_offset, data, handle_offset):
    raise NotImplementedError()

  def Deserialize(self, value, context):
    raise NotImplementedError()

  def Filter(self, version):
    raise NotImplementedError()


class SingleFieldGroup(FieldGroup, FieldDescriptor):
  """A FieldGroup that contains a single FieldDescriptor."""

  def __init__(self, name, field_type, index, version, default_value=None):
    FieldDescriptor.__init__(
        self, name, field_type, index, version, default_value)
    FieldGroup.__init__(self, [self])

  def GetTypeCode(self):
    return self.field_type.GetTypeCode()

  def GetByteSize(self):
    return self.field_type.GetByteSize()

  def GetAlignment(self):
    return self.field_type.GetAlignment()

  def GetMinVersion(self):
    return self.version

  def GetMaxVersion(self):
    return self.version

  def Serialize(self, obj, data_offset, data, handle_offset):
    value = getattr(obj, self.name)
    return self.field_type.Serialize(value, data_offset, data, handle_offset)

  def Deserialize(self, value, context):
    entity = self.field_type.Deserialize(value, context)
    return { self.name: entity }

  def Filter(self, version):
    return self


class BooleanGroup(FieldGroup):
  """A FieldGroup to pack booleans."""
  def __init__(self, descriptors):
    FieldGroup.__init__(self, descriptors)
    self.min_version = min([descriptor.version  for descriptor in descriptors])
    self.max_version = max([descriptor.version  for descriptor in descriptors])

  def GetTypeCode(self):
    return 'B'

  def GetByteSize(self):
    return 1

  def GetAlignment(self):
    return 1

  def GetMinVersion(self):
    return self.min_version

  def GetMaxVersion(self):
    return self.max_version

  def Serialize(self, obj, data_offset, data, handle_offset):
    value = _ConvertBooleansToByte(
        [getattr(obj, field.name) for field in self.GetDescriptors()])
    return (value, [])

  def Deserialize(self, value, context):
    values =  itertools.izip_longest([x.name for x in self.descriptors],
                                      _ConvertByteToBooleans(value),
                                     fillvalue=False)
    return dict(values)

  def Filter(self, version):
    return BooleanGroup(
        filter(lambda d: d.version <= version, self.descriptors))


def _SerializeNativeArray(value, data_offset, data, length):
  data_size = len(data)
  data.extend(bytearray(serialization.HEADER_STRUCT.size))
  data.extend(buffer(value))
  data_length = len(data) - data_size
  data.extend(bytearray(serialization.NeededPaddingForAlignment(data_length)))
  serialization.HEADER_STRUCT.pack_into(data, data_size, data_length, length)
  return (data_offset, [])


def _ConvertBooleansToByte(booleans):
  """Pack a list of booleans into an integer."""
  return reduce(lambda x, y: x * 2 + y, reversed(booleans), 0)


def _ConvertByteToBooleans(value, min_size=0):
  """Unpack an integer into a list of booleans."""
  res = []
  while value:
    res.append(bool(value&1))
    value = value / 2
  res.extend([False] * (min_size - len(res)))
  return res
