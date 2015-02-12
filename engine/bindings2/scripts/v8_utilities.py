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

"""Functions shared by various parts of the code generator.

Extends IdlTypeBase type with |enum_validation_expression| property.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

import re

from idl_types import IdlTypeBase
import idl_types
from v8_globals import includes
import v8_types

ACRONYMS = [
    'CSSOM',  # must come *before* CSS to match full acronym
    'CSS',
    'HTML',
    'IME',
    'JS',
    'URL',
    'WOFF',
    'XML',
]


################################################################################
# Extended attribute parsing
################################################################################

def extended_attribute_value_contains(extended_attribute_value, key):
    return (extended_attribute_value == key or
            (isinstance(extended_attribute_value, list) and
             key in extended_attribute_value))


def has_extended_attribute(definition_or_member, extended_attribute_list):
    return any(extended_attribute in definition_or_member.extended_attributes
               for extended_attribute in extended_attribute_list)


def has_extended_attribute_value(definition_or_member, name, value):
    extended_attributes = definition_or_member.extended_attributes
    return (name in extended_attributes and
            extended_attribute_value_contains(extended_attributes[name], value))


def extended_attribute_value_as_list(definition_or_member, name):
    extended_attributes = definition_or_member.extended_attributes
    if name not in extended_attributes:
        return None
    value = extended_attributes[name]
    if isinstance(value, list):
        return value
    return [value]


################################################################################
# String handling
################################################################################

def capitalize(name):
    """Capitalize first letter or initial acronym (used in setter names)."""
    for acronym in ACRONYMS:
        if name.startswith(acronym.lower()):
            return name.replace(acronym.lower(), acronym)
    return name[0].upper() + name[1:]


def strip_suffix(string, suffix):
    if not suffix or not string.endswith(suffix):
        return string
    return string[:-len(suffix)]


def uncapitalize(name):
    """Uncapitalizes first letter or initial acronym (used in method names).

    E.g., 'SetURL' becomes 'setURL', but 'URLFoo' becomes 'urlFoo'.
    """
    for acronym in ACRONYMS:
        if name.startswith(acronym):
            return name.replace(acronym, acronym.lower())
    return name[0].lower() + name[1:]


################################################################################
# C++
################################################################################

def enum_validation_expression(idl_type):
    # FIXME: Add IdlEnumType, move property to derived type, and remove this check
    if not idl_type.is_enum:
        return None
    return ' || '.join(['string == "%s"' % enum_value
                        for enum_value in idl_type.enum_values])
IdlTypeBase.enum_validation_expression = property(enum_validation_expression)


def scoped_name(interface, definition, base_name):
    # partial interfaces are implemented as separate classes, with their members
    # implemented as static member functions
    partial_interface_implemented_as = definition.extended_attributes.get('PartialInterfaceImplementedAs')
    if partial_interface_implemented_as:
        return '%s::%s' % (partial_interface_implemented_as, base_name)
    if (definition.is_static or
        definition.name in ('Constructor', 'NamedConstructor')):
        return '%s::%s' % (cpp_name(interface), base_name)
    return 'impl->%s' % base_name


################################################################################
# Specific extended attributes
################################################################################


# [CallWith]
CALL_WITH_ARGUMENTS = {
    'ScriptState': 'scriptState',
    'ExecutionContext': 'executionContext',
    'ScriptArguments': 'scriptArguments.release()',
    'ActiveWindow': 'callingDOMWindow(info.GetIsolate())',
    'FirstWindow': 'enteredDOMWindow(info.GetIsolate())',
    'Document': 'document',
}
# List because key order matters, as we want arguments in deterministic order
CALL_WITH_VALUES = [
    'ScriptState',
    'ExecutionContext',
    'ScriptArguments',
    'ActiveWindow',
    'FirstWindow',
    'Document',
]


def call_with_arguments(call_with_values):
    if not call_with_values:
        return []
    return [CALL_WITH_ARGUMENTS[value]
            for value in CALL_WITH_VALUES
            if extended_attribute_value_contains(call_with_values, value)]


# [Exposed]
EXPOSED_EXECUTION_CONTEXT_METHOD = {
    'Window': 'isDocument',
}


def exposed(definition_or_member, interface):
    exposure_set = extended_attribute_value_as_list(definition_or_member, 'Exposed')
    if not exposure_set:
        return None

    interface_exposure_set = expanded_exposure_set_for_interface(interface)

    # Methods must not be exposed to a broader scope than their interface.
    if not set(exposure_set).issubset(interface_exposure_set):
        raise ValueError('Interface members\' exposure sets must be a subset of the interface\'s.')

    exposure_checks = []
    for environment in exposure_set:
        # Methods must be exposed on one of the scopes known to Blink.
        if environment not in EXPOSED_EXECUTION_CONTEXT_METHOD:
            raise ValueError('Values for the [Exposed] annotation must reflect to a valid exposure scope.')

        exposure_checks.append('context->%s()' % EXPOSED_EXECUTION_CONTEXT_METHOD[environment])

    return ' || '.join(exposure_checks)


def expanded_exposure_set_for_interface(interface):
    exposure_set = extended_attribute_value_as_list(interface, 'Exposed')
    return sorted(set(exposure_set))


# [ImplementedAs]
def cpp_name(definition_or_member):
    extended_attributes = definition_or_member.extended_attributes
    if 'ImplementedAs' not in extended_attributes:
        return definition_or_member.name
    return extended_attributes['ImplementedAs']
