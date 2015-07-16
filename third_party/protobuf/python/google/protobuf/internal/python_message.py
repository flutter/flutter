# Protocol Buffers - Google's data interchange format
# Copyright 2008 Google Inc.  All rights reserved.
# http://code.google.com/p/protobuf/
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

# This code is meant to work on Python 2.4 and above only.
#
# TODO(robinson): Helpers for verbose, common checks like seeing if a
# descriptor's cpp_type is CPPTYPE_MESSAGE.

"""Contains a metaclass and helper functions used to create
protocol message classes from Descriptor objects at runtime.

Recall that a metaclass is the "type" of a class.
(A class is to a metaclass what an instance is to a class.)

In this case, we use the GeneratedProtocolMessageType metaclass
to inject all the useful functionality into the classes
output by the protocol compiler at compile-time.

The upshot of all this is that the real implementation
details for ALL pure-Python protocol buffers are *here in
this file*.
"""

__author__ = 'robinson@google.com (Will Robinson)'

try:
  from cStringIO import StringIO
except ImportError:
  from StringIO import StringIO
import copy_reg
import struct
import weakref

# We use "as" to avoid name collisions with variables.
from google.protobuf.internal import containers
from google.protobuf.internal import decoder
from google.protobuf.internal import encoder
from google.protobuf.internal import enum_type_wrapper
from google.protobuf.internal import message_listener as message_listener_mod
from google.protobuf.internal import type_checkers
from google.protobuf.internal import wire_format
from google.protobuf import descriptor as descriptor_mod
from google.protobuf import message as message_mod
from google.protobuf import text_format

_FieldDescriptor = descriptor_mod.FieldDescriptor


def NewMessage(bases, descriptor, dictionary):
  _AddClassAttributesForNestedExtensions(descriptor, dictionary)
  _AddSlots(descriptor, dictionary)
  return bases


def InitMessage(descriptor, cls):
  cls._decoders_by_tag = {}
  cls._extensions_by_name = {}
  cls._extensions_by_number = {}
  if (descriptor.has_options and
      descriptor.GetOptions().message_set_wire_format):
    cls._decoders_by_tag[decoder.MESSAGE_SET_ITEM_TAG] = (
        decoder.MessageSetItemDecoder(cls._extensions_by_number))

  # Attach stuff to each FieldDescriptor for quick lookup later on.
  for field in descriptor.fields:
    _AttachFieldHelpers(cls, field)

  _AddEnumValues(descriptor, cls)
  _AddInitMethod(descriptor, cls)
  _AddPropertiesForFields(descriptor, cls)
  _AddPropertiesForExtensions(descriptor, cls)
  _AddStaticMethods(cls)
  _AddMessageMethods(descriptor, cls)
  _AddPrivateHelperMethods(cls)
  copy_reg.pickle(cls, lambda obj: (cls, (), obj.__getstate__()))


# Stateless helpers for GeneratedProtocolMessageType below.
# Outside clients should not access these directly.
#
# I opted not to make any of these methods on the metaclass, to make it more
# clear that I'm not really using any state there and to keep clients from
# thinking that they have direct access to these construction helpers.


def _PropertyName(proto_field_name):
  """Returns the name of the public property attribute which
  clients can use to get and (in some cases) set the value
  of a protocol message field.

  Args:
    proto_field_name: The protocol message field name, exactly
      as it appears (or would appear) in a .proto file.
  """
  # TODO(robinson): Escape Python keywords (e.g., yield), and test this support.
  # nnorwitz makes my day by writing:
  # """
  # FYI.  See the keyword module in the stdlib. This could be as simple as:
  #
  # if keyword.iskeyword(proto_field_name):
  #   return proto_field_name + "_"
  # return proto_field_name
  # """
  # Kenton says:  The above is a BAD IDEA.  People rely on being able to use
  #   getattr() and setattr() to reflectively manipulate field values.  If we
  #   rename the properties, then every such user has to also make sure to apply
  #   the same transformation.  Note that currently if you name a field "yield",
  #   you can still access it just fine using getattr/setattr -- it's not even
  #   that cumbersome to do so.
  # TODO(kenton):  Remove this method entirely if/when everyone agrees with my
  #   position.
  return proto_field_name


def _VerifyExtensionHandle(message, extension_handle):
  """Verify that the given extension handle is valid."""

  if not isinstance(extension_handle, _FieldDescriptor):
    raise KeyError('HasExtension() expects an extension handle, got: %s' %
                   extension_handle)

  if not extension_handle.is_extension:
    raise KeyError('"%s" is not an extension.' % extension_handle.full_name)

  if not extension_handle.containing_type:
    raise KeyError('"%s" is missing a containing_type.'
                   % extension_handle.full_name)

  if extension_handle.containing_type is not message.DESCRIPTOR:
    raise KeyError('Extension "%s" extends message type "%s", but this '
                   'message is of type "%s".' %
                   (extension_handle.full_name,
                    extension_handle.containing_type.full_name,
                    message.DESCRIPTOR.full_name))


