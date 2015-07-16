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

"""Generate template values for a callback interface.

Extends IdlType with property |callback_cpp_type|.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

from idl_types import IdlType, IdlTypeBase
import dart_types
from dart_utilities import DartUtilities
from v8_globals import includes

CALLBACK_INTERFACE_H_INCLUDES = frozenset([
    'bindings/dart_callback.h',
])

CALLBACK_INTERFACE_CPP_INCLUDES = frozenset([
    'wtf/GetPtr.h',
    'wtf/RefPtr.h',
])

def cpp_type(idl_type):
    # FIXME: remove this function by making callback types consistent
    # (always use usual v8_types.cpp_type)
    idl_type_name = idl_type.name
    if idl_type_name == 'String':
        return 'const String&'
    if idl_type_name == 'void':
        return 'void'
    # Callbacks use raw pointers, so raw_type=True
    usual_cpp_type = idl_type.cpp_type_args(raw_type=True)
    if usual_cpp_type.startswith(('Vector', 'HeapVector', 'WillBeHeapVector')):
        return 'const %s&' % usual_cpp_type
    return usual_cpp_type

IdlTypeBase.callback_cpp_type = property(cpp_type)


def generate_callback_interface(callback_interface):
    includes.clear()
    includes.update(CALLBACK_INTERFACE_CPP_INCLUDES)
    name = callback_interface.name

    methods = [generate_method(operation)
               for operation in callback_interface.operations]
    template_contents = {
        'cpp_class': name,
        'dart_class': dart_types.dart_type(callback_interface.name),
        'header_includes': set(CALLBACK_INTERFACE_H_INCLUDES),
        'methods': methods,
    }
    return template_contents


def add_includes_for_operation(operation):
    operation.idl_type.add_includes_for_type()
    for argument in operation.arguments:
        argument.idl_type.add_includes_for_type()


def generate_method(operation):
    extended_attributes = operation.extended_attributes
    idl_type = operation.idl_type
    idl_type_str = str(idl_type)
    if idl_type_str not in ['boolean', 'void']:
        raise Exception('We only support callbacks that return boolean or void values.')
    is_custom = 'Custom' in extended_attributes
    if not is_custom:
        add_includes_for_operation(operation)
    call_with = extended_attributes.get('CallWith')
    call_with_this_handle = DartUtilities.extended_attribute_value_contains(call_with, 'ThisValue')
    contents = {
        'call_with_this_handle': call_with_this_handle,
        'cpp_type': idl_type.callback_cpp_type,
        'custom': is_custom,
        'idl_type': idl_type_str,
        'name': operation.name,
    }
    contents.update(generate_arguments_contents(operation.arguments, call_with_this_handle))
    return contents


def generate_arguments_contents(arguments, call_with_this_handle):
    def generate_argument(argument):
        creation_context = ''
        if argument.idl_type.native_array_element_type is not None:
            creation_context = '<Dart%s>' % argument.idl_type.native_array_element_type
        return {
            'handle': '%sHandle' % argument.name,
            'cpp_value_to_dart_value': argument.idl_type.cpp_value_to_dart_value(argument.name,
                                                                                 creation_context=creation_context),
        }

    argument_declarations = [
            '%s %s' % (argument.idl_type.callback_cpp_type, argument.name)
            for argument in arguments]
    if call_with_this_handle:
        argument_declarations.insert(0, 'ScriptValue thisValue')

    dart_argument_declarations = [
            '%s %s' % (dart_types.idl_type_to_dart_type(argument.idl_type), argument.name)
            for argument in arguments]
    return  {
        'argument_declarations': argument_declarations,
        'dart_argument_declarations': dart_argument_declarations,
        'arguments': [generate_argument(argument) for argument in arguments],
    }
