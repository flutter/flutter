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
import dart_types
from dart_utilities import DartUtilities
from v8_globals import interfaces

import v8_attributes


def attribute_context(interface, attribute):
    # Call v8's implementation.
    context = v8_attributes.attribute_context(interface, attribute)

    extended_attributes = attribute.extended_attributes

    # Augment's Dart's information to context.
    idl_type = attribute.idl_type
    base_idl_type = idl_type.base_type
    # TODO(terry): Work around for DOMString[] base should be IDLTypeArray
    if base_idl_type == None:
        # Returns Array or Sequence.
        base_idl_type = idl_type.inner_name

    # [Custom]
    has_custom_getter = ('Custom' in extended_attributes and
                          extended_attributes['Custom'] in [None, 'Getter'])
    has_custom_setter = (not attribute.is_read_only and
                         (('Custom' in extended_attributes and
                          extended_attributes['Custom'] in [None, 'Setter'])))

    is_call_with_script_state = DartUtilities.has_extended_attribute_value(attribute, 'CallWith', 'ScriptState')

    is_auto_scope = not 'DartNoAutoScope' in extended_attributes

    context.update({
      'has_custom_getter': has_custom_getter,
      'has_custom_setter': has_custom_setter,
      'is_auto_scope': is_auto_scope,   # Used internally (outside of templates).
      'is_call_with_script_state': is_call_with_script_state,
      'auto_scope': DartUtilities.bool_to_cpp(is_auto_scope),
      'dart_type': dart_types.idl_type_to_dart_type(idl_type),
    })

    if v8_attributes.is_constructor_attribute(attribute):
        v8_attributes.constructor_getter_context(interface, attribute, context)
        return context
    if not v8_attributes.has_custom_getter(attribute):
        getter_context(interface, attribute, context)
    if (not attribute.is_read_only):
        # FIXME: We did not previously support the PutForwards attribute, so I am
        # disabling it here for now to get things compiling.
        # We may wish to revisit this.
        # if (not has_custom_setter(attribute) and
        # (not attribute.is_read_only or 'PutForwards' in extended_attributes)):
        setter_context(interface, attribute, context)

    native_entry_getter = \
        DartUtilities.generate_native_entry(
            interface.name, attribute.name, 'Getter', attribute.is_static, 0)
    native_entry_setter = \
        DartUtilities.generate_native_entry(
            interface.name, attribute.name, 'Setter', attribute.is_static, 1)
    context.update({
        'native_entry_getter': native_entry_getter,
        'native_entry_setter': native_entry_setter,
    })

    return context


################################################################################
# Getter
################################################################################

def getter_context(interface, attribute, context):
    v8_attributes.getter_context(interface, attribute, context)

    idl_type = attribute.idl_type
    base_idl_type = idl_type.base_type
    extended_attributes = attribute.extended_attributes

    cpp_value = getter_expression(interface, attribute, context)
    # Normally we can inline the function call into the return statement to
    # avoid the overhead of using a Ref<> temporary, but for some cases
    # (nullable types, EventHandler, [CachedAttribute], or if there are
    # exceptions), we need to use a local variable.
    # FIXME: check if compilers are smart enough to inline this, and if so,
    # always use a local variable (for readability and CG simplicity).
    release = False
    if (idl_type.is_nullable or
        base_idl_type == 'EventHandler' or
        'CachedAttribute' in extended_attributes or
        'ReflectOnly' in extended_attributes or
        context['is_getter_raises_exception']):
        context['cpp_value_original'] = cpp_value
        cpp_value = 'result'
        # EventHandler has special handling
        if base_idl_type != 'EventHandler' and idl_type.is_interface_type:
            release = True

    dart_set_return_value = \
        idl_type.dart_set_return_value(cpp_value,
                                       extended_attributes=extended_attributes,
                                       script_wrappable='impl',
                                       release=release,
                                       for_main_world=False,
                                       auto_scope=context['is_auto_scope'])

    context.update({
        'cpp_value': cpp_value,
        'dart_set_return_value': dart_set_return_value,
    })


def getter_expression(interface, attribute, context):
    v8_attributes.getter_expression(interface, attribute, context)

    arguments = []
    this_getter_base_name = v8_attributes.getter_base_name(interface, attribute, arguments)
    getter_name = DartUtilities.scoped_name(interface, attribute, this_getter_base_name)

    arguments.extend(DartUtilities.call_with_arguments(
        attribute.extended_attributes.get('CallWith')))
    if ('PartialInterfaceImplementedAs' in attribute.extended_attributes and
        not attribute.is_static):
        # Pass by reference.
        arguments.append('*receiver')

    if attribute.idl_type.is_explicit_nullable:
        arguments.append('is_null')
    if context['is_getter_raises_exception']:
        arguments.append('es')
    return '%s(%s)' % (getter_name, ', '.join(arguments))


