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

Extends IdlArgument with property |default_cpp_value|.
Extends IdlTypeBase and IdlUnionType with property |union_arguments|.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

from idl_definitions import IdlArgument
from idl_types import IdlTypeBase, IdlUnionType, inherits_interface
from v8_globals import includes
import v8_types
import v8_utilities
from v8_utilities import has_extended_attribute_value


# Methods with any of these require custom method registration code in the
# interface's configure*Template() function.
CUSTOM_REGISTRATION_EXTENDED_ATTRIBUTES = frozenset([
    'NotEnumerable',
])


def argument_needs_try_catch(method, argument):
    return_promise = method.idl_type and method.idl_type.name == 'Promise'
    idl_type = argument.idl_type
    base_type = idl_type.base_type

    return not(
        # These cases are handled by separate code paths in the
        # generate_argument() macro in engine/bindings/templates/methods.cpp.
        idl_type.is_callback_interface or
        base_type == 'SerializedScriptValue' or
        (argument.is_variadic and idl_type.is_wrapper_type) or
        # String and enumeration arguments converted using one of the
        # TOSTRING_* macros except for _PROMISE variants in
        # engine/bindings/core/v8/V8BindingMacros.h don't use a v8::TryCatch.
        ((base_type == 'DOMString' or idl_type.is_enum) and
         not argument.is_variadic and
         not return_promise))


def use_local_result(method):
    extended_attributes = method.extended_attributes
    idl_type = method.idl_type
    return (has_extended_attribute_value(method, 'CallWith', 'ScriptState') or
            'RaisesException' in extended_attributes or
            idl_type.is_union_type or
            idl_type.is_explicit_nullable)


def method_context(interface, method):
    arguments = method.arguments
    extended_attributes = method.extended_attributes
    idl_type = method.idl_type
    is_static = method.is_static
    name = method.name

    idl_type.add_includes_for_type()
    this_cpp_value = cpp_value(interface, method, len(arguments))

    def function_template():
        if is_static:
            return 'functionTemplate'
        return 'prototypeTemplate'

    is_call_with_script_arguments = has_extended_attribute_value(method, 'CallWith', 'ScriptArguments')
    if is_call_with_script_arguments:
        includes.update(['bindings/core/v8/ScriptCallStackFactory.h',
                         'core/inspector/ScriptArguments.h'])
    is_call_with_script_state = has_extended_attribute_value(method, 'CallWith', 'ScriptState')
    if is_call_with_script_state:
        includes.add('bindings/core/v8/ScriptState.h')
    is_custom_element_callbacks = 'CustomElementCallbacks' in extended_attributes
    if is_custom_element_callbacks:
        includes.add('sky/engine/core/dom/custom/custom_element_callback_scope.h')

    is_raises_exception = 'RaisesException' in extended_attributes

    arguments_need_try_catch = (
        any(argument_needs_try_catch(method, argument)
            for argument in arguments))

    return {
        'arguments': [argument_context(interface, method, argument, index)
                      for index, argument in enumerate(arguments)],
        'arguments_need_try_catch': arguments_need_try_catch,
        'cpp_type': (v8_types.cpp_template_type('Nullable', idl_type.cpp_type)
                     if idl_type.is_explicit_nullable else idl_type.cpp_type),
        'cpp_value': this_cpp_value,
        'cpp_type_initializer': idl_type.cpp_type_initializer,
        'custom_registration_extended_attributes':
            CUSTOM_REGISTRATION_EXTENDED_ATTRIBUTES.intersection(
                extended_attributes.iterkeys()),
        'exposed_test': v8_utilities.exposed(method, interface),  # [Exposed]
        'function_template': function_template(),
        'has_custom_registration': is_static or
            v8_utilities.has_extended_attribute(
                method, CUSTOM_REGISTRATION_EXTENDED_ATTRIBUTES),
        'has_exception_state':
            is_raises_exception or
            any(argument for argument in arguments
                if argument.idl_type.name == 'SerializedScriptValue' or
                   argument.idl_type.may_raise_exception_on_conversion),
        'idl_type': idl_type.base_type,
        'is_call_with_execution_context': has_extended_attribute_value(method, 'CallWith', 'ExecutionContext'),
        'is_call_with_script_arguments': is_call_with_script_arguments,
        'is_call_with_script_state': is_call_with_script_state,
        'is_custom': 'Custom' in extended_attributes,
        'is_custom_element_callbacks': is_custom_element_callbacks,
        'is_explicit_nullable': idl_type.is_explicit_nullable,
        'is_partial_interface_member':
            'PartialInterfaceImplementedAs' in extended_attributes,
        'is_raises_exception': is_raises_exception,
        'is_static': is_static,
        'is_variadic': arguments and arguments[-1].is_variadic,
        'name': name,
        'number_of_arguments': len(arguments),
        'number_of_required_arguments': len([
            argument for argument in arguments
            if not (argument.is_optional or argument.is_variadic)]),
        'number_of_required_or_variadic_arguments': len([
            argument for argument in arguments
            if not argument.is_optional]),
        'union_arguments': idl_type.union_arguments,
        'use_local_result': use_local_result(method),
    }


