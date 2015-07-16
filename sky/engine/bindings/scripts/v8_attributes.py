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

"""Generate template values for attributes.

Extends IdlType with property |constructor_type_name|.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

import idl_types
from idl_types import inherits_interface
from v8_globals import includes, interfaces
import v8_types
import v8_utilities
from v8_utilities import (capitalize, cpp_name, has_extended_attribute,
                          has_extended_attribute_value, scoped_name, strip_suffix,
                          uncapitalize, extended_attribute_value_as_list)


def attribute_context(interface, attribute):
    idl_type = attribute.idl_type
    base_idl_type = idl_type.base_type
    extended_attributes = attribute.extended_attributes

    idl_type.add_includes_for_type()

    # [CustomElementCallbacks], [Reflect]
    is_custom_element_callbacks = 'CustomElementCallbacks' in extended_attributes
    is_reflect = 'Reflect' in extended_attributes
    if is_custom_element_callbacks or is_reflect:
        includes.add('sky/engine/core/dom/custom/custom_element_callback_scope.h')
    # [TypeChecking]
    has_type_checking_unrestricted = (
        (has_extended_attribute_value(interface, 'TypeChecking', 'Unrestricted') or
         has_extended_attribute_value(attribute, 'TypeChecking', 'Unrestricted')) and
         idl_type.name in ('Float', 'Double'))

    if (base_idl_type == 'EventHandler' and
        interface.name in ['Window'] and
        attribute.name == 'onerror'):
        includes.add('bindings/core/v8/V8ErrorHandler.h')

    context = {
        'argument_cpp_type': idl_type.cpp_type_args(used_as_rvalue_type=True),
        'cached_attribute_validation_method': extended_attributes.get('CachedAttribute'),
        'constructor_type': idl_type.constructor_type_name
                            if is_constructor_attribute(attribute) else None,
        'cpp_name': cpp_name(attribute),
        'cpp_type': idl_type.cpp_type,
        'cpp_type_initializer': idl_type.cpp_type_initializer,
        'enum_validation_expression': idl_type.enum_validation_expression,
        'exposed_test': v8_utilities.exposed(attribute, interface),  # [Exposed]
        'has_custom_getter': has_custom_getter(attribute),
        'has_custom_setter': has_custom_setter(attribute),
        'has_type_checking_unrestricted': has_type_checking_unrestricted,
        'idl_type': str(idl_type),  # need trailing [] on array for Dictionary::ConversionContext::setConversionType
        'is_call_with_execution_context': v8_utilities.has_extended_attribute_value(attribute, 'CallWith', 'ExecutionContext'),
        'is_call_with_script_state': v8_utilities.has_extended_attribute_value(attribute, 'CallWith', 'ScriptState'),
        'is_custom_element_callbacks': is_custom_element_callbacks,
        'is_getter_raises_exception':  # [RaisesException]
            'RaisesException' in extended_attributes and
            extended_attributes['RaisesException'] in (None, 'Getter'),
        'is_initialized_by_event_constructor':
            'InitializedByEventConstructor' in extended_attributes,
        'is_keep_alive_for_gc': is_keep_alive_for_gc(interface, attribute),
        'is_nullable': idl_type.is_nullable,
        'is_explicit_nullable': idl_type.is_explicit_nullable,
        'is_partial_interface_member':
            'PartialInterfaceImplementedAs' in extended_attributes,
        'is_read_only': attribute.is_read_only,
        'is_reflect': is_reflect,
        'is_replaceable': 'Replaceable' in attribute.extended_attributes,
        'is_static': attribute.is_static,
        'is_url': 'URL' in extended_attributes,
        'name': attribute.name,
        'put_forwards': 'PutForwards' in extended_attributes,
        'reflect_empty': extended_attributes.get('ReflectEmpty'),
        'reflect_invalid': extended_attributes.get('ReflectInvalid', ''),
        'reflect_missing': extended_attributes.get('ReflectMissing'),
        'reflect_only': extended_attribute_value_as_list(attribute, 'ReflectOnly'),
        'setter_callback': setter_callback_name(interface, attribute),
    }

    if is_constructor_attribute(attribute):
        constructor_getter_context(interface, attribute, context)
        return context
    if not has_custom_getter(attribute):
        getter_context(interface, attribute, context)
    if (not has_custom_setter(attribute) and
        (not attribute.is_read_only or 'PutForwards' in extended_attributes)):
        setter_context(interface, attribute, context)

    return context


################################################################################
# Getter
################################################################################

def getter_context(interface, attribute, context):
    cpp_value = getter_expression(interface, attribute, context)

    context.update({
        'cpp_value': cpp_value,
    })


def getter_expression(interface, attribute, context):
    arguments = []
    this_getter_base_name = getter_base_name(interface, attribute, arguments)
    getter_name = scoped_name(interface, attribute, this_getter_base_name)

    arguments.extend(v8_utilities.call_with_arguments(
        attribute.extended_attributes.get('CallWith')))
    # Members of IDL partial interface definitions are implemented in C++ as
    # static member functions, which for instance members (non-static members)
    # take *impl as their first argument
    if ('PartialInterfaceImplementedAs' in attribute.extended_attributes and
        not attribute.is_static):
        arguments.append('*impl')
    if attribute.idl_type.is_explicit_nullable:
        arguments.append('isNull')
    if context['is_getter_raises_exception']:
        arguments.append('exceptionState')
    return '%s(%s)' % (getter_name, ', '.join(arguments))


CONTENT_ATTRIBUTE_GETTER_NAMES = {
    'boolean': 'hasAttribute',
    'long': 'getIntegralAttribute',
    'unsigned long': 'getUnsignedIntegralAttribute',
}


def getter_base_name(interface, attribute, arguments):
    extended_attributes = attribute.extended_attributes

    if 'Reflect' not in extended_attributes:
        return uncapitalize(cpp_name(attribute))

    content_attribute_name = extended_attributes['Reflect'] or attribute.name.lower()
    if content_attribute_name in ['class', 'id']:
        # Special-case for performance optimization.
        return 'get%sAttribute' % content_attribute_name.capitalize()

    arguments.append(scoped_content_attribute_name(interface, attribute))

    base_idl_type = attribute.idl_type.base_type
    if base_idl_type in CONTENT_ATTRIBUTE_GETTER_NAMES:
        return CONTENT_ATTRIBUTE_GETTER_NAMES[base_idl_type]
    if 'URL' in attribute.extended_attributes:
        return 'getURLAttribute'
    return 'getAttribute'


def is_keep_alive_for_gc(interface, attribute):
    idl_type = attribute.idl_type
    base_idl_type = idl_type.base_type
    extended_attributes = attribute.extended_attributes
    return (
        # For readonly attributes, for performance reasons we keep the attribute
        # wrapper alive while the owner wrapper is alive, because the attribute
        # never changes.
        (attribute.is_read_only and
         idl_type.is_wrapper_type and
         # There are some exceptions, however:
         not(
             # Node lifetime is managed by object grouping.
             inherits_interface(interface.name, 'Node') or
             inherits_interface(base_idl_type, 'Node') or
             # A self-reference is unnecessary.
             attribute.name == 'self' or
             # FIXME: Remove these hard-coded hacks.
             base_idl_type in ['EventTarget', 'Window'] or
             base_idl_type.startswith('HTML'))))


################################################################################
# Setter
################################################################################

def setter_context(interface, attribute, context):
    if 'PutForwards' in attribute.extended_attributes:
        # Use target interface and attribute in place of original interface and
        # attribute from this point onwards.
        target_interface_name = attribute.idl_type.base_type
        target_attribute_name = attribute.extended_attributes['PutForwards']
        interface = interfaces[target_interface_name]
        try:
            attribute = next(candidate
                             for candidate in interface.attributes
                             if candidate.name == target_attribute_name)
        except StopIteration:
            raise Exception('[PutForward] target not found:\n'
                            'Attribute "%s" is not present in interface "%s"' %
                            (target_attribute_name, target_interface_name))

    extended_attributes = attribute.extended_attributes
    idl_type = attribute.idl_type

    # [RaisesException], [RaisesException=Setter]
    is_setter_raises_exception = (
        'RaisesException' in extended_attributes and
        extended_attributes['RaisesException'] in [None, 'Setter'])
    # [TypeChecking=Interface]
    has_type_checking_interface = (
        (has_extended_attribute_value(interface, 'TypeChecking', 'Interface') or
         has_extended_attribute_value(attribute, 'TypeChecking', 'Interface')) and
        idl_type.is_wrapper_type)

    context.update({
        'has_setter_exception_state':
            is_setter_raises_exception or has_type_checking_interface or
            context['has_type_checking_unrestricted'] or
            idl_type.may_raise_exception_on_conversion,
        'has_type_checking_interface': has_type_checking_interface,
        'is_setter_call_with_execution_context': v8_utilities.has_extended_attribute_value(
            attribute, 'SetterCallWith', 'ExecutionContext'),
        'is_setter_raises_exception': is_setter_raises_exception,
    })


CONTENT_ATTRIBUTE_SETTER_NAMES = {
    'boolean': 'setBooleanAttribute',
    'long': 'setIntegralAttribute',
    'unsigned long': 'setUnsignedIntegralAttribute',
}


def setter_base_name(interface, attribute, arguments):
    if 'Reflect' not in attribute.extended_attributes:
        return 'set%s' % capitalize(cpp_name(attribute))
    arguments.append(scoped_content_attribute_name(interface, attribute))

    base_idl_type = attribute.idl_type.base_type
    if base_idl_type in CONTENT_ATTRIBUTE_SETTER_NAMES:
        return CONTENT_ATTRIBUTE_SETTER_NAMES[base_idl_type]
    return 'setAttribute'


def scoped_content_attribute_name(interface, attribute):
    content_attribute_name = attribute.extended_attributes['Reflect'] or attribute.name.lower()
    namespace = 'HTMLNames'
    includes.add('gen/sky/core/%s.h' % namespace)
    return '%s::%sAttr' % (namespace, content_attribute_name)


################################################################################
# Attribute configuration
################################################################################

# [Replaceable]
def setter_callback_name(interface, attribute):
    cpp_class_name = cpp_name(interface)
    extended_attributes = attribute.extended_attributes
    if (('Replaceable' in extended_attributes and
         'PutForwards' not in extended_attributes) or
        is_constructor_attribute(attribute)):
        return '{0}V8Internal::{0}ForceSetAttributeOnThisCallback'.format(cpp_class_name)
    if attribute.is_read_only and 'PutForwards' not in extended_attributes:
        return '0'
    return '%sV8Internal::%sAttributeSetterCallback' % (cpp_class_name, attribute.name)


# [Custom], [Custom=Getter]
def has_custom_getter(attribute):
    extended_attributes = attribute.extended_attributes
    return ('Custom' in extended_attributes and
            extended_attributes['Custom'] in [None, 'Getter'])


# [Custom], [Custom=Setter]
def has_custom_setter(attribute):
    extended_attributes = attribute.extended_attributes
    return (not attribute.is_read_only and
            'Custom' in extended_attributes and
            extended_attributes['Custom'] in [None, 'Setter'])


################################################################################
# Constructors
################################################################################

idl_types.IdlType.constructor_type_name = property(
    # FIXME: replace this with a [ConstructorAttribute] extended attribute
    lambda self: strip_suffix(self.base_type, 'Constructor'))


def is_constructor_attribute(attribute):
    # FIXME: replace this with [ConstructorAttribute] extended attribute
    return attribute.idl_type.name.endswith('Constructor')
