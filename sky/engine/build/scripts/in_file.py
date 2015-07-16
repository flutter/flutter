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

import copy
import os

# NOTE: This has only been used to parse
# core/page/RuntimeEnabledFeatures.in and may not be capable
# of parsing other .in files correctly.

# .in file format is:
# // comment
# name1 arg=value, arg2=value2, arg2=value3
#
# InFile must be passed a dictionary of default values
# with which to validate arguments against known names.
# Sequence types as default values will produce sequences
# as parse results.
# Bare arguments (no '=') are treated as names with value True.
# The first field will always be labeled 'name'.
#
# InFile.load_from_files(['file.in'], {'arg': None, 'arg2': []})
#
# Parsing produces an array of dictionaries:
# [ { 'name' : 'name1', 'arg' :' value', arg2=['value2', 'value3'] }

def _is_comment(line):
    return line.startswith("//") or line.startswith("#")

class InFile(object):
    def __init__(self, lines, defaults, valid_values=None, default_parameters=None):
        self.name_dictionaries = []
        self.parameters = copy.deepcopy(default_parameters if default_parameters else {})
        self._defaults = defaults
        self._valid_values = copy.deepcopy(valid_values if valid_values else {})
        self._parse(map(str.strip, lines))

    @classmethod
    def load_from_files(self, file_paths, defaults, valid_values, default_parameters):
        lines = []
        for path in file_paths:
            assert path.endswith(".in")
            with open(os.path.abspath(path)) as in_file:
                lines += in_file.readlines()
        return InFile(lines, defaults, valid_values, default_parameters)

    def _is_sequence(self, arg):
        return (not hasattr(arg, "strip")
                and hasattr(arg, "__getitem__")
                or hasattr(arg, "__iter__"))

    def _parse(self, lines):
        parsing_parameters = True
        indices = {}
        for line in lines:
            if _is_comment(line):
                continue
            if not line:
                parsing_parameters = False
                continue
            if parsing_parameters:
                self._parse_parameter(line)
            else:
                entry = self._parse_line(line)
                name = entry['name']
                if name in indices:
                    entry = self._merge_entries(entry, self.name_dictionaries[indices[name]])
                    entry['name'] = name
                    self.name_dictionaries[indices[name]] = entry
                else:
                    indices[name] = len(self.name_dictionaries)
                    self.name_dictionaries.append(entry)


    def _merge_entries(self, one, two):
        merged = {}
        for key in one:
            if key not in two:
                self._fatal("Expected key '%s' not found in entry: %s" % (key, two))
            if one[key] and two[key]:
                val_one = one[key]
                val_two = two[key]
                if isinstance(val_one, list) and isinstance(val_two, list):
                    val = val_one + val_two
                elif isinstance(val_one, list):
                    val = val_one + [val_two]
                elif isinstance(val_two, list):
                    val = [val_one] + val_two
                else:
                    val = [val_one, val_two]
                merged[key] = val
            elif one[key]:
                merged[key] = one[key]
            else:
                merged[key] = two[key]
        return merged


    def _parse_parameter(self, line):
        if '=' in line:
            name, value = line.split('=')
        else:
            name, value = line, True
        if not name in self.parameters:
            self._fatal("Unknown parameter: '%s' in line:\n%s\nKnown parameters: %s" % (name, line, self.parameters.keys()))
        self.parameters[name] = value

    def _parse_line(self, line):
        args = copy.deepcopy(self._defaults)
        parts = line.split(' ')
        args['name'] = parts[0]
        # re-join the rest of the line and split on ','
        args_list = ' '.join(parts[1:]).strip().split(',')
        for arg_string in args_list:
            arg_string = arg_string.strip()
            if not arg_string: # Ignore empty args
                continue
            if '=' in arg_string:
                arg_name, arg_value = arg_string.split('=')
            else:
                arg_name, arg_value = arg_string, True
            if arg_name not in self._defaults:
                self._fatal("Unknown argument: '%s' in line:\n%s\nKnown arguments: %s" % (arg_name, line, self._defaults.keys()))
            valid_values = self._valid_values.get(arg_name)
            if valid_values and arg_value not in valid_values:
                self._fatal("Unknown value: '%s' in line:\n%s\nKnown values: %s" % (arg_value, line, valid_values))
            if self._is_sequence(args[arg_name]):
                args[arg_name].append(arg_value)
            else:
                args[arg_name] = arg_value
        return args

    def _fatal(self, message):
        # FIXME: This should probably raise instead of exit(1)
        print message
        exit(1)