################################################################################
# Setter
################################################################################

def setter_context(interface, attribute, context):
    v8_attributes.setter_context(interface, attribute, context)

    def target_attribute():
        target_interface_name = attribute.idl_type.base_type
        target_attribute_name = extended_attributes['PutForwards']
        target_interface = interfaces[target_interface_name]
        try:
            return next(attribute
                        for attribute in target_interface.attributes
                        if attribute.name == target_attribute_name)
        except StopIteration:
            raise Exception('[PutForward] target not found:\n'
                            'Attribute "%s" is not present in interface "%s"' %
                            (target_attribute_name, target_interface_name))

    extended_attributes = attribute.extended_attributes

    if 'PutForwards' in extended_attributes:
        # Use target attribute in place of original attribute
        attribute = target_attribute()
        this_cpp_type = 'DartStringAdapter'
    else:
        this_cpp_type = context['cpp_type']

    idl_type = attribute.idl_type

    context.update({
        'has_setter_exception_state': (
            context['is_setter_raises_exception'] or context['has_type_checking_interface'] or
            idl_type.is_integer_type),
        'setter_lvalue': dart_types.check_reserved_name(attribute.name),
        'cpp_type': this_cpp_type,
        'local_cpp_type': idl_type.cpp_type_args(attribute.extended_attributes, raw_type=True),
        'dart_value_to_local_cpp_value':
            attribute.idl_type.dart_value_to_local_cpp_value(
                extended_attributes, attribute.name, False,
                context['has_type_checking_interface'], 1,
                context['is_auto_scope']),
    })

    # setter_expression() depends on context values we set above.
    context['cpp_setter'] = setter_expression(interface, attribute, context)


def setter_expression(interface, attribute, context):
    extended_attributes = attribute.extended_attributes
    arguments = DartUtilities.call_with_arguments(
        extended_attributes.get('SetterCallWith') or
        extended_attributes.get('CallWith'))

    this_setter_base_name = v8_attributes.setter_base_name(interface, attribute, arguments)
    setter_name = DartUtilities.scoped_name(interface, attribute, this_setter_base_name)

    if ('PartialInterfaceImplementedAs' in extended_attributes and
        not attribute.is_static):
        arguments.append('*receiver')
    idl_type = attribute.idl_type
    if idl_type.base_type == 'EventHandler':
        getter_name = DartUtilities.scoped_name(interface, attribute, DartUtilities.cpp_name(attribute))
        context['event_handler_getter_expression'] = '%s(%s)' % (
            getter_name, ', '.join(arguments))
        # FIXME(vsm): Do we need to support this? If so, what's our analogue of
        # V8EventListenerList?
        arguments.append('nullptr')
    else:
        attribute_name = dart_types.check_reserved_name(attribute.name)
        arguments.append(attribute_name)
    if context['is_setter_raises_exception']:
        arguments.append('es')

    return '%s(%s)' % (setter_name, ', '.join(arguments))


################################################################################
# Attribute configuration
################################################################################

# [Replaceable]
def setter_callback_name(interface, attribute):
    cpp_class_name = DartUtilities.cpp_name(interface)
    extended_attributes = attribute.extended_attributes
    if (('Replaceable' in extended_attributes and
         'PutForwards' not in extended_attributes) or
        v8_attributes.is_constructor_attribute(attribute)):
        # FIXME: rename to ForceSetAttributeOnThisCallback, since also used for Constructors
        return '{0}V8Internal::{0}ReplaceableAttributeSetterCallback'.format(cpp_class_name)
    # FIXME:disabling PutForwards for now since we didn't support it before
    #    if attribute.is_read_only and 'PutForwards' not in extended_attributes:
    if attribute.is_read_only:
        return '0'
    return '%sV8Internal::%sAttributeSetterCallback' % (cpp_class_name, attribute.name)


################################################################################
# Constructors
################################################################################

idl_types.IdlType.constructor_type_name = property(
    # FIXME: replace this with a [ConstructorAttribute] extended attribute
    lambda self: DartUtilities.strip_suffix(self.base_type, 'Constructor'))
