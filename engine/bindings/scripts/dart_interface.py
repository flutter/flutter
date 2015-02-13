# Copyright (C) 2013 Google Inc. All rights reserved.
# coding=utf-8
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

"""Generate template values for an interface.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

from collections import defaultdict
import itertools
from operator import itemgetter

import idl_types
from idl_types import IdlType, inherits_interface, IdlArrayOrSequenceType, IdlArrayType
import dart_attributes
import dart_methods
import dart_types
from dart_utilities import DartUtilities
from v8_globals import includes
import v8_attributes
import v8_interface


INTERFACE_H_INCLUDES = frozenset([
    'dart/runtime/include/dart_api.h',
])


INTERFACE_CPP_INCLUDES = frozenset([
    'sky/engine/bindings/exception_state.h',
    'sky/engine/core/script/dom_dart_state.h',
    'sky/engine/tonic/dart_converter.h',
    'sky/engine/tonic/dart_wrappable.h',
    'sky/engine/wtf/GetPtr.h',
    'sky/engine/wtf/RefPtr.h',
])

# TODO(terry): Rename genenerate_interface to interface_context.
def interface_context(interface):
    context = v8_interface.interface_context(interface)

    includes.clear()

    includes.update(INTERFACE_CPP_INCLUDES)
    header_includes = set(INTERFACE_H_INCLUDES)

    parent_interface = interface.parent
    if parent_interface:
        header_includes.update(dart_types.includes_for_interface(parent_interface))
    extended_attributes = interface.extended_attributes

    if inherits_interface(interface.name, 'EventTarget'):
        includes.update(['bindings/dart_event_listener.h'])

    # [SetWrapperReferenceTo]
    set_wrapper_reference_to_list = [{
        'name': argument.name,
        # FIXME: properly should be:
        # 'cpp_type': argument.idl_type.cpp_type_args(used_as_rvalue_type=True),
        # (if type is non-wrapper type like NodeFilter, normally RefPtr)
        # Raw pointers faster though, and NodeFilter hacky anyway.
        'cpp_type': argument.idl_type.implemented_as + '*',
        'idl_type': argument.idl_type,
    } for argument in extended_attributes.get('SetWrapperReferenceTo', [])]
    for set_wrapper_reference_to in set_wrapper_reference_to_list:
        set_wrapper_reference_to['idl_type'].add_includes_for_type()

    context.update({
        'cpp_class': DartUtilities.cpp_name(interface),
        'header_includes': header_includes,
         'set_wrapper_reference_to_list': set_wrapper_reference_to_list,
        'dart_class': dart_types.dart_type(interface.name),
    })

    # Constructors
    constructors = [constructor_context(interface, constructor)
                    for constructor in interface.constructors
                    # FIXME: shouldn't put named constructors with constructors
                    # (currently needed for Perl compatibility)
                    # Handle named constructors separately
                    if constructor.name == 'Constructor']
    if len(constructors) > 1:
        context.update({'constructor_overloads': overloads_context(constructors)})

    # [CustomConstructor]
    custom_constructors = [custom_constructor_context(interface, constructor)
                           for constructor in interface.custom_constructors]

    # [NamedConstructor]
    named_constructor = generate_named_constructor(interface)

    generate_method_native_entries(interface, constructors, 'Constructor')
    generate_method_native_entries(interface, custom_constructors, 'Constructor')
    if named_constructor:
        generate_method_native_entries(interface, [named_constructor],
                                       'Constructor')
    event_constructor = None
    if context['has_event_constructor']:
        event_constructor = {
            'native_entries': [
                DartUtilities.generate_native_entry(
                    interface.name, None, 'Constructor', False, 2)],
        }

    if (context['constructors'] or custom_constructors or context['has_event_constructor'] or
        named_constructor):
        includes.add('core/frame/LocalDOMWindow.h')

    context.update({
        'constructors': constructors,
        'custom_constructors': custom_constructors,
        'event_constructor': event_constructor,
        'has_custom_constructor': bool(custom_constructors),
        'interface_length':
            v8_interface.interface_length(interface, constructors + custom_constructors),
        'is_constructor_call_with_document': DartUtilities.has_extended_attribute_value(
            interface, 'ConstructorCallWith', 'Document'),  # [ConstructorCallWith=Document]
        'is_constructor_call_with_execution_context': DartUtilities.has_extended_attribute_value(
            interface, 'ConstructorCallWith', 'ExecutionContext'),  # [ConstructorCallWith=ExeuctionContext]
        'named_constructor': named_constructor,
    })

    # Attributes
    attributes = [dart_attributes.attribute_context(interface, attribute)
                  for attribute in interface.attributes
                      if not v8_attributes.is_constructor_attribute(attribute)]
    context.update({
        'attributes': attributes,
        'has_constructor_attributes': any(attribute['constructor_type'] for attribute in attributes),
        'has_replaceable_attributes': any(attribute['is_replaceable'] for attribute in attributes),
    })

    # Methods
    methods = [dart_methods.method_context(interface, method)
               for method in interface.operations
               # Skip anonymous special operations (methods name empty).
               if (method.name and
                   # detect unnamed getters from v8_interface.
                   method.name != 'anonymousNamedGetter')]
    compute_method_overloads_context(methods)
    for method in methods:
        method['do_generate_method_configuration'] = (
            # For overloaded methods, only generate one accessor
            ('overload_index' not in method or method['overload_index'] == 1))

    generate_method_native_entries(interface, methods, 'Method')

    context.update({
        'has_method_configuration': any(method['do_generate_method_configuration'] for method in methods),
        'methods': methods,
    })

    context.update({
        'indexed_property_getter': indexed_property_getter(interface),
        'indexed_property_setter': indexed_property_setter(interface),
        'indexed_property_deleter': v8_interface.indexed_property_deleter(interface),
        'is_override_builtins': 'OverrideBuiltins' in extended_attributes,
        'named_property_getter': named_property_getter(interface),
        'named_property_setter': named_property_setter(interface),
        'named_property_deleter': v8_interface.named_property_deleter(interface),
    })

    generate_native_entries_for_specials(interface, context)

    native_entries = generate_interface_native_entries(context)

    context.update({
        'native_entries': native_entries,
    })

    return context


def generate_interface_native_entries(context):
    entries = {}

    def add(ne):
        entries[ne['blink_entry']] = ne

    def addAll(nes):
        for ne in nes:
            add(ne)

    for constructor in context['constructors']:
        addAll(constructor['native_entries'])
    for constructor in context['custom_constructors']:
        addAll(constructor['native_entries'])
    if context['named_constructor']:
        addAll(context['named_constructor']['native_entries'])
    if context['event_constructor']:
        addAll(context['event_constructor']['native_entries'])
    for method in context['methods']:
        addAll(method['native_entries'])
    for attribute in context['attributes']:
        add(attribute['native_entry_getter'])
        if not attribute['is_read_only'] or attribute['put_forwards']:
            add(attribute['native_entry_setter'])
    if context['indexed_property_getter']:
        addAll(context['indexed_property_getter']['native_entries'])
    if context['indexed_property_setter']:
        addAll(context['indexed_property_setter']['native_entries'])
    if context['indexed_property_deleter']:
        addAll(context['indexed_property_deleter']['native_entries'])
    if context['named_property_getter']:
        addAll(context['named_property_getter']['native_entries'])
    if context['named_property_setter']:
        addAll(context['named_property_setter']['native_entries'])
    if context['named_property_deleter']:
        addAll(context['named_property_deleter']['native_entries'])
    return list(entries.values())


def generate_method_native_entry(interface, method, count, kind):
    name = method.get('name')
    is_static = bool(method.get('is_static'))
    native_entry = \
        DartUtilities.generate_native_entry(interface.name, name,
                                            kind, is_static, count)
    return native_entry


def generate_method_native_entries(interface, methods, kind):
    for method in methods:
        native_entries = []
        arg_count = method['number_of_arguments']
        native_entry = \
            generate_method_native_entry(interface, method, arg_count, kind)
        native_entries.append(native_entry)

        method.update({'native_entries': native_entries})


################################################################################
# Overloads
################################################################################

def compute_method_overloads_context(methods):
    # Regular methods
    compute_method_overloads_context_by_type([method for method in methods
                                              if not method['is_static']])
    # Static methods
    compute_method_overloads_context_by_type([method for method in methods
                                              if method['is_static']])


def compute_method_overloads_context_by_type(methods):
    """Computes |method.overload*| template values.

    Called separately for static and non-static (regular) methods,
    as these are overloaded separately.
    Modifies |method| in place for |method| in |methods|.
    Doesn't change the |methods| list itself (only the values, i.e. individual
    methods), so ok to treat these separately.
    """
    # Add overload information only to overloaded methods, so template code can
    # easily verify if a function is overloaded
    for name, overloads in v8_interface.method_overloads_by_name(methods):
        # Resolution function is generated after last overloaded function;
        # package necessary information into |method.overloads| for that method.
        overloads[-1]['overloads'] = overloads_context(overloads)
        overloads[-1]['overloads']['name'] = name


def overloads_context(overloads):
    """Returns |overloads| template values for a single name.

    Sets |method.overload_index| in place for |method| in |overloads|
    and returns dict of overall overload template values.
    """
    assert len(overloads) > 1  # only apply to overloaded names
    for index, method in enumerate(overloads, 1):
        method['overload_index'] = index

    effective_overloads_by_length = v8_interface.effective_overload_set_by_length(overloads)
    lengths = [length for length, _ in effective_overloads_by_length]
    name = overloads[0].get('name', '<constructor>')

    # Check and fail if all overloads with the shortest acceptable arguments
    # list are runtime enabled, since we would otherwise set 'length' on the
    # function object to an incorrect value when none of those overloads were
    # actually enabled at runtime. The exception is if all overloads are
    # controlled by the same runtime enabled feature, in which case there would
    # be no function object at all if it is not enabled.
    shortest_overloads = effective_overloads_by_length[0][1]

    return {
        'exposed_test_all': v8_interface.common_value(overloads, 'exposed_test'),  # [Exposed]
        'length_tests_methods': length_tests_methods(effective_overloads_by_length),
        # 1. Let maxarg be the length of the longest type list of the
        # entries in S.
        'maxarg': lengths[-1],
        'minarg': lengths[0],
        'valid_arities': lengths
            # Only need to report valid arities if there is a gap in the
            # sequence of possible lengths, otherwise invalid length means
            # "not enough arguments".
            if lengths[-1] - lengths[0] != len(lengths) - 1 else None,
    }


def length_tests_methods(effective_overloads_by_length):
    """Returns sorted list of resolution tests and associated methods, by length.

    This builds the main data structure for the overload resolution loop.
    For a given argument length, bindings test argument at distinguishing
    argument index, in order given by spec: if it is compatible with
    (optionality or) type required by an overloaded method, resolve to that
    method.

    Returns:
        [(length, [(test, method)])]
    """
    return [(length, list(resolution_tests_methods(effective_overloads)))
            for length, effective_overloads in effective_overloads_by_length]


DART_CHECK_TYPE = {
    'ArrayBufferView': 'Dart_IsTypedData({cpp_value})',
    'ArrayBuffer': 'Dart_IsByteBuffer({cpp_value})',
    'Uint8Array': 'Dart_GetTypeOfTypedData({cpp_value}) == Dart_TypedData_kUint8',
    'Uint8ClampedArray': 'Dart_GetTypeOfTypedData({cpp_value}) == Dart_TypedData_kUint8Clamped',
}


def resolution_tests_methods(effective_overloads):
    """Yields resolution test and associated method, in resolution order, for effective overloads of a given length.

    This is the heart of the resolution algorithm.
    http://heycam.github.io/webidl/#dfn-overload-resolution-algorithm

    Note that a given method can be listed multiple times, with different tests!
    This is to handle implicit type conversion.

    Returns:
        [(test, method)]
    """
    methods = [effective_overload[0]
               for effective_overload in effective_overloads]
    if len(methods) == 1:
        # If only one method with a given length, no test needed
        yield 'true', methods[0]
        return

    # 6. If there is more than one entry in S, then set d to be the
    # distinguishing argument index for the entries of S.
    index = v8_interface.distinguishing_argument_index(effective_overloads)
    # (7-9 are for handling |undefined| values for optional arguments before
    # the distinguishing argument (as "missing"), so you can specify only some
    # optional arguments. We don't support this, so we skip these steps.)
    # 10. If i = d, then:
    # (d is the distinguishing argument index)
    # 1. Let V be argi.
    #     Note: This is the argument that will be used to resolve which
    #           overload is selected.
    cpp_value = 'Dart_GetNativeArgument(args, %s + argOffset)' % index

    # Extract argument and IDL type to simplify accessing these in each loop.
    arguments = [method['arguments'][index] for method in methods]
    arguments_methods = zip(arguments, methods)
    idl_types = [argument['idl_type_object'] for argument in arguments]
    idl_types_methods = zip(idl_types, methods)

    # We can't do a single loop through all methods or simply sort them, because
    # a method may be listed in multiple steps of the resolution algorithm, and
    # which test to apply differs depending on the step.
    #
    # Instead, we need to go through all methods at each step, either finding
    # first match (if only one test is allowed) or filtering to matches (if
    # multiple tests are allowed), and generating an appropriate tests.

    # 2. If V is undefined, and there is an entry in S whose list of
    # optionality values has "optional" at index i, then remove from S all
    # other entries.
    try:
        method = next(method for argument, method in arguments_methods
                      if argument['is_optional'])
        test = 'Dart_IsNull(%s)' % cpp_value
        yield test, method
    except StopIteration:
        pass

    # 3. Otherwise: if V is null or undefined, and there is an entry in S that
    # has one of the following types at position i of its type list,
    # - a nullable type
    try:
        method = next(method for idl_type, method in idl_types_methods
                      if idl_type.is_nullable)
        test = 'Dart_IsNull(%s)' % cpp_value
        yield test, method
    except StopIteration:
        pass

    # 4. Otherwise: if V is a platform object - but not a platform array
    # object - and there is an entry in S that has one of the following
    # types at position i of its type list,
    # - an interface type that V implements
    # (Unlike most of these tests, this can return multiple methods, since we
    #  test if it implements an interface. Thus we need a for loop, not a next.)
    # (We distinguish wrapper types from built-in interface types.)
    for idl_type, method in ((idl_type, method)
                             for idl_type, method in idl_types_methods
                             if idl_type.is_wrapper_type):
        fmtstr = 'Dart{idl_type}::hasInstance({cpp_value})'
        if idl_type.base_type in DART_CHECK_TYPE:
            fmtstr = DART_CHECK_TYPE[idl_type.base_type]
        test = fmtstr.format(idl_type=idl_type.base_type, cpp_value=cpp_value)
        yield test, method

    # 8. Otherwise: if V is any kind of object except for a native Date object,
    # a native RegExp object, and there is an entry in S that has one of the
    # following types at position i of its type list,
    # - an array type
    # - a sequence type
    # ...
    # - a dictionary
    try:
        idl_type, method = next((idl_type, method)
                                for idl_type, method in idl_types_methods
                                if (idl_type.native_array_element_type))
        if idl_type.native_array_element_type:
            # (We test for Array instead of generic Object to type-check.)
            # FIXME: test for Object during resolution, then have type check for
            # Array in overloaded method: http://crbug.com/262383
            test = 'Dart_IsList(%s)' % cpp_value
        else:
            # FIXME: should be '{1}->IsObject() && !{1}->IsDate() && !{1}->IsRegExp()'.format(cpp_value)
            # FIXME: the IsDate and IsRegExp checks can be skipped if we've
            # already generated tests for them.
            test = 'Dart_IsInstance(%s)' % cpp_value
        yield test, method
    except StopIteration:
        pass

    # (Check for exact type matches before performing automatic type conversion;
    # only needed if distinguishing between primitive types.)
    if len([idl_type.is_primitive_type for idl_type in idl_types]) > 1:
        # (Only needed if match in step 11, otherwise redundant.)
        if any(idl_type.is_string_type or idl_type.is_enum
               for idl_type in idl_types):
            # 10. Otherwise: if V is a Number value, and there is an entry in S
            # that has one of the following types at position i of its type
            # list,
            # - a numeric type
            try:
                method = next(method for idl_type, method in idl_types_methods
                              if idl_type.is_numeric_type)
                test = 'Dart_IsNumber(%s)' % cpp_value
                yield test, method
            except StopIteration:
                pass

    # (Perform automatic type conversion, in order. If any of these match,
    # that's the end, and no other tests are needed.) To keep this code simple,
    # we rely on the C++ compiler's dead code elimination to deal with the
    # redundancy if both cases below trigger.

    # 11. Otherwise: if there is an entry in S that has one of the following
    # types at position i of its type list,
    # - DOMString
    # - ByteString
    # - ScalarValueString [a DOMString typedef, per definition.]
    # - an enumeration type
    try:
        method = next(method for idl_type, method in idl_types_methods
                      if idl_type.is_string_type or idl_type.is_enum)
        yield 'true', method
    except StopIteration:
        pass

    # 12. Otherwise: if there is an entry in S that has one of the following
    # types at position i of its type list,
    # - a numeric type
    try:
        method = next(method for idl_type, method in idl_types_methods
                      if idl_type.is_numeric_type)
        yield 'true', method
    except StopIteration:
        pass


################################################################################
# Constructors
################################################################################

# [Constructor]
def custom_constructor_context(interface, constructor):
    return {
        'arguments': [custom_constructor_argument(argument, index)
                      for index, argument in enumerate(constructor.arguments)],
        'auto_scope': 'true',
        'is_auto_scope': True,
        'is_call_with_script_arguments': False,
        'is_custom': True,
        'number_of_arguments': len(constructor.arguments),
        'number_of_required_arguments':
            v8_interface.number_of_required_arguments(constructor),
        }


# We don't need much from this - just the idl_type_objects and preproceed_type
# to use in generating the resolver strings.
def custom_constructor_argument(argument, index):
    return {
        'idl_type_object': argument.idl_type,
        'name': argument.name,
        'preprocessed_type': str(argument.idl_type.preprocessed_type),
    }


# [Constructor]
def constructor_context(interface, constructor):
    return {
        'arguments': [dart_methods.argument_context(interface, constructor, argument, index)
                      for index, argument in enumerate(constructor.arguments)],
        'auto_scope': 'true',
        'cpp_value': dart_methods.cpp_value(
            interface, constructor, len(constructor.arguments)),
        'has_exception_state':
            # [RaisesException=Constructor]
            interface.extended_attributes.get('RaisesException') == 'Constructor' or
            any(argument for argument in constructor.arguments
                if argument.idl_type.name == 'SerializedScriptValue' or
                   argument.idl_type.is_integer_type),
        'is_auto_scope': True,
        'is_call_with_script_arguments': False,
        'is_constructor': True,
        'is_custom': False,
        'is_variadic': False,  # Required for overload resolution
        'number_of_required_arguments':
            v8_interface.number_of_required_arguments(constructor),
        'number_of_arguments': len(constructor.arguments),
    }


# [NamedConstructor]
def generate_named_constructor(interface):
    extended_attributes = interface.extended_attributes
    if 'NamedConstructor' not in extended_attributes:
        return None
    # FIXME: parser should return named constructor separately;
    # included in constructors (and only name stored in extended attribute)
    # for Perl compatibility
    idl_constructor = interface.constructors[0]
    constructor = constructor_context(interface, idl_constructor)
    # FIXME(vsm): We drop the name. We don't use this in Dart APIs right now.
    # We probably need to encode this somehow to deal with conflicts.
    # constructor['name'] = extended_attributes['NamedConstructor']
    return constructor


################################################################################
# Special operations (methods)
# http://heycam.github.io/webidl/#idl-special-operations
################################################################################

def property_getter(getter, cpp_arguments):
    def is_null_expression(idl_type):
        if idl_type.is_union_type:
            return ' && '.join('!result%sEnabled' % i
                               for i, _ in enumerate(idl_type.member_types))
        if idl_type.name == 'String':
            # FIXME(vsm): This looks V8 specific.
            return 'result.isNull()'
        if idl_type.is_interface_type:
            return '!result'
        return ''

    context = v8_interface.property_getter(getter, [])

    idl_type = getter.idl_type
    extended_attributes = getter.extended_attributes
    is_raises_exception = 'RaisesException' in extended_attributes

    # FIXME: make more generic, so can use dart_methods.cpp_value
    cpp_method_name = 'receiver->%s' % DartUtilities.cpp_name(getter)

    if is_raises_exception:
        cpp_arguments.append('es')
    union_arguments = idl_type.union_arguments
    if union_arguments:
        cpp_arguments.extend([member_argument['cpp_value']
                              for member_argument in union_arguments])

    cpp_value = '%s(%s)' % (cpp_method_name, ', '.join(cpp_arguments))

    context.update({
        'cpp_type': idl_type.cpp_type,
        'cpp_value': cpp_value,
        'is_null_expression': is_null_expression(idl_type),
        'is_raises_exception': is_raises_exception,
        'name': DartUtilities.cpp_name(getter),
        'union_arguments': union_arguments,
        'dart_set_return_value': idl_type.dart_set_return_value('result',
                                                                extended_attributes=extended_attributes,
                                                                script_wrappable='receiver',
                                                                release=idl_type.release)})
    return context


def property_setter(setter):
    context = v8_interface.property_setter(setter)

    idl_type = setter.arguments[1].idl_type
    extended_attributes = setter.extended_attributes

    context.update({
        'dart_value_to_local_cpp_value': idl_type.dart_value_to_local_cpp_value(
            extended_attributes, 'propertyValue', False,
            context['has_type_checking_interface']),
    })

    return context


################################################################################
# Indexed properties
# http://heycam.github.io/webidl/#idl-indexed-properties
################################################################################

def indexed_property_getter(interface):
    try:
        # Find indexed property getter, if present; has form:
        # getter TYPE [OPTIONAL_IDENTIFIER](unsigned long ARG1)
        getter = next(
            method
            for method in interface.operations
            if ('getter' in method.specials and
                len(method.arguments) == 1 and
                str(method.arguments[0].idl_type) == 'unsigned long'))
    except StopIteration:
        return None

    getter.name = getter.name or 'anonymousIndexedGetter'

    return property_getter(getter, ['index'])


def indexed_property_setter(interface):
    try:
        # Find indexed property setter, if present; has form:
        # setter RETURN_TYPE [OPTIONAL_IDENTIFIER](unsigned long ARG1, ARG_TYPE ARG2)
        setter = next(
            method
            for method in interface.operations
            if ('setter' in method.specials and
                len(method.arguments) == 2 and
                str(method.arguments[0].idl_type) == 'unsigned long'))
    except StopIteration:
        return None

    return property_setter(setter)


################################################################################
# Named properties
# http://heycam.github.io/webidl/#idl-named-properties
################################################################################

def named_property_getter(interface):
    try:
        # Find named property getter, if present; has form:
        # getter TYPE [OPTIONAL_IDENTIFIER](DOMString ARG1)
        getter = next(
            method
            for method in interface.operations
            if ('getter' in method.specials and
                len(method.arguments) == 1 and
                str(method.arguments[0].idl_type) == 'DOMString'))
    except StopIteration:
        return None

    getter.name = getter.name or 'anonymousNamedGetter'

    return property_getter(getter, ['propertyName'])


def named_property_setter(interface):
    try:
        # Find named property setter, if present; has form:
        # setter RETURN_TYPE [OPTIONAL_IDENTIFIER](DOMString ARG1, ARG_TYPE ARG2)
        setter = next(
            method
            for method in interface.operations
            if ('setter' in method.specials and
                len(method.arguments) == 2 and
                str(method.arguments[0].idl_type) == 'DOMString'))
    except StopIteration:
        return None

    return property_setter(setter)


def generate_native_entries_for_specials(interface, context):
    def add(prop, name, arity):
        if context[prop]:
            if 'native_entries' not in context[prop]:
                context[prop].update({'native_entries': []})
            context[prop]['native_entries'].append(
                DartUtilities.generate_native_entry(
                    interface.name, name, 'Method', False, arity))

    pre = ['indexed_property', 'named_property']
    post = [('setter', '__setter__', 2),
            ('getter', '__getter__', 1),
            ('deleter', '__delete__', 1),
          ]
    props = [(p1 + "_" + p2, name, arity)
             for (p1, (p2, name, arity)) in itertools.product(pre, post)]
    for t in props:
        add(*t)

    for (p, name, arity) in props:
        if context[p]:
            if context[p].get('is_custom_property_query'):
                add(p, '__propertyQuery__', 1)