def _AddSlots(message_descriptor, dictionary):
  """Adds a __slots__ entry to dictionary, containing the names of all valid
  attributes for this message type.

  Args:
    message_descriptor: A Descriptor instance describing this message type.
    dictionary: Class dictionary to which we'll add a '__slots__' entry.
  """
  dictionary['__slots__'] = ['_cached_byte_size',
                             '_cached_byte_size_dirty',
                             '_fields',
                             '_unknown_fields',
                             '_is_present_in_parent',
                             '_listener',
                             '_listener_for_children',
                             '__weakref__']


def _IsMessageSetExtension(field):
  return (field.is_extension and
          field.containing_type.has_options and
          field.containing_type.GetOptions().message_set_wire_format and
          field.type == _FieldDescriptor.TYPE_MESSAGE and
          field.message_type == field.extension_scope and
          field.label == _FieldDescriptor.LABEL_OPTIONAL)


def _AttachFieldHelpers(cls, field_descriptor):
  is_repeated = (field_descriptor.label == _FieldDescriptor.LABEL_REPEATED)
  is_packed = (field_descriptor.has_options and
               field_descriptor.GetOptions().packed)

  if _IsMessageSetExtension(field_descriptor):
    field_encoder = encoder.MessageSetItemEncoder(field_descriptor.number)
    sizer = encoder.MessageSetItemSizer(field_descriptor.number)
  else:
    field_encoder = type_checkers.TYPE_TO_ENCODER[field_descriptor.type](
        field_descriptor.number, is_repeated, is_packed)
    sizer = type_checkers.TYPE_TO_SIZER[field_descriptor.type](
        field_descriptor.number, is_repeated, is_packed)

  field_descriptor._encoder = field_encoder
  field_descriptor._sizer = sizer
  field_descriptor._default_constructor = _DefaultValueConstructorForField(
      field_descriptor)

  def AddDecoder(wiretype, is_packed):
    tag_bytes = encoder.TagBytes(field_descriptor.number, wiretype)
    cls._decoders_by_tag[tag_bytes] = (
        type_checkers.TYPE_TO_DECODER[field_descriptor.type](
            field_descriptor.number, is_repeated, is_packed,
            field_descriptor, field_descriptor._default_constructor))

  AddDecoder(type_checkers.FIELD_TYPE_TO_WIRE_TYPE[field_descriptor.type],
             False)

  if is_repeated and wire_format.IsTypePackable(field_descriptor.type):
    # To support wire compatibility of adding packed = true, add a decoder for
    # packed values regardless of the field's options.
    AddDecoder(wire_format.WIRETYPE_LENGTH_DELIMITED, True)


def _AddClassAttributesForNestedExtensions(descriptor, dictionary):
  extension_dict = descriptor.extensions_by_name
  for extension_name, extension_field in extension_dict.iteritems():
    assert extension_name not in dictionary
    dictionary[extension_name] = extension_field


def _AddEnumValues(descriptor, cls):
  """Sets class-level attributes for all enum fields defined in this message.

  Also exporting a class-level object that can name enum values.

  Args:
    descriptor: Descriptor object for this message type.
    cls: Class we're constructing for this message type.
  """
  for enum_type in descriptor.enum_types:
    setattr(cls, enum_type.name, enum_type_wrapper.EnumTypeWrapper(enum_type))
    for enum_value in enum_type.values:
      setattr(cls, enum_value.name, enum_value.number)


def _DefaultValueConstructorForField(field):
  """Returns a function which returns a default value for a field.

  Args:
    field: FieldDescriptor object for this field.

  The returned function has one argument:
    message: Message instance containing this field, or a weakref proxy
      of same.

  That function in turn returns a default value for this field.  The default
    value may refer back to |message| via a weak reference.
  """

  if field.label == _FieldDescriptor.LABEL_REPEATED:
    if field.has_default_value and field.default_value != []:
      raise ValueError('Repeated field default value not empty list: %s' % (
          field.default_value))
    if field.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
      # We can't look at _concrete_class yet since it might not have
      # been set.  (Depends on order in which we initialize the classes).
      message_type = field.message_type
      def MakeRepeatedMessageDefault(message):
        return containers.RepeatedCompositeFieldContainer(
            message._listener_for_children, field.message_type)
      return MakeRepeatedMessageDefault
    else:
      type_checker = type_checkers.GetTypeChecker(field.cpp_type, field.type)
      def MakeRepeatedScalarDefault(message):
        return containers.RepeatedScalarFieldContainer(
            message._listener_for_children, type_checker)
      return MakeRepeatedScalarDefault

  if field.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
    # _concrete_class may not yet be initialized.
    message_type = field.message_type
    def MakeSubMessageDefault(message):
      result = message_type._concrete_class()
      result._SetListener(message._listener_for_children)
      return result
    return MakeSubMessageDefault

  def MakeScalarDefault(message):
    # TODO(protobuf-team): This may be broken since there may not be
    # default_value.  Combine with has_default_value somehow.
    return field.default_value
  return MakeScalarDefault


