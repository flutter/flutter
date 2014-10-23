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

import tempfile
import unittest

from make_token_matcher import BadInput, CaseLineProcessor, MainLineProcessor, Optimizer, process_file, SwitchCase, SwitchLineProcessor


class OptimizerTest(unittest.TestCase):
    def test_nonalphabetic(self):
        optimizer = Optimizer(None, None, None)
        self.assertRaises(
            BadInput,
            optimizer.inspect_array,
            [SwitchCase('-', None), SwitchCase('x', None)],
            [0])


class MainLineProcessorTest(unittest.TestCase):
    def test_switch(self):
        processor = MainLineProcessor(None)
        switchLineProcessor = processor.process_line('SWITCH(array, length) {')
        self.assertIsInstance(switchLineProcessor, SwitchLineProcessor)
        self.assertEquals('array', switchLineProcessor.array_variable)
        self.assertEquals('length', switchLineProcessor.length_variable)


class SwitchLineProcessorTest(unittest.TestCase):
    def test_case(self):
        processor = SwitchLineProcessor(None, None, None, None)
        caseLineProcessor = processor.process_line('CASE("identifier") {')
        self.assertIsInstance(caseLineProcessor, CaseLineProcessor)
        self.assertEquals('identifier', caseLineProcessor.identifier)

    def test_unexpected(self):
        processor = SwitchLineProcessor(None, None, None, None)
        self.assertRaises(
            BadInput,
            processor.process_line,
            'unexpected')

    def test_repeated(self):
        processor = SwitchLineProcessor(None, None, None, None)
        processor.process_line('CASE("x") {').process_line('}')
        caseLineProcessor = processor.process_line('CASE("x") {')
        self.assertRaises(
            BadInput,
            caseLineProcessor.process_line,
            '}')


class CaseLineProcessorTest(unittest.TestCase):
    def test_break(self):
        processor = CaseLineProcessor(None, None, None)
        self.assertRaises(
            BadInput,
            processor.process_line,
            'break;')


class ProcessFileTest(unittest.TestCase):
    SOURCE_SMALL = """
        SWITCH(p, q) {
            CASE("a(") {
                X;
            }
            CASE("b(") {
                Y;
            }
        }
        """

    EXPECTED_SMALL = """
        if (LIKELY(q == 2)) {
            if (LIKELY(p[1] == '(')) {
                if ((p[0] | 0x20) == 'a') {
                    X;
                } else if (LIKELY((p[0] | 0x20) == 'b')) {
                    Y;
                }
            }
        }
        """

    SOURCE_MEDIUM = """
        SWITCH (p, q) {
            CASE ("ab") {
                X;
            }
            CASE ("cd") {
                Y;
            }
            CASE ("ed") {
                Z;
            }
        }
        """

    EXPECTED_MEDIUM = """
        if (LIKELY(q == 2)) {
            if ((p[1] | 0x20) == 'b') {
                if (LIKELY((p[0] | 0x20) == 'a')) {
                    X;
                }
            } else if (LIKELY((p[1] | 0x20) == 'd')) {
                if ((p[0] | 0x20) == 'c') {
                    Y;
                } else if (LIKELY((p[0] | 0x20) == 'e')) {
                    Z;
                }
            }
        }
        """

    SOURCE_LARGE = """
        prefix;
        SWITCH(p, q) {
            CASE("hij") {
                R;
            }
            CASE("efg") {
                S;
            }
            CASE("c-") {
                T;
            }
            CASE("klm") {
                U;
            }

            CASE("d-") {
                V;
            }
            CASE("a") {
                W;
                X;
            }
            CASE("b-") {
                Y;
                Z;
            }
        }
        suffix;
        """

    EXPECTED_LARGE = """
        prefix;
        switch (q) {
        case 1: {
            if (LIKELY((p[0] | 0x20) == 'a')) {
                W;
                X;
            }
        } break;
        case 2: {
            if (LIKELY(p[1] == '-')) {
                switch ((p[0] | 0x20)) {
                case 'b': {
                    Y;
                    Z;
                } break;
                case 'c': {
                    T;
                } break;
                case 'd': {
                    V;
                } break;
                }
            }
        } break;
        case 3: {
            switch ((p[0] | 0x20)) {
            case 'e': {
                if (LIKELY((p[1] | 0x20) == 'f' && (p[2] | 0x20) == 'g')) {
                    S;
                }
            } break;
            case 'h': {
                if (LIKELY((p[1] | 0x20) == 'i' && (p[2] | 0x20) == 'j')) {
                    R;
                }
            } break;
            case 'k': {
                if (LIKELY((p[1] | 0x20) == 'l' && (p[2] | 0x20) == 'm')) {
                    U;
                }
            } break;
            }
        } break;
        }
        suffix;
        """

    def validate(self, source, expected):
        with tempfile.NamedTemporaryFile() as input_file:
            with tempfile.NamedTemporaryFile() as generated_file:
                input_file.write(source)
                input_file.flush()
                process_file(input_file.name, generated_file.name)
                # Our code generation does not yet implement pretty indentation.
                actual = generated_file.read().replace('    ', '')
                expected = expected.replace('    ', '')
                self.assertEquals(actual, expected)

    def test_small(self):
        self.validate(ProcessFileTest.SOURCE_SMALL, ProcessFileTest.EXPECTED_SMALL)

    def test_medium(self):
        self.validate(ProcessFileTest.SOURCE_MEDIUM, ProcessFileTest.EXPECTED_MEDIUM)

    def test_large(self):
        self.validate(ProcessFileTest.SOURCE_LARGE, ProcessFileTest.EXPECTED_LARGE)


if __name__ == "__main__":
    unittest.main()
