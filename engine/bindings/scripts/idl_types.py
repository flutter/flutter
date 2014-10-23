# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""IDL type handling.

Classes:
IdlTypeBase
 IdlType
 IdlUnionType
 IdlArrayOrSequenceType
  IdlArrayType
  IdlSequenceType
 IdlNullableType
"""

from collections import defaultdict


################################################################################
# IDL types
################################################################################

INTEGER_TYPES = frozenset([
    # http://www.w3.org/TR/WebIDL/#dfn-integer-type
    'byte',
    'octet',
    'short',
    'unsigned short',
    # int and unsigned are not IDL types
    'long',
    'unsigned long',
    'long long',
    'unsigned long long',
])
NUMERIC_TYPES = (INTEGER_TYPES | frozenset([
    # http://www.w3.org/TR/WebIDL/#dfn-numeric-type
    'float',
    'unrestricted float',
    'double',
    'unrestricted double',
]))
# http://www.w3.org/TR/WebIDL/#dfn-primitive-type
PRIMITIVE_TYPES = (frozenset(['boolean']) | NUMERIC_TYPES)
BASIC_TYPES = (PRIMITIVE_TYPES | frozenset([
    # Built-in, non-composite, non-object data types
    # http://heycam.github.io/webidl/#idl-types
    'DOMString',
    'ByteString',
    'Date',
    # http://heycam.github.io/webidl/#es-type-mapping
    'void',
    # http://encoding.spec.whatwg.org/#type-scalarvaluestring
    'ScalarValueString',
]))
TYPE_NAMES = {
    # http://heycam.github.io/webidl/#dfn-type-name
    'any': 'Any',
    'boolean': 'Boolean',
    'byte': 'Byte',
    'octet': 'Octet',
    'short': 'Short',
    'unsigned short': 'UnsignedShort',
    'long': 'Long',
    'unsigned long': 'UnsignedLong',
    'long long': 'LongLong',
    'unsigned long long': 'UnsignedLongLong',
    'float': 'Float',
    'unrestricted float': 'UnrestrictedFloat',
    'double': 'Double',
    'unrestricted double': 'UnrestrictedDouble',
    'DOMString': 'String',
    'ByteString': 'ByteString',
    'ScalarValueString': 'ScalarValueString',
    'object': 'Object',
    'Date': 'Date',
}

STRING_TYPES = frozenset([
    # http://heycam.github.io/webidl/#es-interface-call (step 10.11)
    # (Interface object [[Call]] method's string types.)
    'String',
    'ByteString',
    'ScalarValueString',
])


################################################################################
# Inheritance
################################################################################

ancestors = defaultdict(list)  # interface_name -> ancestors

def inherits_interface(interface_name, ancestor_name):
    return (interface_name == ancestor_name or
            ancestor_name in ancestors[interface_name])


def set_ancestors(new_ancestors):
    ancestors.update(new_ancestors)


class IdlTypeBase(object):
    """Base class for IdlType, IdlUnionType, IdlArrayOrSequenceType and IdlNullableType."""

    def __str__(self):
        raise NotImplementedError(
            '__str__() should be defined in subclasses')

    def __getattr__(self, name):
        # Default undefined attributes to None (analogous to Jinja variables).
        # This allows us to not define default properties in the base class, and
        # allows us to relay __getattr__ in IdlNullableType to the inner type.
        return None

    def resolve_typedefs(self, typedefs):
        raise NotImplementedError(
            'resolve_typedefs should be defined in subclasses')


################################################################################
# IdlType
################################################################################

class IdlType(IdlTypeBase):
    # FIXME: incorporate Nullable, etc.
    # to support types like short?[] vs. short[]?, instead of treating these
    # as orthogonal properties (via flags).
    callback_functions = set()
    callback_interfaces = set()
    dictionaries = set()
    enums = {}  # name -> values

    def __init__(self, base_type, is_unrestricted=False):
        super(IdlType, self).__init__()
        if is_unrestricted:
            self.base_type = 'unrestricted %s' % base_type
        else:
            self.base_type = base_type

    def __str__(self):
        return self.base_type

    @property
    def is_basic_type(self):
        return self.base_type in BASIC_TYPES

    @property
    def is_callback_function(self):
        return self.base_type in IdlType.callback_functions

    @property
    def is_callback_interface(self):
        return self.base_type in IdlType.callback_interfaces

    @property
    def is_dictionary(self):
        return self.base_type in IdlType.dictionaries

    @property
    def is_enum(self):
        # FIXME: add an IdlEnumType class and a resolve_enums step at end of
        # IdlDefinitions constructor
        return self.name in IdlType.enums

    @property
    def enum_values(self):
        return IdlType.enums[self.name]

    @property
    def is_integer_type(self):
        return self.base_type in INTEGER_TYPES

    @property
    def is_numeric_type(self):
        return self.base_type in NUMERIC_TYPES

    @property
    def is_primitive_type(self):
        return self.base_type in PRIMITIVE_TYPES

    @property
    def is_interface_type(self):
        # Anything that is not another type is an interface type.
        # http://www.w3.org/TR/WebIDL/#idl-types
        # http://www.w3.org/TR/WebIDL/#idl-interface
        # In C++ these are RefPtr or PassRefPtr types.
        return not(self.is_basic_type or
                   self.is_callback_function or
                   self.is_dictionary or
                   self.is_enum or
                   self.name == 'Any' or
                   self.name == 'Object' or
                   self.name == 'Promise')  # Promise will be basic in future

    @property
    def is_string_type(self):
        return self.name in STRING_TYPES

    @property
    def may_raise_exception_on_conversion(self):
        return (self.is_integer_type or
                self.name in ('ByteString', 'ScalarValueString'))

    @property
    def is_union_type(self):
        return isinstance(self, IdlUnionType)

    @property
    def name(self):
        """Return type name

        http://heycam.github.io/webidl/#dfn-type-name
        """
        base_type = self.base_type
        return TYPE_NAMES.get(base_type, base_type)

    @classmethod
    def set_callback_functions(cls, new_callback_functions):
        cls.callback_functions.update(new_callback_functions)

    @classmethod
    def set_callback_interfaces(cls, new_callback_interfaces):
        cls.callback_interfaces.update(new_callback_interfaces)

    @classmethod
    def set_dictionaries(cls, new_dictionaries):
        cls.dictionaries.update(new_dictionaries)

    @classmethod
    def set_enums(cls, new_enums):
        cls.enums.update(new_enums)

    def resolve_typedefs(self, typedefs):
        # This function either returns |self| or a different object.
        # FIXME: Rename typedefs_resolved().
        return typedefs.get(self.base_type, self)


################################################################################
# IdlUnionType
################################################################################

class IdlUnionType(IdlTypeBase):
    # http://heycam.github.io/webidl/#idl-union
    def __init__(self, member_types):
        super(IdlUnionType, self).__init__()
        self.member_types = member_types

    @property
    def is_union_type(self):
        return True

    @property
    def name(self):
        """Return type name (or inner type name if nullable)

        http://heycam.github.io/webidl/#dfn-type-name
        """
        return 'Or'.join(member_type.name for member_type in self.member_types)

    def resolve_typedefs(self, typedefs):
        self.member_types = [
            typedefs.get(member_type, member_type)
            for member_type in self.member_types]
        return self


################################################################################
# IdlArrayOrSequenceType, IdlArrayType, IdlSequenceType
################################################################################

class IdlArrayOrSequenceType(IdlTypeBase):
    """Base class for IdlArrayType and IdlSequenceType."""

    def __init__(self, element_type):
        super(IdlArrayOrSequenceType, self).__init__()
        self.element_type = element_type

    def resolve_typedefs(self, typedefs):
        self.element_type = self.element_type.resolve_typedefs(typedefs)
        return self


class IdlArrayType(IdlArrayOrSequenceType):
    def __init__(self, element_type):
        super(IdlArrayType, self).__init__(element_type)

    def __str__(self):
        return '%s[]' % self.element_type

    @property
    def name(self):
        return self.element_type.name + 'Array'


class IdlSequenceType(IdlArrayOrSequenceType):
    def __init__(self, element_type):
        super(IdlSequenceType, self).__init__(element_type)

    def __str__(self):
        return 'sequence<%s>' % self.element_type

    @property
    def name(self):
        return self.element_type.name + 'Sequence'


################################################################################
# IdlNullableType
################################################################################

class IdlNullableType(IdlTypeBase):
    def __init__(self, inner_type):
        super(IdlNullableType, self).__init__()
        self.inner_type = inner_type

    def __str__(self):
        # FIXME: Dictionary::ConversionContext::setConversionType can't
        # handle the '?' in nullable types (passes nullability separately).
        # Update that function to handle nullability from the type name,
        # simplifying its signature.
        # return str(self.inner_type) + '?'
        return str(self.inner_type)

    def __getattr__(self, name):
        return getattr(self.inner_type, name)

    @property
    def is_nullable(self):
        return True

    @property
    def name(self):
        return self.inner_type.name + 'OrNull'

    def resolve_typedefs(self, typedefs):
        self.inner_type = self.inner_type.resolve_typedefs(typedefs)
        return self