def _AddInitMethod(message_descriptor, cls):
  """Adds an __init__ method to cls."""
  fields = message_descriptor.fields
  def init(self, **kwargs):
    self._cached_byte_size = 0
    self._cached_byte_size_dirty = len(kwargs) > 0
    self._fields = {}
    # _unknown_fields is () when empty for efficiency, and will be turned into
    # a list if fields are added.
    self._unknown_fields = ()
    self._is_present_in_parent = False
    self._listener = message_listener_mod.NullMessageListener()
    self._listener_for_children = _Listener(self)
    for field_name, field_value in kwargs.iteritems():
      field = _GetFieldByName(message_descriptor, field_name)
      if field is None:
        raise TypeError("%s() got an unexpected keyword argument '%s'" %
                        (message_descriptor.name, field_name))
      if field.label == _FieldDescriptor.LABEL_REPEATED:
        copy = field._default_constructor(self)
        if field.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:  # Composite
          for val in field_value:
            copy.add().MergeFrom(val)
        else:  # Scalar
          copy.extend(field_value)
        self._fields[field] = copy
      elif field.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
        copy = field._default_constructor(self)
        copy.MergeFrom(field_value)
        self._fields[field] = copy
      else:
        setattr(self, field_name, field_value)

  init.__module__ = None
  init.__doc__ = None
  cls.__init__ = init


def _GetFieldByName(message_descriptor, field_name):
  """Returns a field descriptor by field name.

  Args:
    message_descriptor: A Descriptor describing all fields in message.
    field_name: The name of the field to retrieve.
  Returns:
    The field descriptor associated with the field name.
  """
  try:
    return message_descriptor.fields_by_name[field_name]
  except KeyError:
    raise ValueError('Protocol message has no "%s" field.' % field_name)


def _AddPropertiesForFields(descriptor, cls):
  """Adds properties for all fields in this protocol message type."""
  for field in descriptor.fields:
    _AddPropertiesForField(field, cls)

  if descriptor.is_extendable:
    # _ExtensionDict is just an adaptor with no state so we allocate a new one
    # every time it is accessed.
    cls.Extensions = property(lambda self: _ExtensionDict(self))


def _AddPropertiesForField(field, cls):
  """Adds a public property for a protocol message field.
  Clients can use this property to get and (in the case
  of non-repeated scalar fields) directly set the value
  of a protocol message field.

  Args:
    field: A FieldDescriptor for this field.
    cls: The class we're constructing.
  """
  # Catch it if we add other types that we should
  # handle specially here.
  assert _FieldDescriptor.MAX_CPPTYPE == 10

  constant_name = field.name.upper() + "_FIELD_NUMBER"
  setattr(cls, constant_name, field.number)

  if field.label == _FieldDescriptor.LABEL_REPEATED:
    _AddPropertiesForRepeatedField(field, cls)
  elif field.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
    _AddPropertiesForNonRepeatedCompositeField(field, cls)
  else:
    _AddPropertiesForNonRepeatedScalarField(field, cls)


def _AddPropertiesForRepeatedField(field, cls):
  """Adds a public property for a "repeated" protocol message field.  Clients
  can use this property to get the value of the field, which will be either a
  _RepeatedScalarFieldContainer or _RepeatedCompositeFieldContainer (see
  below).

  Note that when clients add values to these containers, we perform
  type-checking in the case of repeated scalar fields, and we also set any
  necessary "has" bits as a side-effect.

  Args:
    field: A FieldDescriptor for this field.
    cls: The class we're constructing.
  """
  proto_field_name = field.name
  property_name = _PropertyName(proto_field_name)

  def getter(self):
    field_value = self._fields.get(field)
    if field_value is None:
      # Construct a new object to represent this field.
      field_value = field._default_constructor(self)

      # Atomically check if another thread has preempted us and, if not, swap
      # in the new object we just created.  If someone has preempted us, we
      # take that object and discard ours.
      # WARNING:  We are relying on setdefault() being atomic.  This is true
      #   in CPython but we haven't investigated others.  This warning appears
      #   in several other locations in this file.
      field_value = self._fields.setdefault(field, field_value)
    return field_value
  getter.__module__ = None
  getter.__doc__ = 'Getter for %s.' % proto_field_name

  # We define a setter just so we can throw an exception with a more
  # helpful error message.
  def setter(self, new_value):
    raise AttributeError('Assignment not allowed to repeated field '
                         '"%s" in protocol message object.' % proto_field_name)

  doc = 'Magic attribute generated for "%s" proto field.' % proto_field_name
  setattr(cls, property_name, property(getter, setter, doc=doc))


