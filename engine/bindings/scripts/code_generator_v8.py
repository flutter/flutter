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

"""Generate Blink V8 bindings (.h and .cpp files).

If run itself, caches Jinja templates (and creates dummy file for build,
since cache filenames are unpredictable and opaque).

This module is *not* concurrency-safe without care: bytecode caching creates
a race condition on cache *write* (crashes if one process tries to read a
partially-written cache). However, if you pre-cache the templates (by running
the module itself), then you can parallelize compiling individual files, since
cache *reading* is safe.

Input: An object of class IdlDefinitions, containing an IDL interface X
Output: V8X.h and V8X.cpp

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

import os
import posixpath
import re
import sys

# Path handling for libraries and templates
# Paths have to be normalized because Jinja uses the exact template path to
# determine the hash used in the cache filename, and we need a pre-caching step
# to be concurrency-safe. Use absolute path because __file__ is absolute if
# module is imported, and relative if executed directly.
# If paths differ between pre-caching and individual file compilation, the cache
# is regenerated, which causes a race condition and breaks concurrent build,
# since some compile processes will try to read the partially written cache.
module_path, module_filename = os.path.split(os.path.realpath(__file__))
third_party_dir = os.path.normpath(os.path.join(
    module_path, os.pardir, os.pardir, os.pardir, os.pardir, 'third_party'))
templates_dir = os.path.normpath(os.path.join(
    module_path, os.pardir, 'templates'))
# Make sure extension is .py, not .pyc or .pyo, so doesn't depend on caching
module_pyname = os.path.splitext(module_filename)[0] + '.py'

# jinja2 is in chromium's third_party directory.
# Insert at 1 so at front to override system libraries, and
# after path[0] == invoking script dir
sys.path.insert(1, third_party_dir)
import jinja2

import idl_types
from idl_types import IdlType
import v8_callback_interface
import v8_dictionary
from v8_globals import includes, interfaces
import v8_interface
import v8_types
from v8_utilities import capitalize, cpp_name, conditional_string, v8_class_name


KNOWN_COMPONENTS = frozenset(['core', 'modules'])


def render_template(interface_info, header_template, cpp_template,
                    template_context):
    template_context['code_generator'] = module_pyname

    # Add includes for any dependencies
    template_context['header_includes'] = sorted(
        template_context['header_includes'])
    includes.update(interface_info.get('dependencies_include_paths', []))
    template_context['cpp_includes'] = sorted(includes)

    header_text = header_template.render(template_context)
    cpp_text = cpp_template.render(template_context)
    return header_text, cpp_text


class CodeGeneratorBase(object):
    """Base class for v8 bindings generator and IDL dictionary impl generator"""

    def __init__(self, interfaces_info, cache_dir, output_dir):
        interfaces_info = interfaces_info or {}
        self.interfaces_info = interfaces_info
        self.jinja_env = initialize_jinja_env(cache_dir)
        self.output_dir = output_dir

        # Set global type info
        idl_types.set_ancestors(dict(
            (interface_name, interface_info['ancestors'])
            for interface_name, interface_info in interfaces_info.iteritems()
            if interface_info['ancestors']))
        IdlType.set_callback_interfaces(set(
            interface_name
            for interface_name, interface_info in interfaces_info.iteritems()
            if interface_info['is_callback_interface']))
        IdlType.set_dictionaries(set(
            dictionary_name
            for dictionary_name, interface_info in interfaces_info.iteritems()
            if interface_info['is_dictionary']))
        IdlType.set_implemented_as_interfaces(dict(
            (interface_name, interface_info['implemented_as'])
            for interface_name, interface_info in interfaces_info.iteritems()
            if interface_info['implemented_as']))
        IdlType.set_garbage_collected_types(set(
            interface_name
            for interface_name, interface_info in interfaces_info.iteritems()
            if 'GarbageCollected' in interface_info['inherited_extended_attributes']))
        IdlType.set_will_be_garbage_collected_types(set(
            interface_name
            for interface_name, interface_info in interfaces_info.iteritems()
            if 'WillBeGarbageCollected' in interface_info['inherited_extended_attributes']))
        v8_types.set_component_dirs(dict(
            (interface_name, interface_info['component_dir'])
            for interface_name, interface_info in interfaces_info.iteritems()))

    def generate_code(self, definitions, definition_name):
        """Returns .h/.cpp code as ((path, content)...)."""
        # Set local type info
        IdlType.set_callback_functions(definitions.callback_functions.keys())
        IdlType.set_enums((enum.name, enum.values)
                          for enum in definitions.enumerations.values())
        return self.generate_code_internal(definitions, definition_name)

    def generate_code_internal(self, definitions, definition_name):
        # This should be implemented in subclasses.
        raise NotImplementedError()


class CodeGeneratorV8(CodeGeneratorBase):
    def __init__(self, interfaces_info, cache_dir, output_dir):
        CodeGeneratorBase.__init__(self, interfaces_info, cache_dir, output_dir)

    def output_paths(self, definition_name):
        header_path = posixpath.join(self.output_dir,
                                     'V8%s.h' % definition_name)
        cpp_path = posixpath.join(self.output_dir, 'V8%s.cpp' % definition_name)
        return header_path, cpp_path

    def generate_code_internal(self, definitions, definition_name):
        if definition_name in definitions.interfaces:
            return self.generate_interface_code(
                definitions, definition_name,
                definitions.interfaces[definition_name])
        if definition_name in definitions.dictionaries:
            return self.generate_dictionary_code(
                definitions, definition_name,
                definitions.dictionaries[definition_name])
        raise ValueError('%s is not in IDL definitions' % definition_name)

    def generate_interface_code(self, definitions, interface_name, interface):
        # Store other interfaces for introspection
        interfaces.update(definitions.interfaces)

        # Select appropriate Jinja template and contents function
        if interface.is_callback:
            header_template_filename = 'callback_interface.h'
            cpp_template_filename = 'callback_interface.cpp'
            interface_context = v8_callback_interface.callback_interface_context
        else:
            header_template_filename = 'interface.h'
            cpp_template_filename = 'interface.cpp'
            interface_context = v8_interface.interface_context
        header_template = self.jinja_env.get_template(header_template_filename)
        cpp_template = self.jinja_env.get_template(cpp_template_filename)

        interface_info = self.interfaces_info[interface_name]

        template_context = interface_context(interface)
        # Add the include for interface itself
        template_context['header_includes'].add(interface_info['include_path'])
        header_text, cpp_text = render_template(
            interface_info, header_template, cpp_template, template_context)
        header_path, cpp_path = self.output_paths(interface_name)
        return (
            (header_path, header_text),
            (cpp_path, cpp_text),
        )

    def generate_dictionary_code(self, definitions, dictionary_name,
                                 dictionary):
        header_template = self.jinja_env.get_template('dictionary_v8.h')
        cpp_template = self.jinja_env.get_template('dictionary_v8.cpp')
        template_context = v8_dictionary.dictionary_context(dictionary)
        interface_info = self.interfaces_info[dictionary_name]
        # Add the include for interface itself
        template_context['header_includes'].add(interface_info['include_path'])
        header_text, cpp_text = render_template(
            interface_info, header_template, cpp_template, template_context)
        header_path, cpp_path = self.output_paths(dictionary_name)
        return (
            (header_path, header_text),
            (cpp_path, cpp_text),
        )


class CodeGeneratorDictionaryImpl(CodeGeneratorBase):
    def __init__(self, interfaces_info, cache_dir, output_dir):
        CodeGeneratorBase.__init__(self, interfaces_info, cache_dir, output_dir)

    def output_paths(self, definition_name, interface_info):
        if interface_info['component_dir'] in KNOWN_COMPONENTS:
            output_dir = posixpath.join(self.output_dir,
                                        interface_info['relative_dir'])
        else:
            output_dir = self.output_dir
        header_path = posixpath.join(output_dir, '%s.h' % definition_name)
        cpp_path = posixpath.join(output_dir, '%s.cpp' % definition_name)
        return header_path, cpp_path

    def generate_code_internal(self, definitions, definition_name):
        if not definition_name in definitions.dictionaries:
            raise ValueError('%s is not an IDL dictionary')
        dictionary = definitions.dictionaries[definition_name]
        interface_info = self.interfaces_info[definition_name]
        header_template = self.jinja_env.get_template('dictionary_impl.h')
        cpp_template = self.jinja_env.get_template('dictionary_impl.cpp')
        template_context = v8_dictionary.dictionary_impl_context(
            dictionary, self.interfaces_info)
        header_text, cpp_text = render_template(
            interface_info, header_template, cpp_template, template_context)
        header_path, cpp_path = self.output_paths(
            definition_name, interface_info)
        return (
            (header_path, header_text),
            (cpp_path, cpp_text),
        )


def initialize_jinja_env(cache_dir):
    jinja_env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(templates_dir),
        # Bytecode cache is not concurrency-safe unless pre-cached:
        # if pre-cached this is read-only, but writing creates a race condition.
        bytecode_cache=jinja2.FileSystemBytecodeCache(cache_dir),
        keep_trailing_newline=True,  # newline-terminate generated files
        lstrip_blocks=True,  # so can indent control flow tags
        trim_blocks=True)
    jinja_env.filters.update({
        'blink_capitalize': capitalize,
        'conditional': conditional_if_endif,
        'exposed': exposed_if,
        'runtime_enabled': runtime_enabled_if,
        })
    return jinja_env


def generate_indented_conditional(code, conditional):
    # Indent if statement to level of original code
    indent = re.match(' *', code).group(0)
    return ('%sif (%s) {\n' % (indent, conditional) +
            '    %s\n' % '\n    '.join(code.splitlines()) +
            '%s}\n' % indent)


# [Conditional]
def conditional_if_endif(code, conditional_string):
    # Jinja2 filter to generate if/endif directive blocks
    if not conditional_string:
        return code
    return ('#if %s\n' % conditional_string +
            code +
            '#endif // %s\n' % conditional_string)


# [Exposed]
def exposed_if(code, exposed_test):
    if not exposed_test:
        return code
    return generate_indented_conditional(code, 'context && (%s)' % exposed_test)


# [RuntimeEnabled]
def runtime_enabled_if(code, runtime_enabled_function_name):
    if not runtime_enabled_function_name:
        return code
    return generate_indented_conditional(code, '%s()' % runtime_enabled_function_name)


################################################################################

def main(argv):
    # If file itself executed, cache templates
    try:
        cache_dir = argv[1]
        dummy_filename = argv[2]
    except IndexError as err:
        print 'Usage: %s CACHE_DIR DUMMY_FILENAME' % argv[0]
        return 1

    # Cache templates
    jinja_env = initialize_jinja_env(cache_dir)
    template_filenames = [filename for filename in os.listdir(templates_dir)
                          # Skip .svn, directories, etc.
                          if filename.endswith(('.cpp', '.h'))]
    for template_filename in template_filenames:
        jinja_env.get_template(template_filename)

    # Create a dummy file as output for the build system,
    # since filenames of individual cache files are unpredictable and opaque
    # (they are hashes of the template path, which varies based on environment)
    with open(dummy_filename, 'w') as dummy_file:
        pass  # |open| creates or touches the file


if __name__ == '__main__':
    sys.exit(main(sys.argv))
