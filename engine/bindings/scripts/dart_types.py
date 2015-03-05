# Copyright (C) 2013 Google Inc. All rights reserved.
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

"""Functions for type handling and type conversion (Blink/C++ <-> Dart:HTML).

Extends IdlType and IdlUnionType with C++-specific properties, methods, and
class methods.

Spec:
http://www.w3.org/TR/WebIDL/#es-type-mapping

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

import posixpath
from idl_types import IdlTypeBase, IdlType, IdlUnionType, TYPE_NAMES, IdlArrayOrSequenceType

import dart_attributes
from dart_utilities import DartUtilities
from v8_globals import includes


################################################################################
# CPP -specific handling of IDL types for Dart:Blink
################################################################################

NON_WRAPPER_TYPES = frozenset([
    'CompareHow',
    'DartValue',
    'EventHandler',
    'EventListener',
    'MediaQueryListListener',
    'NodeFilter',
])
TYPED_ARRAYS = {
    # (cpp_type, dart_type), used by constructor templates
    'ArrayBuffer': (None, 'ByteBuffer'),
    'ArrayBufferView': (None, 'ByteData'),
    'Float32Array': ('float', 'Float32List'),
    'Float64Array': ('double', 'Float64List'),
    'Int8Array': ('signed char', 'Int8List'),
    'Int16Array': ('short', 'Int16List'),
    'Int32Array': ('int', 'Int32List'),
    'Uint8Array': ('unsigned char', 'Uint8List'),
    'Uint8ClampedArray': ('unsigned char', 'Uint8ClampedList'),
    'Uint16Array': ('unsigned short', 'Uint16List'),
    'Uint32Array': ('unsigned int', 'Uint32List'),
}


IdlTypeBase.is_typed_array_type = property(
    lambda self: self.base_type in TYPED_ARRAYS)


IdlType.is_wrapper_type = property(
    lambda self: (self.is_interface_type and
                  self.base_type not in NON_WRAPPER_TYPES))


################################################################################
# C++ types
################################################################################

CPP_TYPE_SAME_AS_IDL_TYPE = set([
    'double',
    'float',
    'long long',
    'unsigned long long',
])
CPP_INT_TYPES = set([
    'byte',
    'long',
    'short',
])
CPP_UNSIGNED_TYPES = set([
    'octet',
    'unsigned int',
    'unsigned long',
    'unsigned short',
])
CPP_SPECIAL_CONVERSION_RULES = {
    'CompareHow': 'Range::CompareHow',
    'Date': 'double',
    'EventHandler': 'EventListener*',
    'MediaQueryListListener': 'RefPtrWillBeRawPtr<MediaQueryListListener>',
    'Promise': 'ScriptPromise',
    # FIXME: Eliminate custom bindings for XPathNSResolver  http://crbug.com/345529
    'XPathNSResolver': 'RefPtrWillBeRawPtr<XPathNSResolver>',
    'boolean': 'bool',
    'unrestricted double': 'double',
    'unrestricted float': 'float',
}


def cpp_type(idl_type, extended_attributes=None, raw_type=False, used_as_rvalue_type=False, used_as_variadic_argument=False, used_in_cpp_sequence=False):
    """Returns C++ type corresponding to IDL type.

    |idl_type| argument is of type IdlType, while return value is a string

    Args:
        idl_type:
            IdlType
        raw_type:
            bool, True if idl_type's raw/primitive C++ type should be returned.
        used_as_rvalue_type:
            bool, True if the C++ type is used as an argument or the return
            type of a method.
        used_as_variadic_argument:
            bool, True if the C++ type is used as a variadic argument of a method.
        used_in_cpp_sequence:
            bool, True if the C++ type is used as an element of a container.
            Containers can be an array, a sequence or a dictionary.
    """
    extended_attributes = extended_attributes or {}
    idl_type = idl_type.preprocessed_type

    # Composite types
    native_array_element_type = idl_type.native_array_element_type
    if native_array_element_type:
        return cpp_template_type('Vector', native_array_element_type.cpp_type_args(used_in_cpp_sequence=True))

    # Simple types
    base_idl_type = idl_type.base_type

    if base_idl_type in CPP_TYPE_SAME_AS_IDL_TYPE:
        return base_idl_type
    if base_idl_type in CPP_INT_TYPES:
        return 'int'
    if base_idl_type in CPP_UNSIGNED_TYPES:
        return 'unsigned'
    if base_idl_type in CPP_SPECIAL_CONVERSION_RULES:
        return CPP_SPECIAL_CONVERSION_RULES[base_idl_type]

    if base_idl_type in NON_WRAPPER_TYPES:
        return ('PassRefPtr<%s>' if used_as_rvalue_type else 'RefPtr<%s>') % base_idl_type
    if base_idl_type in ('DOMString', 'ByteString', 'ScalarValueString'):
        return 'String'

    if idl_type.is_typed_array_type and raw_type:
        return 'RefPtr<%s>' % base_idl_type
    if idl_type.is_callback_interface:
        return 'OwnPtr<%s>' % base_idl_type
    if idl_type.is_interface_type:
        implemented_as_class = idl_type.implemented_as
        if raw_type:
            return implemented_as_class + '*'
        new_type = 'Member' if used_in_cpp_sequence else 'RawPtr'
        ptr_type = 'PassRefPtr' if used_as_rvalue_type else 'RefPtr'
        return cpp_template_type(ptr_type, implemented_as_class)

    # Default, assume native type is a pointer with same type name as idl type
    return base_idl_type + '*'


def cpp_type_union(idl_type, extended_attributes=None, used_as_rvalue_type=False, will_be_in_heap_object=False):
    return (member_type.cpp_type for member_type in idl_type.member_types)


# Allow access as idl_type.cpp_type if no arguments
IdlTypeBase.cpp_type = property(cpp_type)
IdlTypeBase.cpp_type_args = cpp_type
IdlUnionType.cpp_type = property(cpp_type_union)
IdlUnionType.cpp_type_args = cpp_type_union


IdlTypeBase.native_array_element_type = None
IdlArrayOrSequenceType.native_array_element_type = property(
    lambda self: self.element_type)


def cpp_template_type(template, inner_type):
    """Returns C++ template specialized to type, with space added if needed."""
    if inner_type.endswith('>'):
        format_string = '{template}<{inner_type} >'
    else:
        format_string = '{template}<{inner_type}>'
    return format_string.format(template=template, inner_type=inner_type)


def dart_type(interface_name):
    return 'Dart' + str(interface_name)


# [ImplementedAs]
# This handles [ImplementedAs] on interface types, not [ImplementedAs] in the
# interface being generated. e.g., given:
#   Foo.idl: interface Foo {attribute Bar bar};
#   Bar.idl: [ImplementedAs=Zork] interface Bar {};
# when generating bindings for Foo, the [ImplementedAs] on Bar is needed.
# This data is external to Foo.idl, and hence computed as global information in
# compute_interfaces_info.py to avoid having to parse IDLs of all used interfaces.
IdlType.implemented_as_interfaces = {}


def implemented_as(idl_type):
    base_idl_type = idl_type.base_type
    if base_idl_type in IdlType.implemented_as_interfaces:
        return IdlType.implemented_as_interfaces[base_idl_type]
    return base_idl_type


IdlType.implemented_as = property(implemented_as)

IdlType.set_implemented_as_interfaces = classmethod(
    lambda cls, new_implemented_as_interfaces:
        cls.implemented_as_interfaces.update(new_implemented_as_interfaces))



################################################################################
# Includes
################################################################################

def includes_for_cpp_class(class_name, relative_dir_posix):
    return set([posixpath.join('bindings', relative_dir_posix, class_name + '.h')])

# TODO(terry): Will we need this group header for dart:blink?
INCLUDES_FOR_TYPE = {
    'object': set(),
    'CompareHow': set(),
    'EventHandler': set(),
    'EventListener': set(),
    'MediaQueryListListener': set(['sky/engine/core/css/MediaQueryListListener.h']),
    'NodeList': set(['sky/engine/core/dom/NodeList.h',
                     'sky/engine/core/dom/StaticNodeList.h']),
    'DartValue': set(['sky/engine/tonic/dart_value.h']),
}


def includes_for_type(idl_type):
    idl_type = idl_type.preprocessed_type

    # Composite types
    if idl_type.native_array_element_type:
        return includes_for_type(idl_type)

    # Simple types
    base_idl_type = idl_type.base_type
    if base_idl_type in INCLUDES_FOR_TYPE:
        return INCLUDES_FOR_TYPE[base_idl_type]
    if idl_type.is_basic_type:
        return set()
    if idl_type.is_typed_array_type:
        # Typed array factory methods are already provided by DartUtilities.h.
        return set([])
    if base_idl_type.endswith('ConstructorConstructor'):
        # FIXME: rename to NamedConstructor
        # FIXME: replace with a [NamedConstructorAttribute] extended attribute
        # Ending with 'ConstructorConstructor' indicates a named constructor,
        # and these do not have header files, as they are part of the generated
        # bindings for the interface
        return set()
    if base_idl_type.endswith('Constructor'):
        # FIXME: replace with a [ConstructorAttribute] extended attribute
        base_idl_type = idl_type.constructor_type_name
    if base_idl_type not in component_dir:
        return set()
    return set(['gen/sky/bindings/Dart%s.h' % base_idl_type])

IdlType.includes_for_type = property(includes_for_type)
IdlUnionType.includes_for_type = property(
    lambda self: set.union(*[includes_for_type(member_type)
                             for member_type in self.member_types]))


def add_includes_for_type(idl_type):
    includes.update(idl_type.includes_for_type)

IdlTypeBase.add_includes_for_type = add_includes_for_type
IdlUnionType.add_includes_for_type = add_includes_for_type


def includes_for_interface(interface_name):
    return IdlType(interface_name).includes_for_type


def add_includes_for_interface(interface_name):
    includes.update(includes_for_interface(interface_name))


component_dir = {}


def set_component_dirs(new_component_dirs):
    component_dir.update(new_component_dirs)


################################################################################
# Dart -> C++
################################################################################

# TODO(terry): Need to fix to handle getter/setters for onEvent.
DART_FIX_ME = 'DART_UNIMPLEMENTED(/* Conversion unimplemented*/);'

# For a given IDL type, the DartHandle to C++ conversion.
DART_TO_CPP_VALUE = {
    # Basic
    'Date': 'DartUtilities::dartToDate(args, {index}, exception)',
    'DOMString': 'DartConverter<String>::FromArguments{null_check}(args, {index}, exception, {auto_scope})',
    'ByteString': 'DartUtilities::dartToByteString{null_check}(args, {index}, exception, {auto_scope})',
    'ScalarValueString': 'DartUtilities::dartToScalarValueString{null_check}(args, {index}, exception, {auto_scope})',
    'boolean': 'DartConverter<bool>::FromArguments(args, {index}, exception)',
    'float': 'static_cast<float>(DartConverter<double>::FromArguments(args, {index}, exception))',
    'unrestricted float': 'static_cast<float>(DartConverter<double>::FromArguments(args, {index}, exception))',
    'double': 'DartConverter<double>::FromArguments(args, {index}, exception)',
    'unrestricted double': 'DartConverter<double>::FromArguments(args, {index}, exception)',
    # FIXME(vsm): Inconsistent with V8.
    'byte': 'DartConverter<unsigned>::FromArguments(args, {index}, exception)',
    'octet': 'DartConverter<unsigned>::FromArguments(args, {index}, exception)',
    'short': 'DartConverter<int>::FromArguments(args, {index}, exception)',
    'unsigned short': 'DartConverter<unsigned>::FromArguments(args, {index}, exception)',
    'long': 'DartConverter<int>::FromArguments(args, {index}, exception)',
    'unsigned long': 'DartConverter<unsigned>::FromArguments(args, {index}, exception)',
    'long long': 'DartConverter<long long>::FromArguments(args, {index}, exception)',
    'unsigned long long': 'DartConverter<unsigned long long>::FromArguments(args, {index}, exception)',
    # Interface types
    'CompareHow': 'static_cast<Range::CompareHow>(0) /* FIXME, DART_TO_CPP_VALUE[CompareHow] */',
    'EventTarget': '0 /* FIXME, DART_TO_CPP_VALUE[EventTarget] */',
    'MediaQueryListListener': 'nullptr /* FIXME, DART_TO_CPP_VALUE[MediaQueryListener] */',
    'NodeFilter': 'nullptr /* FIXME, DART_TO_CPP_VALUE[NodeFilter] */',
    'Promise': 'DartUtilities::dartToScriptPromise{null_check}(args, {index})',
    'DartValue': 'DartConverter<DartValue*>::FromArguments(args, {index}, exception)',
    # FIXME(vsm): Why don't we have an entry for Window? V8 does.
    # I think I removed this as the Window object is more special in V8 - it's the
    # global context as well.  Do we need to special case it?
    'XPathNSResolver': 'nullptr /* FIXME, DART_TO_CPP_VALUE[XPathNSResolver] */',
    # FIXME(vsm): This is an enum type (defined in StorageQuota.idl).
    # We should handle it automatically, but map to a String for now.
    'StorageType': 'DartUtilities::dartToString(args, {index}, exception, {auto_scope})',
}


def dart_value_to_cpp_value(idl_type, extended_attributes, variable_name,
                            null_check, has_type_checking_interface,
                            index, auto_scope=True):
    # Composite types
    native_array_element_type = idl_type.native_array_element_type
    if native_array_element_type:
        return dart_value_to_cpp_value_array_or_sequence(native_array_element_type, variable_name, index)

    # Simple types
    idl_type = idl_type.preprocessed_type
    add_includes_for_type(idl_type)
    base_idl_type = idl_type.base_type

    if 'EnforceRange' in extended_attributes:
        arguments = ', '.join([variable_name, 'EnforceRange', 'exceptionState'])
    elif idl_type.is_integer_type:  # NormalConversion
        arguments = ', '.join([variable_name, 'es'])
    else:
        arguments = variable_name

    if base_idl_type in DART_TO_CPP_VALUE:
        cpp_expression_format = DART_TO_CPP_VALUE[base_idl_type]
    elif idl_type.is_typed_array_type:
        # FIXME(vsm): V8 generates a type check here as well. Do we need one?
        # FIXME(vsm): When do we call the externalized version? E.g., see
        # bindings/dart/custom/DartWaveShaperNodeCustom.cpp - it calls
        # DartUtilities::dartToExternalizedArrayBufferView instead.
        # V8 always converts null here
        cpp_expression_format = ('DartUtilities::dartTo{idl_type}WithNullCheck(args, {index}, exception)')
    elif idl_type.is_callback_interface:
        cpp_expression_format = ('Dart{idl_type}::create{null_check}(args, {index}, exception)')
    else:
        cpp_expression_format = ('DartConverter<{implemented_as}*>::FromArguments{null_check}(args, {index}, exception)')

    # We allow the calling context to force a null check to handle
    # some cases that require calling context info.  V8 handles all
    # of this differently, and we may wish to reconsider this approach
    check_string = ''
    if null_check or allow_null(idl_type, extended_attributes,
                                has_type_checking_interface):
        check_string = 'WithNullCheck'
    elif allow_empty(idl_type, extended_attributes):
        check_string = 'WithEmptyCheck'
    return cpp_expression_format.format(null_check=check_string,
                                        arguments=arguments,
                                        index=index,
                                        idl_type=base_idl_type,
                                        implemented_as=idl_type.implemented_as,
                                        auto_scope=DartUtilities.bool_to_cpp(auto_scope))


def dart_value_to_cpp_value_array_or_sequence(native_array_element_type, variable_name, index):
    # Index is None for setters, index (starting at 0) for method arguments,
    # and is used to provide a human-readable exception message
    if index is None:
        index = 0  # special case, meaning "setter"
    this_cpp_type = native_array_element_type.cpp_type
    expression_format = '{variable_name} = DartConverter<Vector<{cpp_type}>>::FromArguments(args, {index}, exception)'
    expression = expression_format.format(native_array_element_type=native_array_element_type.name,
                                          cpp_type=this_cpp_type, index=index,
                                          variable_name=variable_name)
    return expression


def dart_value_to_local_cpp_value(idl_type, extended_attributes, variable_name,
                                  null_check, has_type_checking_interface,
                                  index=None, auto_scope=True):
    """Returns an expression that converts a Dart value to a C++ value as a local value."""
    idl_type = idl_type.preprocessed_type

    cpp_value = dart_value_to_cpp_value(
        idl_type, extended_attributes, variable_name,
        null_check, has_type_checking_interface,
        index, auto_scope)

    return cpp_value

IdlTypeBase.dart_value_to_local_cpp_value = dart_value_to_local_cpp_value
#IdlUnionType.dart_value_to_local_cpp_value = dart_value_to_local_cpp_value


# Insure that we don't use C++ reserved names.  Today on default is a problem.
def check_reserved_name(name):
    return 'default_value' if (name == 'default') else name


################################################################################
# C++ -> V8
################################################################################

def preprocess_idl_type(idl_type):
    if idl_type.is_enum:
        # Enumerations are internally DOMStrings
        return IdlType('DOMString')
    if (idl_type.name == 'Any' or idl_type.is_callback_function):
        return IdlType('DartValue')
    return idl_type

IdlTypeBase.preprocessed_type = property(preprocess_idl_type)
IdlUnionType.preprocessed_type = property(preprocess_idl_type)


def preprocess_idl_type_and_value(idl_type, cpp_value, extended_attributes):
    """Returns IDL type and value, with preliminary type conversions applied."""
    idl_type = idl_type.preprocessed_type
    if idl_type.name == 'Promise':
        idl_type = IdlType('ScriptPromise')

    # FIXME(vsm): V8 maps 'long long' and 'unsigned long long' to double
    # as they are not representable in ECMAScript.  Should we do the same?

    # HTML5 says that unsigned reflected attributes should be in the range
    # [0, 2^31). When a value isn't in this range, a default value (or 0)
    # should be returned instead.
    extended_attributes = extended_attributes or {}
    if ('Reflect' in extended_attributes and
        idl_type.base_type in ['unsigned long', 'unsigned short']):
        cpp_value = cpp_value.replace('getUnsignedIntegralAttribute',
                                      'getIntegralAttribute')
        cpp_value = 'std::max(0, %s)' % cpp_value
    return idl_type, cpp_value


IDL_TO_DART_TYPE = {
    'DOMString': 'String',
    'DartValue': 'dynamic',
    'boolean': 'bool',
    'void': 'void',
    'unsigned long': 'int',
}

def idl_type_to_dart_type(idl_type):
    preprocessed_type = str(idl_type.preprocessed_type)
    dart_type = IDL_TO_DART_TYPE.get(preprocessed_type)
    if dart_type:
        return dart_type
    if idl_type.is_integer_type:
        return 'int'
    if idl_type.is_numeric_type:
        return 'double'
    native_array_element_type = idl_type.native_array_element_type
    if native_array_element_type:
        return 'List<%s>' % idl_type_to_dart_type(native_array_element_type)
    assert preprocessed_type
    assert idl_type.is_interface_type, "Missing dart type mapping for '%s'" % preprocessed_type
    return preprocessed_type


DART_DEFAULT_VALUES_BY_TYPE = {
    'String': '""',
    'bool': 'false',
    'double': '0.0',
    'dynamic': 'null',
    'int': '0',
}

def dart_default_value(dart_type, argument=None):
    # TODO(eseidel): Maybe take the idl_type instead?
    # if argument.default_value:
    #     return argument.default_value
    default_value = DART_DEFAULT_VALUES_BY_TYPE.get(dart_type)
    if default_value:
        return default_value
    idl_type = argument.idl_type
    if idl_type.is_interface_type:
        return 'null'
    if idl_type.native_array_element_type:
        return 'null'
    assert default_value, "Missing default value mapping for '%s'" % dart_type


def dart_conversion_type(idl_type, extended_attributes):
    """Returns Dart conversion type, adding any additional includes.

    The Dart conversion type is used to select the C++ -> Dart conversion function
    or setDart*ReturnValue function; it can be an idl_type, a cpp_type, or a
    separate name for the type of conversion (e.g., 'DOMWrapper').
    """
    extended_attributes = extended_attributes or {}

    # Composite types
    native_array_element_type = idl_type.native_array_element_type
    if native_array_element_type:
        if native_array_element_type.is_interface_type:
            add_includes_for_type(native_array_element_type)
        return 'array'

    # Simple types
    base_idl_type = idl_type.base_type
    # Basic types, without additional includes
    if base_idl_type in CPP_INT_TYPES or base_idl_type == 'long long':
        return 'int'
    if base_idl_type in CPP_UNSIGNED_TYPES or base_idl_type == 'unsigned long long':
        return 'unsigned'
    if idl_type.is_string_type:
        if idl_type.is_nullable:
            return 'StringOrNull'
        if 'TreatReturnedNullStringAs' not in extended_attributes:
            return 'DOMString'
        treat_returned_null_string_as = extended_attributes['TreatReturnedNullStringAs']
        if treat_returned_null_string_as == 'Null':
            return 'StringOrNull'
        if treat_returned_null_string_as == 'Undefined':
            return 'StringOrUndefined'
        raise 'Unrecognized TreatReturnNullStringAs value: "%s"' % treat_returned_null_string_as
    if idl_type.is_basic_type or base_idl_type == 'DartValue':
        return base_idl_type

    # Data type with potential additional includes
    add_includes_for_type(idl_type)
    if base_idl_type in DART_SET_RETURN_VALUE:  # Special dartSetReturnValue treatment
        return base_idl_type

    # Typed arrays don't have special Dart* classes for Dart.
    if idl_type.is_typed_array_type:
        if base_idl_type == 'ArrayBuffer':
            return 'ArrayBuffer'
        else:
            return 'TypedList'

    # Pointer type
    return 'DOMWrapper'

IdlTypeBase.dart_conversion_type = dart_conversion_type


DART_SET_RETURN_VALUE = {
    'boolean': 'DartConverter<bool>::SetReturnValue(args, {cpp_value})',
    'int': 'DartConverter<int>::SetReturnValue(args, {cpp_value})',
    'unsigned': 'DartConverter<unsigned>::SetReturnValue(args, {cpp_value})',
    'DOMString': 'DartConverter<String>::SetReturnValue(args, {cpp_value}, {auto_scope})',
    # FIXME(terry): Need to handle checking to byte values > 255 throwing exception.
    'ByteString': 'DartUtilities::setDartByteStringReturnValue(args, {cpp_value}, {auto_scope})',
    # FIXME(terry):  Need to make valid unicode; match UTF-16 to U+FFFD REPLACEMENT CHARACTER.
    'ScalarValueString': 'DartUtilities::setDartScalarValueStringReturnValue(args, {cpp_value}, {auto_scope})',
    # [TreatNullReturnValueAs]
    'StringOrNull': 'DartConverter<String>::SetReturnValueWithNullCheck(args, {cpp_value}, {auto_scope})',
    # FIXME(vsm): How should we handle undefined?
    'StringOrUndefined': 'DartConverter<String>::SetReturnValueWithNullCheck(args, {cpp_value}, {auto_scope})',
    'void': '',
    # We specialize these as well in Dart.
    'float': 'DartConverter<double>::SetReturnValue(args, {cpp_value})',
    'unrestricted float': 'DartConverter<double>::SetReturnValue(args, {cpp_value})',
    'double': 'DartConverter<double>::SetReturnValue(args, {cpp_value})',
    'unrestricted double': 'DartConverter<double>::SetReturnValue(args, {cpp_value})',
    # No special function, but instead convert value to Dart_Handle
    # and then use general Dart_SetReturnValue.
    'array': 'Dart_SetReturnValue(args, {cpp_value})',
    'Date': 'Dart_SetReturnValue(args, {cpp_value})',
    'EventHandler': DART_FIX_ME,
    'ScriptPromise': 'Dart_SetReturnValue(args, {cpp_value})',
    'DartValue': 'DartConverter<DartValue*>::SetReturnValue(args, {cpp_value})',
    # DOMWrapper
    # TODO(terry): Remove ForMainWorld stuff.
    'DOMWrapperForMainWorld': DART_FIX_ME,
    # FIXME(vsm): V8 has a fast path. Do we?
    'DOMWrapperFast': 'DartConverter<{implemented_as}*>::SetReturnValue(args, WTF::getPtr({cpp_value}), {auto_scope})',
    'DOMWrapperDefault': 'DartConverter<{implemented_as}*>::SetReturnValue(args, WTF::getPtr({cpp_value}), {auto_scope})',
    # Typed arrays don't have special Dart* classes for Dart.
    'ArrayBuffer': 'Dart_SetReturnValue(args, DartUtilities::arrayBufferToDart({cpp_value}))',
    'TypedList': 'Dart_SetReturnValue(args, DartUtilities::arrayBufferViewToDart({cpp_value}))',
}


def dart_set_return_value(idl_type, cpp_value,
                          extended_attributes=None, script_wrappable='',
                          release=False, for_main_world=False,
                          auto_scope=True):
    """Returns a statement that converts a C++ value to a Dart value and sets it as a return value.

    """
    def dom_wrapper_conversion_type():
        if not script_wrappable:
            return 'DOMWrapperDefault'
        if for_main_world:
            return 'DOMWrapperForMainWorld'
        return 'DOMWrapperFast'

    idl_type, cpp_value = preprocess_idl_type_and_value(idl_type, cpp_value, extended_attributes)
    this_dart_conversion_type = idl_type.dart_conversion_type(extended_attributes)
    # SetReturn-specific overrides
    if this_dart_conversion_type in ['Date', 'EventHandler', 'ScriptPromise', 'SerializedScriptValue', 'array']:
        # Convert value to Dart and then use general Dart_SetReturnValue
        # FIXME(vsm): Why do we differ from V8 here? It doesn't have a
        # creation_context.
        creation_context = ''
        if this_dart_conversion_type == 'array':
            # FIXME: This is not right if the base type is a primitive, DOMString, etc.
            # What is the right check for base type?
            base_type = str(idl_type.element_type)
            if base_type not in DART_TO_CPP_VALUE:
                if base_type == 'None':
                    raise Exception('Unknown base type for ' + str(idl_type))
                creation_context = '<Dart%s>' % base_type
            if idl_type.is_nullable:
                creation_context = 'Nullable' + creation_context

        cpp_value = idl_type.cpp_value_to_dart_value(cpp_value, creation_context=creation_context,
                                                     extended_attributes=extended_attributes)
    if this_dart_conversion_type == 'DOMWrapper':
        this_dart_conversion_type = dom_wrapper_conversion_type()

    format_string = DART_SET_RETURN_VALUE[this_dart_conversion_type]

    if release:
        cpp_value = '%s.release()' % cpp_value
    statement = format_string.format(cpp_value=cpp_value,
                                     implemented_as=idl_type.implemented_as,
                                     type_name=idl_type.name,
                                     script_wrappable=script_wrappable,
                                     auto_scope=DartUtilities.bool_to_cpp(auto_scope))
    return statement


def dart_set_return_value_union(idl_type, cpp_value, extended_attributes=None,
                              script_wrappable='', release=False, for_main_world=False,
                              auto_scope=True):
    """
    release: can be either False (False for all member types) or
             a sequence (list or tuple) of booleans (if specified individually).
    """

    return [
        # FIXME(vsm): Why do we use 'result' instead of cpp_value as V8?
        member_type.dart_set_return_value('result' + str(i),
                                        extended_attributes,
                                        script_wrappable,
                                        release and release[i],
                                        for_main_world,
                                        auto_scope)
            for i, member_type in
            enumerate(idl_type.member_types)]

IdlTypeBase.dart_set_return_value = dart_set_return_value
IdlUnionType.dart_set_return_value = dart_set_return_value_union

IdlType.release = property(lambda self: self.is_interface_type)
IdlUnionType.release = property(
    lambda self: [member_type.is_interface_type
                  for member_type in self.member_types])


CPP_VALUE_TO_DART_VALUE = {
    # Built-in types
    # FIXME(vsm): V8 uses DateOrNull - do we need a null check?
    'Date': 'DartUtilities::dateToDart({cpp_value})',
    'DOMString': 'DartConverter<String>::ToDart(DartState::Current(), {cpp_value})',
    'boolean': 'DartConverter<bool>::ToDart({cpp_value})',
    'int': 'DartConverter<int>::ToDart({cpp_value})',
    'unsigned': 'DartConverter<unsigned>::ToDart({cpp_value})',
    'float': 'DartConverter<double>::ToDart({cpp_value})',
    'unrestricted float': 'DartConverter<double>::ToDart({cpp_value})',
    'double': 'DartConverter<double>::ToDart({cpp_value})',
    'unrestricted double': 'DartConverter<double>::ToDart({cpp_value})',
    # FIXME(vsm): Dart_Null?
    'void': '',
    # Special cases
    'EventHandler': '-----OOPS TO DART-EVENT---',
    # We need to generate the NullCheck version in some cases.
    'ScriptPromise': 'DartUtilities::scriptPromiseToDart({cpp_value})',
    'DartValue': 'DartConverter<DartValue*>::ToDart({cpp_value})',
    # General
    'array': 'VectorToDart({cpp_value})',
    'DOMWrapper': 'Dart{idl_type}::toDart({cpp_value})',
}


def cpp_value_to_dart_value(idl_type, cpp_value, creation_context='', extended_attributes=None):
    """Returns an expression that converts a C++ value to a Dart value."""
    # the isolate parameter is needed for callback interfaces
    idl_type, cpp_value = preprocess_idl_type_and_value(idl_type, cpp_value, extended_attributes)
    this_dart_conversion_type = idl_type.dart_conversion_type(extended_attributes)
    format_string = CPP_VALUE_TO_DART_VALUE[this_dart_conversion_type]
    statement = format_string.format(cpp_value=cpp_value, idl_type=idl_type.base_type)
    return statement

IdlTypeBase.cpp_value_to_dart_value = cpp_value_to_dart_value

# FIXME(leafp) This is horrible, we should do better, but currently this is hard to do
# in a nice way.  Best solution might be to extend DartStringAdapter to accomodate
# initialization from constant strings, but better to do that once we're stable
# on the bots so we can track any performance regression
CPP_LITERAL_TO_DART_VALUE = {
    'DOMString': {'nullptr': 'String()',
                  'String("")': 'String(StringImpl::empty())',
                  '*': 'DartUtilities::dartToString(DartUtilities::stringToDart({cpp_literal}), exception)'},
    'ScalarValueString': {'nullptr': 'DartStringAdapter(DartStringPeer::nullString())',
                          'String("")': 'DartStringAdapter(DartStringPeer::emptyString())',
                          '*': 'DartUtilities::dartToScalarValueString(DartUtilities::stringToDart({cpp_literal}), exception)'},
}


def literal_cpp_value(idl_type, idl_literal):
    """Converts an expression that is a valid C++ literal for this type."""
    # FIXME: add validation that idl_type and idl_literal are compatible
    literal_value = str(idl_literal)
    base_type = idl_type.preprocessed_type.base_type
    if base_type in CPP_UNSIGNED_TYPES:
        return literal_value + 'u'
    if base_type in CPP_LITERAL_TO_DART_VALUE:
        if literal_value in CPP_LITERAL_TO_DART_VALUE[base_type]:
            format_string = CPP_LITERAL_TO_DART_VALUE[base_type][literal_value]
        else:
            format_string = CPP_LITERAL_TO_DART_VALUE[base_type]['*']
        return format_string.format(cpp_literal=literal_value)
    return literal_value

IdlType.literal_cpp_value = literal_cpp_value


CPP_DEFAULT_VALUE_FOR_CPP_TYPE = {
    'DOMString': 'String()',
    'ByteString': 'String()',
    'ScalarValueString': 'String()',
    'boolean': 'false',
    'float': '0.0f',
    'unrestricted float': '0.0f',
    'double': '0.0',
    'unrestricted double': '0.0',
    'byte': '0',
    'octet': '0',
    'short': '0',
    'unsigned short': '0',
    'long': '0',
    'unsigned long': '0',
    'long long': '0',
    'unsigned long long': '0',
}


def default_cpp_value_for_cpp_type(idl_type):
    idl_type = idl_type.preprocessed_type
    add_includes_for_type(idl_type)
    base_idl_type = idl_type.base_type
    if base_idl_type in CPP_DEFAULT_VALUE_FOR_CPP_TYPE:
        return CPP_DEFAULT_VALUE_FOR_CPP_TYPE[base_idl_type]
    return 'nullptr'


# Override idl_type.name to not suffix orNull to the name, in Dart we always
# test for null e.g.,
#
#      bool isNull = false;
#      TYPE* result = receiver->GETTER(isNull);
#      if (isNull)
#          return;
#
def dart_name(idl_type):
    """Return type name.

    http://heycam.github.io/webidl/#dfn-type-name
    """
    base_type = idl_type.base_type
    base_type_name = TYPE_NAMES.get(base_type, base_type)
    if idl_type.native_array_element_type:
        return idl_type.inner_name()
    return base_type_name

IdlType.name = property(dart_name)
IdlUnionType.name = property(dart_name)


# If True use the WithNullCheck version when converting.
def allow_null(idl_type, extended_attributes, has_type_checking_interface):
    if idl_type.base_type in ('DOMString', 'ByteString', 'ScalarValueString'):
        # This logic is in cpp_types in v8_types.py, since they handle
        # this using the V8StringResource type.  We handle it here
        if (extended_attributes.get('TreatNullAs') == 'NullString' or
            extended_attributes.get('TreatUndefinedAs') == 'NullString'):
            return True

        if extended_attributes.get('Default') == 'NullString':
            return True

        if extended_attributes.get('Default') == 'Undefined':
            return True

        if idl_type.is_nullable:
            return True

        return False
    else:
        # This logic is implemented in the methods.cpp template in V8
        if (idl_type.is_nullable or not has_type_checking_interface):
            return True

        if extended_attributes.get('Default') == 'Undefined':
            return True

        return False


# If True use the WithEmptyCheck version when converting.
def allow_empty(idl_type, extended_attributes):
    if idl_type.base_type in ('DOMString', 'ByteString', 'ScalarValueString'):
        # This logic is in cpp_types in v8_types.py, since they handle
        # this using the V8StringResource type.  We handle it here
        if (extended_attributes.get('TreatNullAs') == 'EmptyString' or
            extended_attributes.get('TreatUndefinedAs') == 'EmptyString'):
            return True

        if extended_attributes.get('Default') == 'EmptyString':
            return True

    return False