def _AddPropertiesForNonRepeatedScalarField(field, cls):
  """Adds a public property for a nonrepeated, scalar protocol message field.
  Clients can use this property to get and directly set the value of the field.
  Note that when the client sets the value of a field by using this property,
  all necessary "has" bits are set as a side-effect, and we also perform
  type-checking.

  Args:
    field: A FieldDescriptor for this field.
    cls: The class we're constructing.
  """
  proto_field_name = field.name
  property_name = _PropertyName(proto_field_name)
  type_checker = type_checkers.GetTypeChecker(field.cpp_type, field.type)
  default_value = field.default_value
  valid_values = set()

  def getter(self):
    # TODO(protobuf-team): This may be broken since there may not be
    # default_value.  Combine with has_default_value somehow.
    return self._fields.get(field, default_value)
  getter.__module__ = None
  getter.__doc__ = 'Getter for %s.' % proto_field_name
  def setter(self, new_value):
    type_checker.CheckValue(new_value)
    self._fields[field] = new_value
    # Check _cached_byte_size_dirty inline to improve performance, since scalar
    # setters are called frequently.
    if not self._cached_byte_size_dirty:
      self._Modified()

  setter.__module__ = None
  setter.__doc__ = 'Setter for %s.' % proto_field_name

  # Add a property to encapsulate the getter/setter.
  doc = 'Magic attribute generated for "%s" proto field.' % proto_field_name
  setattr(cls, property_name, property(getter, setter, doc=doc))


def _AddPropertiesForNonRepeatedCompositeField(field, cls):
  """Adds a public property for a nonrepeated, composite protocol message field.
  A composite field is a "group" or "message" field.

  Clients can use this property to get the value of the field, but cannot
  assign to the property directly.

  Args:
    field: A FieldDescriptor for this field.
    cls: The class we're constructing.
  """
  # TODO(robinson): Remove duplication with similar method
  # for non-repeated scalars.
  proto_field_name = field.name
  property_name = _PropertyName(proto_field_name)

  # TODO(komarek): Can anyone explain to me why we cache the message_type this
  # way, instead of referring to field.message_type inside of getter(self)?
  # What if someone sets message_type later on (which makes for simpler
  # dyanmic proto descriptor and class creation code).
  message_type = field.message_type

  def getter(self):
    field_value = self._fields.get(field)
    if field_value is None:
      # Construct a new object to represent this field.
      field_value = message_type._concrete_class()  # use field.message_type?
      field_value._SetListener(self._listener_for_children)

      # Atomically check if another thread has preempted us and, if not, swap
      # in the new object we just created.  If someone has preempted us, we
      # take that object and discard ours.
      # WARNING:  We are relying on setdefault() being atomic.  This is true
      #   in CPython but we haven't investigated others.  This warning appears
      #   in several other locations in this file.
      field_value = self._fields.setdefault(field, field_value)
    return field_value
  getter.__module__ = None
  getter.__doc__ = 'Getter for %s.' % proto_field_name

  # We define a setter just so we can throw an exception with a more
  # helpful error message.
  def setter(self, new_value):
    raise AttributeError('Assignment not allowed to composite field '
                         '"%s" in protocol message object.' % proto_field_name)

  # Add a property to encapsulate the getter.
  doc = 'Magic attribute generated for "%s" proto field.' % proto_field_name
  setattr(cls, property_name, property(getter, setter, doc=doc))


def _AddPropertiesForExtensions(descriptor, cls):
  """Adds properties for all fields in this protocol message type."""
  extension_dict = descriptor.extensions_by_name
  for extension_name, extension_field in extension_dict.iteritems():
    constant_name = extension_name.upper() + "_FIELD_NUMBER"
    setattr(cls, constant_name, extension_field.number)


