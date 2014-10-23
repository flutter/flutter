#!/usr/bin/env python
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

import io
import itertools
import re
import sys


class BadInput(Exception):
    """Unsupported input has been found."""


class SwitchCase(object):
    """Represents a CASE block."""
    def __init__(self, identifier, block):
        self.identifier = identifier
        self.block = block


class Optimizer(object):
    """Generates optimized identifier matching code."""
    def __init__(self, output_file, array_variable, length_variable):
        self.output_file = output_file
        self.array_variable = array_variable
        self.length_variable = length_variable

    def inspect(self, cases):
        lengths = list(set([len(c.identifier) for c in cases]))
        lengths.sort()

        def response(length):
            self.inspect_array([c for c in cases if len(c.identifier) == length], range(length))
        self.write_selection(self.length_variable, lengths, str, response)

    def score(self, alternatives):
        return -sum([len(list(count)) ** 2 for _, count in itertools.groupby(sorted(alternatives))])

    def choose_selection_pos(self, cases, pending):
        candidates = [pos for pos in pending if all(alternative.isalpha() for alternative in [c.identifier[pos] for c in cases])]
        if not candidates:
            raise BadInput('Case-insensitive switching on non-alphabetic characters not yet implemented')
        return sorted(candidates, key=lambda pos: self.score([c.identifier[pos] for c in cases]))[0]

    def inspect_array(self, cases, pending):
        assert len(cases) >= 1
        if pending:
            common = [pos for pos in pending
                      if len(set([c.identifier[pos] for c in cases])) == 1]
            if common:
                identifier = cases[0].identifier
                for index in xrange(len(common)):
                    if index == 0:
                        self.output_file.write(u'if (LIKELY(')
                    else:
                        self.output_file.write(u' && ')
                    pos = common[index]
                    if identifier[pos].isalpha():
                        self.output_file.write("(%s[%d] | 0x20) == '%s'" %
                                               (self.array_variable, pos, identifier[pos]))
                    else:
                        self.output_file.write("%s[%d] == '%s'" %
                                               (self.array_variable, pos, identifier[pos]))
                self.output_file.write(u')) {\n')
                next_pending = list(set(pending) - set(common))
                next_pending.sort()
                self.inspect_array(cases, next_pending)
                self.output_file.write(u'}\n')
            else:
                pos = self.choose_selection_pos(cases, pending)
                next_pending = filter(lambda p: p != pos, pending)

                alternatives = list(set([c.identifier[pos] for c in cases]))
                alternatives.sort()

                def literal(alternative):
                    if isinstance(alternative, int):
                        return str(alternative)
                    else:
                        return "'%s'" % alternative

                def response(alternative):
                    self.inspect_array([c for c in cases if c.identifier[pos] == alternative],
                                       next_pending)

                expression = '(%s[%d] | 0x20)' % (self.array_variable, pos)
                self.write_selection(expression, alternatives, literal, response)
        else:
            assert len(cases) == 1
            for block_line in cases[0].block:
                self.output_file.write(block_line)

    def write_selection(self, expression, alternatives, literal, response):
        if len(alternatives) == 1:
            self.output_file.write(u'if (LIKELY(%s == %s)) {\n' % (expression, literal(alternatives[0])))
            response(alternatives[0])
            self.output_file.write(u'}\n')
        elif len(alternatives) == 2:
            self.output_file.write(u'if (%s == %s) {\n' % (expression, literal(alternatives[0])))
            response(alternatives[0])
            self.output_file.write(u'} else if (LIKELY(%s == %s)) {\n' % (expression, literal(alternatives[1])))
            response(alternatives[1])
            self.output_file.write(u'}\n')
        else:
            self.output_file.write('switch (%s) {\n' % expression)
            for alternative in alternatives:
                self.output_file.write(u'case %s: {\n' % literal(alternative))
                response(alternative)
                self.output_file.write(u'} break;\n')
            self.output_file.write(u'}\n')


class LineProcessor(object):
    def process_line(self, line):
        pass


class MainLineProcessor(LineProcessor):
    """Processes the contents of an input file."""
    SWITCH_PATTERN = re.compile(r'\s*SWITCH\s*\((\w*),\s*(\w*)\) \{$')

    def __init__(self, output_file):
        self.output_file = output_file

    def process_line(self, line):
        match_switch = MainLineProcessor.SWITCH_PATTERN.match(line)
        if match_switch:
            array_variable = match_switch.group(1)
            length_variable = match_switch.group(2)
            return SwitchLineProcessor(self, self.output_file, array_variable, length_variable)
        else:
            self.output_file.write(line)
            return self


class SwitchLineProcessor(LineProcessor):
    """Processes the contents of a SWITCH block."""
    CASE_PATTERN = re.compile(r'\s*CASE\s*\(\"([a-z0-9_\-\(]*)\"\) \{$')
    CLOSE_BRACE_PATTERN = re.compile(r'\s*\}$')
    EMPTY_PATTERN = re.compile(r'\s*$')

    def __init__(self, parent, output_file, array_variable, length_variable):
        self.parent = parent
        self.output_file = output_file
        self.array_variable = array_variable
        self.length_variable = length_variable
        self.cases = []

    def process_line(self, line):
        match_case = SwitchLineProcessor.CASE_PATTERN.match(line)
        match_close_brace = SwitchLineProcessor.CLOSE_BRACE_PATTERN.match(line)
        match_empty = SwitchLineProcessor.EMPTY_PATTERN.match(line)
        if match_case:
            identifier = match_case.group(1)
            return CaseLineProcessor(self, self.output_file, identifier)
        elif match_close_brace:
            Optimizer(self.output_file, self.array_variable, self.length_variable).inspect(self.cases)
            return self.parent
        elif match_empty:
            return self
        else:
            raise BadInput('Invalid line within SWITCH: %s' % line)

    def add_case(self, latest_case):
        if latest_case.identifier in [c.identifier for c in self.cases]:
            raise BadInput('Repeated case: %s' % latest_case.identifier)
        self.cases.append(latest_case)


class CaseLineProcessor(LineProcessor):
    """Processes the contents of a CASE block."""
    CLOSE_BRACE_PATTERN = re.compile(r'\s*\}$')
    BREAK_PATTERN = re.compile(r'break;')

    def __init__(self, parent, output_file, identifier):
        self.parent = parent
        self.output_file = output_file
        self.identifier = identifier
        self.block = []

    def process_line(self, line):
        match_close_brace = CaseLineProcessor.CLOSE_BRACE_PATTERN.match(line)
        match_break = CaseLineProcessor.BREAK_PATTERN.search(line)
        if match_close_brace:
            self.parent.add_case(SwitchCase(self.identifier, self.block))
            return self.parent
        elif match_break:
            raise BadInput('break within CASE not supported: %s' % line)
        else:
            self.block.append(line)
            return self


def process_file(input_name, output_name):
    """Transforms input file into legal C++ source code."""
    with io.open(input_name, 'r', -1, 'utf-8') as input_file:
        with io.open(output_name, 'w', -1, 'utf-8') as output_file:
            processor = MainLineProcessor(output_file)
            input_lines = input_file.readlines()
            for line in input_lines:
                processor = processor.process_line(line)


if __name__ == '__main__':
        process_file(sys.argv[1], sys.argv[2])
