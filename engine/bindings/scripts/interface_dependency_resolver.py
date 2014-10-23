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

"""Resolve interface dependencies, producing a merged IdlDefinitions object.

This library computes interface dependencies (partial interfaces and
implements), reads the dependency files, and merges them to the IdlDefinitions
for the main IDL file, producing an IdlDefinitions object representing the
entire interface.

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler#TOC-Dependency-resolution
"""

import os.path

# The following extended attributes can be applied to a dependency interface,
# and are then applied to the individual members when merging.
# Note that this moves the extended attribute from the interface to the member,
# which changes the semantics and yields different code than the same extended
# attribute on the main interface.
DEPENDENCY_EXTENDED_ATTRIBUTES = set([
    'Conditional',
    'RuntimeEnabled',
])


class InterfaceDependencyResolver(object):
    def __init__(self, interfaces_info, reader):
        """Initialize dependency resolver.

        Args:
            interfaces_info:
                dict of interfaces information, from compute_dependencies.py
            reader:
                IdlReader, used for reading dependency files
        """
        self.interfaces_info = interfaces_info
        self.reader = reader

    def resolve_dependencies(self, definitions):
        """Resolve dependencies, merging them into IDL definitions of main file.

        Dependencies consist of 'partial interface' for the same interface as
        in the main file, and other interfaces that this interface 'implements'.
        These are merged into the main IdlInterface, as the main IdlInterface
        implements all these members.

        Referenced interfaces are added to IdlDefinitions, but not merged into
        the main IdlInterface, as these are only referenced (their members are
        introspected, but not implemented in this interface).

        Inherited extended attributes are also added to the main IdlInterface.

        Modifies definitions in place by adding parsed dependencies.

        Args:
            definitions: IdlDefinitions object, modified in place
        """
        if not definitions.interfaces:
            # This definitions should have a dictionary. Nothing to do for it.
            return
        target_interface = next(definitions.interfaces.itervalues())
        interface_name = target_interface.name
        interface_info = self.interfaces_info[interface_name]

        if 'inherited_extended_attributes' in interface_info:
            target_interface.extended_attributes.update(
                interface_info['inherited_extended_attributes'])

        merge_interface_dependencies(definitions,
                                     target_interface,
                                     interface_info['dependencies_full_paths'],
                                     self.reader)

        for referenced_interface_name in interface_info['referenced_interfaces']:
            referenced_definitions = self.reader.read_idl_definitions(
                self.interfaces_info[referenced_interface_name]['full_path'])
            definitions.update(referenced_definitions)


def merge_interface_dependencies(definitions, target_interface, dependency_idl_filenames, reader):
    """Merge dependencies ('partial interface' and 'implements') in dependency_idl_filenames into target_interface.

    No return: modifies target_interface in place.
    """
    # Sort so order consistent, so can compare output from run to run.
    for dependency_idl_filename in sorted(dependency_idl_filenames):
        dependency_definitions = reader.read_idl_file(dependency_idl_filename)
        dependency_interface = next(dependency_definitions.interfaces.itervalues())
        dependency_interface_basename, _ = os.path.splitext(os.path.basename(dependency_idl_filename))

        transfer_extended_attributes(dependency_interface,
                                     dependency_interface_basename)
        definitions.update(dependency_definitions)  # merges partial interfaces
        if not dependency_interface.is_partial:
            # Implemented interfaces (non-partial dependencies) are also merged
            # into the target interface, so Code Generator can just iterate
            # over one list (and not need to handle 'implements' itself).
            target_interface.merge(dependency_interface)


def transfer_extended_attributes(dependency_interface, dependency_interface_basename):
    """Transfer extended attributes from dependency interface onto members.

    Merging consists of storing certain interface-level data in extended
    attributes of the *members* (because there is no separate dependency
    interface post-merging).

    The data storing consists of:
    * applying certain extended attributes from the dependency interface
      to its members
    * storing the C++ class of the implementation in an internal
      extended attribute of each member, [PartialInterfaceImplementedAs]

    No return: modifies dependency_interface in place.
    """
    merged_extended_attributes = dict(
        (key, value)
        for key, value in dependency_interface.extended_attributes.iteritems()
        if key in DEPENDENCY_EXTENDED_ATTRIBUTES)

    # A partial interface's members are implemented as static member functions
    # in a separate C++ class. This class name is stored in
    # [PartialInterfaceImplementedAs] which defaults to the basename of
    # dependency IDL file.
    # This class name can be overridden by [ImplementedAs] on the partial
    # interface definition.
    #
    # Note that implemented interfaces do *not* need [ImplementedAs], since
    # they are implemented on the C++ object |impl| itself, just like members of
    # the main interface definition, so the bindings do not need to know in
    # which class implemented interfaces are implemented.
    #
    # Currently [LegacyTreatAsPartialInterface] can be used to have partial
    # interface behavior on implemented interfaces, but this is being removed
    # as legacy cruft:
    # FIXME: Remove [LegacyTreatAsPartialInterface]
    # http://crbug.com/360435
    #
    # Note that [ImplementedAs] is used with different meanings on interfaces
    # and members:
    # for Blink class name and function name (or constant name), respectively.
    # Thus we do not want to copy this from the interface to the member, but
    # instead extract it and handle it separately.
    if (dependency_interface.is_partial or
        'LegacyTreatAsPartialInterface' in dependency_interface.extended_attributes):
        merged_extended_attributes['PartialInterfaceImplementedAs'] = (
            dependency_interface.extended_attributes.get(
                'ImplementedAs', dependency_interface_basename))

    for attribute in dependency_interface.attributes:
        attribute.extended_attributes.update(merged_extended_attributes)
    for constant in dependency_interface.constants:
        constant.extended_attributes.update(merged_extended_attributes)
    for operation in dependency_interface.operations:
        operation.extended_attributes.update(merged_extended_attributes)