def _AddStaticMethods(cls):
  # TODO(robinson): This probably needs to be thread-safe(?)
  def RegisterExtension(extension_handle):
    extension_handle.containing_type = cls.DESCRIPTOR
    _AttachFieldHelpers(cls, extension_handle)

    # Try to insert our extension, failing if an extension with the same number
    # already exists.
    actual_handle = cls._extensions_by_number.setdefault(
        extension_handle.number, extension_handle)
    if actual_handle is not extension_handle:
      raise AssertionError(
          'Extensions "%s" and "%s" both try to extend message type "%s" with '
          'field number %d.' %
          (extension_handle.full_name, actual_handle.full_name,
           cls.DESCRIPTOR.full_name, extension_handle.number))

    cls._extensions_by_name[extension_handle.full_name] = extension_handle

    handle = extension_handle  # avoid line wrapping
    if _IsMessageSetExtension(handle):
      # MessageSet extension.  Also register under type name.
      cls._extensions_by_name[
          extension_handle.message_type.full_name] = extension_handle

  cls.RegisterExtension = staticmethod(RegisterExtension)

  def FromString(s):
    message = cls()
    message.MergeFromString(s)
    return message
  cls.FromString = staticmethod(FromString)


def _IsPresent(item):
  """Given a (FieldDescriptor, value) tuple from _fields, return true if the
  value should be included in the list returned by ListFields()."""

  if item[0].label == _FieldDescriptor.LABEL_REPEATED:
    return bool(item[1])
  elif item[0].cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
    return item[1]._is_present_in_parent
  else:
    return True


def _AddListFieldsMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""

  def ListFields(self):
    all_fields = [item for item in self._fields.iteritems() if _IsPresent(item)]
    all_fields.sort(key = lambda item: item[0].number)
    return all_fields

  cls.ListFields = ListFields


def _AddHasFieldMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""

  singular_fields = {}
  for field in message_descriptor.fields:
    if field.label != _FieldDescriptor.LABEL_REPEATED:
      singular_fields[field.name] = field

  def HasField(self, field_name):
    try:
      field = singular_fields[field_name]
    except KeyError:
      raise ValueError(
          'Protocol message has no singular "%s" field.' % field_name)

    if field.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
      value = self._fields.get(field)
      return value is not None and value._is_present_in_parent
    else:
      return field in self._fields
  cls.HasField = HasField


def _AddClearFieldMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""
  def ClearField(self, field_name):
    try:
      field = message_descriptor.fields_by_name[field_name]
    except KeyError:
      raise ValueError('Protocol message has no "%s" field.' % field_name)

    if field in self._fields:
      # Note:  If the field is a sub-message, its listener will still point
      #   at us.  That's fine, because the worst than can happen is that it
      #   will call _Modified() and invalidate our byte size.  Big deal.
      del self._fields[field]

    # Always call _Modified() -- even if nothing was changed, this is
    # a mutating method, and thus calling it should cause the field to become
    # present in the parent message.
    self._Modified()

  cls.ClearField = ClearField


def _AddClearExtensionMethod(cls):
  """Helper for _AddMessageMethods()."""
  def ClearExtension(self, extension_handle):
    _VerifyExtensionHandle(self, extension_handle)

    # Similar to ClearField(), above.
    if extension_handle in self._fields:
      del self._fields[extension_handle]
    self._Modified()
  cls.ClearExtension = ClearExtension


def _AddClearMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""
  def Clear(self):
    # Clear fields.
    self._fields = {}
    self._unknown_fields = ()
    self._Modified()
  cls.Clear = Clear


def _AddHasExtensionMethod(cls):
  """Helper for _AddMessageMethods()."""
  def HasExtension(self, extension_handle):
    _VerifyExtensionHandle(self, extension_handle)
    if extension_handle.label == _FieldDescriptor.LABEL_REPEATED:
      raise KeyError('"%s" is repeated.' % extension_handle.full_name)

    if extension_handle.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
      value = self._fields.get(extension_handle)
      return value is not None and value._is_present_in_parent
    else:
      return extension_handle in self._fields
  cls.HasExtension = HasExtension


def _AddEqualsMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""
  def __eq__(self, other):
    if (not isinstance(other, message_mod.Message) or
        other.DESCRIPTOR != self.DESCRIPTOR):
      return False

    if self is other:
      return True

    if not self.ListFields() == other.ListFields():
      return False

    # Sort unknown fields because their order shouldn't affect equality test.
    unknown_fields = list(self._unknown_fields)
    unknown_fields.sort()
    other_unknown_fields = list(other._unknown_fields)
    other_unknown_fields.sort()

    return unknown_fields == other_unknown_fields

  cls.__eq__ = __eq__


def _AddStrMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""
  def __str__(self):
    return text_format.MessageToString(self)
  cls.__str__ = __str__


def _AddUnicodeMethod(unused_message_descriptor, cls):
  """Helper for _AddMessageMethods()."""

  def __unicode__(self):
    return text_format.MessageToString(self, as_utf8=True).decode('utf-8')
  cls.__unicode__ = __unicode__


