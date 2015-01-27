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

Extends IdlType and IdlUnion type with |enum_validation_expression| property.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""


################################################################################
# Utility function exposed for Dart CodeGenerator. Only 6 methods are special
# to Dart the rest delegate to the v8_utilities functions.
################################################################################


import v8_types  # Required
import v8_utilities


def _scoped_name(interface, definition, base_name):
    # partial interfaces are implemented as separate classes, with their members
    # implemented as static member functions
    partial_interface_implemented_as = definition.extended_attributes.get('PartialInterfaceImplementedAs')
    if partial_interface_implemented_as:
        return '%s::%s' % (partial_interface_implemented_as, base_name)
    if (definition.is_static or
        definition.name in ('Constructor', 'NamedConstructor')):
        return '%s::%s' % (v8_utilities.cpp_name(interface), base_name)
    return 'receiver->%s' % base_name


def _bool_to_cpp(tf):
    return "true" if tf else "false"


# [ActivityLogging]
def _activity_logging_world_list(member, access_type=None):
    """Returns a set of world suffixes for which a definition member has activity logging, for specified access type.

    access_type can be 'Getter' or 'Setter' if only checking getting or setting.
    """
    if 'ActivityLogging' not in member.extended_attributes:
        return set()
    activity_logging = member.extended_attributes['ActivityLogging']
    # [ActivityLogging=For*] (no prefix, starts with the worlds suffix) means
    # "log for all use (method)/access (attribute)", otherwise check that value
    # agrees with specified access_type (Getter/Setter).
    has_logging = (activity_logging.startswith('For') or
                   (access_type and activity_logging.startswith(access_type)))
    if not has_logging:
        return set()
# TODO(terry): Remove Me?
#    includes.add('bindings/core/v8/V8DOMActivityLogger.h')
    if activity_logging.endswith('ForIsolatedWorlds'):
        return set([''])
    return set(['', 'ForMainWorld'])  # endswith('ForAllWorlds')


# [CallWith]
_CALL_WITH_ARGUMENTS = {
    'ScriptState': 'state',
    'ExecutionContext': 'context',
    'ScriptArguments': 'scriptArguments.release()',
    'ActiveWindow': 'DartUtilities::callingDomWindowForCurrentIsolate()',
    'FirstWindow': 'DartUtilities::enteredDomWindowForCurrentIsolate()',
    'Document': 'document',
}

# List because key order matters, as we want arguments in deterministic order
_CALL_WITH_VALUES = [
    'ScriptState',
    'ExecutionContext',
    'ScriptArguments',
    'ActiveWindow',
    'FirstWindow',
    'Document',
]


def _call_with_arguments(call_with_values):
    if not call_with_values:
        return []
    return [_CALL_WITH_ARGUMENTS[value]
            for value in _CALL_WITH_VALUES
            if v8_utilities.extended_attribute_value_contains(call_with_values, value)]


# [DeprecateAs]
def _deprecate_as(member):
    extended_attributes = member.extended_attributes
    if 'DeprecateAs' not in extended_attributes:
        return None
# TODO(terry): Remove me?
#    includes.add('core/frame/UseCounter.h')
    return extended_attributes['DeprecateAs']


# [MeasureAs]
def _measure_as(definition_or_member):
    extended_attributes = definition_or_member.extended_attributes
    if 'MeasureAs' not in extended_attributes:
        return None
# TODO(terry): Remove Me?
#    includes.add('core/frame/UseCounter.h')
    return extended_attributes['MeasureAs']


def _generate_native_entry(interface_name, name, kind, is_static, arity):

    def mkPublic(s):
        if s.startswith("_") or s.startswith("$"):
            return "$" + s
        return s

    arity_str = ""
    if kind == 'Getter':
        suffix = "_Getter"
    elif kind == 'Setter':
        suffix = "_Setter"
    elif kind == 'Constructor':
        name = "constructor"
        suffix = "Callback"
        arity_str = "_" + str(arity)
    elif kind == 'Method':
        suffix = "_Callback"
        arity_str = "_" + str(arity)

    tag = "%s%s" % (name, suffix)
    blink_entry = mkPublic(tag + arity_str)
    native_entry = "_".join([interface_name, tag])

    argument_names = ['__arg_%d' % i for i in range(0, arity)]
    if not is_static and kind != 'Constructor':
        argument_names.insert(0, "mthis")

    return {'blink_entry': blink_entry,
            'argument_names': argument_names,
            'resolver_string': native_entry}

################################################################################
# This is the monkey patched methods most delegate to v8_utilities but some are
# overridden in dart_utilities.
################################################################################


class dart_utilities_monkey():
    def __init__(self):
        self.base_class_name = 'dart_utilities'

DartUtilities = dart_utilities_monkey()

DartUtilities.activity_logging_world_list = _activity_logging_world_list
DartUtilities.bool_to_cpp = _bool_to_cpp
DartUtilities.call_with_arguments = _call_with_arguments
DartUtilities.capitalize = v8_utilities.capitalize
DartUtilities.conditional_string = v8_utilities.conditional_string
DartUtilities.cpp_name = v8_utilities.cpp_name
DartUtilities.deprecate_as = _deprecate_as
DartUtilities.extended_attribute_value_contains = v8_utilities.extended_attribute_value_contains
DartUtilities.gc_type = v8_utilities.gc_type
DartUtilities.generate_native_entry = _generate_native_entry
DartUtilities.has_extended_attribute = v8_utilities.has_extended_attribute
DartUtilities.has_extended_attribute_value = v8_utilities.has_extended_attribute_value
DartUtilities.measure_as = _measure_as
DartUtilities.per_context_enabled_function_name = v8_utilities.per_context_enabled_function_name
DartUtilities.runtime_enabled_function_name = v8_utilities.runtime_enabled_function_name
DartUtilities.scoped_name = _scoped_name
DartUtilities.strip_suffix = v8_utilities.strip_suffix
DartUtilities.uncapitalize = v8_utilities.uncapitalize
DartUtilities.v8_class_name = v8_utilities.v8_class_name
