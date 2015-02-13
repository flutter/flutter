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

"""Generate template values for methods.

Extends IdlType and IdlUnionType with property |union_arguments|.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

from idl_types import inherits_interface
import dart_types
from dart_utilities import DartUtilities
from v8_globals import includes

import v8_methods


def method_context(interface, method):
    context = v8_methods.method_context(interface, method)

    arguments = method.arguments
    extended_attributes = method.extended_attributes
    idl_type = method.idl_type

#    idl_type.add_includes_for_type()
    this_cpp_value = cpp_value(interface, method, len(arguments))

    if context['is_call_with_script_state']:
        includes.add('bindings/core/dart/DartScriptState.h')

    if idl_type.union_arguments and len(idl_type.union_arguments) > 0:
        this_cpp_type = []
        for cpp_type in idl_type.member_types:
            this_cpp_type.append("RefPtr<%s>" % cpp_type)
    else:
        this_cpp_type = idl_type.cpp_type

    is_auto_scope = not 'DartNoAutoScope' in extended_attributes

    arguments_data = [argument_context(interface, method, argument, index)
                      for index, argument in enumerate(arguments)]

    union_arguments = []
    if idl_type.union_arguments:
        union_arguments.extend([union_arg['cpp_value']
                                for union_arg in idl_type.union_arguments])

    is_custom = 'Custom' in extended_attributes or 'DartCustom' in extended_attributes

    context.update({
        'arguments': arguments_data,
        'cpp_type': this_cpp_type,
        'cpp_value': this_cpp_value,
        'dart_type': dart_types.idl_type_to_dart_type(idl_type),
        'dart_name': extended_attributes.get('DartName'),
        'has_exception_state':
            context['is_raises_exception'] or
            any(argument for argument in arguments
                if argument.idl_type.name == 'SerializedScriptValue' or
                   argument.idl_type.is_integer_type),
        'is_auto_scope': is_auto_scope,
        'auto_scope': DartUtilities.bool_to_cpp(is_auto_scope),
        'is_custom': is_custom,
        'is_custom_dart': 'DartCustom' in extended_attributes,
        'is_custom_dart_new': DartUtilities.has_extended_attribute_value(method, 'DartCustom', 'New'),
        # FIXME(terry): DartStrictTypeChecking no longer supported; TypeChecking is
        #               new extended attribute.
        'is_strict_type_checking':
            'DartStrictTypeChecking' in extended_attributes or
            'DartStrictTypeChecking' in interface.extended_attributes,
        'union_arguments': union_arguments,
        'dart_set_return_value': dart_set_return_value(interface.name, method, this_cpp_value),
    })
    return context

def argument_context(interface, method, argument, index):
    context = v8_methods.argument_context(interface, method, argument, index)

    extended_attributes = argument.extended_attributes
    idl_type = argument.idl_type
    this_cpp_value = cpp_value(interface, method, index)
    auto_scope = not 'DartNoAutoScope' in extended_attributes
    arg_index = index + 1 if not (method.is_static or method.is_constructor) else index
    preprocessed_type = str(idl_type.preprocessed_type)
    local_cpp_type = idl_type.cpp_type_args(argument.extended_attributes, raw_type=True)
    default_value = argument.default_cpp_value
    if context['has_default']:
        default_value = (argument.default_cpp_value or
            dart_types.default_cpp_value_for_cpp_type(idl_type))
    dart_type = dart_types.idl_type_to_dart_type(idl_type)
    dart_default_value = dart_types.dart_default_value(dart_type, argument)
    context.update({
        'cpp_type': idl_type.cpp_type_args(extended_attributes=extended_attributes,
                                           raw_type=True,
                                           used_in_cpp_sequence=False),
        'dart_type': dart_type,
        'implemented_as': idl_type.implemented_as,
        'cpp_value': this_cpp_value,
        'local_cpp_type': local_cpp_type,
        # FIXME: check that the default value's type is compatible with the argument's
        'default_value': default_value,
        'dart_default_value': dart_default_value,
        'enum_validation_expression': idl_type.enum_validation_expression,
        'preprocessed_type': preprocessed_type,
        'is_array_or_sequence_type': not not idl_type.native_array_element_type,
        'is_strict_type_checking': 'DartStrictTypeChecking' in extended_attributes,
        'dart_set_return_value_for_main_world': dart_set_return_value(interface.name, method,
                                                                      this_cpp_value, for_main_world=True),
        'dart_set_return_value': dart_set_return_value(interface.name, method, this_cpp_value),
        'arg_index': arg_index,
        'dart_value_to_local_cpp_value': dart_value_to_local_cpp_value(interface,
                                                                       context['has_type_checking_interface'],
                                                                       argument, arg_index, auto_scope),
    })
    return context


################################################################################
# Value handling
################################################################################

def cpp_value(interface, method, number_of_arguments):
    def cpp_argument(argument):
        argument_name = dart_types.check_reserved_name(argument.name)
        idl_type = argument.idl_type

        if idl_type.is_typed_array_type:
            return '%s.get()' % argument_name

        if idl_type.name == 'EventListener':
            if (interface.name == 'EventTarget' and
                method.name == 'removeEventListener'):
                # FIXME: remove this special case by moving get() into
                # EventTarget::removeEventListener
                return '%s.get()' % argument_name
            return argument.name
        if (idl_type.is_callback_interface or
            idl_type.name in ['NodeFilter', 'XPathNSResolver']):
            # FIXME: remove this special case
            return '%s.release()' % argument_name
        return argument_name

    # Truncate omitted optional arguments
    arguments = method.arguments[:number_of_arguments]
    if method.is_constructor:
        call_with_values = interface.extended_attributes.get('ConstructorCallWith')
    else:
        call_with_values = method.extended_attributes.get('CallWith')
    cpp_arguments = DartUtilities.call_with_arguments(call_with_values)
    if ('PartialInterfaceImplementedAs' in method.extended_attributes and not method.is_static):
        cpp_arguments.append('*receiver')

    cpp_arguments.extend(cpp_argument(argument) for argument in arguments)
    this_union_arguments = method.idl_type and method.idl_type.union_arguments
    if this_union_arguments:
        cpp_arguments.extend([member_argument['cpp_value']
                              for member_argument in this_union_arguments])

    if ('RaisesException' in method.extended_attributes or
        (method.is_constructor and
         DartUtilities.has_extended_attribute_value(interface, 'RaisesException', 'Constructor'))):
        cpp_arguments.append('es')

    if method.name == 'Constructor':
        base_name = 'create'
    elif method.name == 'NamedConstructor':
        base_name = 'createForJSConstructor'
    else:
        base_name = DartUtilities.cpp_name(method)
    cpp_method_name = DartUtilities.scoped_name(interface, method, base_name)
    return '%s(%s)' % (cpp_method_name, ', '.join(cpp_arguments))


def dart_set_return_value(interface_name, method, cpp_value, for_main_world=False):
    idl_type = method.idl_type
    extended_attributes = method.extended_attributes
    if not idl_type or idl_type.name == 'void':
        # Constructors and void methods don't have a return type
        return None

    release = False

    if idl_type.is_union_type:
        release = idl_type.release

    # [CallWith=ScriptState], [RaisesException]
# TODO(terry): Disable ScriptState temporarily need to handle.
#    if (has_extended_attribute_value(method, 'CallWith', 'ScriptState') or
#        'RaisesException' in extended_attributes or
#        idl_type.is_union_type):
#        cpp_value = 'result'  # use local variable for value
#        release = idl_type.release

    auto_scope = not 'DartNoAutoScope' in extended_attributes
    script_wrappable = 'impl' if inherits_interface(interface_name, 'Node') else ''
    return idl_type.dart_set_return_value(cpp_value, extended_attributes,
                                          script_wrappable=script_wrappable,
                                          release=release,
                                          for_main_world=for_main_world,
                                          auto_scope=auto_scope)


def dart_value_to_local_cpp_value(interface, has_type_checking_interface,
                                  argument, index, auto_scope=True):
    extended_attributes = argument.extended_attributes
    idl_type = argument.idl_type
    name = argument.name

    # FIXME: V8 has some special logic around the addEventListener and
    # removeEventListener methods that should be added in somewhere.
    # There is also some logic in systemnative.py to force a null check
    # for the useCapture argument of those same methods that we may need to
    # pull over.
    null_check = ((argument.is_optional and idl_type.is_callback_interface) or
                  (argument.default_value and argument.default_value.is_null))

    return idl_type.dart_value_to_local_cpp_value(
        extended_attributes, name, null_check, has_type_checking_interface,
        index=index, auto_scope=auto_scope)