def _AddSetListenerMethod(cls):
  """Helper for _AddMessageMethods()."""
  def SetListener(self, listener):
    if listener is None:
      self._listener = message_listener_mod.NullMessageListener()
    else:
      self._listener = listener
  cls._SetListener = SetListener


def _BytesForNonRepeatedElement(value, field_number, field_type):
  """Returns the number of bytes needed to serialize a non-repeated element.
  The returned byte count includes space for tag information and any
  other additional space associated with serializing value.

  Args:
    value: Value we're serializing.
    field_number: Field number of this value.  (Since the field number
      is stored as part of a varint-encoded tag, this has an impact
      on the total bytes required to serialize the value).
    field_type: The type of the field.  One of the TYPE_* constants
      within FieldDescriptor.
  """
  try:
    fn = type_checkers.TYPE_TO_BYTE_SIZE_FN[field_type]
    return fn(field_number, value)
  except KeyError:
    raise message_mod.EncodeError('Unrecognized field type: %d' % field_type)


def _AddByteSizeMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""

  def ByteSize(self):
    if not self._cached_byte_size_dirty:
      return self._cached_byte_size

    size = 0
    for field_descriptor, field_value in self.ListFields():
      size += field_descriptor._sizer(field_value)

    for tag_bytes, value_bytes in self._unknown_fields:
      size += len(tag_bytes) + len(value_bytes)

    self._cached_byte_size = size
    self._cached_byte_size_dirty = False
    self._listener_for_children.dirty = False
    return size

  cls.ByteSize = ByteSize


def _AddSerializeToStringMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""

  def SerializeToString(self):
    # Check if the message has all of its required fields set.
    errors = []
    if not self.IsInitialized():
      raise message_mod.EncodeError(
          'Message %s is missing required fields: %s' % (
          self.DESCRIPTOR.full_name, ','.join(self.FindInitializationErrors())))
    return self.SerializePartialToString()
  cls.SerializeToString = SerializeToString


def _AddSerializePartialToStringMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""

  def SerializePartialToString(self):
    out = StringIO()
    self._InternalSerialize(out.write)
    return out.getvalue()
  cls.SerializePartialToString = SerializePartialToString

  def InternalSerialize(self, write_bytes):
    for field_descriptor, field_value in self.ListFields():
      field_descriptor._encoder(write_bytes, field_value)
    for tag_bytes, value_bytes in self._unknown_fields:
      write_bytes(tag_bytes)
      write_bytes(value_bytes)
  cls._InternalSerialize = InternalSerialize


def _AddMergeFromStringMethod(message_descriptor, cls):
  """Helper for _AddMessageMethods()."""
  def MergeFromString(self, serialized):
    length = len(serialized)
    try:
      if self._InternalParse(serialized, 0, length) != length:
        # The only reason _InternalParse would return early is if it
        # encountered an end-group tag.
        raise message_mod.DecodeError('Unexpected end-group tag.')
    except IndexError:
      raise message_mod.DecodeError('Truncated message.')
    except struct.error, e:
      raise message_mod.DecodeError(e)
    return length   # Return this for legacy reasons.
  cls.MergeFromString = MergeFromString

  local_ReadTag = decoder.ReadTag
  local_SkipField = decoder.SkipField
  decoders_by_tag = cls._decoders_by_tag

  def InternalParse(self, buffer, pos, end):
    self._Modified()
    field_dict = self._fields
    unknown_field_list = self._unknown_fields
    while pos != end:
      (tag_bytes, new_pos) = local_ReadTag(buffer, pos)
      field_decoder = decoders_by_tag.get(tag_bytes)
      if field_decoder is None:
        value_start_pos = new_pos
        new_pos = local_SkipField(buffer, new_pos, end, tag_bytes)
        if new_pos == -1:
          return pos
        if not unknown_field_list:
          unknown_field_list = self._unknown_fields = []
        unknown_field_list.append((tag_bytes, buffer[value_start_pos:new_pos]))
        pos = new_pos
      else:
        pos = field_decoder(buffer, new_pos, end, self, field_dict)
    return pos
  cls._InternalParse = InternalParse