def argument_context(interface, method, argument, index):
    extended_attributes = argument.extended_attributes
    idl_type = argument.idl_type
    this_cpp_value = cpp_value(interface, method, index)
    return_promise = (method.idl_type.name == 'Promise' if method.idl_type
                                                        else False)

    default_cpp_value = argument.default_cpp_value
    return {
        'cpp_type': idl_type.cpp_type_args(extended_attributes=extended_attributes,
                                           raw_type=True,
                                           used_as_variadic_argument=argument.is_variadic),
        'cpp_value': this_cpp_value,
        # FIXME: check that the default value's type is compatible with the argument's
        'default_value': default_cpp_value,
        'enum_validation_expression': idl_type.enum_validation_expression,
        'handle': '%sHandle' % argument.name,
        # FIXME: remove once [Default] removed and just use argument.default_value
        'has_default': 'Default' in extended_attributes or default_cpp_value,
        'has_type_checking_interface':
            (has_extended_attribute_value(interface, 'TypeChecking', 'Interface') or
             has_extended_attribute_value(method, 'TypeChecking', 'Interface')) and
            idl_type.is_wrapper_type,
        'has_type_checking_unrestricted':
            (has_extended_attribute_value(interface, 'TypeChecking', 'Unrestricted') or
             has_extended_attribute_value(method, 'TypeChecking', 'Unrestricted')) and
            idl_type.name in ('Float', 'Double'),
        'idl_type': idl_type.base_type,
        'idl_type_object': idl_type,
        'index': index,
        'is_callback_interface': idl_type.is_callback_interface,
        'is_nullable': idl_type.is_nullable,
        'is_optional': argument.is_optional,
        'is_wrapper_type': idl_type.is_wrapper_type,
        'name': argument.name,
    }


################################################################################
# Value handling
################################################################################

def cpp_value(interface, method, number_of_arguments):
    def cpp_argument(argument):
        idl_type = argument.idl_type
        if idl_type.name == 'EventListener':
            return argument.name
        if (idl_type.is_callback_interface or
            idl_type.name in ['NodeFilter', 'NodeFilterOrNull']):
            # FIXME: remove this special case
            return '%s.release()' % argument.name
        return argument.name

    # Truncate omitted optional arguments
    arguments = method.arguments[:number_of_arguments]
    cpp_arguments = []

    if method.is_constructor:
        call_with_values = interface.extended_attributes.get('ConstructorCallWith')
    else:
        call_with_values = method.extended_attributes.get('CallWith')
    cpp_arguments.extend(v8_utilities.call_with_arguments(call_with_values))

    # Members of IDL partial interface definitions are implemented in C++ as
    # static member functions, which for instance members (non-static members)
    # take *impl as their first argument
    if ('PartialInterfaceImplementedAs' in method.extended_attributes and
        not method.is_static):
        cpp_arguments.append('*impl')
    cpp_arguments.extend(cpp_argument(argument) for argument in arguments)

    this_union_arguments = method.idl_type and method.idl_type.union_arguments
    if this_union_arguments:
        cpp_arguments.extend([member_argument['cpp_value']
                              for member_argument in this_union_arguments])

    if ('RaisesException' in method.extended_attributes or
        (method.is_constructor and
         has_extended_attribute_value(interface, 'RaisesException', 'Constructor'))):
        cpp_arguments.append('exceptionState')

    if method.name == 'Constructor':
        base_name = 'create'
    elif method.name == 'NamedConstructor':
        base_name = 'createForJSConstructor'
    else:
        base_name = v8_utilities.cpp_name(method)

    cpp_method_name = v8_utilities.scoped_name(interface, method, base_name)
    return '%s(%s)' % (cpp_method_name, ', '.join(cpp_arguments))


def v8_value_to_local_cpp_variadic_value(argument, index, return_promise):
    assert argument.is_variadic
    idl_type = argument.idl_type

    suffix = ''

    macro = 'TONATIVE_VOID'
    macro_args = [
      argument.name,
      'toNativeArguments<%s>(info, %s)' % (idl_type.cpp_type, index),
    ]

    if return_promise:
        suffix += '_PROMISE'
        macro_args.append('info')

    suffix += '_INTERNAL'

    return '%s%s(%s)' % (macro, suffix, ', '.join(macro_args))


def v8_value_to_local_cpp_value(argument, index, return_promise=False):
    extended_attributes = argument.extended_attributes
    idl_type = argument.idl_type
    name = argument.name
    if argument.is_variadic:
        return v8_value_to_local_cpp_variadic_value(argument, index, return_promise)
    return idl_type.v8_value_to_local_cpp_value(extended_attributes, 'info[%s]' % index,
                                                name, index=index, declare_variable=False, return_promise=return_promise)


################################################################################
# Auxiliary functions
################################################################################

def union_member_argument_context(idl_type, index):
    """Returns a context of union member for argument."""
    this_cpp_value = 'result%d' % index
    this_cpp_type = idl_type.cpp_type
    this_cpp_type_initializer = idl_type.cpp_type_initializer
    cpp_return_value = this_cpp_value

    if not idl_type.cpp_type_has_null_value:
        this_cpp_type = v8_types.cpp_template_type('Nullable', this_cpp_type)
        this_cpp_type_initializer = ''
        cpp_return_value = '%s.get()' % this_cpp_value

    if idl_type.is_string_type:
        null_check_value = '!%s.isNull()' % this_cpp_value
    else:
        null_check_value = this_cpp_value

    return {
        'cpp_type': this_cpp_type,
        'cpp_type_initializer': this_cpp_type_initializer,
        'cpp_value': this_cpp_value,
        'null_check_value': null_check_value,
    }


def union_arguments(idl_type):
    return [union_member_argument_context(member_idl_type, index)
            for index, member_idl_type
            in enumerate(idl_type.member_types)]


def argument_default_cpp_value(argument):
    if not argument.default_value:
        return None
    return argument.idl_type.literal_cpp_value(argument.default_value)

IdlTypeBase.union_arguments = None
IdlUnionType.union_arguments = property(union_arguments)
IdlArgument.default_cpp_value = property(argument_default_cpp_value)