def _AddIsInitializedMethod(message_descriptor, cls):
  """Adds the IsInitialized and FindInitializationError methods to the
  protocol message class."""

  required_fields = [field for field in message_descriptor.fields
                           if field.label == _FieldDescriptor.LABEL_REQUIRED]

  def IsInitialized(self, errors=None):
    """Checks if all required fields of a message are set.

    Args:
      errors:  A list which, if provided, will be populated with the field
               paths of all missing required fields.

    Returns:
      True iff the specified message has all required fields set.
    """

    # Performance is critical so we avoid HasField() and ListFields().

    for field in required_fields:
      if (field not in self._fields or
          (field.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE and
           not self._fields[field]._is_present_in_parent)):
        if errors is not None:
          errors.extend(self.FindInitializationErrors())
        return False

    for field, value in self._fields.iteritems():
      if field.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
        if field.label == _FieldDescriptor.LABEL_REPEATED:
          for element in value:
            if not element.IsInitialized():
              if errors is not None:
                errors.extend(self.FindInitializationErrors())
              return False
        elif value._is_present_in_parent and not value.IsInitialized():
          if errors is not None:
            errors.extend(self.FindInitializationErrors())
          return False

    return True

  cls.IsInitialized = IsInitialized

  def FindInitializationErrors(self):
    """Finds required fields which are not initialized.

    Returns:
      A list of strings.  Each string is a path to an uninitialized field from
      the top-level message, e.g. "foo.bar[5].baz".
    """

    errors = []  # simplify things

    for field in required_fields:
      if not self.HasField(field.name):
        errors.append(field.name)

    for field, value in self.ListFields():
      if field.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
        if field.is_extension:
          name = "(%s)" % field.full_name
        else:
          name = field.name

        if field.label == _FieldDescriptor.LABEL_REPEATED:
          for i in xrange(len(value)):
            element = value[i]
            prefix = "%s[%d]." % (name, i)
            sub_errors = element.FindInitializationErrors()
            errors += [ prefix + error for error in sub_errors ]
        else:
          prefix = name + "."
          sub_errors = value.FindInitializationErrors()
          errors += [ prefix + error for error in sub_errors ]

    return errors

  cls.FindInitializationErrors = FindInitializationErrors


def _AddMergeFromMethod(cls):
  LABEL_REPEATED = _FieldDescriptor.LABEL_REPEATED
  CPPTYPE_MESSAGE = _FieldDescriptor.CPPTYPE_MESSAGE

  def MergeFrom(self, msg):
    if not isinstance(msg, cls):
      raise TypeError(
          "Parameter to MergeFrom() must be instance of same class: "
          "expected %s got %s." % (cls.__name__, type(msg).__name__))

    assert msg is not self
    self._Modified()

    fields = self._fields

    for field, value in msg._fields.iteritems():
      if field.label == LABEL_REPEATED:
        field_value = fields.get(field)
        if field_value is None:
          # Construct a new object to represent this field.
          field_value = field._default_constructor(self)
          fields[field] = field_value
        field_value.MergeFrom(value)
      elif field.cpp_type == CPPTYPE_MESSAGE:
        if value._is_present_in_parent:
          field_value = fields.get(field)
          if field_value is None:
            # Construct a new object to represent this field.
            field_value = field._default_constructor(self)
            fields[field] = field_value
          field_value.MergeFrom(value)
      else:
        self._fields[field] = value

    if msg._unknown_fields:
      if not self._unknown_fields:
        self._unknown_fields = []
      self._unknown_fields.extend(msg._unknown_fields)

  cls.MergeFrom = MergeFrom


def _AddMessageMethods(message_descriptor, cls):
  """Adds implementations of all Message methods to cls."""
  _AddListFieldsMethod(message_descriptor, cls)
  _AddHasFieldMethod(message_descriptor, cls)
  _AddClearFieldMethod(message_descriptor, cls)
  if message_descriptor.is_extendable:
    _AddClearExtensionMethod(cls)
    _AddHasExtensionMethod(cls)
  _AddClearMethod(message_descriptor, cls)
  _AddEqualsMethod(message_descriptor, cls)
  _AddStrMethod(message_descriptor, cls)
  _AddUnicodeMethod(message_descriptor, cls)
  _AddSetListenerMethod(cls)
  _AddByteSizeMethod(message_descriptor, cls)
  _AddSerializeToStringMethod(message_descriptor, cls)
  _AddSerializePartialToStringMethod(message_descriptor, cls)
  _AddMergeFromStringMethod(message_descriptor, cls)
  _AddIsInitializedMethod(message_descriptor, cls)
  _AddMergeFromMethod(cls)


def _AddPrivateHelperMethods(cls):
  """Adds implementation of private helper methods to cls."""

  def Modified(self):
    """Sets the _cached_byte_size_dirty bit to true,
    and propagates this to our listener iff this was a state change.
    """

    # Note:  Some callers check _cached_byte_size_dirty before calling
    #   _Modified() as an extra optimization.  So, if this method is ever
    #   changed such that it does stuff even when _cached_byte_size_dirty is
    #   already true, the callers need to be updated.
    if not self._cached_byte_size_dirty:
      self._cached_byte_size_dirty = True
      self._listener_for_children.dirty = True
      self._is_present_in_parent = True
      self._listener.Modified()

  cls._Modified = Modified
  cls.SetInParent = Modified


class _Listener(object):

  """MessageListener implementation that a parent message registers with its
  child message.

  In order to support semantics like:

    foo.bar.baz.qux = 23
    assert foo.HasField('bar')

  ...child objects must have back references to their parents.
  This helper class is at the heart of this support.
  """

  def __init__(self, parent_message):
    """Args:
      parent_message: The message whose _Modified() method we should call when
        we receive Modified() messages.
    """
    # This listener establishes a back reference from a child (contained) object
    # to its parent (containing) object.  We make this a weak reference to avoid
    # creating cyclic garbage when the client finishes with the 'parent' object
    # in the tree.
    if isinstance(parent_message, weakref.ProxyType):
      self._parent_message_weakref = parent_message
    else:
      self._parent_message_weakref = weakref.proxy(parent_message)

    # As an optimization, we also indicate directly on the listener whether
    # or not the parent message is dirty.  This way we can avoid traversing
    # up the tree in the common case.
    self.dirty = False

  def Modified(self):
    if self.dirty:
      return
    try:
      # Propagate the signal to our parents iff this is the first field set.
      self._parent_message_weakref._Modified()
    except ReferenceError:
      # We can get here if a client has kept a reference to a child object,
      # and is now setting a field on it, but the child's parent has been
      # garbage-collected.  This is not an error.
      pass


# TODO(robinson): Move elsewhere?  This file is getting pretty ridiculous...
# TODO(robinson): Unify error handling of "unknown extension" crap.
# TODO(robinson): Support iteritems()-style iteration over all
# extensions with the "has" bits turned on?
class _ExtensionDict(object):

  """Dict-like container for supporting an indexable "Extensions"
  field on proto instances.

  Note that in all cases we expect extension handles to be
  FieldDescriptors.
  """

  def __init__(self, extended_message):
    """extended_message: Message instance for which we are the Extensions dict.
    """

    self._extended_message = extended_message

  def __getitem__(self, extension_handle):
    """Returns the current value of the given extension handle."""

    _VerifyExtensionHandle(self._extended_message, extension_handle)

    result = self._extended_message._fields.get(extension_handle)
    if result is not None:
      return result

    if extension_handle.label == _FieldDescriptor.LABEL_REPEATED:
      result = extension_handle._default_constructor(self._extended_message)
    elif extension_handle.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE:
      result = extension_handle.message_type._concrete_class()
      try:
        result._SetListener(self._extended_message._listener_for_children)
      except ReferenceError:
        pass
    else:
      # Singular scalar -- just return the default without inserting into the
      # dict.
      return extension_handle.default_value

    # Atomically check if another thread has preempted us and, if not, swap
    # in the new object we just created.  If someone has preempted us, we
    # take that object and discard ours.
    # WARNING:  We are relying on setdefault() being atomic.  This is true
    #   in CPython but we haven't investigated others.  This warning appears
    #   in several other locations in this file.
    result = self._extended_message._fields.setdefault(
        extension_handle, result)

    return result

  def __eq__(self, other):
    if not isinstance(other, self.__class__):
      return False

    my_fields = self._extended_message.ListFields()
    other_fields = other._extended_message.ListFields()

    # Get rid of non-extension fields.
    my_fields    = [ field for field in my_fields    if field.is_extension ]
    other_fields = [ field for field in other_fields if field.is_extension ]

    return my_fields == other_fields

  def __ne__(self, other):
    return not self == other

  def __hash__(self):
    raise TypeError('unhashable object')

  # Note that this is only meaningful for non-repeated, scalar extension
  # fields.  Note also that we may have to call _Modified() when we do
  # successfully set a field this way, to set any necssary "has" bits in the
  # ancestors of the extended message.
  def __setitem__(self, extension_handle, value):
    """If extension_handle specifies a non-repeated, scalar extension
    field, sets the value of that field.
    """

    _VerifyExtensionHandle(self._extended_message, extension_handle)

    if (extension_handle.label == _FieldDescriptor.LABEL_REPEATED or
        extension_handle.cpp_type == _FieldDescriptor.CPPTYPE_MESSAGE):
      raise TypeError(
          'Cannot assign to extension "%s" because it is a repeated or '
          'composite type.' % extension_handle.full_name)

    # It's slightly wasteful to lookup the type checker each time,
    # but we expect this to be a vanishingly uncommon case anyway.
    type_checker = type_checkers.GetTypeChecker(
        extension_handle.cpp_type, extension_handle.type)
    type_checker.CheckValue(value)
    self._extended_message._fields[extension_handle] = value
    self._extended_message._Modified()

  def _FindExtensionByName(self, name):
    """Tries to find a known extension with the specified name.

    Args:
      name: Extension full name.

    Returns:
      Extension field descriptor.
    """
    return self._extended_message._extensions_by_name.get(name, None)
