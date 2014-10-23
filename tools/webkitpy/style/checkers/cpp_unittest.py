# -*- coding: utf-8; -*-
#
# Copyright (C) 2011 Google Inc. All rights reserved.
# Copyright (C) 2009 Torch Mobile Inc.
# Copyright (C) 2009 Apple Inc. All rights reserved.
# Copyright (C) 2010 Chris Jerdonek (cjerdonek@webkit.org)
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
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

"""Unit test for cpp_style.py."""

# FIXME: Add a good test that tests UpdateIncludeState.

import os
import random
import re
import unittest

import cpp as cpp_style
from cpp import CppChecker
from ..filter import FilterConfiguration
from webkitpy.common.system.filesystem import FileSystem

# This class works as an error collector and replaces cpp_style.Error
# function for the unit tests.  We also verify each category we see
# is in STYLE_CATEGORIES, to help keep that list up to date.
class ErrorCollector:
    _all_style_categories = CppChecker.categories
    # This is a list including all categories seen in any unit test.
    _seen_style_categories = {}

    def __init__(self, assert_fn, filter=None, lines_to_check=None):
        """assert_fn: a function to call when we notice a problem.
           filter: filters the errors that we are concerned about."""
        self._assert_fn = assert_fn
        self._errors = []
        self._lines_to_check = lines_to_check
        if not filter:
            filter = FilterConfiguration()
        self._filter = filter

    def __call__(self, line_number, category, confidence, message):
        self._assert_fn(category in self._all_style_categories,
                        'Message "%s" has category "%s",'
                        ' which is not in STYLE_CATEGORIES' % (message, category))

        if self._lines_to_check and not line_number in self._lines_to_check:
            return False

        if self._filter.should_check(category, ""):
            self._seen_style_categories[category] = 1
            self._errors.append('%s  [%s] [%d]' % (message, category, confidence))
        return True

    def results(self):
        if len(self._errors) < 2:
            return ''.join(self._errors)  # Most tests expect to have a string.
        else:
            return self._errors  # Let's give a list if there is more than one.

    def result_list(self):
        return self._errors

    def verify_all_categories_are_seen(self):
        """Fails if there's a category in _all_style_categories - _seen_style_categories.

        This should only be called after all tests are run, so
        _seen_style_categories has had a chance to fully populate.  Since
        this isn't called from within the normal unittest framework, we
        can't use the normal unittest assert macros.  Instead we just exit
        when we see an error.  Good thing this test is always run last!
        """
        for category in self._all_style_categories:
            if category not in self._seen_style_categories:
                import sys
                sys.exit('FATAL ERROR: There are no tests for category "%s"' % category)


class CppFunctionsTest(unittest.TestCase):

    """Supports testing functions that do not need CppStyleTestBase."""

    def test_convert_to_lower_with_underscores(self):
        self.assertEqual(cpp_style._convert_to_lower_with_underscores('ABC'), 'abc')
        self.assertEqual(cpp_style._convert_to_lower_with_underscores('aB'), 'a_b')
        self.assertEqual(cpp_style._convert_to_lower_with_underscores('isAName'), 'is_a_name')
        self.assertEqual(cpp_style._convert_to_lower_with_underscores('AnotherTest'), 'another_test')
        self.assertEqual(cpp_style._convert_to_lower_with_underscores('PassRefPtr<MyClass>'), 'pass_ref_ptr<my_class>')
        self.assertEqual(cpp_style._convert_to_lower_with_underscores('_ABC'), '_abc')

    def test_create_acronym(self):
        self.assertEqual(cpp_style._create_acronym('ABC'), 'ABC')
        self.assertEqual(cpp_style._create_acronym('IsAName'), 'IAN')
        self.assertEqual(cpp_style._create_acronym('PassRefPtr<MyClass>'), 'PRP<MC>')

    def test_is_c_or_objective_c(self):
        clean_lines = cpp_style.CleansedLines([''])
        clean_objc_lines = cpp_style.CleansedLines(['#import "header.h"'])
        self.assertTrue(cpp_style._FileState(clean_lines, 'c').is_c_or_objective_c())
        self.assertTrue(cpp_style._FileState(clean_lines, 'm').is_c_or_objective_c())
        self.assertFalse(cpp_style._FileState(clean_lines, 'cpp').is_c_or_objective_c())
        self.assertFalse(cpp_style._FileState(clean_lines, 'cc').is_c_or_objective_c())
        self.assertFalse(cpp_style._FileState(clean_lines, 'h').is_c_or_objective_c())
        self.assertTrue(cpp_style._FileState(clean_objc_lines, 'h').is_c_or_objective_c())

    def test_parameter(self):
        # Test type.
        parameter = cpp_style.Parameter('ExceptionCode', 13, 1)
        self.assertEqual(parameter.type, 'ExceptionCode')
        self.assertEqual(parameter.name, '')
        self.assertEqual(parameter.row, 1)

        # Test type and name.
        parameter = cpp_style.Parameter('PassRefPtr<MyClass> parent', 19, 1)
        self.assertEqual(parameter.type, 'PassRefPtr<MyClass>')
        self.assertEqual(parameter.name, 'parent')
        self.assertEqual(parameter.row, 1)

        # Test type, no name, with default value.
        parameter = cpp_style.Parameter('MyClass = 0', 7, 0)
        self.assertEqual(parameter.type, 'MyClass')
        self.assertEqual(parameter.name, '')
        self.assertEqual(parameter.row, 0)

        # Test type, name, and default value.
        parameter = cpp_style.Parameter('MyClass a = 0', 7, 0)
        self.assertEqual(parameter.type, 'MyClass')
        self.assertEqual(parameter.name, 'a')
        self.assertEqual(parameter.row, 0)

    def test_single_line_view(self):
        start_position = cpp_style.Position(row=1, column=1)
        end_position = cpp_style.Position(row=3, column=1)
        single_line_view = cpp_style.SingleLineView(['0', 'abcde', 'fgh', 'i'], start_position, end_position)
        self.assertEqual(single_line_view.single_line, 'bcde fgh i')
        self.assertEqual(single_line_view.convert_column_to_row(0), 1)
        self.assertEqual(single_line_view.convert_column_to_row(4), 1)
        self.assertEqual(single_line_view.convert_column_to_row(5), 2)
        self.assertEqual(single_line_view.convert_column_to_row(8), 2)
        self.assertEqual(single_line_view.convert_column_to_row(9), 3)
        self.assertEqual(single_line_view.convert_column_to_row(100), 3)

        start_position = cpp_style.Position(row=0, column=3)
        end_position = cpp_style.Position(row=0, column=4)
        single_line_view = cpp_style.SingleLineView(['abcdef'], start_position, end_position)
        self.assertEqual(single_line_view.single_line, 'd')

    def test_create_skeleton_parameters(self):
        self.assertEqual(cpp_style.create_skeleton_parameters(''), '')
        self.assertEqual(cpp_style.create_skeleton_parameters(' '), ' ')
        self.assertEqual(cpp_style.create_skeleton_parameters('long'), 'long,')
        self.assertEqual(cpp_style.create_skeleton_parameters('const unsigned long int'), '                    int,')
        self.assertEqual(cpp_style.create_skeleton_parameters('long int*'), '     int ,')
        self.assertEqual(cpp_style.create_skeleton_parameters('PassRefPtr<Foo> a'), 'PassRefPtr      a,')
        self.assertEqual(cpp_style.create_skeleton_parameters(
                'ComplexTemplate<NestedTemplate1<MyClass1, MyClass2>, NestedTemplate1<MyClass1, MyClass2> > param, int second'),
                          'ComplexTemplate                                                                            param, int second,')
        self.assertEqual(cpp_style.create_skeleton_parameters('int = 0, Namespace::Type& a'), 'int    ,            Type  a,')
        # Create skeleton parameters is a bit too aggressive with function variables, but
        # it allows for parsing other parameters and declarations like this are rare.
        self.assertEqual(cpp_style.create_skeleton_parameters('void (*fn)(int a, int b), Namespace::Type& a'),
                          'void                    ,            Type  a,')

        # This doesn't look like functions declarations but the simplifications help to eliminate false positives.
        self.assertEqual(cpp_style.create_skeleton_parameters('b{d}'), 'b   ,')

    def test_find_parameter_name_index(self):
        self.assertEqual(cpp_style.find_parameter_name_index(' int a '), 5)
        self.assertEqual(cpp_style.find_parameter_name_index(' PassRefPtr     '), 16)
        self.assertEqual(cpp_style.find_parameter_name_index('double'), 6)

    def test_parameter_list(self):
        elided_lines = ['int blah(PassRefPtr<MyClass> paramName,',
                        'const Other1Class& foo,',
                        'const ComplexTemplate<Class1, NestedTemplate<P1, P2> >* const * param = new ComplexTemplate<Class1, NestedTemplate<P1, P2> >(34, 42),',
                        'int* myCount = 0);']
        start_position = cpp_style.Position(row=0, column=8)
        end_position = cpp_style.Position(row=3, column=16)

        expected_parameters = ({'type': 'PassRefPtr<MyClass>', 'name': 'paramName', 'row': 0},
                               {'type': 'const Other1Class&', 'name': 'foo', 'row': 1},
                               {'type': 'const ComplexTemplate<Class1, NestedTemplate<P1, P2> >* const *', 'name': 'param', 'row': 2},
                               {'type': 'int*', 'name': 'myCount', 'row': 3})
        index = 0
        for parameter in cpp_style.parameter_list(elided_lines, start_position, end_position):
            expected_parameter = expected_parameters[index]
            self.assertEqual(parameter.type, expected_parameter['type'])
            self.assertEqual(parameter.name, expected_parameter['name'])
            self.assertEqual(parameter.row, expected_parameter['row'])
            index += 1
        self.assertEqual(index, len(expected_parameters))

    def test_check_parameter_against_text(self):
        error_collector = ErrorCollector(self.assertTrue)
        parameter = cpp_style.Parameter('FooF ooF', 4, 1)
        self.assertFalse(cpp_style._check_parameter_name_against_text(parameter, 'FooF', error_collector))
        self.assertEqual(error_collector.results(),
                          'The parameter name "ooF" adds no information, so it should be removed.  [readability/parameter_name] [5]')

class CppStyleTestBase(unittest.TestCase):
    """Provides some useful helper functions for cpp_style tests.

    Attributes:
      min_confidence: An integer that is the current minimum confidence
                      level for the tests.

    """

    # FIXME: Refactor the unit tests so the confidence level is passed
    #        explicitly, just like it is in the real code.
    min_confidence = 1;

    # Helper function to avoid needing to explicitly pass confidence
    # in all the unit test calls to cpp_style.process_file_data().
    def process_file_data(self, filename, file_extension, lines, error, fs=None):
        """Call cpp_style.process_file_data() with the min_confidence."""
        return cpp_style.process_file_data(filename, file_extension, lines,
                                           error, self.min_confidence, fs)

    def perform_lint(self, code, filename, basic_error_rules, fs=None, lines_to_check=None):
        error_collector = ErrorCollector(self.assertTrue, FilterConfiguration(basic_error_rules), lines_to_check)
        lines = code.split('\n')
        extension = filename.split('.')[1]
        self.process_file_data(filename, extension, lines, error_collector, fs)
        return error_collector.results()

    # Perform lint on single line of input and return the error message.
    def perform_single_line_lint(self, code, filename):
        basic_error_rules = ('-build/header_guard',
                             '-legal/copyright',
                             '-readability/fn_size',
                             '-readability/parameter_name',
                             '-readability/pass_ptr',
                             '-whitespace/ending_newline')
        return self.perform_lint(code, filename, basic_error_rules)

    # Perform lint over multiple lines and return the error message.
    def perform_multi_line_lint(self, code, file_extension):
        basic_error_rules = ('-build/header_guard',
                             '-legal/copyright',
                             '-readability/parameter_name',
                             '-whitespace/ending_newline')
        return self.perform_lint(code, 'test.' + file_extension, basic_error_rules)

    # Only keep some errors related to includes, namespaces and rtti.
    def perform_language_rules_check(self, filename, code, lines_to_check=None):
        basic_error_rules = ('-',
                             '+build/include',
                             '+build/include_order',
                             '+build/namespaces',
                             '+runtime/rtti')
        return self.perform_lint(code, filename, basic_error_rules, lines_to_check=lines_to_check)

    # Only keep function length errors.
    def perform_function_lengths_check(self, code):
        basic_error_rules = ('-',
                             '+readability/fn_size')
        return self.perform_lint(code, 'test.cpp', basic_error_rules)

    # Only keep pass ptr errors.
    def perform_pass_ptr_check(self, code):
        basic_error_rules = ('-',
                             '+readability/pass_ptr')
        return self.perform_lint(code, 'test.cpp', basic_error_rules)

    # Only keep leaky pattern errors.
    def perform_leaky_pattern_check(self, code):
        basic_error_rules = ('-',
                             '+runtime/leaky_pattern')
        return self.perform_lint(code, 'test.cpp', basic_error_rules)

    # Only include what you use errors.
    def perform_include_what_you_use(self, code, filename='foo.h', fs=None):
        basic_error_rules = ('-',
                             '+build/include_what_you_use')
        return self.perform_lint(code, filename, basic_error_rules, fs)

    def perform_avoid_static_cast_of_objects(self, code, filename='foo.cpp', fs=None):
        basic_error_rules = ('-',
                             '+runtime/casting')
        return self.perform_lint(code, filename, basic_error_rules, fs)

    # Perform lint and compare the error message with "expected_message".
    def assert_lint(self, code, expected_message, file_name='foo.cpp'):
        self.assertEqual(expected_message, self.perform_single_line_lint(code, file_name))

    def assert_lint_one_of_many_errors_re(self, code, expected_message_re, file_name='foo.cpp'):
        messages = self.perform_single_line_lint(code, file_name)
        for message in messages:
            if re.search(expected_message_re, message):
                return

        self.assertEqual(expected_message_re, messages)

    def assert_multi_line_lint(self, code, expected_message, file_name='foo.h'):
        file_extension = file_name[file_name.rfind('.') + 1:]
        self.assertEqual(expected_message, self.perform_multi_line_lint(code, file_extension))

    def assert_multi_line_lint_re(self, code, expected_message_re, file_name='foo.h'):
        file_extension = file_name[file_name.rfind('.') + 1:]
        message = self.perform_multi_line_lint(code, file_extension)
        if not re.search(expected_message_re, message):
            self.fail('Message was:\n' + message + 'Expected match to "' + expected_message_re + '"')

    def assert_language_rules_check(self, file_name, code, expected_message, lines_to_check=None):
        self.assertEqual(expected_message,
                          self.perform_language_rules_check(file_name, code, lines_to_check))

    def assert_include_what_you_use(self, code, expected_message):
        self.assertEqual(expected_message,
                          self.perform_include_what_you_use(code))

    def assert_blank_lines_check(self, lines, start_errors, end_errors):
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data('foo.cpp', 'cpp', lines, error_collector)
        self.assertEqual(
            start_errors,
            error_collector.results().count(
                'Blank line at the start of a code block.  Is this needed?'
                '  [whitespace/blank_line] [2]'))
        self.assertEqual(
            end_errors,
            error_collector.results().count(
                'Blank line at the end of a code block.  Is this needed?'
                '  [whitespace/blank_line] [3]'))

    def assert_positions_equal(self, position, tuple_position):
        """Checks if the two positions are equal.

        position: a cpp_style.Position object.
        tuple_position: a tuple (row, column) to compare against."""
        self.assertEqual(position, cpp_style.Position(tuple_position[0], tuple_position[1]),
                          'position %s, tuple_position %s' % (position, tuple_position))


class FunctionDetectionTest(CppStyleTestBase):
    def perform_function_detection(self, lines, function_information, detection_line=0):
        clean_lines = cpp_style.CleansedLines(lines)
        function_state = cpp_style._FunctionState(5)
        error_collector = ErrorCollector(self.assertTrue)
        cpp_style.detect_functions(clean_lines, detection_line, function_state, error_collector)
        if not function_information:
            self.assertEqual(function_state.in_a_function, False)
            return
        self.assertEqual(function_state.in_a_function, True)
        self.assertEqual(function_state.current_function, function_information['name'] + '()')
        self.assertEqual(function_state.modifiers_and_return_type(), function_information['modifiers_and_return_type'])
        self.assertEqual(function_state.is_pure, function_information['is_pure'])
        self.assertEqual(function_state.is_declaration, function_information['is_declaration'])
        self.assert_positions_equal(function_state.function_name_start_position, function_information['function_name_start_position'])
        self.assert_positions_equal(function_state.parameter_start_position, function_information['parameter_start_position'])
        self.assert_positions_equal(function_state.parameter_end_position, function_information['parameter_end_position'])
        self.assert_positions_equal(function_state.body_start_position, function_information['body_start_position'])
        self.assert_positions_equal(function_state.end_position, function_information['end_position'])
        expected_parameters = function_information.get('parameter_list')
        if expected_parameters:
            actual_parameters = function_state.parameter_list()
            self.assertEqual(len(actual_parameters), len(expected_parameters))
            for index in range(len(expected_parameters)):
                actual_parameter = actual_parameters[index]
                expected_parameter = expected_parameters[index]
                self.assertEqual(actual_parameter.type, expected_parameter['type'])
                self.assertEqual(actual_parameter.name, expected_parameter['name'])
                self.assertEqual(actual_parameter.row, expected_parameter['row'])

    def test_basic_function_detection(self):
        self.perform_function_detection(
            ['void theTestFunctionName(int) {',
             '}'],
            {'name': 'theTestFunctionName',
             'modifiers_and_return_type': 'void',
             'function_name_start_position': (0, 5),
             'parameter_start_position': (0, 24),
             'parameter_end_position': (0, 29),
             'body_start_position': (0, 30),
             'end_position': (1, 1),
             'is_pure': False,
             'is_declaration': False})

    def test_function_declaration_detection(self):
        self.perform_function_detection(
            ['void aFunctionName(int);'],
            {'name': 'aFunctionName',
             'modifiers_and_return_type': 'void',
             'function_name_start_position': (0, 5),
             'parameter_start_position': (0, 18),
             'parameter_end_position': (0, 23),
             'body_start_position': (0, 23),
             'end_position': (0, 24),
             'is_pure': False,
             'is_declaration': True})

        self.perform_function_detection(
            ['CheckedInt<T> operator /(const CheckedInt<T> &lhs, const CheckedInt<T> &rhs);'],
            {'name': 'operator /',
             'modifiers_and_return_type': 'CheckedInt<T>',
             'function_name_start_position': (0, 14),
             'parameter_start_position': (0, 24),
             'parameter_end_position': (0, 76),
             'body_start_position': (0, 76),
             'end_position': (0, 77),
             'is_pure': False,
             'is_declaration': True})

        self.perform_function_detection(
            ['CheckedInt<T> operator -(const CheckedInt<T> &lhs, const CheckedInt<T> &rhs);'],
            {'name': 'operator -',
             'modifiers_and_return_type': 'CheckedInt<T>',
             'function_name_start_position': (0, 14),
             'parameter_start_position': (0, 24),
             'parameter_end_position': (0, 76),
             'body_start_position': (0, 76),
             'end_position': (0, 77),
             'is_pure': False,
             'is_declaration': True})

        self.perform_function_detection(
            ['CheckedInt<T> operator !=(const CheckedInt<T> &lhs, const CheckedInt<T> &rhs);'],
            {'name': 'operator !=',
             'modifiers_and_return_type': 'CheckedInt<T>',
             'function_name_start_position': (0, 14),
             'parameter_start_position': (0, 25),
             'parameter_end_position': (0, 77),
             'body_start_position': (0, 77),
             'end_position': (0, 78),
             'is_pure': False,
             'is_declaration': True})

        self.perform_function_detection(
            ['CheckedInt<T> operator +(const CheckedInt<T> &lhs, const CheckedInt<T> &rhs);'],
            {'name': 'operator +',
             'modifiers_and_return_type': 'CheckedInt<T>',
             'function_name_start_position': (0, 14),
             'parameter_start_position': (0, 24),
             'parameter_end_position': (0, 76),
             'body_start_position': (0, 76),
             'end_position': (0, 77),
             'is_pure': False,
             'is_declaration': True})

    def test_pure_function_detection(self):
        self.perform_function_detection(
            ['virtual void theTestFunctionName(int = 0);'],
            {'name': 'theTestFunctionName',
             'modifiers_and_return_type': 'virtual void',
             'function_name_start_position': (0, 13),
             'parameter_start_position': (0, 32),
             'parameter_end_position': (0, 41),
             'body_start_position': (0, 41),
             'end_position': (0, 42),
             'is_pure': False,
             'is_declaration': True})

        self.perform_function_detection(
            ['virtual void theTestFunctionName(int) = 0;'],
            {'name': 'theTestFunctionName',
             'modifiers_and_return_type': 'virtual void',
             'function_name_start_position': (0, 13),
             'parameter_start_position': (0, 32),
             'parameter_end_position': (0, 37),
             'body_start_position': (0, 41),
             'end_position': (0, 42),
             'is_pure': True,
             'is_declaration': True})

        # Hopefully, no one writes code like this but it is a tricky case.
        self.perform_function_detection(
            ['virtual void theTestFunctionName(int)',
             ' = ',
             ' 0 ;'],
            {'name': 'theTestFunctionName',
             'modifiers_and_return_type': 'virtual void',
             'function_name_start_position': (0, 13),
             'parameter_start_position': (0, 32),
             'parameter_end_position': (0, 37),
             'body_start_position': (2, 3),
             'end_position': (2, 4),
             'is_pure': True,
             'is_declaration': True})

    def test_ignore_macros(self):
        self.perform_function_detection(['void aFunctionName(int); \\'], None)

    def test_non_functions(self):
        # This case exposed an error because the open brace was in quotes.
        self.perform_function_detection(
            ['asm(',
             '    "stmdb sp!, {r1-r3}" "\n"',
             ');'],
            # This isn't a function but it looks like one to our simple
            # algorithm and that is ok.
            {'name': 'asm',
             'modifiers_and_return_type': '',
             'function_name_start_position': (0, 0),
             'parameter_start_position': (0, 3),
             'parameter_end_position': (2, 1),
             'body_start_position': (2, 1),
             'end_position': (2, 2),
             'is_pure': False,
             'is_declaration': True})

        # Simple test case with something that is not a function.
        self.perform_function_detection(['class Stuff;'], None)

    def test_parameter_list(self):
        # A function with no arguments.
        function_state = self.perform_function_detection(
            ['void functionName();'],
            {'name': 'functionName',
             'modifiers_and_return_type': 'void',
             'function_name_start_position': (0, 5),
             'parameter_start_position': (0, 17),
             'parameter_end_position': (0, 19),
             'body_start_position': (0, 19),
             'end_position': (0, 20),
             'is_pure': False,
             'is_declaration': True,
             'parameter_list': ()})

        # A function with one argument.
        function_state = self.perform_function_detection(
            ['void functionName(int);'],
            {'name': 'functionName',
             'modifiers_and_return_type': 'void',
             'function_name_start_position': (0, 5),
             'parameter_start_position': (0, 17),
             'parameter_end_position': (0, 22),
             'body_start_position': (0, 22),
             'end_position': (0, 23),
             'is_pure': False,
             'is_declaration': True,
             'parameter_list':
                 ({'type': 'int', 'name': '', 'row': 0},)})

        # A function with unsigned and short arguments
        function_state = self.perform_function_detection(
            ['void functionName(unsigned a, short b, long c, long long short unsigned int);'],
            {'name': 'functionName',
             'modifiers_and_return_type': 'void',
             'function_name_start_position': (0, 5),
             'parameter_start_position': (0, 17),
             'parameter_end_position': (0, 76),
             'body_start_position': (0, 76),
             'end_position': (0, 77),
             'is_pure': False,
             'is_declaration': True,
             'parameter_list':
                 ({'type': 'unsigned', 'name': 'a', 'row': 0},
                  {'type': 'short', 'name': 'b', 'row': 0},
                  {'type': 'long', 'name': 'c', 'row': 0},
                  {'type': 'long long short unsigned int', 'name': '', 'row': 0})})

        # Some parameter type with modifiers and no parameter names.
        function_state = self.perform_function_detection(
            ['virtual void determineARIADropEffects(Vector<String>*&, const unsigned long int*&, const MediaPlayer::Preload, Other<Other2, Other3<P1, P2> >, int);'],
            {'name': 'determineARIADropEffects',
             'modifiers_and_return_type': 'virtual void',
             'parameter_start_position': (0, 37),
             'function_name_start_position': (0, 13),
             'parameter_end_position': (0, 147),
             'body_start_position': (0, 147),
             'end_position': (0, 148),
             'is_pure': False,
             'is_declaration': True,
             'parameter_list':
                 ({'type': 'Vector<String>*&', 'name': '', 'row': 0},
                  {'type': 'const unsigned long int*&', 'name': '', 'row': 0},
                  {'type': 'const MediaPlayer::Preload', 'name': '', 'row': 0},
                  {'type': 'Other<Other2, Other3<P1, P2> >', 'name': '', 'row': 0},
                  {'type': 'int', 'name': '', 'row': 0})})

        # Try parsing a function with a very complex definition.
        function_state = self.perform_function_detection(
            ['#define MyMacro(a) a',
             'virtual',
             'AnotherTemplate<Class1, Class2> aFunctionName(PassRefPtr<MyClass> paramName,',
             'const Other1Class& foo,',
             'const ComplexTemplate<Class1, NestedTemplate<P1, P2> >* const * param = new ComplexTemplate<Class1, NestedTemplate<P1, P2> >(34, 42),',
             'int* myCount = 0);'],
            {'name': 'aFunctionName',
             'modifiers_and_return_type': 'virtual AnotherTemplate<Class1, Class2>',
             'function_name_start_position': (2, 32),
             'parameter_start_position': (2, 45),
             'parameter_end_position': (5, 17),
             'body_start_position': (5, 17),
             'end_position': (5, 18),
             'is_pure': False,
             'is_declaration': True,
             'parameter_list':
                 ({'type': 'PassRefPtr<MyClass>', 'name': 'paramName', 'row': 2},
                  {'type': 'const Other1Class&', 'name': 'foo', 'row': 3},
                  {'type': 'const ComplexTemplate<Class1, NestedTemplate<P1, P2> >* const *', 'name': 'param', 'row': 4},
                  {'type': 'int*', 'name': 'myCount', 'row': 5})},
            detection_line=2)


class CppStyleTest(CppStyleTestBase):

    def test_asm_lines_ignored(self):
        self.assert_lint(
            '__asm mov [registration], eax',
            '')

    # Test get line width.
    def test_get_line_width(self):
        self.assertEqual(0, cpp_style.get_line_width(''))
        self.assertEqual(10, cpp_style.get_line_width(u'x' * 10))
        self.assertEqual(16, cpp_style.get_line_width(u'都|道|府|県|支庁'))

    def test_find_next_multi_line_comment_start(self):
        self.assertEqual(1, cpp_style.find_next_multi_line_comment_start([''], 0))

        lines = ['a', 'b', '/* c']
        self.assertEqual(2, cpp_style.find_next_multi_line_comment_start(lines, 0))

        lines = ['char a[] = "/*";']  # not recognized as comment.
        self.assertEqual(1, cpp_style.find_next_multi_line_comment_start(lines, 0))

    def test_find_next_multi_line_comment_end(self):
        self.assertEqual(1, cpp_style.find_next_multi_line_comment_end([''], 0))
        lines = ['a', 'b', ' c */']
        self.assertEqual(2, cpp_style.find_next_multi_line_comment_end(lines, 0))

    def test_remove_multi_line_comments_from_range(self):
        lines = ['a', '  /* comment ', ' * still comment', ' comment */   ', 'b']
        cpp_style.remove_multi_line_comments_from_range(lines, 1, 4)
        self.assertEqual(['a', '// dummy', '// dummy', '// dummy', 'b'], lines)

    def test_position(self):
        position = cpp_style.Position(3, 4)
        self.assert_positions_equal(position, (3, 4))
        self.assertEqual(position.row, 3)
        self.assertTrue(position > cpp_style.Position(position.row - 1, position.column + 1))
        self.assertTrue(position > cpp_style.Position(position.row, position.column - 1))
        self.assertTrue(position < cpp_style.Position(position.row, position.column + 1))
        self.assertTrue(position < cpp_style.Position(position.row + 1, position.column - 1))
        self.assertEqual(position.__str__(), '(3, 4)')

    def test_rfind_in_lines(self):
        not_found_position = cpp_style.Position(10, 11)
        start_position = cpp_style.Position(2, 2)
        lines = ['ab', 'ace', 'test']
        self.assertEqual(not_found_position, cpp_style._rfind_in_lines('st', lines, start_position, not_found_position))
        self.assertTrue(cpp_style.Position(1, 1) == cpp_style._rfind_in_lines('a', lines, start_position, not_found_position))
        self.assertEqual(cpp_style.Position(2, 2), cpp_style._rfind_in_lines('(te|a)', lines, start_position, not_found_position))

    def test_close_expression(self):
        self.assertEqual(cpp_style.Position(1, -1), cpp_style.close_expression([')('], cpp_style.Position(0, 1)))
        self.assertEqual(cpp_style.Position(1, -1), cpp_style.close_expression([') ()'], cpp_style.Position(0, 1)))
        self.assertEqual(cpp_style.Position(0, 4), cpp_style.close_expression([')[)]'], cpp_style.Position(0, 1)))
        self.assertEqual(cpp_style.Position(0, 5), cpp_style.close_expression(['}{}{}'], cpp_style.Position(0, 3)))
        self.assertEqual(cpp_style.Position(1, 1), cpp_style.close_expression(['}{}{', '}'], cpp_style.Position(0, 3)))
        self.assertEqual(cpp_style.Position(2, -1), cpp_style.close_expression(['][][', ' '], cpp_style.Position(0, 3)))

    def test_spaces_at_end_of_line(self):
        self.assert_lint(
            '// Hello there ',
            'Line ends in whitespace.  Consider deleting these extra spaces.'
            '  [whitespace/end_of_line] [4]')

    # Test C-style cast cases.
    def test_cstyle_cast(self):
        self.assert_lint(
            'int a = (int)1.0;',
            'Using C-style cast.  Use static_cast<int>(...) instead'
            '  [readability/casting] [4]')
        self.assert_lint(
            'int *a = (int *)DEFINED_VALUE;',
            'Using C-style cast.  Use reinterpret_cast<int *>(...) instead'
            '  [readability/casting] [4]', 'foo.c')
        self.assert_lint(
            'uint16 a = (uint16)1.0;',
            'Using C-style cast.  Use static_cast<uint16>(...) instead'
            '  [readability/casting] [4]')
        self.assert_lint(
            'int32 a = (int32)1.0;',
            'Using C-style cast.  Use static_cast<int32>(...) instead'
            '  [readability/casting] [4]')
        self.assert_lint(
            'uint64 a = (uint64)1.0;',
            'Using C-style cast.  Use static_cast<uint64>(...) instead'
            '  [readability/casting] [4]')

    # Test taking address of casts (runtime/casting)
    def test_runtime_casting(self):
        self.assert_lint(
            'int* x = &static_cast<int*>(foo);',
            'Are you taking an address of a cast?  '
            'This is dangerous: could be a temp var.  '
            'Take the address before doing the cast, rather than after'
            '  [runtime/casting] [4]')

        self.assert_lint(
            'int* x = &dynamic_cast<int *>(foo);',
            ['Are you taking an address of a cast?  '
             'This is dangerous: could be a temp var.  '
             'Take the address before doing the cast, rather than after'
             '  [runtime/casting] [4]',
             'Do not use dynamic_cast<>.  If you need to cast within a class '
             'hierarchy, use static_cast<> to upcast.  Google doesn\'t support '
             'RTTI.  [runtime/rtti] [5]'])

        self.assert_lint(
            'int* x = &reinterpret_cast<int *>(foo);',
            'Are you taking an address of a cast?  '
            'This is dangerous: could be a temp var.  '
            'Take the address before doing the cast, rather than after'
            '  [runtime/casting] [4]')

        # It's OK to cast an address.
        self.assert_lint(
            'int* x = reinterpret_cast<int *>(&foo);',
            '')

    def test_runtime_selfinit(self):
        self.assert_lint(
            'Foo::Foo(Bar r, Bel l) : r_(r_), l_(l_) { }',
            'You seem to be initializing a member variable with itself.'
            '  [runtime/init] [4]')
        self.assert_lint(
            'Foo::Foo(Bar r, Bel l) : r_(r), l_(l) { }',
            '')
        self.assert_lint(
            'Foo::Foo(Bar r) : r_(r), l_(r_), ll_(l_) { }',
            '')

    def test_runtime_rtti(self):
        statement = 'int* x = dynamic_cast<int*>(&foo);'
        error_message = (
            'Do not use dynamic_cast<>.  If you need to cast within a class '
            'hierarchy, use static_cast<> to upcast.  Google doesn\'t support '
            'RTTI.  [runtime/rtti] [5]')
        # dynamic_cast is disallowed in most files.
        self.assert_language_rules_check('foo.cpp', statement, error_message)
        self.assert_language_rules_check('foo.h', statement, error_message)

    # Tests for static_cast readability.
    def test_static_cast_on_objects_with_toFoo(self):
        mock_header_contents = ['inline Foo* toFoo(Bar* bar)']
        fs = FileSystem()
        orig_read_text_file_fn = fs.read_text_file

        def mock_read_text_file_fn(path):
            return mock_header_contents

        try:
            fs.read_text_file = mock_read_text_file_fn
            message = self.perform_avoid_static_cast_of_objects(
                'Foo* x = static_cast<Foo*>(bar);',
                filename='casting.cpp',
                fs=fs)
            self.assertEqual(message, 'static_cast of class objects is not allowed. Use toFoo defined in Foo.h.'
                                      '  [runtime/casting] [4]')
        finally:
            fs.read_text_file = orig_read_text_file_fn

    def test_static_cast_on_objects_without_toFoo(self):
        mock_header_contents = ['inline FooBar* toFooBar(Bar* bar)']
        fs = FileSystem()
        orig_read_text_file_fn = fs.read_text_file

        def mock_read_text_file_fn(path):
            return mock_header_contents

        try:
            fs.read_text_file = mock_read_text_file_fn
            message = self.perform_avoid_static_cast_of_objects(
                'Foo* x = static_cast<Foo*>(bar);',
                filename='casting.cpp',
                fs=fs)
            self.assertEqual(message, 'static_cast of class objects is not allowed. Add toFoo in Foo.h and use it instead.'
                                      '  [runtime/casting] [4]')
        finally:
            fs.read_text_file = orig_read_text_file_fn

    # We cannot test this functionality because of difference of
    # function definitions.  Anyway, we may never enable this.
    #
    # # Test for unnamed arguments in a method.
    # def test_check_for_unnamed_params(self):
    #   message = ('All parameters should be named in a function'
    #              '  [readability/function] [3]')
    #   self.assert_lint('virtual void A(int*) const;', message)
    #   self.assert_lint('virtual void B(void (*fn)(int*));', message)
    #   self.assert_lint('virtual void C(int*);', message)
    #   self.assert_lint('void *(*f)(void *) = x;', message)
    #   self.assert_lint('void Method(char*) {', message)
    #   self.assert_lint('void Method(char*);', message)
    #   self.assert_lint('void Method(char* /*x*/);', message)
    #   self.assert_lint('typedef void (*Method)(int32);', message)
    #   self.assert_lint('static void operator delete[](void*) throw();', message)
    #
    #   self.assert_lint('virtual void D(int* p);', '')
    #   self.assert_lint('void operator delete(void* x) throw();', '')
    #   self.assert_lint('void Method(char* x)\n{', '')
    #   self.assert_lint('void Method(char* /*x*/)\n{', '')
    #   self.assert_lint('void Method(char* x);', '')
    #   self.assert_lint('typedef void (*Method)(int32 x);', '')
    #   self.assert_lint('static void operator delete[](void* x) throw();', '')
    #   self.assert_lint('static void operator delete[](void* /*x*/) throw();', '')
    #
    #   # This one should technically warn, but doesn't because the function
    #   # pointer is confusing.
    #   self.assert_lint('virtual void E(void (*fn)(int* p));', '')

    # Test deprecated casts such as int(d)
    def test_deprecated_cast(self):
        self.assert_lint(
            'int a = int(2.2);',
            'Using deprecated casting style.  '
            'Use static_cast<int>(...) instead'
            '  [readability/casting] [4]')
        # Checks for false positives...
        self.assert_lint(
            'int a = int(); // Constructor, o.k.',
            '')
        self.assert_lint(
            'X::X() : a(int()) { } // default Constructor, o.k.',
            '')
        self.assert_lint(
            'operator bool(); // Conversion operator, o.k.',
            '')

    # The second parameter to a gMock method definition is a function signature
    # that often looks like a bad cast but should not picked up by lint.
    def test_mock_method(self):
        self.assert_lint(
            'MOCK_METHOD0(method, int());',
            '')
        self.assert_lint(
            'MOCK_CONST_METHOD1(method, float(string));',
            '')
        self.assert_lint(
            'MOCK_CONST_METHOD2_T(method, double(float, float));',
            '')

    # Test sizeof(type) cases.
    def test_sizeof_type(self):
        self.assert_lint(
            'sizeof(int);',
            'Using sizeof(type).  Use sizeof(varname) instead if possible'
            '  [runtime/sizeof] [1]')
        self.assert_lint(
            'sizeof(int *);',
            'Using sizeof(type).  Use sizeof(varname) instead if possible'
            '  [runtime/sizeof] [1]')

    # Test typedef cases.  There was a bug that cpp_style misidentified
    # typedef for pointer to function as C-style cast and produced
    # false-positive error messages.
    def test_typedef_for_pointer_to_function(self):
        self.assert_lint(
            'typedef void (*Func)(int x);',
            '')
        self.assert_lint(
            'typedef void (*Func)(int *x);',
            '')
        self.assert_lint(
            'typedef void Func(int x);',
            '')
        self.assert_lint(
            'typedef void Func(int *x);',
            '')

    def test_include_what_you_use_no_implementation_files(self):
        code = 'std::vector<int> foo;'
        self.assertEqual('Add #include <vector> for vector<>'
                          '  [build/include_what_you_use] [4]',
                          self.perform_include_what_you_use(code, 'foo.h'))
        self.assertEqual('',
                          self.perform_include_what_you_use(code, 'foo.cpp'))

    def test_include_what_you_use(self):
        self.assert_include_what_you_use(
            '''#include <vector>
               std::vector<int> foo;
            ''',
            '')
        self.assert_include_what_you_use(
            '''#include <map>
               std::pair<int,int> foo;
            ''',
            '')
        self.assert_include_what_you_use(
            '''#include <multimap>
               std::pair<int,int> foo;
            ''',
            '')
        self.assert_include_what_you_use(
            '''#include <hash_map>
               std::pair<int,int> foo;
            ''',
            '')
        self.assert_include_what_you_use(
            '''#include <utility>
               std::pair<int,int> foo;
            ''',
            '')
        self.assert_include_what_you_use(
            '''#include <vector>
               DECLARE_string(foobar);
            ''',
            '')
        self.assert_include_what_you_use(
            '''#include <vector>
               DEFINE_string(foobar, "", "");
            ''',
            '')
        self.assert_include_what_you_use(
            '''#include <vector>
               std::pair<int,int> foo;
            ''',
            'Add #include <utility> for pair<>'
            '  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include "base/foobar.h"
               std::vector<int> foo;
            ''',
            'Add #include <vector> for vector<>'
            '  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include <vector>
               std::set<int> foo;
            ''',
            'Add #include <set> for set<>'
            '  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include "base/foobar.h"
              hash_map<int, int> foobar;
            ''',
            'Add #include <hash_map> for hash_map<>'
            '  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include "base/foobar.h"
               bool foobar = std::less<int>(0,1);
            ''',
            'Add #include <functional> for less<>'
            '  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include "base/foobar.h"
               bool foobar = min<int>(0,1);
            ''',
            'Add #include <algorithm> for min  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            'void a(const string &foobar);',
            'Add #include <string> for string  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include "base/foobar.h"
               bool foobar = swap(0,1);
            ''',
            'Add #include <algorithm> for swap  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include "base/foobar.h"
               bool foobar = transform(a.begin(), a.end(), b.start(), Foo);
            ''',
            'Add #include <algorithm> for transform  '
            '[build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include "base/foobar.h"
               bool foobar = min_element(a.begin(), a.end());
            ''',
            'Add #include <algorithm> for min_element  '
            '[build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''foo->swap(0,1);
               foo.swap(0,1);
            ''',
            '')
        self.assert_include_what_you_use(
            '''#include <string>
               void a(const std::multimap<int,string> &foobar);
            ''',
            'Add #include <map> for multimap<>'
            '  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include <queue>
               void a(const std::priority_queue<int> &foobar);
            ''',
            '')
        self.assert_include_what_you_use(
             '''#include "base/basictypes.h"
                #include "base/port.h"
                #include <assert.h>
                #include <string>
                #include <vector>
                vector<string> hajoa;''', '')
        self.assert_include_what_you_use(
            '''#include <string>
               int i = numeric_limits<int>::max()
            ''',
            'Add #include <limits> for numeric_limits<>'
            '  [build/include_what_you_use] [4]')
        self.assert_include_what_you_use(
            '''#include <limits>
               int i = numeric_limits<int>::max()
            ''',
            '')

        # Test the UpdateIncludeState code path.
        mock_header_contents = ['#include "blah/foo.h"', '#include "blah/bar.h"']
        fs = FileSystem()
        orig_read_text_file_fn = fs.read_text_file

        def mock_read_text_file_fn(path):
            return mock_header_contents

        try:
            fs.read_text_file = mock_read_text_file_fn
            message = self.perform_include_what_you_use(
                '#include "config.h"\n'
                '#include "blah/a.h"\n',
                filename='blah/a.cpp',
                fs=fs)
            self.assertEqual(message, '')

            mock_header_contents = ['#include <set>']
            message = self.perform_include_what_you_use(
                '''#include "config.h"
                   #include "blah/a.h"

                   std::set<int> foo;''',
                filename='blah/a.cpp',
                fs=fs)
            self.assertEqual(message, '')

            # If there's just a .cpp and the header can't be found then it's ok.
            message = self.perform_include_what_you_use(
                '''#include "config.h"
                   #include "blah/a.h"

                   std::set<int> foo;''',
                filename='blah/a.cpp')
            self.assertEqual(message, '')

            # Make sure we find the headers with relative paths.
            mock_header_contents = ['']
            message = self.perform_include_what_you_use(
                '''#include "config.h"
                   #include "%s%sa.h"

                   std::set<int> foo;''' % (os.path.basename(os.getcwd()), os.path.sep),
                filename='a.cpp',
                fs=fs)
            self.assertEqual(message, 'Add #include <set> for set<>  '
                                       '[build/include_what_you_use] [4]')
        finally:
            fs.read_text_file = orig_read_text_file_fn

    def test_files_belong_to_same_module(self):
        f = cpp_style.files_belong_to_same_module
        self.assertEqual((True, ''), f('a.cpp', 'a.h'))
        self.assertEqual((True, ''), f('base/google.cpp', 'base/google.h'))
        self.assertEqual((True, ''), f('base/google_test.cpp', 'base/google.h'))
        self.assertEqual((True, ''),
                          f('base/google_unittest.cpp', 'base/google.h'))
        self.assertEqual((True, ''),
                          f('base/internal/google_unittest.cpp',
                            'base/public/google.h'))
        self.assertEqual((True, 'xxx/yyy/'),
                          f('xxx/yyy/base/internal/google_unittest.cpp',
                            'base/public/google.h'))
        self.assertEqual((True, 'xxx/yyy/'),
                          f('xxx/yyy/base/google_unittest.cpp',
                            'base/public/google.h'))
        self.assertEqual((True, ''),
                          f('base/google_unittest.cpp', 'base/google-inl.h'))
        self.assertEqual((True, '/home/build/google3/'),
                          f('/home/build/google3/base/google.cpp', 'base/google.h'))

        self.assertEqual((False, ''),
                          f('/home/build/google3/base/google.cpp', 'basu/google.h'))
        self.assertEqual((False, ''), f('a.cpp', 'b.h'))

    def test_cleanse_line(self):
        self.assertEqual('int foo = 0;  ',
                          cpp_style.cleanse_comments('int foo = 0;  // danger!'))
        self.assertEqual('int o = 0;',
                          cpp_style.cleanse_comments('int /* foo */ o = 0;'))
        self.assertEqual('foo(int a, int b);',
                          cpp_style.cleanse_comments('foo(int a /* abc */, int b);'))
        self.assertEqual('f(a, b);',
                         cpp_style.cleanse_comments('f(a, /* name */ b);'))
        self.assertEqual('f(a, b);',
                         cpp_style.cleanse_comments('f(a /* name */, b);'))
        self.assertEqual('f(a, b);',
                         cpp_style.cleanse_comments('f(a, /* name */b);'))

    def test_multi_line_comments(self):
        # missing explicit is bad
        self.assert_multi_line_lint(
            r'''int a = 0;
                /* multi-liner
                class Foo {
                Foo(int f);  // should cause a lint warning in code
                }
            */ ''',
        '')
        self.assert_multi_line_lint(
            '''\
            /* int a = 0; multi-liner
            static const int b = 0;''',
            ['Could not find end of multi-line comment'
             '  [readability/multiline_comment] [5]',
             'Complex multi-line /*...*/-style comment found. '
             'Lint may give bogus warnings.  Consider replacing these with '
             '//-style comments, with #if 0...#endif, or with more clearly '
             'structured multi-line comments.  [readability/multiline_comment] [5]'])
        self.assert_multi_line_lint(r'''    /* multi-line comment''',
                                    ['Could not find end of multi-line comment'
                                     '  [readability/multiline_comment] [5]',
                                     'Complex multi-line /*...*/-style comment found. '
                                     'Lint may give bogus warnings.  Consider replacing these with '
                                     '//-style comments, with #if 0...#endif, or with more clearly '
                                     'structured multi-line comments.  [readability/multiline_comment] [5]'])
        self.assert_multi_line_lint(r'''    // /* comment, but not multi-line''', '')

    def test_multiline_strings(self):
        multiline_string_error_message = (
            'Multi-line string ("...") found.  This lint script doesn\'t '
            'do well with such strings, and may give bogus warnings.  They\'re '
            'ugly and unnecessary, and you should use concatenation instead".'
            '  [readability/multiline_string] [5]')

        file_path = 'mydir/foo.cpp'

        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(file_path, 'cpp',
                               ['const char* str = "This is a\\',
                                ' multiline string.";'],
                               error_collector)
        self.assertEqual(
            2,  # One per line.
            error_collector.result_list().count(multiline_string_error_message))

    # Test non-explicit single-argument constructors
    def test_explicit_single_argument_constructors(self):
        # missing explicit is bad
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Foo(int f);
            };''',
            'Single-argument constructors should be marked explicit.'
            '  [runtime/explicit] [5]')
        # missing explicit is bad, even with whitespace
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Foo (int f);
            };''',
            ['Extra space before ( in function call  [whitespace/parens] [4]',
             'Single-argument constructors should be marked explicit.'
             '  [runtime/explicit] [5]'])
        # missing explicit, with distracting comment, is still bad
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Foo(int f); // simpler than Foo(blargh, blarg)
            };''',
            'Single-argument constructors should be marked explicit.'
            '  [runtime/explicit] [5]')
        # missing explicit, with qualified classname
        self.assert_multi_line_lint(
            '''\
            class Qualifier::AnotherOne::Foo {
                Foo(int f);
            };''',
            'Single-argument constructors should be marked explicit.'
            '  [runtime/explicit] [5]')
        # structs are caught as well.
        self.assert_multi_line_lint(
            '''\
            struct Foo {
                Foo(int f);
            };''',
            'Single-argument constructors should be marked explicit.'
            '  [runtime/explicit] [5]')
        # Templatized classes are caught as well.
        self.assert_multi_line_lint(
            '''\
            template<typename T> class Foo {
                Foo(int f);
            };''',
            'Single-argument constructors should be marked explicit.'
            '  [runtime/explicit] [5]')
        # proper style is okay
        self.assert_multi_line_lint(
            '''\
            class Foo {
                explicit Foo(int f);
            };''',
            '')
        # two argument constructor is okay
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Foo(int f, int b);
            };''',
            '')
        # two argument constructor, across two lines, is okay
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Foo(int f,
                    int b);
            };''',
            '')
        # non-constructor (but similar name), is okay
        self.assert_multi_line_lint(
            '''\
            class Foo {
                aFoo(int f);
            };''',
            '')
        # constructor with void argument is okay
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Foo(void);
            };''',
            '')
        # single argument method is okay
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Bar(int b);
            };''',
            '')
        # comments should be ignored
        self.assert_multi_line_lint(
            '''\
            class Foo {
            // Foo(int f);
            };''',
            '')
        # single argument function following class definition is okay
        # (okay, it's not actually valid, but we don't want a false positive)
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Foo(int f, int b);
            };
            Foo(int f);''',
            '')
        # single argument function is okay
        self.assert_multi_line_lint(
            '''static Foo(int f);''',
            '')
        # single argument copy constructor is okay.
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Foo(const Foo&);
            };''',
            '')
        self.assert_multi_line_lint(
            '''\
            class Foo {
                Foo(Foo&);
            };''',
            '')

    def test_slash_star_comment_on_single_line(self):
        self.assert_multi_line_lint(
            '''/* static */ Foo(int f);''',
            '')
        self.assert_multi_line_lint(
            '''/*/ static */  Foo(int f);''',
            '')
        self.assert_multi_line_lint(
            '''/*/ static Foo(int f);''',
            'Could not find end of multi-line comment'
            '  [readability/multiline_comment] [5]')
        self.assert_multi_line_lint(
            '''    /*/ static Foo(int f);''',
            'Could not find end of multi-line comment'
            '  [readability/multiline_comment] [5]')

    # Test suspicious usage of "if" like this:
    # if (a == b) {
    #   DoSomething();
    # } if (a == c) {   // Should be "else if".
    #   DoSomething();  // This gets called twice if a == b && a == c.
    # }
    def test_suspicious_usage_of_if(self):
        self.assert_lint(
            '    if (a == b) {',
            '')
        self.assert_lint(
            '    } if (a == b) {',
            'Did you mean "else if"? If not, start a new line for "if".'
            '  [readability/braces] [4]')

    # Test suspicious usage of memset. Specifically, a 0
    # as the final argument is almost certainly an error.
    def test_suspicious_usage_of_memset(self):
        # Normal use is okay.
        self.assert_lint(
            '    memset(buf, 0, sizeof(buf))',
            '')

        # A 0 as the final argument is almost certainly an error.
        self.assert_lint(
            '    memset(buf, sizeof(buf), 0)',
            'Did you mean "memset(buf, 0, sizeof(buf))"?'
            '  [runtime/memset] [4]')
        self.assert_lint(
            '    memset(buf, xsize * ysize, 0)',
            'Did you mean "memset(buf, 0, xsize * ysize)"?'
            '  [runtime/memset] [4]')

        # There is legitimate test code that uses this form.
        # This is okay since the second argument is a literal.
        self.assert_lint(
            "    memset(buf, 'y', 0)",
            '')
        self.assert_lint(
            '    memset(buf, 4, 0)',
            '')
        self.assert_lint(
            '    memset(buf, -1, 0)',
            '')
        self.assert_lint(
            '    memset(buf, 0xF1, 0)',
            '')
        self.assert_lint(
            '    memset(buf, 0xcd, 0)',
            '')

    def test_check_posix_threading(self):
        self.assert_lint('sctime_r()', '')
        self.assert_lint('strtok_r()', '')
        self.assert_lint('    strtok_r(foo, ba, r)', '')
        self.assert_lint('brand()', '')
        self.assert_lint('_rand()', '')
        self.assert_lint('.rand()', '')
        self.assert_lint('>rand()', '')
        self.assert_lint('rand()',
                         'Consider using rand_r(...) instead of rand(...)'
                         ' for improved thread safety.'
                         '  [runtime/threadsafe_fn] [2]')
        self.assert_lint('strtok()',
                         'Consider using strtok_r(...) '
                         'instead of strtok(...)'
                         ' for improved thread safety.'
                         '  [runtime/threadsafe_fn] [2]')

    # Test potential format string bugs like printf(foo).
    def test_format_strings(self):
        self.assert_lint('printf("foo")', '')
        self.assert_lint('printf("foo: %s", foo)', '')
        self.assert_lint('DocidForPrintf(docid)', '')  # Should not trigger.
        self.assert_lint(
            'printf(foo)',
            'Potential format string bug. Do printf("%s", foo) instead.'
            '  [runtime/printf] [4]')
        self.assert_lint(
            'printf(foo.c_str())',
            'Potential format string bug. '
            'Do printf("%s", foo.c_str()) instead.'
            '  [runtime/printf] [4]')
        self.assert_lint(
            'printf(foo->c_str())',
            'Potential format string bug. '
            'Do printf("%s", foo->c_str()) instead.'
            '  [runtime/printf] [4]')
        self.assert_lint(
            'StringPrintf(foo)',
            'Potential format string bug. Do StringPrintf("%s", foo) instead.'
            ''
            '  [runtime/printf] [4]')

    # Variable-length arrays are not permitted.
    def test_variable_length_array_detection(self):
        errmsg = ('Do not use variable-length arrays.  Use an appropriately named '
                  "('k' followed by CamelCase) compile-time constant for the size."
                  '  [runtime/arrays] [1]')

        self.assert_lint('int a[any_old_variable];', errmsg)
        self.assert_lint('int doublesize[some_var * 2];', errmsg)
        self.assert_lint('int a[afunction()];', errmsg)
        self.assert_lint('int a[function(kMaxFooBars)];', errmsg)
        self.assert_lint('bool aList[items_->size()];', errmsg)
        self.assert_lint('namespace::Type buffer[len+1];', errmsg)

        self.assert_lint('int a[64];', '')
        self.assert_lint('int a[0xFF];', '')
        self.assert_lint('int first[256], second[256];', '')
        self.assert_lint('int arrayName[kCompileTimeConstant];', '')
        self.assert_lint('char buf[somenamespace::kBufSize];', '')
        self.assert_lint('int arrayName[ALL_CAPS];', '')
        self.assert_lint('AClass array1[foo::bar::ALL_CAPS];', '')
        self.assert_lint('int a[kMaxStrLen + 1];', '')
        self.assert_lint('int a[sizeof(foo)];', '')
        self.assert_lint('int a[sizeof(*foo)];', '')
        self.assert_lint('int a[sizeof foo];', '')
        self.assert_lint('int a[sizeof(struct Foo)];', '')
        self.assert_lint('int a[128 - sizeof(const bar)];', '')
        self.assert_lint('int a[(sizeof(foo) * 4)];', '')
        self.assert_lint('int a[(arraysize(fixed_size_array)/2) << 1];', 'Missing spaces around /  [whitespace/operators] [3]')
        self.assert_lint('delete a[some_var];', '')
        self.assert_lint('return a[some_var];', '')

    # Brace usage
    def test_braces(self):
        # Braces shouldn't be followed by a ; unless they're defining a struct
        # or initializing an array
        self.assert_lint('int a[3] = { 1, 2, 3 };', '')
        self.assert_lint(
            '''\
            const int foo[] =
                {1, 2, 3 };''',
            '')
        # For single line, unmatched '}' with a ';' is ignored (not enough context)
        self.assert_multi_line_lint(
            '''\
            int a[3] = { 1,
                2,
                3 };''',
            '')
        self.assert_multi_line_lint(
            '''\
            int a[2][3] = { { 1, 2 },
                { 3, 4 } };''',
            '')
        self.assert_multi_line_lint(
            '''\
            int a[2][3] =
                { { 1, 2 },
                { 3, 4 } };''',
            '')

    # CHECK/EXPECT_TRUE/EXPECT_FALSE replacements
    def test_check_check(self):
        self.assert_lint('CHECK(x == 42)',
                         'Consider using CHECK_EQ instead of CHECK(a == b)'
                         '  [readability/check] [2]')
        self.assert_lint('CHECK(x != 42)',
                         'Consider using CHECK_NE instead of CHECK(a != b)'
                         '  [readability/check] [2]')
        self.assert_lint('CHECK(x >= 42)',
                         'Consider using CHECK_GE instead of CHECK(a >= b)'
                         '  [readability/check] [2]')
        self.assert_lint('CHECK(x > 42)',
                         'Consider using CHECK_GT instead of CHECK(a > b)'
                         '  [readability/check] [2]')
        self.assert_lint('CHECK(x <= 42)',
                         'Consider using CHECK_LE instead of CHECK(a <= b)'
                         '  [readability/check] [2]')
        self.assert_lint('CHECK(x < 42)',
                         'Consider using CHECK_LT instead of CHECK(a < b)'
                         '  [readability/check] [2]')

        self.assert_lint('DCHECK(x == 42)',
                         'Consider using DCHECK_EQ instead of DCHECK(a == b)'
                         '  [readability/check] [2]')
        self.assert_lint('DCHECK(x != 42)',
                         'Consider using DCHECK_NE instead of DCHECK(a != b)'
                         '  [readability/check] [2]')
        self.assert_lint('DCHECK(x >= 42)',
                         'Consider using DCHECK_GE instead of DCHECK(a >= b)'
                         '  [readability/check] [2]')
        self.assert_lint('DCHECK(x > 42)',
                         'Consider using DCHECK_GT instead of DCHECK(a > b)'
                         '  [readability/check] [2]')
        self.assert_lint('DCHECK(x <= 42)',
                         'Consider using DCHECK_LE instead of DCHECK(a <= b)'
                         '  [readability/check] [2]')
        self.assert_lint('DCHECK(x < 42)',
                         'Consider using DCHECK_LT instead of DCHECK(a < b)'
                         '  [readability/check] [2]')

        self.assert_lint(
            'EXPECT_TRUE("42" == x)',
            'Consider using EXPECT_EQ instead of EXPECT_TRUE(a == b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'EXPECT_TRUE("42" != x)',
            'Consider using EXPECT_NE instead of EXPECT_TRUE(a != b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'EXPECT_TRUE(+42 >= x)',
            'Consider using EXPECT_GE instead of EXPECT_TRUE(a >= b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'EXPECT_TRUE_M(-42 > x)',
            'Consider using EXPECT_GT_M instead of EXPECT_TRUE_M(a > b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'EXPECT_TRUE_M(42U <= x)',
            'Consider using EXPECT_LE_M instead of EXPECT_TRUE_M(a <= b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'EXPECT_TRUE_M(42L < x)',
            'Consider using EXPECT_LT_M instead of EXPECT_TRUE_M(a < b)'
            '  [readability/check] [2]')

        self.assert_lint(
            'EXPECT_FALSE(x == 42)',
            'Consider using EXPECT_NE instead of EXPECT_FALSE(a == b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'EXPECT_FALSE(x != 42)',
            'Consider using EXPECT_EQ instead of EXPECT_FALSE(a != b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'EXPECT_FALSE(x >= 42)',
            'Consider using EXPECT_LT instead of EXPECT_FALSE(a >= b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'ASSERT_FALSE(x > 42)',
            'Consider using ASSERT_LE instead of ASSERT_FALSE(a > b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'ASSERT_FALSE(x <= 42)',
            'Consider using ASSERT_GT instead of ASSERT_FALSE(a <= b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'ASSERT_FALSE_M(x < 42)',
            'Consider using ASSERT_GE_M instead of ASSERT_FALSE_M(a < b)'
            '  [readability/check] [2]')

        self.assert_lint('CHECK(some_iterator == obj.end())', '')
        self.assert_lint('EXPECT_TRUE(some_iterator == obj.end())', '')
        self.assert_lint('EXPECT_FALSE(some_iterator == obj.end())', '')

        self.assert_lint('CHECK(CreateTestFile(dir, (1 << 20)));', '')
        self.assert_lint('CHECK(CreateTestFile(dir, (1 >> 20)));', '')

        self.assert_lint('CHECK(x<42)',
                         ['Missing spaces around <'
                          '  [whitespace/operators] [3]',
                          'Consider using CHECK_LT instead of CHECK(a < b)'
                          '  [readability/check] [2]'])
        self.assert_lint('CHECK(x>42)',
                         'Consider using CHECK_GT instead of CHECK(a > b)'
                         '  [readability/check] [2]')

        self.assert_lint(
            '    EXPECT_TRUE(42 < x) // Random comment.',
            'Consider using EXPECT_LT instead of EXPECT_TRUE(a < b)'
            '  [readability/check] [2]')
        self.assert_lint(
            'EXPECT_TRUE( 42 < x )',
            ['Extra space after ( in function call'
             '  [whitespace/parens] [4]',
             'Consider using EXPECT_LT instead of EXPECT_TRUE(a < b)'
             '  [readability/check] [2]'])
        self.assert_lint(
            'CHECK("foo" == "foo")',
            'Consider using CHECK_EQ instead of CHECK(a == b)'
            '  [readability/check] [2]')

        self.assert_lint('CHECK_EQ("foo", "foo")', '')

    def test_brace_at_begin_of_line(self):
        self.assert_lint('{',
                         'This { should be at the end of the previous line'
                         '  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            '#endif\n'
            '{\n'
            '}\n',
            '')
        self.assert_multi_line_lint(
            'if (condition) {',
            '')
        self.assert_multi_line_lint(
            '    MACRO1(macroArg) {',
            '')
        self.assert_multi_line_lint(
            'ACCESSOR_GETTER(MessageEventPorts) {',
            'Place brace on its own line for function definitions.  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'int foo() {',
            'Place brace on its own line for function definitions.  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'int foo() const {',
            'Place brace on its own line for function definitions.  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'int foo() const OVERRIDE {',
            'Place brace on its own line for function definitions.  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'int foo() OVERRIDE {',
            'Place brace on its own line for function definitions.  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'int foo() const\n'
            '{\n'
            '}\n',
            '')
        self.assert_multi_line_lint(
            'int foo() OVERRIDE\n'
            '{\n'
            '}\n',
            '')
        self.assert_multi_line_lint(
            'if (condition\n'
            '    && condition2\n'
            '    && condition3) {\n'
            '}\n',
            '')

    def test_mismatching_spaces_in_parens(self):
        self.assert_lint('if (foo ) {', 'Extra space before ) in if'
                         '  [whitespace/parens] [5]')
        self.assert_lint('switch ( foo) {', 'Extra space after ( in switch'
                         '  [whitespace/parens] [5]')
        self.assert_lint('for (foo; ba; bar ) {', 'Extra space before ) in for'
                         '  [whitespace/parens] [5]')
        self.assert_lint('for ((foo); (ba); (bar) ) {', 'Extra space before ) in for'
                         '  [whitespace/parens] [5]')
        self.assert_lint('for (; foo; bar) {', '')
        self.assert_lint('for (; (foo); (bar)) {', '')
        self.assert_lint('for ( ; foo; bar) {', '')
        self.assert_lint('for ( ; (foo); (bar)) {', '')
        self.assert_lint('for ( ; foo; bar ) {', 'Extra space before ) in for'
                         '  [whitespace/parens] [5]')
        self.assert_lint('for ( ; (foo); (bar) ) {', 'Extra space before ) in for'
                         '  [whitespace/parens] [5]')
        self.assert_lint('for (foo; bar; ) {', '')
        self.assert_lint('for ((foo); (bar); ) {', '')
        self.assert_lint('foreach (foo, foos ) {', 'Extra space before ) in foreach'
                         '  [whitespace/parens] [5]')
        self.assert_lint('foreach ( foo, foos) {', 'Extra space after ( in foreach'
                         '  [whitespace/parens] [5]')
        self.assert_lint('while (  foo) {', 'Extra space after ( in while'
                         '  [whitespace/parens] [5]')

    def test_spacing_for_fncall(self):
        self.assert_lint('if (foo) {', '')
        self.assert_lint('for (foo;bar;baz) {', '')
        self.assert_lint('foreach (foo, foos) {', '')
        self.assert_lint('while (foo) {', '')
        self.assert_lint('switch (foo) {', '')
        self.assert_lint('new (RenderArena()) RenderInline(document())', '')
        self.assert_lint('foo( bar)', 'Extra space after ( in function call'
                         '  [whitespace/parens] [4]')
        self.assert_lint('foobar( \\', '')
        self.assert_lint('foobar(     \\', '')
        self.assert_lint('( a + b)', 'Extra space after ('
                         '  [whitespace/parens] [2]')
        self.assert_lint('((a+b))', '')
        self.assert_lint('foo (foo)', 'Extra space before ( in function call'
                         '  [whitespace/parens] [4]')
        self.assert_lint('#elif (foo(bar))', '')
        self.assert_lint('#elif (foo(bar) && foo(baz))', '')
        self.assert_lint('typedef foo (*foo)(foo)', '')
        self.assert_lint('typedef foo (*foo12bar_)(foo)', '')
        self.assert_lint('typedef foo (Foo::*bar)(foo)', '')
        self.assert_lint('foo (Foo::*bar)(',
                         'Extra space before ( in function call'
                         '  [whitespace/parens] [4]')
        self.assert_lint('typedef foo (Foo::*bar)(', '')
        self.assert_lint('(foo)(bar)', '')
        self.assert_lint('Foo (*foo)(bar)', '')
        self.assert_lint('Foo (*foo)(Bar bar,', '')
        self.assert_lint('char (*p)[sizeof(foo)] = &foo', '')
        self.assert_lint('char (&ref)[sizeof(foo)] = &foo', '')
        self.assert_lint('const char32 (*table[])[6];', '')

    def test_spacing_before_braces(self):
        self.assert_lint('if (foo){', 'Missing space before {'
                         '  [whitespace/braces] [5]')
        self.assert_lint('for{', 'Missing space before {'
                         '  [whitespace/braces] [5]')
        self.assert_lint('for {', '')
        self.assert_lint('EXPECT_DEBUG_DEATH({', '')

    def test_spacing_between_braces(self):
        self.assert_lint('    { }', '')
        self.assert_lint('    {}', 'Missing space inside { }.  [whitespace/braces] [5]')
        self.assert_lint('    {   }', 'Too many spaces inside { }.  [whitespace/braces] [5]')

    def test_spacing_around_else(self):
        self.assert_lint('}else {', 'Missing space before else'
                         '  [whitespace/braces] [5]')
        self.assert_lint('} else{', 'Missing space before {'
                         '  [whitespace/braces] [5]')
        self.assert_lint('} else {', '')
        self.assert_lint('} else if', '')

    def test_spacing_for_binary_ops(self):
        self.assert_lint('if (foo<=bar) {', 'Missing spaces around <='
                         '  [whitespace/operators] [3]')
        self.assert_lint('if (foo<bar) {', 'Missing spaces around <'
                         '  [whitespace/operators] [3]')
        self.assert_lint('if (foo<bar->baz) {', 'Missing spaces around <'
                         '  [whitespace/operators] [3]')
        self.assert_lint('if (foo<bar->bar) {', 'Missing spaces around <'
                         '  [whitespace/operators] [3]')
        self.assert_lint('typedef hash_map<Foo, Bar', 'Missing spaces around <'
                         '  [whitespace/operators] [3]')
        self.assert_lint('typedef hash_map<FoooooType, BaaaaarType,', '')
        self.assert_lint('a<Foo> t+=b;', 'Missing spaces around +='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo> t-=b;', 'Missing spaces around -='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t*=b;', 'Missing spaces around *='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t/=b;', 'Missing spaces around /='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t|=b;', 'Missing spaces around |='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t&=b;', 'Missing spaces around &='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t<<=b;', 'Missing spaces around <<='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t>>=b;', 'Missing spaces around >>='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t>>=&b|c;', 'Missing spaces around >>='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t<<=*b/c;', 'Missing spaces around <<='
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo> t -= b;', '')
        self.assert_lint('a<Foo> t += b;', '')
        self.assert_lint('a<Foo*> t *= b;', '')
        self.assert_lint('a<Foo*> t /= b;', '')
        self.assert_lint('a<Foo*> t |= b;', '')
        self.assert_lint('a<Foo*> t &= b;', '')
        self.assert_lint('a<Foo*> t <<= b;', '')
        self.assert_lint('a<Foo*> t >>= b;', '')
        self.assert_lint('a<Foo*> t >>= &b|c;', 'Missing spaces around |'
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t <<= *b/c;', 'Missing spaces around /'
                         '  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t <<= b/c; //Test', [
                         'Should have a space between // and comment  '
                         '[whitespace/comments] [4]', 'Missing'
                         ' spaces around /  [whitespace/operators] [3]'])
        self.assert_lint('a<Foo*> t <<= b||c;  //Test', ['One space before end'
                         ' of line comments  [whitespace/comments] [5]',
                         'Should have a space between // and comment  '
                         '[whitespace/comments] [4]',
                         'Missing spaces around ||  [whitespace/operators] [3]'])
        self.assert_lint('a<Foo*> t <<= b&&c; // Test', 'Missing spaces around'
                         ' &&  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t <<= b&&&c; // Test', 'Missing spaces around'
                         ' &&  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t <<= b&&*c; // Test', 'Missing spaces around'
                         ' &&  [whitespace/operators] [3]')
        self.assert_lint('a<Foo*> t <<= b && *c; // Test', '')
        self.assert_lint('a<Foo*> t <<= b && &c; // Test', '')
        self.assert_lint('a<Foo*> t <<= b || &c;  /*Test', 'Complex multi-line '
                         '/*...*/-style comment found. Lint may give bogus '
                         'warnings.  Consider replacing these with //-style'
                         ' comments, with #if 0...#endif, or with more clearly'
                         ' structured multi-line comments.  [readability/multiline_comment] [5]')
        self.assert_lint('a<Foo&> t <<= &b | &c;', '')
        self.assert_lint('a<Foo*> t <<= &b & &c; // Test', '')
        self.assert_lint('a<Foo*> t <<= *b / &c; // Test', '')
        self.assert_lint('if (a=b == 1)', 'Missing spaces around =  [whitespace/operators] [4]')
        self.assert_lint('a = 1<<20', 'Missing spaces around <<  [whitespace/operators] [3]')
        self.assert_lint('if (a = b == 1)', '')
        self.assert_lint('a = 1 << 20', '')
        self.assert_multi_line_lint('#include <sys/io.h>\n', '')
        self.assert_multi_line_lint('#import <foo/bar.h>\n', '')

    def test_operator_methods(self):
        self.assert_lint('String operator+(const String&, const String&);', '')
        self.assert_lint('String operator/(const String&, const String&);', '')
        self.assert_lint('bool operator==(const String&, const String&);', '')
        self.assert_lint('String& operator-=(const String&, const String&);', '')
        self.assert_lint('String& operator+=(const String&, const String&);', '')
        self.assert_lint('String& operator*=(const String&, const String&);', '')
        self.assert_lint('String& operator%=(const String&, const String&);', '')
        self.assert_lint('String& operator&=(const String&, const String&);', '')
        self.assert_lint('String& operator<<=(const String&, const String&);', '')
        self.assert_lint('String& operator>>=(const String&, const String&);', '')
        self.assert_lint('String& operator|=(const String&, const String&);', '')
        self.assert_lint('String& operator^=(const String&, const String&);', '')

    def test_spacing_before_last_semicolon(self):
        self.assert_lint('call_function() ;',
                         'Extra space before last semicolon. If this should be an '
                         'empty statement, use { } instead.'
                         '  [whitespace/semicolon] [5]')
        self.assert_lint('while (true) ;',
                         'Extra space before last semicolon. If this should be an '
                         'empty statement, use { } instead.'
                         '  [whitespace/semicolon] [5]')
        self.assert_lint('default:;',
                         'Semicolon defining empty statement. Use { } instead.'
                         '  [whitespace/semicolon] [5]')
        self.assert_lint('        ;',
                         'Line contains only semicolon. If this should be an empty '
                         'statement, use { } instead.'
                         '  [whitespace/semicolon] [5]')
        self.assert_lint('for (int i = 0; ;', '')

    # Static or global STL strings.
    def test_static_or_global_stlstrings(self):
        self.assert_lint('string foo;',
                         'For a static/global string constant, use a C style '
                         'string instead: "char foo[]".'
                         '  [runtime/string] [4]')
        self.assert_lint('string kFoo = "hello"; // English',
                         'For a static/global string constant, use a C style '
                         'string instead: "char kFoo[]".'
                         '  [runtime/string] [4]')
        self.assert_lint('static string foo;',
                         'For a static/global string constant, use a C style '
                         'string instead: "static char foo[]".'
                         '  [runtime/string] [4]')
        self.assert_lint('static const string foo;',
                         'For a static/global string constant, use a C style '
                         'string instead: "static const char foo[]".'
                         '  [runtime/string] [4]')
        self.assert_lint('string Foo::bar;',
                         'For a static/global string constant, use a C style '
                         'string instead: "char Foo::bar[]".'
                         '  [runtime/string] [4]')
        # Rare case.
        self.assert_lint('string foo("foobar");',
                         'For a static/global string constant, use a C style '
                         'string instead: "char foo[]".'
                         '  [runtime/string] [4]')
        # Should not catch local or member variables.
        self.assert_lint('    string foo', '')
        # Should not catch functions.
        self.assert_lint('string EmptyString() { return ""; }', '')
        self.assert_lint('string EmptyString () { return ""; }', '')
        self.assert_lint('string VeryLongNameFunctionSometimesEndsWith(\n'
                         '    VeryLongNameType veryLongNameVariable) { }', '')
        self.assert_lint('template<>\n'
                         'string FunctionTemplateSpecialization<SomeType>(\n'
                         '    int x) { return ""; }', '')
        self.assert_lint('template<>\n'
                         'string FunctionTemplateSpecialization<vector<A::B>* >(\n'
                         '    int x) { return ""; }', '')

        # should not catch methods of template classes.
        self.assert_lint('string Class<Type>::Method() const\n'
                         '{\n'
                         '    return "";\n'
                         '}\n', '')
        self.assert_lint('string Class<Type>::Method(\n'
                         '    int arg) const\n'
                         '{\n'
                         '    return "";\n'
                         '}\n', '')

    def test_no_spaces_in_function_calls(self):
        self.assert_lint('TellStory(1, 3);',
                         '')
        self.assert_lint('TellStory(1, 3 );',
                         'Extra space before )'
                         '  [whitespace/parens] [2]')
        self.assert_lint('TellStory(1 /* wolf */, 3 /* pigs */);',
                         '')
        self.assert_multi_line_lint('#endif\n    );',
                                    '')

    def test_one_spaces_between_code_and_comments(self):
        self.assert_lint('} // namespace foo',
                         '')
        self.assert_lint('}// namespace foo',
                         'One space before end of line comments'
                         '  [whitespace/comments] [5]')
        self.assert_lint('printf("foo"); // Outside quotes.',
                         '')
        self.assert_lint('int i = 0; // Having one space is fine.','')
        self.assert_lint('int i = 0;  // Having two spaces is bad.',
                         'One space before end of line comments'
                         '  [whitespace/comments] [5]')
        self.assert_lint('int i = 0;   // Having three spaces is bad.',
                         'One space before end of line comments'
                         '  [whitespace/comments] [5]')
        self.assert_lint('// Top level comment', '')
        self.assert_lint('    // Line starts with four spaces.', '')
        self.assert_lint('foo();\n'
                         '{ // A scope is opening.', '')
        self.assert_lint('    foo();\n'
                         '    { // An indented scope is opening.', '')
        self.assert_lint('if (foo) { // not a pure scope',
                         '')
        self.assert_lint('printf("// In quotes.")', '')
        self.assert_lint('printf("\\"%s // In quotes.")', '')
        self.assert_lint('printf("%s", "// In quotes.")', '')

    def test_one_spaces_after_punctuation_in_comments(self):
        self.assert_lint('int a; // This is a sentence.',
                         '')
        self.assert_lint('int a; // This is a sentence.  ',
                         'Line ends in whitespace.  Consider deleting these extra spaces.  [whitespace/end_of_line] [4]')
        self.assert_lint('int a; // This is a sentence. This is a another sentence.',
                         '')
        self.assert_lint('int a; // This is a sentence.  This is a another sentence.',
                         'Should have only a single space after a punctuation in a comment.  [whitespace/comments] [5]')
        self.assert_lint('int a; // This is a sentence!  This is a another sentence.',
                         'Should have only a single space after a punctuation in a comment.  [whitespace/comments] [5]')
        self.assert_lint('int a; // Why did I write this?  This is a another sentence.',
                         'Should have only a single space after a punctuation in a comment.  [whitespace/comments] [5]')
        self.assert_lint('int a; // Elementary,  my dear.',
                         'Should have only a single space after a punctuation in a comment.  [whitespace/comments] [5]')
        self.assert_lint('int a; // The following should be clear:  Is it?',
                         'Should have only a single space after a punctuation in a comment.  [whitespace/comments] [5]')
        self.assert_lint('int a; // Look at the follow semicolon;  I hope this gives an error.',
                         'Should have only a single space after a punctuation in a comment.  [whitespace/comments] [5]')

    def test_space_after_comment_marker(self):
        self.assert_lint('//', '')
        self.assert_lint('//x', 'Should have a space between // and comment'
                         '  [whitespace/comments] [4]')
        self.assert_lint('// x', '')
        self.assert_lint('//----', '')
        self.assert_lint('//====', '')
        self.assert_lint('//////', '')
        self.assert_lint('////// x', '')
        self.assert_lint('/// x', '')
        self.assert_lint('////x', 'Should have a space between // and comment'
                         '  [whitespace/comments] [4]')

    def test_newline_at_eof(self):
        def do_test(self, data, is_missing_eof):
            error_collector = ErrorCollector(self.assertTrue)
            self.process_file_data('foo.cpp', 'cpp', data.split('\n'),
                                   error_collector)
            # The warning appears only once.
            self.assertEqual(
                int(is_missing_eof),
                error_collector.results().count(
                    'Could not find a newline character at the end of the file.'
                    '  [whitespace/ending_newline] [5]'))

        do_test(self, '// Newline\n// at EOF\n', False)
        do_test(self, '// No newline\n// at EOF', True)

    def test_invalid_utf8(self):
        def do_test(self, raw_bytes, has_invalid_utf8):
            error_collector = ErrorCollector(self.assertTrue)
            self.process_file_data('foo.cpp', 'cpp',
                                   unicode(raw_bytes, 'utf8', 'replace').split('\n'),
                                   error_collector)
            # The warning appears only once.
            self.assertEqual(
                int(has_invalid_utf8),
                error_collector.results().count(
                    'Line contains invalid UTF-8'
                    ' (or Unicode replacement character).'
                    '  [readability/utf8] [5]'))

        do_test(self, 'Hello world\n', False)
        do_test(self, '\xe9\x8e\xbd\n', False)
        do_test(self, '\xe9x\x8e\xbd\n', True)
        # This is the encoding of the replacement character itself (which
        # you can see by evaluating codecs.getencoder('utf8')(u'\ufffd')).
        do_test(self, '\xef\xbf\xbd\n', True)

    def test_is_blank_line(self):
        self.assertTrue(cpp_style.is_blank_line(''))
        self.assertTrue(cpp_style.is_blank_line(' '))
        self.assertTrue(cpp_style.is_blank_line(' \t\r\n'))
        self.assertTrue(not cpp_style.is_blank_line('int a;'))
        self.assertTrue(not cpp_style.is_blank_line('{'))

    def test_blank_lines_check(self):
        self.assert_blank_lines_check(['{\n', '\n', '\n', '}\n'], 1, 1)
        self.assert_blank_lines_check(['  if (foo) {\n', '\n', '  }\n'], 1, 1)
        self.assert_blank_lines_check(
            ['\n', '// {\n', '\n', '\n', '// Comment\n', '{\n', '}\n'], 0, 0)
        self.assert_blank_lines_check(['\n', 'run("{");\n', '\n'], 0, 0)
        self.assert_blank_lines_check(['\n', '  if (foo) { return 0; }\n', '\n'], 0, 0)

    def test_allow_blank_line_before_closing_namespace(self):
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data('foo.cpp', 'cpp',
                               ['namespace {', '', '}  // namespace'],
                               error_collector)
        self.assertEqual(0, error_collector.results().count(
            'Blank line at the end of a code block.  Is this needed?'
            '  [whitespace/blank_line] [3]'))

    def test_allow_blank_line_before_if_else_chain(self):
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data('foo.cpp', 'cpp',
                               ['if (hoge) {',
                                '',  # No warning
                                '} else if (piyo) {',
                                '',  # No warning
                                '} else if (piyopiyo) {',
                                '  hoge = true;',  # No warning
                                '} else {',
                                '',  # Warning on this line
                                '}'],
                               error_collector)
        self.assertEqual(1, error_collector.results().count(
            'Blank line at the end of a code block.  Is this needed?'
            '  [whitespace/blank_line] [3]'))

    def test_else_on_same_line_as_closing_braces(self):
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data('foo.cpp', 'cpp',
                               ['if (hoge) {',
                                '',
                                '}',
                                ' else {'  # Warning on this line
                                '',
                                '}'],
                               error_collector)
        self.assertEqual(1, error_collector.results().count(
            'An else should appear on the same line as the preceding }'
            '  [whitespace/newline] [4]'))

    def test_else_clause_not_on_same_line_as_else(self):
        self.assert_lint('    else DoSomethingElse();',
                         'Else clause should never be on same line as else '
                         '(use 2 lines)  [whitespace/newline] [4]')
        self.assert_lint('    else ifDoSomethingElse();',
                         'Else clause should never be on same line as else '
                         '(use 2 lines)  [whitespace/newline] [4]')
        self.assert_lint('    else if (blah) {', '')
        self.assert_lint('    variable_ends_in_else = true;', '')

    def test_comma(self):
        self.assert_lint('a = f(1,2);',
                         'Missing space after ,  [whitespace/comma] [3]')
        self.assert_lint('int tmp=a,a=b,b=tmp;',
                         ['Missing spaces around =  [whitespace/operators] [4]',
                          'Missing space after ,  [whitespace/comma] [3]'])
        self.assert_lint('f(a, /* name */ b);', '')
        self.assert_lint('f(a, /* name */b);', '')

    def test_declaration(self):
        self.assert_lint('int a;', '')
        self.assert_lint('int   a;', 'Extra space between int and a  [whitespace/declaration] [3]')
        self.assert_lint('int*  a;', 'Extra space between int* and a  [whitespace/declaration] [3]')
        self.assert_lint('else if { }', '')
        self.assert_lint('else   if { }', 'Extra space between else and if  [whitespace/declaration] [3]')

    def test_pointer_reference_marker_location(self):
        self.assert_lint('int* b;', '', 'foo.cpp')
        self.assert_lint('int *b;',
                         'Declaration has space between type name and * in int *b  [whitespace/declaration] [3]',
                         'foo.cpp')
        self.assert_lint('return *b;', '', 'foo.cpp')
        self.assert_lint('delete *b;', '', 'foo.cpp')
        self.assert_lint('int *b;', '', 'foo.c')
        self.assert_lint('int* b;',
                         'Declaration has space between * and variable name in int* b  [whitespace/declaration] [3]',
                         'foo.c')
        self.assert_lint('int& b;', '', 'foo.cpp')
        self.assert_lint('int &b;',
                         'Declaration has space between type name and & in int &b  [whitespace/declaration] [3]',
                         'foo.cpp')
        self.assert_lint('return &b;', '', 'foo.cpp')

    def test_indent(self):
        self.assert_lint('static int noindent;', '')
        self.assert_lint('    int fourSpaceIndent;', '')
        self.assert_lint(' int oneSpaceIndent;',
                         'Weird number of spaces at line-start.  '
                         'Are you using a 4-space indent?  [whitespace/indent] [3]')
        self.assert_lint('   int threeSpaceIndent;',
                         'Weird number of spaces at line-start.  '
                         'Are you using a 4-space indent?  [whitespace/indent] [3]')
        self.assert_lint(' char* oneSpaceIndent = "public:";',
                         'Weird number of spaces at line-start.  '
                         'Are you using a 4-space indent?  [whitespace/indent] [3]')
        self.assert_lint(' public:',
                         'Weird number of spaces at line-start.  '
                         'Are you using a 4-space indent?  [whitespace/indent] [3]')
        self.assert_lint('  public:',
                         'Weird number of spaces at line-start.  '
                         'Are you using a 4-space indent?  [whitespace/indent] [3]')
        self.assert_lint('   public:',
                         'Weird number of spaces at line-start.  '
                         'Are you using a 4-space indent?  [whitespace/indent] [3]')
        self.assert_multi_line_lint(
            'class Foo {\n'
            'public:\n'
            '    enum Bar {\n'
            '        Alpha,\n'
            '        Beta,\n'
            '#if ENABLED_BETZ\n'
            '        Charlie,\n'
            '#endif\n'
            '    };\n'
            '};',
            '')
        self.assert_multi_line_lint(
            'if (true) {\n'
            '    myFunction(reallyLongParam1, reallyLongParam2,\n'
            '               reallyLongParam3);\n'
            '}\n',
            'Weird number of spaces at line-start.  Are you using a 4-space indent?  [whitespace/indent] [3]')

        self.assert_multi_line_lint(
            'if (true) {\n'
            '    myFunction(reallyLongParam1, reallyLongParam2,\n'
            '            reallyLongParam3);\n'
            '}\n',
            'When wrapping a line, only indent 4 spaces.  [whitespace/indent] [3]')


    def test_not_alabel(self):
        self.assert_lint('MyVeryLongNamespace::MyVeryLongClassName::', '')

    def test_tab(self):
        self.assert_lint('\tint a;',
                         'Tab found; better to use spaces  [whitespace/tab] [1]')
        self.assert_lint('int a = 5;\t// set a to 5',
                         'Tab found; better to use spaces  [whitespace/tab] [1]')

    def test_unnamed_namespaces_in_headers(self):
        self.assert_language_rules_check(
            'foo.h', 'namespace {',
            'Do not use unnamed namespaces in header files.  See'
            ' http://google-styleguide.googlecode.com/svn/trunk/cppguide.xml#Namespaces'
            ' for more information.  [build/namespaces] [4]')
        # namespace registration macros are OK.
        self.assert_language_rules_check('foo.h', 'namespace {  \\', '')
        # named namespaces are OK.
        self.assert_language_rules_check('foo.h', 'namespace foo {', '')
        self.assert_language_rules_check('foo.h', 'namespace foonamespace {', '')
        self.assert_language_rules_check('foo.cpp', 'namespace {', '')
        self.assert_language_rules_check('foo.cpp', 'namespace foo {', '')

    def test_build_class(self):
        # Test that the linter can parse to the end of class definitions,
        # and that it will report when it can't.
        # Use multi-line linter because it performs the ClassState check.
        self.assert_multi_line_lint(
            'class Foo {',
            'Failed to find complete declaration of class Foo'
            '  [build/class] [5]')
        # Don't warn on forward declarations of various types.
        self.assert_multi_line_lint(
            'class Foo;',
            '')
        self.assert_multi_line_lint(
            '''\
            struct Foo*
                foo = NewFoo();''',
            '')
        # Here is an example where the linter gets confused, even though
        # the code doesn't violate the style guide.
        self.assert_multi_line_lint(
            'class Foo\n'
            '#ifdef DERIVE_FROM_GOO\n'
            '    : public Goo {\n'
            '#else\n'
            '    : public Hoo {\n'
            '#endif\n'
            '};',
            'Failed to find complete declaration of class Foo'
            '  [build/class] [5]')

    def test_build_end_comment(self):
        # The crosstool compiler we currently use will fail to compile the
        # code in this test, so we might consider removing the lint check.
        self.assert_lint('#endif Not a comment',
                         'Uncommented text after #endif is non-standard.'
                         '  Use a comment.'
                         '  [build/endif_comment] [5]')

    def test_build_forward_decl(self):
        # The crosstool compiler we currently use will fail to compile the
        # code in this test, so we might consider removing the lint check.
        self.assert_lint('class Foo::Goo;',
                         'Inner-style forward declarations are invalid.'
                         '  Remove this line.'
                         '  [build/forward_decl] [5]')

    def test_build_header_guard(self):
        file_path = 'mydir/Foo.h'

        # We can't rely on our internal stuff to get a sane path on the open source
        # side of things, so just parse out the suggested header guard. This
        # doesn't allow us to test the suggested header guard, but it does let us
        # test all the other header tests.
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(file_path, 'h', [], error_collector)
        expected_guard = ''
        matcher = re.compile(
            'No \#ifndef header guard found\, suggested CPP variable is\: ([A-Za-z_0-9]+) ')
        for error in error_collector.result_list():
            matches = matcher.match(error)
            if matches:
                expected_guard = matches.group(1)
                break

        # Make sure we extracted something for our header guard.
        self.assertNotEqual(expected_guard, '')

        # Wrong guard
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(file_path, 'h',
                               ['#ifndef FOO_H', '#define FOO_H'], error_collector)
        self.assertEqual(
            1,
            error_collector.result_list().count(
                '#ifndef header guard has wrong style, please use: %s'
                '  [build/header_guard] [5]' % expected_guard),
            error_collector.result_list())

        # No define
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(file_path, 'h',
                               ['#ifndef %s' % expected_guard], error_collector)
        self.assertEqual(
            1,
            error_collector.result_list().count(
                'No #ifndef header guard found, suggested CPP variable is: %s'
                '  [build/header_guard] [5]' % expected_guard),
            error_collector.result_list())

        # Mismatched define
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(file_path, 'h',
                               ['#ifndef %s' % expected_guard,
                                '#define FOO_H'],
                               error_collector)
        self.assertEqual(
            1,
            error_collector.result_list().count(
                'No #ifndef header guard found, suggested CPP variable is: %s'
                '  [build/header_guard] [5]' % expected_guard),
            error_collector.result_list())

        # No header guard errors
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(file_path, 'h',
                               ['#ifndef %s' % expected_guard,
                                '#define %s' % expected_guard,
                                '#endif // %s' % expected_guard],
                               error_collector)
        for line in error_collector.result_list():
            if line.find('build/header_guard') != -1:
                self.fail('Unexpected error: %s' % line)

        # Completely incorrect header guard
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(file_path, 'h',
                               ['#ifndef FOO',
                                '#define FOO',
                                '#endif  // FOO'],
                               error_collector)
        self.assertEqual(
            1,
            error_collector.result_list().count(
                '#ifndef header guard has wrong style, please use: %s'
                '  [build/header_guard] [5]' % expected_guard),
            error_collector.result_list())

        # Special case for flymake
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data('mydir/Foo_flymake.h', 'h',
                               ['#ifndef %s' % expected_guard,
                                '#define %s' % expected_guard,
                                '#endif // %s' % expected_guard],
                               error_collector)
        for line in error_collector.result_list():
            if line.find('build/header_guard') != -1:
                self.fail('Unexpected error: %s' % line)

        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data('mydir/Foo_flymake.h', 'h', [], error_collector)
        self.assertEqual(
            1,
            error_collector.result_list().count(
                'No #ifndef header guard found, suggested CPP variable is: %s'
                '  [build/header_guard] [5]' % expected_guard),
            error_collector.result_list())

        # Verify that we don't blindly suggest the WTF prefix for all headers.
        self.assertFalse(expected_guard.startswith('WTF_'))

        # Allow the WTF_ prefix for files in that directory.
        header_guard_filter = FilterConfiguration(('-', '+build/header_guard'))
        error_collector = ErrorCollector(self.assertTrue, header_guard_filter)
        self.process_file_data('Source/JavaScriptCore/wtf/TestName.h', 'h',
                               ['#ifndef WTF_TestName_h', '#define WTF_TestName_h'],
                               error_collector)
        self.assertEqual(0, len(error_collector.result_list()),
                          error_collector.result_list())

        # Also allow the non WTF_ prefix for files in that directory.
        error_collector = ErrorCollector(self.assertTrue, header_guard_filter)
        self.process_file_data('Source/JavaScriptCore/wtf/TestName.h', 'h',
                               ['#ifndef TestName_h', '#define TestName_h'],
                               error_collector)
        self.assertEqual(0, len(error_collector.result_list()),
                          error_collector.result_list())

        # Verify that we suggest the WTF prefix version.
        error_collector = ErrorCollector(self.assertTrue, header_guard_filter)
        self.process_file_data('Source/JavaScriptCore/wtf/TestName.h', 'h',
                               ['#ifndef BAD_TestName_h', '#define BAD_TestName_h'],
                               error_collector)
        self.assertEqual(
            1,
            error_collector.result_list().count(
                '#ifndef header guard has wrong style, please use: WTF_TestName_h'
                '  [build/header_guard] [5]'),
            error_collector.result_list())

        # Verify that the Chromium-style header guard is allowed as well.
        error_collector = ErrorCollector(self.assertTrue, header_guard_filter)
        self.process_file_data('Source/foo/testname.h', 'h',
                               ['#ifndef BLINK_FOO_TESTNAME_H_',
                                '#define BLINK_FOO_TESTNAME_H_'],
                              error_collector)
        self.assertEqual(0, len(error_collector.result_list()),
                          error_collector.result_list())

    def test_build_printf_format(self):
        self.assert_lint(
            r'printf("\%%d", value);',
            '%, [, (, and { are undefined character escapes.  Unescape them.'
            '  [build/printf_format] [3]')

        self.assert_lint(
            r'snprintf(buffer, sizeof(buffer), "\[%d", value);',
            '%, [, (, and { are undefined character escapes.  Unescape them.'
            '  [build/printf_format] [3]')

        self.assert_lint(
            r'fprintf(file, "\(%d", value);',
            '%, [, (, and { are undefined character escapes.  Unescape them.'
            '  [build/printf_format] [3]')

        self.assert_lint(
            r'vsnprintf(buffer, sizeof(buffer), "\\\{%d", ap);',
            '%, [, (, and { are undefined character escapes.  Unescape them.'
            '  [build/printf_format] [3]')

        # Don't warn if double-slash precedes the symbol
        self.assert_lint(r'printf("\\%%%d", value);',
                         '')

    def test_runtime_printf_format(self):
        self.assert_lint(
            r'fprintf(file, "%q", value);',
            '%q in format strings is deprecated.  Use %ll instead.'
            '  [runtime/printf_format] [3]')

        self.assert_lint(
            r'aprintf(file, "The number is %12q", value);',
            '%q in format strings is deprecated.  Use %ll instead.'
            '  [runtime/printf_format] [3]')

        self.assert_lint(
            r'printf(file, "The number is" "%-12q", value);',
            '%q in format strings is deprecated.  Use %ll instead.'
            '  [runtime/printf_format] [3]')

        self.assert_lint(
            r'printf(file, "The number is" "%+12q", value);',
            '%q in format strings is deprecated.  Use %ll instead.'
            '  [runtime/printf_format] [3]')

        self.assert_lint(
            r'printf(file, "The number is" "% 12q", value);',
            '%q in format strings is deprecated.  Use %ll instead.'
            '  [runtime/printf_format] [3]')

        self.assert_lint(
            r'snprintf(file, "Never mix %d and %1$d parmaeters!", value);',
            '%N$ formats are unconventional.  Try rewriting to avoid them.'
            '  [runtime/printf_format] [2]')

    def assert_lintLogCodeOnError(self, code, expected_message):
        # Special assert_lint which logs the input code on error.
        result = self.perform_single_line_lint(code, 'foo.cpp')
        if result != expected_message:
            self.fail('For code: "%s"\nGot: "%s"\nExpected: "%s"'
                      % (code, result, expected_message))

    def test_build_storage_class(self):
        qualifiers = [None, 'const', 'volatile']
        signs = [None, 'signed', 'unsigned']
        types = ['void', 'char', 'int', 'float', 'double',
                 'schar', 'int8', 'uint8', 'int16', 'uint16',
                 'int32', 'uint32', 'int64', 'uint64']
        storage_classes = ['auto', 'extern', 'register', 'static', 'typedef']

        build_storage_class_error_message = (
            'Storage class (static, extern, typedef, etc) should be first.'
            '  [build/storage_class] [5]')

        # Some explicit cases. Legal in C++, deprecated in C99.
        self.assert_lint('const int static foo = 5;',
                         build_storage_class_error_message)

        self.assert_lint('char static foo;',
                         build_storage_class_error_message)

        self.assert_lint('double const static foo = 2.0;',
                         build_storage_class_error_message)

        self.assert_lint('uint64 typedef unsignedLongLong;',
                         build_storage_class_error_message)

        self.assert_lint('int register foo = 0;',
                         build_storage_class_error_message)

        # Since there are a very large number of possibilities, randomly
        # construct declarations.
        # Make sure that the declaration is logged if there's an error.
        # Seed generator with an integer for absolute reproducibility.
        random.seed(25)
        for unused_i in range(10):
            # Build up random list of non-storage-class declaration specs.
            other_decl_specs = [random.choice(qualifiers), random.choice(signs),
                                random.choice(types)]
            # remove None
            other_decl_specs = filter(lambda x: x is not None, other_decl_specs)

            # shuffle
            random.shuffle(other_decl_specs)

            # insert storage class after the first
            storage_class = random.choice(storage_classes)
            insertion_point = random.randint(1, len(other_decl_specs))
            decl_specs = (other_decl_specs[0:insertion_point]
                          + [storage_class]
                          + other_decl_specs[insertion_point:])

            self.assert_lintLogCodeOnError(
                ' '.join(decl_specs) + ';',
                build_storage_class_error_message)

            # but no error if storage class is first
            self.assert_lintLogCodeOnError(
                storage_class + ' ' + ' '.join(other_decl_specs),
                '')

    def test_legal_copyright(self):
        legal_copyright_message = (
            'No copyright message found.  '
            'You should have a line: "Copyright [year] <Copyright Owner>"'
            '  [legal/copyright] [5]')

        copyright_line = '// Copyright 2008 Google Inc. All Rights Reserved.'

        file_path = 'mydir/googleclient/foo.cpp'

        # There should be a copyright message in the first 10 lines
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(file_path, 'cpp', [], error_collector)
        self.assertEqual(
            1,
            error_collector.result_list().count(legal_copyright_message))

        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(
            file_path, 'cpp',
            ['' for unused_i in range(10)] + [copyright_line],
            error_collector)
        self.assertEqual(
            1,
            error_collector.result_list().count(legal_copyright_message))

        # Test that warning isn't issued if Copyright line appears early enough.
        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(file_path, 'cpp', [copyright_line], error_collector)
        for message in error_collector.result_list():
            if message.find('legal/copyright') != -1:
                self.fail('Unexpected error: %s' % message)

        error_collector = ErrorCollector(self.assertTrue)
        self.process_file_data(
            file_path, 'cpp',
            ['' for unused_i in range(9)] + [copyright_line],
            error_collector)
        for message in error_collector.result_list():
            if message.find('legal/copyright') != -1:
                self.fail('Unexpected error: %s' % message)

    def test_invalid_increment(self):
        self.assert_lint('*count++;',
                         'Changing pointer instead of value (or unused value of '
                         'operator*).  [runtime/invalid_increment] [5]')

    # Integral bitfields must be declared with either signed or unsigned keyword.
    def test_plain_integral_bitfields(self):
        errmsg = ('Please declare integral type bitfields with either signed or unsigned.  [runtime/bitfields] [5]')

        self.assert_lint('int a : 30;', errmsg)
        self.assert_lint('mutable short a : 14;', errmsg)
        self.assert_lint('const char a : 6;', errmsg)
        self.assert_lint('long int a : 30;', errmsg)
        self.assert_lint('int a = 1 ? 0 : 30;', '')

    # A mixture of unsigned and bool bitfields in a class will generate a warning.
    def test_mixing_unsigned_bool_bitfields(self):
        def errmsg(bool_bitfields, unsigned_bitfields, name):
            bool_list = ', '.join(bool_bitfields)
            unsigned_list = ', '.join(unsigned_bitfields)
            return ('The class %s contains mixed unsigned and bool bitfields, '
                    'which will pack into separate words on the MSVC compiler.\n'
                    'Bool bitfields are [%s].\nUnsigned bitfields are [%s].\n'
                    'Consider converting bool bitfields to unsigned.  [runtime/bitfields] [5]'
                    % (name, bool_list, unsigned_list))

        def build_test_case(bitfields, name, will_warn, extra_warnings=[]):
            bool_bitfields = []
            unsigned_bitfields = []
            test_string = 'class %s {\n' % (name,)
            line = 2
            for bitfield in bitfields:
                test_string += '    %s %s : %d;\n' % bitfield
                if bitfield[0] == 'bool':
                    bool_bitfields.append('%d: %s' % (line, bitfield[1]))
                elif bitfield[0].startswith('unsigned'):
                    unsigned_bitfields.append('%d: %s' % (line, bitfield[1]))
                line += 1
            test_string += '}\n'
            error = ''
            if will_warn:
                error = errmsg(bool_bitfields, unsigned_bitfields, name)
            if extra_warnings and error:
                error = extra_warnings + [error]
            self.assert_multi_line_lint(test_string, error)

        build_test_case([('bool', 'm_boolMember', 4), ('unsigned', 'm_unsignedMember', 3)],
                        'MyClass', True)
        build_test_case([('bool', 'm_boolMember', 4), ('bool', 'm_anotherBool', 3)],
                        'MyClass', False)
        build_test_case([('unsigned', 'm_unsignedMember', 4), ('unsigned', 'm_anotherUnsigned', 3)],
                        'MyClass', False)

        build_test_case([('bool', 'm_boolMember', 4), ('bool', 'm_anotherbool', 3),
                         ('bool', 'm_moreBool', 1), ('bool', 'm_lastBool', 1),
                         ('unsigned int', 'm_tokenUnsigned', 4)],
                        'MyClass', True, ['Omit int when using unsigned  [runtime/unsigned] [1]'])

        self.assert_multi_line_lint('class NoProblemsHere {\n'
                                    '    bool m_boolMember;\n'
                                    '    unsigned m_unsignedMember;\n'
                                    '    unsigned m_bitField1 : 1;\n'
                                    '    unsigned m_bitField4 : 4;\n'
                                    '}\n', '')

    # Bitfields which are not declared unsigned or bool will generate a warning.
    def test_unsigned_bool_bitfields(self):
        def errmsg(member, name, bit_type):
            return ('Member %s of class %s defined as a bitfield of type %s. '
                    'Please declare all bitfields as unsigned.  [runtime/bitfields] [4]'
                    % (member, name, bit_type))

        def warning_bitfield_test(member, name, bit_type, bits):
            self.assert_multi_line_lint('class %s {\n%s %s: %d;\n}\n'
                                        % (name, bit_type, member, bits),
                                        errmsg(member, name, bit_type))

        def safe_bitfield_test(member, name, bit_type, bits):
            self.assert_multi_line_lint('class %s {\n%s %s: %d;\n}\n'
                                        % (name, bit_type, member, bits),
                                        '')

        warning_bitfield_test('a', 'A', 'int32_t', 25)
        warning_bitfield_test('m_someField', 'SomeClass', 'signed', 4)
        warning_bitfield_test('m_someField', 'SomeClass', 'SomeEnum', 2)

        safe_bitfield_test('a', 'A', 'unsigned', 22)
        safe_bitfield_test('m_someField', 'SomeClass', 'bool', 1)
        safe_bitfield_test('m_someField', 'SomeClass', 'unsigned', 2)

        # Declarations in 'Expected' or 'SameSizeAs' classes are OK.
        warning_bitfield_test('m_bitfields', 'SomeClass', 'int32_t', 32)
        safe_bitfield_test('m_bitfields', 'ExpectedSomeClass', 'int32_t', 32)
        safe_bitfield_test('m_bitfields', 'SameSizeAsSomeClass', 'int32_t', 32)

class CleansedLinesTest(unittest.TestCase):
    def test_init(self):
        lines = ['Line 1',
                 'Line 2',
                 'Line 3 // Comment test',
                 'Line 4 "foo"']

        clean_lines = cpp_style.CleansedLines(lines)
        self.assertEqual(lines, clean_lines.raw_lines)
        self.assertEqual(4, clean_lines.num_lines())

        self.assertEqual(['Line 1',
                           'Line 2',
                           'Line 3 ',
                           'Line 4 "foo"'],
                          clean_lines.lines)

        self.assertEqual(['Line 1',
                           'Line 2',
                           'Line 3 ',
                           'Line 4 ""'],
                          clean_lines.elided)

    def test_init_empty(self):
        clean_lines = cpp_style.CleansedLines([])
        self.assertEqual([], clean_lines.raw_lines)
        self.assertEqual(0, clean_lines.num_lines())

    def test_collapse_strings(self):
        collapse = cpp_style.CleansedLines.collapse_strings
        self.assertEqual('""', collapse('""'))             # ""     (empty)
        self.assertEqual('"""', collapse('"""'))           # """    (bad)
        self.assertEqual('""', collapse('"xyz"'))          # "xyz"  (string)
        self.assertEqual('""', collapse('"\\\""'))         # "\""   (string)
        self.assertEqual('""', collapse('"\'"'))           # "'"    (string)
        self.assertEqual('"\"', collapse('"\"'))           # "\"    (bad)
        self.assertEqual('""', collapse('"\\\\"'))         # "\\"   (string)
        self.assertEqual('"', collapse('"\\\\\\"'))        # "\\\"  (bad)
        self.assertEqual('""', collapse('"\\\\\\\\"'))     # "\\\\" (string)

        self.assertEqual('\'\'', collapse('\'\''))         # ''     (empty)
        self.assertEqual('\'\'', collapse('\'a\''))        # 'a'    (char)
        self.assertEqual('\'\'', collapse('\'\\\'\''))     # '\''   (char)
        self.assertEqual('\'', collapse('\'\\\''))         # '\'    (bad)
        self.assertEqual('', collapse('\\012'))            # '\012' (char)
        self.assertEqual('', collapse('\\xfF0'))           # '\xfF0' (char)
        self.assertEqual('', collapse('\\n'))              # '\n' (char)
        self.assertEqual('\#', collapse('\\#'))            # '\#' (bad)

        self.assertEqual('StringReplace(body, "", "");',
                          collapse('StringReplace(body, "\\\\", "\\\\\\\\");'))
        self.assertEqual('\'\' ""',
                          collapse('\'"\' "foo"'))


class OrderOfIncludesTest(CppStyleTestBase):
    def setUp(self):
        self.include_state = cpp_style._IncludeState()

        # Cheat os.path.abspath called in FileInfo class.
        self.os_path_abspath_orig = os.path.abspath
        os.path.abspath = lambda value: value

    def tearDown(self):
        os.path.abspath = self.os_path_abspath_orig

    def test_try_drop_common_suffixes(self):
        self.assertEqual('foo/foo', cpp_style._drop_common_suffixes('foo/foo-inl.h'))
        self.assertEqual('foo/bar/foo',
                         cpp_style._drop_common_suffixes('foo/bar/foo_inl.h'))
        self.assertEqual('foo/foo', cpp_style._drop_common_suffixes('foo/foo.cpp'))
        self.assertEqual('foo/foo_unusualinternal',
                         cpp_style._drop_common_suffixes('foo/foo_unusualinternal.h'))
        self.assertEqual('',
                         cpp_style._drop_common_suffixes('_test.cpp'))
        self.assertEqual('test',
                         cpp_style._drop_common_suffixes('test.cpp'))


class OrderOfIncludesTest(CppStyleTestBase):
    def setUp(self):
        self.include_state = cpp_style._IncludeState()

        # Cheat os.path.abspath called in FileInfo class.
        self.os_path_abspath_orig = os.path.abspath
        self.os_path_isfile_orig = os.path.isfile
        os.path.abspath = lambda value: value

    def tearDown(self):
        os.path.abspath = self.os_path_abspath_orig
        os.path.isfile = self.os_path_isfile_orig

    def test_check_next_include_order__no_config(self):
        self.assertEqual('Header file should not contain WebCore config.h.',
                         self.include_state.check_next_include_order(cpp_style._CONFIG_HEADER, True, True))

    def test_check_next_include_order__no_self(self):
        self.assertEqual('Header file should not contain itself.',
                         self.include_state.check_next_include_order(cpp_style._PRIMARY_HEADER, True, True))
        # Test actual code to make sure that header types are correctly assigned.
        self.assert_language_rules_check('Foo.h',
                                         '#include "Foo.h"\n',
                                         'Header file should not contain itself. Should be: alphabetically sorted.'
                                         '  [build/include_order] [4]')
        self.assert_language_rules_check('FooBar.h',
                                         '#include "Foo.h"\n',
                                         '')

    def test_check_next_include_order__likely_then_config(self):
        self.assertEqual('Found header this file implements before WebCore config.h.',
                         self.include_state.check_next_include_order(cpp_style._PRIMARY_HEADER, False, True))
        self.assertEqual('Found WebCore config.h after a header this file implements.',
                         self.include_state.check_next_include_order(cpp_style._CONFIG_HEADER, False, True))

    def test_check_next_include_order__other_then_config(self):
        self.assertEqual('Found other header before WebCore config.h.',
                         self.include_state.check_next_include_order(cpp_style._OTHER_HEADER, False, True))
        self.assertEqual('Found WebCore config.h after other header.',
                         self.include_state.check_next_include_order(cpp_style._CONFIG_HEADER, False, True))

    def test_check_next_include_order__config_then_other_then_likely(self):
        self.assertEqual('', self.include_state.check_next_include_order(cpp_style._CONFIG_HEADER, False, True))
        self.assertEqual('Found other header before a header this file implements.',
                         self.include_state.check_next_include_order(cpp_style._OTHER_HEADER, False, True))
        self.assertEqual('Found header this file implements after other header.',
                         self.include_state.check_next_include_order(cpp_style._PRIMARY_HEADER, False, True))

    def test_check_alphabetical_include_order(self):
        self.assert_language_rules_check('foo.h',
                                         '#include "a.h"\n'
                                         '#include "c.h"\n'
                                         '#include "b.h"\n',
                                         'Alphabetical sorting problem.  [build/include_order] [4]')

        self.assert_language_rules_check('foo.h',
                                         '#include "a.h"\n'
                                         '#include "b.h"\n'
                                         '#include "c.h"\n',
                                         '')

        self.assert_language_rules_check('foo.h',
                                         '#include <assert.h>\n'
                                         '#include "bar.h"\n',
                                         'Alphabetical sorting problem.  [build/include_order] [4]')

        self.assert_language_rules_check('foo.h',
                                         '#include "bar.h"\n'
                                         '#include <assert.h>\n',
                                         '')

    def test_check_alphabetical_include_order_errors_reported_for_both_lines(self):
        # If one of the two lines of out of order headers are filtered, the error should be
        # reported on the other line.
        self.assert_language_rules_check('foo.h',
                                         '#include "a.h"\n'
                                         '#include "c.h"\n'
                                         '#include "b.h"\n',
                                         'Alphabetical sorting problem.  [build/include_order] [4]',
                                         lines_to_check=[2])

        self.assert_language_rules_check('foo.h',
                                         '#include "a.h"\n'
                                         '#include "c.h"\n'
                                         '#include "b.h"\n',
                                         'Alphabetical sorting problem.  [build/include_order] [4]',
                                         lines_to_check=[3])

        # If no lines are filtered, the error should be reported only once.
        self.assert_language_rules_check('foo.h',
                                         '#include "a.h"\n'
                                         '#include "c.h"\n'
                                         '#include "b.h"\n',
                                         'Alphabetical sorting problem.  [build/include_order] [4]')

    def test_check_line_break_after_own_header(self):
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '#include "bar.h"\n',
                                         'You should add a blank line after implementation file\'s own header.  [build/include_order] [4]')

        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#include "bar.h"\n',
                                         '')

    def test_check_preprocessor_in_include_section(self):
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#ifdef BAZ\n'
                                         '#include "baz.h"\n'
                                         '#else\n'
                                         '#include "foobar.h"\n'
                                         '#endif"\n'
                                         '#include "bar.h"\n', # No flag because previous is in preprocessor section
                                         '')

        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#ifdef BAZ\n'
                                         '#include "baz.h"\n'
                                         '#endif"\n'
                                         '#include "bar.h"\n'
                                         '#include "a.h"\n', # Should still flag this.
                                         'Alphabetical sorting problem.  [build/include_order] [4]')

        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#ifdef BAZ\n'
                                         '#include "baz.h"\n'
                                         '#include "bar.h"\n' #Should still flag this
                                         '#endif"\n',
                                         'Alphabetical sorting problem.  [build/include_order] [4]')

        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#ifdef BAZ\n'
                                         '#include "baz.h"\n'
                                         '#endif"\n'
                                         '#ifdef FOOBAR\n'
                                         '#include "foobar.h"\n'
                                         '#endif"\n'
                                         '#include "bar.h"\n'
                                         '#include "a.h"\n', # Should still flag this.
                                         'Alphabetical sorting problem.  [build/include_order] [4]')

        # Check that after an already included error, the sorting rules still work.
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#include "foo.h"\n'
                                         '#include "g.h"\n',
                                         '"foo.h" already included at foo.cpp:2  [build/include] [4]')

    def test_primary_header(self):
        # File with non-existing primary header should not produce errors.
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '\n'
                                         '#include "bar.h"\n',
                                         '')
        # Pretend that header files exist.
        os.path.isfile = lambda filename: True
        # Missing include for existing primary header -> error.
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '\n'
                                         '#include "bar.h"\n',
                                         'Found other header before a header this file implements. '
                                         'Should be: config.h, primary header, blank line, and then '
                                         'alphabetically sorted.  [build/include_order] [4]')
        # Having include for existing primary header -> no error.
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#include "bar.h"\n',
                                         '')

        os.path.isfile = self.os_path_isfile_orig

    def test_public_primary_header(self):
        # System header is not considered a primary header.
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include <other/foo.h>\n'
                                         '\n'
                                         '#include "a.h"\n',
                                         'Alphabetical sorting problem.  [build/include_order] [4]')

        # ...except that it starts with public/.
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include <public/foo.h>\n'
                                         '\n'
                                         '#include "a.h"\n',
                                         '')

        # Even if it starts with public/ its base part must match with the source file name.
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include <public/foop.h>\n'
                                         '\n'
                                         '#include "a.h"\n',
                                         'Alphabetical sorting problem.  [build/include_order] [4]')

    def test_check_wtf_includes(self):
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#include <wtf/Assertions.h>\n',
                                         'wtf includes should be "wtf/file.h" instead of <wtf/file.h>.'
                                         '  [build/include] [4]')
        self.assert_language_rules_check('foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#include "wtf/Assertions.h"\n',
                                         '')

    def test_check_cc_includes(self):
        self.assert_language_rules_check('bar/chromium/foo.cpp',
                                         '#include "config.h"\n'
                                         '#include "foo.h"\n'
                                         '\n'
                                         '#include "cc/CCProxy.h"\n',
                                         'cc includes should be "CCFoo.h" instead of "cc/CCFoo.h".'
                                         '  [build/include] [4]')

    def test_classify_include(self):
        classify_include = cpp_style._classify_include
        include_state = cpp_style._IncludeState()
        self.assertEqual(cpp_style._CONFIG_HEADER,
                         classify_include('foo/foo.cpp',
                                          'config.h',
                                          False, include_state))
        self.assertEqual(cpp_style._PRIMARY_HEADER,
                         classify_include('foo/internal/foo.cpp',
                                          'foo/public/foo.h',
                                          False, include_state))
        self.assertEqual(cpp_style._PRIMARY_HEADER,
                         classify_include('foo/internal/foo.cpp',
                                          'foo/other/public/foo.h',
                                          False, include_state))
        self.assertEqual(cpp_style._OTHER_HEADER,
                         classify_include('foo/internal/foo.cpp',
                                          'foo/other/public/foop.h',
                                          False, include_state))
        self.assertEqual(cpp_style._OTHER_HEADER,
                         classify_include('foo/foo.cpp',
                                          'string',
                                          True, include_state))
        self.assertEqual(cpp_style._PRIMARY_HEADER,
                         classify_include('fooCustom.cpp',
                                          'foo.h',
                                          False, include_state))
        self.assertEqual(cpp_style._PRIMARY_HEADER,
                         classify_include('PrefixFooCustom.cpp',
                                          'Foo.h',
                                          False, include_state))
        self.assertEqual(cpp_style._MOC_HEADER,
                         classify_include('foo.cpp',
                                          'foo.moc',
                                          False, include_state))
        self.assertEqual(cpp_style._MOC_HEADER,
                         classify_include('foo.cpp',
                                          'moc_foo.cpp',
                                          False, include_state))
        # <public/foo.h> must be considered as primary even if is_system is True.
        self.assertEqual(cpp_style._PRIMARY_HEADER,
                         classify_include('foo/foo.cpp',
                                          'public/foo.h',
                                          True, include_state))
        self.assertEqual(cpp_style._OTHER_HEADER,
                         classify_include('foo.cpp',
                                          'foo.h',
                                          True, include_state))
        self.assertEqual(cpp_style._OTHER_HEADER,
                         classify_include('foo.cpp',
                                          'public/foop.h',
                                          True, include_state))
        # Qt private APIs use _p.h suffix.
        self.assertEqual(cpp_style._PRIMARY_HEADER,
                         classify_include('foo.cpp',
                                          'foo_p.h',
                                          False, include_state))
        # Tricky example where both includes might be classified as primary.
        self.assert_language_rules_check('ScrollbarThemeWince.cpp',
                                         '#include "config.h"\n'
                                         '#include "ScrollbarThemeWince.h"\n'
                                         '\n'
                                         '#include "Scrollbar.h"\n',
                                         '')
        self.assert_language_rules_check('ScrollbarThemeWince.cpp',
                                         '#include "config.h"\n'
                                         '#include "Scrollbar.h"\n'
                                         '\n'
                                         '#include "ScrollbarThemeWince.h"\n',
                                         'Found header this file implements after a header this file implements.'
                                         ' Should be: config.h, primary header, blank line, and then alphabetically sorted.'
                                         '  [build/include_order] [4]')
        self.assert_language_rules_check('ResourceHandleWin.cpp',
                                         '#include "config.h"\n'
                                         '#include "ResourceHandle.h"\n'
                                         '\n'
                                         '#include "ResourceHandleWin.h"\n',
                                         '')

    def test_try_drop_common_suffixes(self):
        self.assertEqual('foo/foo', cpp_style._drop_common_suffixes('foo/foo-inl.h'))
        self.assertEqual('foo/bar/foo',
                         cpp_style._drop_common_suffixes('foo/bar/foo_inl.h'))
        self.assertEqual('foo/foo', cpp_style._drop_common_suffixes('foo/foo.cpp'))
        self.assertEqual('foo/foo_unusualinternal',
                         cpp_style._drop_common_suffixes('foo/foo_unusualinternal.h'))
        self.assertEqual('',
                         cpp_style._drop_common_suffixes('_test.cpp'))
        self.assertEqual('test',
                         cpp_style._drop_common_suffixes('test.cpp'))
        self.assertEqual('test',
                         cpp_style._drop_common_suffixes('test.cpp'))

class CheckForFunctionLengthsTest(CppStyleTestBase):
    def setUp(self):
        # Reducing these thresholds for the tests speeds up tests significantly.
        self.old_normal_trigger = cpp_style._FunctionState._NORMAL_TRIGGER
        self.old_test_trigger = cpp_style._FunctionState._TEST_TRIGGER

        cpp_style._FunctionState._NORMAL_TRIGGER = 10
        cpp_style._FunctionState._TEST_TRIGGER = 25

    def tearDown(self):
        cpp_style._FunctionState._NORMAL_TRIGGER = self.old_normal_trigger
        cpp_style._FunctionState._TEST_TRIGGER = self.old_test_trigger

    # FIXME: Eliminate the need for this function.
    def set_min_confidence(self, min_confidence):
        """Set new test confidence and return old test confidence."""
        old_min_confidence = self.min_confidence
        self.min_confidence = min_confidence
        return old_min_confidence

    def assert_function_lengths_check(self, code, expected_message):
        """Check warnings for long function bodies are as expected.

        Args:
          code: C++ source code expected to generate a warning message.
          expected_message: Message expected to be generated by the C++ code.
        """
        self.assertEqual(expected_message,
                          self.perform_function_lengths_check(code))

    def trigger_lines(self, error_level):
        """Return number of lines needed to trigger a function length warning.

        Args:
          error_level: --v setting for cpp_style.

        Returns:
          Number of lines needed to trigger a function length warning.
        """
        return cpp_style._FunctionState._NORMAL_TRIGGER * 2 ** error_level

    def trigger_test_lines(self, error_level):
        """Return number of lines needed to trigger a test function length warning.

        Args:
          error_level: --v setting for cpp_style.

        Returns:
          Number of lines needed to trigger a test function length warning.
        """
        return cpp_style._FunctionState._TEST_TRIGGER * 2 ** error_level

    def assert_function_length_check_definition(self, lines, error_level):
        """Generate long function definition and check warnings are as expected.

        Args:
          lines: Number of lines to generate.
          error_level:  --v setting for cpp_style.
        """
        trigger_level = self.trigger_lines(self.min_confidence)
        self.assert_function_lengths_check(
            'void test(int x)' + self.function_body(lines),
            ('Small and focused functions are preferred: '
             'test() has %d non-comment lines '
             '(error triggered by exceeding %d lines).'
             '  [readability/fn_size] [%d]'
             % (lines, trigger_level, error_level)))

    def assert_function_length_check_definition_ok(self, lines):
        """Generate shorter function definition and check no warning is produced.

        Args:
          lines: Number of lines to generate.
        """
        self.assert_function_lengths_check(
            'void test(int x)' + self.function_body(lines),
            '')

    def assert_function_length_check_at_error_level(self, error_level):
        """Generate and check function at the trigger level for --v setting.

        Args:
          error_level: --v setting for cpp_style.
        """
        self.assert_function_length_check_definition(self.trigger_lines(error_level),
                                                     error_level)

    def assert_function_length_check_below_error_level(self, error_level):
        """Generate and check function just below the trigger level for --v setting.

        Args:
          error_level: --v setting for cpp_style.
        """
        self.assert_function_length_check_definition(self.trigger_lines(error_level) - 1,
                                                     error_level - 1)

    def assert_function_length_check_above_error_level(self, error_level):
        """Generate and check function just above the trigger level for --v setting.

        Args:
          error_level: --v setting for cpp_style.
        """
        self.assert_function_length_check_definition(self.trigger_lines(error_level) + 1,
                                                     error_level)

    def function_body(self, number_of_lines):
        return ' {\n' + '    this_is_just_a_test();\n' * number_of_lines + '}'

    def function_body_with_blank_lines(self, number_of_lines):
        return ' {\n' + '    this_is_just_a_test();\n\n' * number_of_lines + '}'

    def function_body_with_no_lints(self, number_of_lines):
        return ' {\n' + '    this_is_just_a_test();  // NOLINT\n' * number_of_lines + '}'

    # Test line length checks.
    def test_function_length_check_declaration(self):
        self.assert_function_lengths_check(
            'void test();',  # Not a function definition
            '')

    def test_function_length_check_declaration_with_block_following(self):
        self.assert_function_lengths_check(
            ('void test();\n'
             + self.function_body(66)),  # Not a function definition
            '')

    def test_function_length_check_class_definition(self):
        self.assert_function_lengths_check(  # Not a function definition
            'class Test' + self.function_body(66) + ';',
            '')

    def test_function_length_check_trivial(self):
        self.assert_function_lengths_check(
            'void test() {}',  # Not counted
            '')

    def test_function_length_check_empty(self):
        self.assert_function_lengths_check(
            'void test() {\n}',
            '')

    def test_function_length_check_definition_below_severity0(self):
        old_min_confidence = self.set_min_confidence(0)
        self.assert_function_length_check_definition_ok(self.trigger_lines(0) - 1)
        self.set_min_confidence(old_min_confidence)

    def test_function_length_check_definition_at_severity0(self):
        old_min_confidence = self.set_min_confidence(0)
        self.assert_function_length_check_definition_ok(self.trigger_lines(0))
        self.set_min_confidence(old_min_confidence)

    def test_function_length_check_definition_above_severity0(self):
        old_min_confidence = self.set_min_confidence(0)
        self.assert_function_length_check_above_error_level(0)
        self.set_min_confidence(old_min_confidence)

    def test_function_length_check_definition_below_severity1v0(self):
        old_min_confidence = self.set_min_confidence(0)
        self.assert_function_length_check_below_error_level(1)
        self.set_min_confidence(old_min_confidence)

    def test_function_length_check_definition_at_severity1v0(self):
        old_min_confidence = self.set_min_confidence(0)
        self.assert_function_length_check_at_error_level(1)
        self.set_min_confidence(old_min_confidence)

    def test_function_length_check_definition_below_severity1(self):
        self.assert_function_length_check_definition_ok(self.trigger_lines(1) - 1)

    def test_function_length_check_definition_at_severity1(self):
        self.assert_function_length_check_definition_ok(self.trigger_lines(1))

    def test_function_length_check_definition_above_severity1(self):
        self.assert_function_length_check_above_error_level(1)

    def test_function_length_check_definition_severity1_plus_indented(self):
        error_level = 1
        error_lines = self.trigger_lines(error_level) + 1
        trigger_level = self.trigger_lines(self.min_confidence)
        indent_spaces = '    '
        self.assert_function_lengths_check(
            re.sub(r'(?m)^(.)', indent_spaces + r'\1',
                   'void test_indent(int x)\n' + self.function_body(error_lines)),
            ('Small and focused functions are preferred: '
             'test_indent() has %d non-comment lines '
             '(error triggered by exceeding %d lines).'
             '  [readability/fn_size] [%d]')
            % (error_lines, trigger_level, error_level))

    def test_function_length_check_definition_severity1_plus_blanks(self):
        error_level = 1
        error_lines = self.trigger_lines(error_level) + 1
        trigger_level = self.trigger_lines(self.min_confidence)
        self.assert_function_lengths_check(
            'void test_blanks(int x)' + self.function_body(error_lines),
            ('Small and focused functions are preferred: '
             'test_blanks() has %d non-comment lines '
             '(error triggered by exceeding %d lines).'
             '  [readability/fn_size] [%d]')
            % (error_lines, trigger_level, error_level))

    def test_function_length_check_complex_definition_severity1(self):
        error_level = 1
        error_lines = self.trigger_lines(error_level) + 1
        trigger_level = self.trigger_lines(self.min_confidence)
        self.assert_function_lengths_check(
            ('my_namespace::my_other_namespace::MyVeryLongTypeName<Type1, bool func(const Element*)>*\n'
             'my_namespace::my_other_namespace<Type3, Type4>::~MyFunction<Type5<Type6, Type7> >(int arg1, char* arg2)'
             + self.function_body(error_lines)),
            ('Small and focused functions are preferred: '
             'my_namespace::my_other_namespace<Type3, Type4>::~MyFunction<Type5<Type6, Type7> >()'
             ' has %d non-comment lines '
             '(error triggered by exceeding %d lines).'
             '  [readability/fn_size] [%d]')
            % (error_lines, trigger_level, error_level))

    def test_function_length_check_definition_severity1_for_test(self):
        error_level = 1
        error_lines = self.trigger_test_lines(error_level) + 1
        trigger_level = self.trigger_test_lines(self.min_confidence)
        self.assert_function_lengths_check(
            'TEST_F(Test, Mutator)' + self.function_body(error_lines),
            ('Small and focused functions are preferred: '
             'TEST_F(Test, Mutator) has %d non-comment lines '
             '(error triggered by exceeding %d lines).'
             '  [readability/fn_size] [%d]')
            % (error_lines, trigger_level, error_level))

    def test_function_length_check_definition_severity1_for_split_line_test(self):
        error_level = 1
        error_lines = self.trigger_test_lines(error_level) + 1
        trigger_level = self.trigger_test_lines(self.min_confidence)
        self.assert_function_lengths_check(
            ('TEST_F(GoogleUpdateRecoveryRegistryProtectedTest,\n'
             '    FixGoogleUpdate_AllValues_MachineApp)'  # note: 4 spaces
             + self.function_body(error_lines)),
            ('Small and focused functions are preferred: '
             'TEST_F(GoogleUpdateRecoveryRegistryProtectedTest, '  # 1 space
             'FixGoogleUpdate_AllValues_MachineApp) has %d non-comment lines '
             '(error triggered by exceeding %d lines).'
             '  [readability/fn_size] [%d]')
            % (error_lines, trigger_level, error_level))

    def test_function_length_check_definition_severity1_for_bad_test_doesnt_break(self):
        error_level = 1
        error_lines = self.trigger_test_lines(error_level) + 1
        trigger_level = self.trigger_test_lines(self.min_confidence)
        # Since the function name isn't valid, the function detection algorithm
        # will skip it, so no error is produced.
        self.assert_function_lengths_check(
            ('TEST_F('
             + self.function_body(error_lines)),
            '')

    def test_function_length_check_definition_severity1_with_embedded_no_lints(self):
        error_level = 1
        error_lines = self.trigger_lines(error_level) + 1
        trigger_level = self.trigger_lines(self.min_confidence)
        self.assert_function_lengths_check(
            'void test(int x)' + self.function_body_with_no_lints(error_lines),
            ('Small and focused functions are preferred: '
             'test() has %d non-comment lines '
             '(error triggered by exceeding %d lines).'
             '  [readability/fn_size] [%d]')
            % (error_lines, trigger_level, error_level))

    def test_function_length_check_definition_severity1_with_no_lint(self):
        self.assert_function_lengths_check(
            ('void test(int x)' + self.function_body(self.trigger_lines(1))
             + '  // NOLINT -- long function'),
            '')

    def test_function_length_check_definition_below_severity2(self):
        self.assert_function_length_check_below_error_level(2)

    def test_function_length_check_definition_severity2(self):
        self.assert_function_length_check_at_error_level(2)

    def test_function_length_check_definition_above_severity2(self):
        self.assert_function_length_check_above_error_level(2)

    def test_function_length_check_definition_below_severity3(self):
        self.assert_function_length_check_below_error_level(3)

    def test_function_length_check_definition_severity3(self):
        self.assert_function_length_check_at_error_level(3)

    def test_function_length_check_definition_above_severity3(self):
        self.assert_function_length_check_above_error_level(3)

    def test_function_length_check_definition_below_severity4(self):
        self.assert_function_length_check_below_error_level(4)

    def test_function_length_check_definition_severity4(self):
        self.assert_function_length_check_at_error_level(4)

    def test_function_length_check_definition_above_severity4(self):
        self.assert_function_length_check_above_error_level(4)

    def test_function_length_check_definition_below_severity5(self):
        self.assert_function_length_check_below_error_level(5)

    def test_function_length_check_definition_at_severity5(self):
        self.assert_function_length_check_at_error_level(5)

    def test_function_length_check_definition_above_severity5(self):
        self.assert_function_length_check_above_error_level(5)

    def test_function_length_check_definition_huge_lines(self):
        # 5 is the limit
        self.assert_function_length_check_definition(self.trigger_lines(6), 5)

    def test_function_length_not_determinable(self):
        # Macro invocation without terminating semicolon.
        self.assert_function_lengths_check(
            'MACRO(arg)',
            '')

        # Macro with underscores
        self.assert_function_lengths_check(
            'MACRO_WITH_UNDERSCORES(arg1, arg2, arg3)',
            '')

        self.assert_function_lengths_check(
            'NonMacro(arg)',
            'Lint failed to find start of function body.'
            '  [readability/fn_size] [5]')


class NoNonVirtualDestructorsTest(CppStyleTestBase):

    def test_no_error(self):
        self.assert_multi_line_lint(
            '''\
                class Foo {
                    virtual ~Foo();
                    virtual void foo();
                };''',
            '')

        self.assert_multi_line_lint(
            '''\
                class Foo {
                    virtual inline ~Foo();
                    virtual void foo();
                };''',
            '')

        self.assert_multi_line_lint(
            '''\
                class Foo {
                    inline virtual ~Foo();
                    virtual void foo();
                };''',
            '')

        self.assert_multi_line_lint(
            '''\
                class Foo::Goo {
                    virtual ~Goo();
                    virtual void goo();
                };''',
            '')
        self.assert_multi_line_lint(
            'class Foo { void foo(); };',
            'More than one command on the same line  [whitespace/newline] [4]')
        self.assert_multi_line_lint(
            'class MyClass {\n'
            '    int getIntValue() { ASSERT(m_ptr); return *m_ptr; }\n'
            '};\n',
            '')
        self.assert_multi_line_lint(
            'class MyClass {\n'
            '    int getIntValue()\n'
            '    {\n'
            '        ASSERT(m_ptr); return *m_ptr;\n'
            '    }\n'
            '};\n',
            'More than one command on the same line  [whitespace/newline] [4]')

        self.assert_multi_line_lint(
            '''\
                class Qualified::Goo : public Foo {
                    virtual void goo();
                };''',
            '')

    def test_no_destructor_when_virtual_needed(self):
        self.assert_multi_line_lint_re(
            '''\
                class Foo {
                    virtual void foo();
                };''',
            'The class Foo probably needs a virtual destructor')

    def test_enum_casing(self):
        self.assert_multi_line_lint(
            '''\
                enum Foo {
                    FOO_ONE = 1,
                    FOO_TWO
                };
                enum { FOO_ONE };
                enum {FooOne, fooTwo};
                enum {
                    FOO_ONE
                };''',
            ['enum members should use InterCaps with an initial capital letter.  [readability/enum_casing] [4]'] * 5)

        self.assert_multi_line_lint(
            '''\
                enum Foo {
                    fooOne = 1,
                    FooTwo = 2
                };''',
            'enum members should use InterCaps with an initial capital letter.  [readability/enum_casing] [4]')

        self.assert_multi_line_lint(
            '''\
                enum Foo {
                    FooOne = 1,
                    FooTwo
                } fooVar = FooOne;
                enum { FooOne, FooTwo };
                enum { FooOne, FooTwo } fooVar = FooTwo;
                enum { FooOne= FooTwo } foo;
                enum Enum123 {
                    FooOne,
                    FooTwo = FooOne,
                };''',
            '')

        self.assert_multi_line_lint(
            '''\
                // WebIDL enum
                enum Foo {
                    FOO_ONE = 1,
                    FOO_TWO = 2,
                };''',
            '')

        self.assert_multi_line_lint(
            '''\
                // WebKitIDL enum
                enum Foo { FOO_ONE, FOO_TWO };''',
            '')

    def test_destructor_non_virtual_when_virtual_needed(self):
        self.assert_multi_line_lint_re(
            '''\
                class Foo {
                    ~Foo();
                    virtual void foo();
                };''',
            'The class Foo probably needs a virtual destructor')

    def test_no_warn_when_derived(self):
        self.assert_multi_line_lint(
            '''\
                class Foo : public Goo {
                    virtual void foo();
                };''',
            '')

    def test_internal_braces(self):
        self.assert_multi_line_lint_re(
            '''\
                class Foo {
                    enum Goo {
                        Goo
                    };
                    virtual void foo();
                };''',
            'The class Foo probably needs a virtual destructor')

    def test_inner_class_needs_virtual_destructor(self):
        self.assert_multi_line_lint_re(
            '''\
                class Foo {
                    class Goo {
                        virtual void goo();
                    };
                };''',
            'The class Goo probably needs a virtual destructor')

    def test_outer_class_needs_virtual_destructor(self):
        self.assert_multi_line_lint_re(
            '''\
                class Foo {
                    class Goo {
                    };
                    virtual void foo();
                };''',
            'The class Foo probably needs a virtual destructor')

    def test_qualified_class_needs_virtual_destructor(self):
        self.assert_multi_line_lint_re(
            '''\
                class Qualified::Foo {
                    virtual void foo();
                };''',
            'The class Qualified::Foo probably needs a virtual destructor')

    def test_multi_line_declaration_no_error(self):
        self.assert_multi_line_lint_re(
            '''\
                class Foo
                    : public Goo {
                    virtual void foo();
                };''',
            '')

    def test_multi_line_declaration_with_error(self):
        self.assert_multi_line_lint(
            '''\
                class Foo
                {
                    virtual void foo();
                };''',
            ['This { should be at the end of the previous line  '
             '[whitespace/braces] [4]',
             'The class Foo probably needs a virtual destructor due to having '
             'virtual method(s), one declared at line 3.  [runtime/virtual] [4]'])


class PassPtrTest(CppStyleTestBase):
    # For http://webkit.org/coding/RefPtr.html

    def assert_pass_ptr_check(self, code, expected_message):
        """Check warnings for Pass*Ptr are as expected.

        Args:
          code: C++ source code expected to generate a warning message.
          expected_message: Message expected to be generated by the C++ code.
        """
        self.assertEqual(expected_message,
                          self.perform_pass_ptr_check(code))

    def test_pass_ref_ptr_in_function(self):
        self.assert_pass_ptr_check(
            'int myFunction()\n'
            '{\n'
            '    PassRefPtr<Type1> variable = variable2;\n'
            '}',
            'Local variables should never be PassRefPtr (see '
            'http://webkit.org/coding/RefPtr.html).  [readability/pass_ptr] [5]')

    def test_pass_own_ptr_in_function(self):
        self.assert_pass_ptr_check(
            'int myFunction()\n'
            '{\n'
            '    PassOwnPtr<Type1> variable = variable2;\n'
            '}',
            'Local variables should never be PassOwnPtr (see '
            'http://webkit.org/coding/RefPtr.html).  [readability/pass_ptr] [5]')

    def test_pass_other_type_ptr_in_function(self):
        self.assert_pass_ptr_check(
            'int myFunction()\n'
            '{\n'
            '    PassOtherTypePtr<Type1> variable;\n'
            '}',
            'Local variables should never be PassOtherTypePtr (see '
            'http://webkit.org/coding/RefPtr.html).  [readability/pass_ptr] [5]')

    def test_pass_ref_ptr_return_value(self):
        self.assert_pass_ptr_check(
            'PassRefPtr<Type1>\n'
            'myFunction(int)\n'
            '{\n'
            '}',
            '')
        self.assert_pass_ptr_check(
            'PassRefPtr<Type1> myFunction(int)\n'
            '{\n'
            '}',
            '')
        self.assert_pass_ptr_check(
            'PassRefPtr<Type1> myFunction();\n',
            '')
        self.assert_pass_ptr_check(
            'OwnRefPtr<Type1> myFunction();\n',
            '')
        self.assert_pass_ptr_check(
            'RefPtr<Type1> myFunction(int)\n'
            '{\n'
            '}',
            'The return type should use PassRefPtr instead of RefPtr.  [readability/pass_ptr] [5]')
        self.assert_pass_ptr_check(
            'OwnPtr<Type1> myFunction(int)\n'
            '{\n'
            '}',
            'The return type should use PassOwnPtr instead of OwnPtr.  [readability/pass_ptr] [5]')

    def test_ref_ptr_parameter_value(self):
        self.assert_pass_ptr_check(
            'int myFunction(PassRefPtr<Type1>)\n'
            '{\n'
            '}',
            '')
        self.assert_pass_ptr_check(
            'int myFunction(RefPtr<Type1>)\n'
            '{\n'
            '}',
            'The parameter type should use PassRefPtr instead of RefPtr.  [readability/pass_ptr] [5]')
        self.assert_pass_ptr_check(
            'int myFunction(RefPtr<Type1>&)\n'
            '{\n'
            '}',
            '')
        self.assert_pass_ptr_check(
            'int myFunction(RefPtr<Type1>*)\n'
            '{\n'
            '}',
            '')
        self.assert_pass_ptr_check(
            'int myFunction(RefPtr<Type1>* = 0)\n'
            '{\n'
            '}',
            '')
        self.assert_pass_ptr_check(
            'int myFunction(RefPtr<Type1>*    =  0)\n'
            '{\n'
            '}',
            '')

    def test_own_ptr_parameter_value(self):
        self.assert_pass_ptr_check(
            'int myFunction(PassOwnPtr<Type1>)\n'
            '{\n'
            '}',
            '')
        self.assert_pass_ptr_check(
            'int myFunction(OwnPtr<Type1>)\n'
            '{\n'
            '}',
            'The parameter type should use PassOwnPtr instead of OwnPtr.  [readability/pass_ptr] [5]')
        self.assert_pass_ptr_check(
            'int myFunction(OwnPtr<Type1>& simple)\n'
            '{\n'
            '}',
            '')

    def test_ref_ptr_member_variable(self):
        self.assert_pass_ptr_check(
            'class Foo {'
            '    RefPtr<Type1> m_other;\n'
            '};\n',
            '')


class LeakyPatternTest(CppStyleTestBase):

    def assert_leaky_pattern_check(self, code, expected_message):
        """Check warnings for leaky patterns are as expected.

        Args:
          code: C++ source code expected to generate a warning message.
          expected_message: Message expected to be generated by the C++ code.
        """
        self.assertEqual(expected_message,
                          self.perform_leaky_pattern_check(code))

    def test_get_dc(self):
        self.assert_leaky_pattern_check(
            'HDC hdc = GetDC(hwnd);',
            'Use the class HWndDC instead of calling GetDC to avoid potential '
            'memory leaks.  [runtime/leaky_pattern] [5]')

    def test_get_dc(self):
        self.assert_leaky_pattern_check(
            'HDC hdc = GetDCEx(hwnd, 0, 0);',
            'Use the class HWndDC instead of calling GetDCEx to avoid potential '
            'memory leaks.  [runtime/leaky_pattern] [5]')

    def test_own_get_dc(self):
        self.assert_leaky_pattern_check(
            'HWndDC hdc(hwnd);',
            '')

    def test_create_dc(self):
        self.assert_leaky_pattern_check(
            'HDC dc2 = ::CreateDC();',
            'Use adoptPtr and OwnPtr<HDC> when calling CreateDC to avoid potential '
            'memory leaks.  [runtime/leaky_pattern] [5]')

        self.assert_leaky_pattern_check(
            'adoptPtr(CreateDC());',
            '')

    def test_create_compatible_dc(self):
        self.assert_leaky_pattern_check(
            'HDC dc2 = CreateCompatibleDC(dc);',
            'Use adoptPtr and OwnPtr<HDC> when calling CreateCompatibleDC to avoid potential '
            'memory leaks.  [runtime/leaky_pattern] [5]')
        self.assert_leaky_pattern_check(
            'adoptPtr(CreateCompatibleDC(dc));',
            '')


class WebKitStyleTest(CppStyleTestBase):

    # for http://webkit.org/coding/coding-style.html
    def test_indentation(self):
        # 1. Use spaces, not tabs. Tabs should only appear in files that
        #    require them for semantic meaning, like Makefiles.
        self.assert_multi_line_lint(
            'class Foo {\n'
            '    int goo;\n'
            '};',
            '')
        self.assert_multi_line_lint(
            'class Foo {\n'
            '\tint goo;\n'
            '};',
            'Tab found; better to use spaces  [whitespace/tab] [1]')

        # 2. The indent size is 4 spaces.
        self.assert_multi_line_lint(
            'class Foo {\n'
            '    int goo;\n'
            '};',
            '')
        self.assert_multi_line_lint(
            'class Foo {\n'
            '   int goo;\n'
            '};',
            'Weird number of spaces at line-start.  Are you using a 4-space indent?  [whitespace/indent] [3]')

        # 3. In a header, code inside a namespace should not be indented.
        self.assert_multi_line_lint(
            'namespace WebCore {\n\n'
            'class Document {\n'
            '    int myVariable;\n'
            '};\n'
            '}',
            '',
            'foo.h')
        self.assert_multi_line_lint(
            'namespace OuterNamespace {\n'
            '    namespace InnerNamespace {\n'
            '    class Document {\n'
            '};\n'
            '};\n'
            '}',
            'Code inside a namespace should not be indented.  [whitespace/indent] [4]',
            'foo.h')
        self.assert_multi_line_lint(
            'namespace OuterNamespace {\n'
            '    class Document {\n'
            '    namespace InnerNamespace {\n'
            '};\n'
            '};\n'
            '}',
            'Code inside a namespace should not be indented.  [whitespace/indent] [4]',
            'foo.h')
        self.assert_multi_line_lint(
            'namespace WebCore {\n'
            '#if 0\n'
            '    class Document {\n'
            '};\n'
            '#endif\n'
            '}',
            'Code inside a namespace should not be indented.  [whitespace/indent] [4]',
            'foo.h')
        self.assert_multi_line_lint(
            'namespace WebCore {\n'
            'class Document {\n'
            '};\n'
            '}',
            '',
            'foo.h')

        # 4. In an implementation file (files with the extension .cpp, .c
        #    or .mm), code inside a namespace should not be indented.
        self.assert_multi_line_lint(
            'namespace WebCore {\n\n'
            'Document::Foo()\n'
            '    : foo(bar)\n'
            '    , boo(far)\n'
            '{\n'
            '    stuff();\n'
            '}',
            '',
            'foo.cpp')
        self.assert_multi_line_lint(
            'namespace OuterNamespace {\n'
            'namespace InnerNamespace {\n'
            'Document::Foo() { }\n'
            '    void* p;\n'
            '}\n'
            '}\n',
            'Code inside a namespace should not be indented.  [whitespace/indent] [4]',
            'foo.cpp')
        self.assert_multi_line_lint(
            'namespace OuterNamespace {\n'
            'namespace InnerNamespace {\n'
            'Document::Foo() { }\n'
            '}\n'
            '    void* p;\n'
            '}\n',
            'Code inside a namespace should not be indented.  [whitespace/indent] [4]',
            'foo.cpp')
        self.assert_multi_line_lint(
            'namespace WebCore {\n\n'
            '    const char* foo = "start:;"\n'
            '        "dfsfsfs";\n'
            '}\n',
            'Code inside a namespace should not be indented.  [whitespace/indent] [4]',
            'foo.cpp')
        self.assert_multi_line_lint(
            'namespace WebCore {\n\n'
            'const char* foo(void* a = ";", // ;\n'
            '    void* b);\n'
            '    void* p;\n'
            '}\n',
            'Code inside a namespace should not be indented.  [whitespace/indent] [4]',
            'foo.cpp')
        self.assert_multi_line_lint(
            'namespace WebCore {\n\n'
            'const char* foo[] = {\n'
            '    "void* b);", // ;\n'
            '    "asfdf",\n'
            '    }\n'
            '    void* p;\n'
            '}\n',
            'Code inside a namespace should not be indented.  [whitespace/indent] [4]',
            'foo.cpp')
        self.assert_multi_line_lint(
            'namespace WebCore {\n\n'
            'const char* foo[] = {\n'
            '    "void* b);", // }\n'
            '    "asfdf",\n'
            '    }\n'
            '}\n',
            '',
            'foo.cpp')
        self.assert_multi_line_lint(
            '    namespace WebCore {\n\n'
            '    void Document::Foo()\n'
            '    {\n'
            'start: // infinite loops are fun!\n'
            '        goto start;\n'
            '    }',
            'namespace should never be indented.  [whitespace/indent] [4]',
            'foo.cpp')
        self.assert_multi_line_lint(
            'namespace WebCore {\n'
            '    Document::Foo() { }\n'
            '}',
            'Code inside a namespace should not be indented.'
            '  [whitespace/indent] [4]',
            'foo.cpp')
        self.assert_multi_line_lint(
            'namespace WebCore {\n'
            '#define abc(x) x; \\\n'
            '    x\n'
            '}',
            '',
            'foo.cpp')
        self.assert_multi_line_lint(
            'namespace WebCore {\n'
            '#define abc(x) x; \\\n'
            '    x\n'
            '    void* x;'
            '}',
            'Code inside a namespace should not be indented.  [whitespace/indent] [4]',
            'foo.cpp')

        # 5. A case label should line up with its switch statement. The
        #    case statement is indented.
        self.assert_multi_line_lint(
            '    switch (condition) {\n'
            '    case fooCondition:\n'
            '    case barCondition:\n'
            '        i++;\n'
            '        break;\n'
            '    default:\n'
            '        i--;\n'
            '    }\n',
            '')
        self.assert_multi_line_lint(
            '    switch (condition) {\n'
            '    case fooCondition:\n'
            '        switch (otherCondition) {\n'
            '        default:\n'
            '            return;\n'
            '        }\n'
            '    default:\n'
            '        i--;\n'
            '    }\n',
            '')
        self.assert_multi_line_lint(
            '    switch (condition) {\n'
            '    case fooCondition: break;\n'
            '    default: return;\n'
            '    }\n',
            '')
        self.assert_multi_line_lint(
            '    switch (condition) {\n'
            '        case fooCondition:\n'
            '        case barCondition:\n'
            '            i++;\n'
            '            break;\n'
            '        default:\n'
            '            i--;\n'
            '    }\n',
            'A case label should not be indented, but line up with its switch statement.'
            '  [whitespace/indent] [4]')
        self.assert_multi_line_lint(
            '    switch (condition) {\n'
            '        case fooCondition:\n'
            '            break;\n'
            '    default:\n'
            '            i--;\n'
            '    }\n',
            'A case label should not be indented, but line up with its switch statement.'
            '  [whitespace/indent] [4]')
        self.assert_multi_line_lint(
            '    switch (condition) {\n'
            '    case fooCondition:\n'
            '    case barCondition:\n'
            '        switch (otherCondition) {\n'
            '            default:\n'
            '            return;\n'
            '        }\n'
            '    default:\n'
            '        i--;\n'
            '    }\n',
            'A case label should not be indented, but line up with its switch statement.'
            '  [whitespace/indent] [4]')
        self.assert_multi_line_lint(
            '    switch (condition) {\n'
            '    case fooCondition:\n'
            '    case barCondition:\n'
            '    i++;\n'
            '    break;\n\n'
            '    default:\n'
            '    i--;\n'
            '    }\n',
            'Non-label code inside switch statements should be indented.'
            '  [whitespace/indent] [4]')
        self.assert_multi_line_lint(
            '    switch (condition) {\n'
            '    case fooCondition:\n'
            '    case barCondition:\n'
            '        switch (otherCondition) {\n'
            '        default:\n'
            '        return;\n'
            '        }\n'
            '    default:\n'
            '        i--;\n'
            '    }\n',
            'Non-label code inside switch statements should be indented.'
            '  [whitespace/indent] [4]')

        # 6. Boolean expressions at the same nesting level that span
        #   multiple lines should have their operators on the left side of
        #   the line instead of the right side.
        self.assert_multi_line_lint(
            '    return attr->name() == srcAttr\n'
            '        || attr->name() == lowsrcAttr;\n',
            '')
        self.assert_multi_line_lint(
            '    return attr->name() == srcAttr ||\n'
            '        attr->name() == lowsrcAttr;\n',
            'Boolean expressions that span multiple lines should have their '
            'operators on the left side of the line instead of the right side.'
            '  [whitespace/operators] [4]')

    def test_spacing(self):
        # 1. Do not place spaces around unary operators.
        self.assert_multi_line_lint(
            'i++;',
            '')
        self.assert_multi_line_lint(
            'i ++;',
            'Extra space for operator  ++;  [whitespace/operators] [4]')

        # 2. Do place spaces around binary and ternary operators.
        self.assert_multi_line_lint(
            'y = m * x + b;',
            '')
        self.assert_multi_line_lint(
            'f(a, b);',
            '')
        self.assert_multi_line_lint(
            'c = a | b;',
            '')
        self.assert_multi_line_lint(
            'return condition ? 1 : 0;',
            '')
        self.assert_multi_line_lint(
            'y=m*x+b;',
            'Missing spaces around =  [whitespace/operators] [4]')
        self.assert_multi_line_lint(
            'f(a,b);',
            'Missing space after ,  [whitespace/comma] [3]')
        self.assert_multi_line_lint(
            'c = a|b;',
            'Missing spaces around |  [whitespace/operators] [3]')
        # FIXME: We cannot catch this lint error.
        # self.assert_multi_line_lint(
        #     'return condition ? 1:0;',
        #     '')

        # 3. Place spaces between control statements and their parentheses.
        self.assert_multi_line_lint(
            '    if (condition)\n'
            '        doIt();\n',
            '')
        self.assert_multi_line_lint(
            '    if(condition)\n'
            '        doIt();\n',
            'Missing space before ( in if(  [whitespace/parens] [5]')

        # 4. Do not place spaces between a function and its parentheses,
        #    or between a parenthesis and its content.
        self.assert_multi_line_lint(
            'f(a, b);',
            '')
        self.assert_multi_line_lint(
            'f (a, b);',
            'Extra space before ( in function call  [whitespace/parens] [4]')
        self.assert_multi_line_lint(
            'f( a, b );',
            ['Extra space after ( in function call  [whitespace/parens] [4]',
             'Extra space before )  [whitespace/parens] [2]'])

    def test_line_breaking(self):
        # 1. Each statement should get its own line.
        self.assert_multi_line_lint(
            '    x++;\n'
            '    y++;\n'
            '    if (condition);\n'
            '        doIt();\n',
            '')
        self.assert_multi_line_lint(
            '    if (condition) \\\n'
            '        doIt();\n',
            '')
        self.assert_multi_line_lint(
            '    x++; y++;',
            'More than one command on the same line  [whitespace/newline] [4]')
        self.assert_multi_line_lint(
            '    if (condition) doIt();\n',
            'More than one command on the same line in if  [whitespace/parens] [4]')
        # Ensure that having a # in the line doesn't hide the error.
        self.assert_multi_line_lint(
            '    x++; char a[] = "#";',
            'More than one command on the same line  [whitespace/newline] [4]')
        # Ignore preprocessor if's.
        self.assert_multi_line_lint(
            '#if (condition) || (condition2)\n',
            '')

        # 2. An else statement should go on the same line as a preceding
        #   close brace if one is present, else it should line up with the
        #   if statement.
        self.assert_multi_line_lint(
            'if (condition) {\n'
            '    doSomething();\n'
            '    doSomethingAgain();\n'
            '} else {\n'
            '    doSomethingElse();\n'
            '    doSomethingElseAgain();\n'
            '}\n',
            '')
        self.assert_multi_line_lint(
            'if (condition)\n'
            '    doSomething();\n'
            'else\n'
            '    doSomethingElse();\n',
            '')
        self.assert_multi_line_lint(
            'if (condition) {\n'
            '    doSomething();\n'
            '} else {\n'
            '    doSomethingElse();\n'
            '    doSomethingElseAgain();\n'
            '}\n',
            '')
        self.assert_multi_line_lint(
            '#define TEST_ASSERT(expression) do { if (!(expression)) { TestsController::shared().testFailed(__FILE__, __LINE__, #expression); return; } } while (0)\n',
            '')
        self.assert_multi_line_lint(
            '#define TEST_ASSERT(expression) do { if ( !(expression)) { TestsController::shared().testFailed(__FILE__, __LINE__, #expression); return; } } while (0)\n',
            'Extra space after ( in if  [whitespace/parens] [5]')
        # FIXME: currently we only check first conditional, so we cannot detect errors in next ones.
        # self.assert_multi_line_lint(
        #     '#define TEST_ASSERT(expression) do { if (!(expression)) { TestsController::shared().testFailed(__FILE__, __LINE__, #expression); return; } } while (0 )\n',
        #     'Mismatching spaces inside () in if  [whitespace/parens] [5]')
        self.assert_multi_line_lint(
            'WTF_MAKE_NONCOPYABLE(ClassName); WTF_MAKE_FAST_ALLOCATED;\n',
            '')
        self.assert_multi_line_lint(
            'if (condition) {\n'
            '    doSomething();\n'
            '    doSomethingAgain();\n'
            '}\n'
            'else {\n'
            '    doSomethingElse();\n'
            '    doSomethingElseAgain();\n'
            '}\n',
            'An else should appear on the same line as the preceding }  [whitespace/newline] [4]')
        self.assert_multi_line_lint(
            'if (condition) doSomething(); else doSomethingElse();\n',
            ['More than one command on the same line  [whitespace/newline] [4]',
             'Else clause should never be on same line as else (use 2 lines)  [whitespace/newline] [4]',
             'More than one command on the same line in if  [whitespace/parens] [4]'])
        self.assert_multi_line_lint(
            'if (condition) doSomething(); else {\n'
            '    doSomethingElse();\n'
            '}\n',
            ['More than one command on the same line in if  [whitespace/parens] [4]',
             'If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]'])
        self.assert_multi_line_lint(
            'void func()\n'
            '{\n'
            '    while (condition) { }\n'
            '    return 0;\n'
            '}\n',
            '')
        self.assert_multi_line_lint(
            'void func()\n'
            '{\n'
            '    for (i = 0; i < 42; i++) { foobar(); }\n'
            '    return 0;\n'
            '}\n',
            'More than one command on the same line in for  [whitespace/parens] [4]')

        # 3. An else if statement should be written as an if statement
        #    when the prior if concludes with a return statement.
        self.assert_multi_line_lint(
            'if (motivated) {\n'
            '    if (liquid)\n'
            '        return money;\n'
            '} else if (tired) {\n'
            '    break;\n'
            '}',
            '')
        self.assert_multi_line_lint(
            'if (condition)\n'
            '    doSomething();\n'
            'else if (otherCondition)\n'
            '    doSomethingElse();\n',
            '')
        self.assert_multi_line_lint(
            'if (condition)\n'
            '    doSomething();\n'
            'else\n'
            '    doSomethingElse();\n',
            '')
        self.assert_multi_line_lint(
            'if (condition)\n'
            '    returnValue = foo;\n'
            'else if (otherCondition)\n'
            '    returnValue = bar;\n',
            '')
        self.assert_multi_line_lint(
            'if (condition)\n'
            '    returnValue = foo;\n'
            'else\n'
            '    returnValue = bar;\n',
            '')
        self.assert_multi_line_lint(
            'if (condition)\n'
            '    doSomething();\n'
            'else if (liquid)\n'
            '    return money;\n'
            'else if (broke)\n'
            '    return favor;\n'
            'else\n'
            '    sleep(28800);\n',
            '')
        self.assert_multi_line_lint(
            'if (liquid) {\n'
            '    prepare();\n'
            '    return money;\n'
            '} else if (greedy) {\n'
            '    keep();\n'
            '    return nothing;\n'
            '}\n',
            'An else if statement should be written as an if statement when the '
            'prior "if" concludes with a return, break, continue or goto statement.'
            '  [readability/control_flow] [4]')
        self.assert_multi_line_lint(
            '    if (stupid) {\n'
            'infiniteLoop:\n'
            '        goto infiniteLoop;\n'
            '    } else if (evil)\n'
            '        goto hell;\n',
            ['If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]',
             'An else if statement should be written as an if statement when the '
             'prior "if" concludes with a return, break, continue or goto statement.'
             '  [readability/control_flow] [4]'])
        self.assert_multi_line_lint(
            'if (liquid)\n'
            '{\n'
            '    prepare();\n'
            '    return money;\n'
            '}\n'
            'else if (greedy)\n'
            '    keep();\n',
            ['If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]',
             'This { should be at the end of the previous line  [whitespace/braces] [4]',
             'An else should appear on the same line as the preceding }  [whitespace/newline] [4]',
             'An else if statement should be written as an if statement when the '
             'prior "if" concludes with a return, break, continue or goto statement.'
             '  [readability/control_flow] [4]'])
        self.assert_multi_line_lint(
            'if (gone)\n'
            '    return;\n'
            'else if (here)\n'
            '    go();\n',
            'An else if statement should be written as an if statement when the '
            'prior "if" concludes with a return, break, continue or goto statement.'
            '  [readability/control_flow] [4]')
        self.assert_multi_line_lint(
            'if (gone)\n'
            '    return;\n'
            'else\n'
            '    go();\n',
            'An else statement can be removed when the prior "if" concludes '
            'with a return, break, continue or goto statement.'
            '  [readability/control_flow] [4]')
        self.assert_multi_line_lint(
            'if (motivated) {\n'
            '    prepare();\n'
            '    continue;\n'
            '} else {\n'
            '    cleanUp();\n'
            '    break;\n'
            '}\n',
            'An else statement can be removed when the prior "if" concludes '
            'with a return, break, continue or goto statement.'
            '  [readability/control_flow] [4]')
        self.assert_multi_line_lint(
            'if (tired)\n'
            '    break;\n'
            'else {\n'
            '    prepare();\n'
            '    continue;\n'
            '}\n',
            ['If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]',
             'An else statement can be removed when the prior "if" concludes '
             'with a return, break, continue or goto statement.'
             '  [readability/control_flow] [4]'])

    def test_braces(self):
        # 1. Function definitions: place each brace on its own line.
        self.assert_multi_line_lint(
            'int main()\n'
            '{\n'
            '    doSomething();\n'
            '}\n',
            '')
        self.assert_multi_line_lint(
            'int main() {\n'
            '    doSomething();\n'
            '}\n',
            'Place brace on its own line for function definitions.  [whitespace/braces] [4]')

        # 2. Other braces: place the open brace on the line preceding the
        #    code block; place the close brace on its own line.
        self.assert_multi_line_lint(
            'class MyClass {\n'
            '    int foo;\n'
            '};\n',
            '')
        self.assert_multi_line_lint(
            'namespace WebCore {\n'
            'int foo;\n'
            '};\n',
            '')
        self.assert_multi_line_lint(
            'for (int i = 0; i < 10; i++) {\n'
            '    DoSomething();\n'
            '};\n',
            '')
        self.assert_multi_line_lint(
            'class MyClass\n'
            '{\n'
            '    int foo;\n'
            '};\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'if (condition)\n'
            '{\n'
            '    int foo;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'for (int i = 0; i < 10; i++)\n'
            '{\n'
            '    int foo;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'while (true)\n'
            '{\n'
            '    int foo;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'foreach (Foo* foo, foos)\n'
            '{\n'
            '    int bar;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'switch (type)\n'
            '{\n'
            'case foo: return;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'if (condition)\n'
            '{\n'
            '    int foo;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'for (int i = 0; i < 10; i++)\n'
            '{\n'
            '    int foo;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'while (true)\n'
            '{\n'
            '    int foo;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'switch (type)\n'
            '{\n'
            'case foo: return;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')
        self.assert_multi_line_lint(
            'else if (type)\n'
            '{\n'
            'case foo: return;\n'
            '}\n',
            'This { should be at the end of the previous line  [whitespace/braces] [4]')

        # 3. Curly braces are not required for single-line conditionals and
        #    loop bodies, but are required for single-statement bodies that
        #    span multiple lines.

        #
        # Positive tests
        #
        self.assert_multi_line_lint(
            'if (condition1)\n'
            '    statement1();\n'
            'else\n'
            '    statement2();\n',
            '')

        self.assert_multi_line_lint(
            'if (condition1)\n'
            '    statement1();\n'
            'else if (condition2)\n'
            '    statement2();\n',
            '')

        self.assert_multi_line_lint(
            'if (condition1)\n'
            '    statement1();\n'
            'else if (condition2)\n'
            '    statement2();\n'
            'else\n'
            '    statement3();\n',
            '')

        self.assert_multi_line_lint(
            'for (; foo; bar)\n'
            '    int foo;\n',
            '')

        self.assert_multi_line_lint(
            'for (; foo; bar) {\n'
            '    int foo;\n'
            '}\n',
            '')

        self.assert_multi_line_lint(
            'foreach (foo, foos) {\n'
            '    int bar;\n'
            '}\n',
            '')

        self.assert_multi_line_lint(
            'foreach (foo, foos)\n'
            '    int bar;\n',
            '')

        self.assert_multi_line_lint(
            'while (true) {\n'
            '    int foo;\n'
            '}\n',
            '')

        self.assert_multi_line_lint(
            'while (true)\n'
            '    int foo;\n',
            '')

        self.assert_multi_line_lint(
            'if (condition1) {\n'
            '    statement1();\n'
            '} else {\n'
            '    statement2();\n'
            '}\n',
            '')

        self.assert_multi_line_lint(
            'if (condition1) {\n'
            '    statement1();\n'
            '} else if (condition2) {\n'
            '    statement2();\n'
            '}\n',
            '')

        self.assert_multi_line_lint(
            'if (condition1) {\n'
            '    statement1();\n'
            '} else if (condition2) {\n'
            '    statement2();\n'
            '} else {\n'
            '    statement3();\n'
            '}\n',
            '')

        self.assert_multi_line_lint(
            'if (condition1) {\n'
            '    statement1();\n'
            '    statement1_2();\n'
            '} else if (condition2) {\n'
            '    statement2();\n'
            '    statement2_2();\n'
            '}\n',
            '')

        self.assert_multi_line_lint(
            'if (condition1) {\n'
            '    statement1();\n'
            '    statement1_2();\n'
            '} else if (condition2) {\n'
            '    statement2();\n'
            '    statement2_2();\n'
            '} else {\n'
            '    statement3();\n'
            '    statement3_2();\n'
            '}\n',
            '')

        #
        # Negative tests
        #

        self.assert_multi_line_lint(
            'if (condition)\n'
            '    doSomething(\n'
            '        spanningMultipleLines);\n',
            'A conditional or loop body must use braces if the statement is more than one line long.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'if (condition)\n'
            '    // Single-line comment\n'
            '    doSomething();\n',
            'A conditional or loop body must use braces if the statement is more than one line long.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'if (condition1)\n'
            '    statement1();\n'
            'else if (condition2)\n'
            '    // Single-line comment\n'
            '    statement2();\n',
            'A conditional or loop body must use braces if the statement is more than one line long.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'if (condition1)\n'
            '    statement1();\n'
            'else if (condition2)\n'
            '    statement2();\n'
            'else\n'
            '    // Single-line comment\n'
            '    statement3();\n',
            'A conditional or loop body must use braces if the statement is more than one line long.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'for (; foo; bar)\n'
            '    // Single-line comment\n'
            '    int foo;\n',
            'A conditional or loop body must use braces if the statement is more than one line long.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'foreach (foo, foos)\n'
            '    // Single-line comment\n'
            '    int bar;\n',
            'A conditional or loop body must use braces if the statement is more than one line long.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'while (true)\n'
            '    // Single-line comment\n'
            '    int foo;\n'
            '\n',
            'A conditional or loop body must use braces if the statement is more than one line long.  [whitespace/braces] [4]')

        # 4. If one part of an if-else statement uses curly braces, the
        #    other part must too.

        self.assert_multi_line_lint(
            'if (condition1) {\n'
            '    doSomething1();\n'
            '    doSomething1_2();\n'
            '} else if (condition2)\n'
            '    doSomething2();\n'
            'else\n'
            '    doSomething3();\n',
            'If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'if (condition1)\n'
            '    doSomething1();\n'
            'else if (condition2) {\n'
            '    doSomething2();\n'
            '    doSomething2_2();\n'
            '} else\n'
            '    doSomething3();\n',
            'If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'if (condition1) {\n'
            '    doSomething1();\n'
            '} else if (condition2) {\n'
            '    doSomething2();\n'
            '    doSomething2_2();\n'
            '} else\n'
            '    doSomething3();\n',
            'If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'if (condition1)\n'
            '    doSomething1();\n'
            'else if (condition2)\n'
            '    doSomething2();\n'
            'else {\n'
            '    doSomething3();\n'
            '    doSomething3_2();\n'
            '}\n',
            'If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'if (condition1) {\n'
            '    doSomething1();\n'
            '    doSomething1_2();\n'
            '} else if (condition2)\n'
            '    doSomething2();\n'
            'else {\n'
            '    doSomething3();\n'
            '    doSomething3_2();\n'
            '}\n',
            'If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]')

        self.assert_multi_line_lint(
            'if (condition1)\n'
            '    doSomething1();\n'
            'else if (condition2) {\n'
            '    doSomething2();\n'
            '    doSomething2_2();\n'
            '} else {\n'
            '    doSomething3();\n'
            '    doSomething3_2();\n'
            '}\n',
            'If one part of an if-else statement uses curly braces, the other part must too.  [whitespace/braces] [4]')


        # 5. Control clauses without a body should use empty braces.
        self.assert_multi_line_lint(
            'for ( ; current; current = current->next) { }\n',
            '')
        self.assert_multi_line_lint(
            'for ( ; current;\n'
            '     current = current->next) { }\n',
            'Weird number of spaces at line-start.  Are you using a 4-space indent?  [whitespace/indent] [3]')
        self.assert_multi_line_lint(
            'for ( ; current; current = current->next);\n',
            'Semicolon defining empty statement for this loop. Use { } instead.  [whitespace/semicolon] [5]')
        self.assert_multi_line_lint(
            'while (true);\n',
            'Semicolon defining empty statement for this loop. Use { } instead.  [whitespace/semicolon] [5]')
        self.assert_multi_line_lint(
            '} while (true);\n',
            '')

    def test_null_false_zero(self):
        # 1. In C++, the null pointer value should be written as 0. In C,
        #    it should be written as NULL. In Objective-C and Objective-C++,
        #    follow the guideline for C or C++, respectively, but use nil to
        #    represent a null Objective-C object.
        self.assert_lint(
            'functionCall(NULL)',
            'Use 0 instead of NULL.'
            '  [readability/null] [5]',
            'foo.cpp')
        self.assert_lint(
            "// Don't use NULL in comments since it isn't in code.",
            'Use 0 or null instead of NULL (even in *comments*).'
            '  [readability/null] [4]',
            'foo.cpp')
        self.assert_lint(
            '"A string with NULL" // and a comment with NULL is tricky to flag correctly in cpp_style.',
            'Use 0 or null instead of NULL (even in *comments*).'
            '  [readability/null] [4]',
            'foo.cpp')
        self.assert_lint(
            '"A string containing NULL is ok"',
            '',
            'foo.cpp')
        self.assert_lint(
            'if (aboutNULL)',
            '',
            'foo.cpp')
        self.assert_lint(
            'myVariable = NULLify',
            '',
            'foo.cpp')
        # Make sure that the NULL check does not apply to C and Objective-C files.
        self.assert_lint(
            'functionCall(NULL)',
            '',
            'foo.c')
        self.assert_lint(
            'functionCall(NULL)',
            '',
            'foo.m')

        # Make sure that the NULL check does not apply to g_object_{set,get} and
        # g_str{join,concat}
        self.assert_lint(
            'g_object_get(foo, "prop", &bar, NULL);',
            '')
        self.assert_lint(
            'g_object_set(foo, "prop", bar, NULL);',
            '')
        self.assert_lint(
            'g_build_filename(foo, bar, NULL);',
            '')
        self.assert_lint(
            'gst_bin_add_many(foo, bar, boo, NULL);',
            '')
        self.assert_lint(
            'gst_bin_remove_many(foo, bar, boo, NULL);',
            '')
        self.assert_lint(
            'gst_element_link_many(foo, bar, boo, NULL);',
            '')
        self.assert_lint(
            'gst_element_unlink_many(foo, bar, boo, NULL);',
            '')
        self.assert_lint(
            'gst_structure_get(foo, "value", G_TYPE_INT, &value, NULL);',
            '')
        self.assert_lint(
            'gst_structure_set(foo, "value", G_TYPE_INT, value, NULL);',
            '')
        self.assert_lint(
            'gst_structure_remove_fields(foo, "value", "bar", NULL);',
            '')
        self.assert_lint(
            'gst_structure_new("foo", "value", G_TYPE_INT, value, NULL);',
            '')
        self.assert_lint(
            'gst_structure_id_new(FOO, VALUE, G_TYPE_INT, value, NULL);',
            '')
        self.assert_lint(
            'gst_structure_id_set(FOO, VALUE, G_TYPE_INT, value, NULL);',
            '')
        self.assert_lint(
            'gst_structure_id_get(FOO, VALUE, G_TYPE_INT, &value, NULL);',
            '')
        self.assert_lint(
            'gst_caps_new_simple(mime, "value", G_TYPE_INT, &value, NULL);',
            '')
        self.assert_lint(
            'gst_caps_new_full(structure1, structure2, NULL);',
            '')
        self.assert_lint(
            'gchar* result = g_strconcat("part1", "part2", "part3", NULL);',
            '')
        self.assert_lint(
            'gchar* result = g_strconcat("part1", NULL);',
            '')
        self.assert_lint(
            'gchar* result = g_strjoin(",", "part1", "part2", "part3", NULL);',
            '')
        self.assert_lint(
            'gchar* result = g_strjoin(",", "part1", NULL);',
            '')
        self.assert_lint(
            'gchar* result = gdk_pixbuf_save_to_callback(pixbuf, function, data, type, error, NULL);',
            '')
        self.assert_lint(
            'gchar* result = gdk_pixbuf_save_to_buffer(pixbuf, function, data, type, error, NULL);',
            '')
        self.assert_lint(
            'gchar* result = gdk_pixbuf_save_to_stream(pixbuf, function, data, type, error, NULL);',
            '')
        self.assert_lint(
            'gtk_widget_style_get(style, "propertyName", &value, "otherName", &otherValue, NULL);',
            '')
        self.assert_lint(
            'gtk_style_context_get_style(context, "propertyName", &value, "otherName", &otherValue, NULL);',
            '')
        self.assert_lint(
            'gtk_style_context_get(context, static_cast<GtkStateFlags>(0), "property", &value, NULL);',
            '')
        self.assert_lint(
            'gtk_widget_style_get_property(style, NULL, NULL);',
            'Use 0 instead of NULL.  [readability/null] [5]',
            'foo.cpp')
        self.assert_lint(
            'gtk_widget_style_get_valist(style, NULL, NULL);',
            'Use 0 instead of NULL.  [readability/null] [5]',
            'foo.cpp')

        # 2. C++ and C bool values should be written as true and
        #    false. Objective-C BOOL values should be written as YES and NO.
        # FIXME: Implement this.

        # 3. Tests for true/false and null/non-null should be done without
        #    equality comparisons.
        self.assert_lint_one_of_many_errors_re(
            'if (string != NULL)',
            r'Tests for true/false and null/non-null should be done without equality comparisons\.')
        self.assert_lint(
            'if (p == nullptr)',
            'Tests for true/false and null/non-null should be done without equality comparisons.'
            '  [readability/comparison_to_boolean] [5]')
        self.assert_lint(
            'if (condition == true)',
            'Tests for true/false and null/non-null should be done without equality comparisons.'
            '  [readability/comparison_to_boolean] [5]')
        self.assert_lint(
            'if (myVariable != /* Why would anyone put a comment here? */ false)',
            'Tests for true/false and null/non-null should be done without equality comparisons.'
            '  [readability/comparison_to_boolean] [5]')

        self.assert_lint_one_of_many_errors_re(
            'if (NULL == thisMayBeNull)',
            r'Tests for true/false and null/non-null should be done without equality comparisons\.')
        self.assert_lint(
            'if (nullptr /* funny place for a comment */ == p)',
            'Tests for true/false and null/non-null should be done without equality comparisons.'
            '  [readability/comparison_to_boolean] [5]')
        self.assert_lint(
            'if (true != anotherCondition)',
            'Tests for true/false and null/non-null should be done without equality comparisons.'
            '  [readability/comparison_to_boolean] [5]')
        self.assert_lint(
            'if (false == myBoolValue)',
            'Tests for true/false and null/non-null should be done without equality comparisons.'
            '  [readability/comparison_to_boolean] [5]')

        self.assert_lint(
            'if (fontType == trueType)',
            '')
        self.assert_lint(
            'if (othertrue == fontType)',
            '')
        self.assert_lint(
            'if (LIKELY(foo == 0))',
            '')
        self.assert_lint(
            'if (UNLIKELY(foo == 0))',
            '')
        self.assert_lint(
            'if ((a - b) == 0.5)',
            '')
        self.assert_lint(
            'if (0.5 == (a - b))',
            '')
        self.assert_lint(
            'if (LIKELY(foo == NULL))',
            'Use 0 instead of NULL.  [readability/null] [5]')
        self.assert_lint(
            'if (UNLIKELY(foo == NULL))',
            'Use 0 instead of NULL.  [readability/null] [5]')

    def test_directive_indentation(self):
        self.assert_lint(
            "    #if FOO",
            "preprocessor directives (e.g., #ifdef, #define, #import) should never be indented."
            "  [whitespace/indent] [4]",
            "foo.cpp")

    def test_using_std(self):
        self.assert_lint(
            'using std::min;',
            "Use 'using namespace std;' instead of 'using std::min;'."
            "  [build/using_std] [4]",
            'foo.cpp')

    def test_using_std_swap_ignored(self):
        self.assert_lint(
            'using std::swap;',
            '',
            'foo.cpp')

    def test_max_macro(self):
        self.assert_lint(
            'int i = MAX(0, 1);',
            '',
            'foo.c')

        self.assert_lint(
            'int i = MAX(0, 1);',
            'Use std::max() or std::max<type>() instead of the MAX() macro.'
            '  [runtime/max_min_macros] [4]',
            'foo.cpp')

        self.assert_lint(
            'inline int foo() { return MAX(0, 1); }',
            'Use std::max() or std::max<type>() instead of the MAX() macro.'
            '  [runtime/max_min_macros] [4]',
            'foo.h')

    def test_min_macro(self):
        self.assert_lint(
            'int i = MIN(0, 1);',
            '',
            'foo.c')

        self.assert_lint(
            'int i = MIN(0, 1);',
            'Use std::min() or std::min<type>() instead of the MIN() macro.'
            '  [runtime/max_min_macros] [4]',
            'foo.cpp')

        self.assert_lint(
            'inline int foo() { return MIN(0, 1); }',
            'Use std::min() or std::min<type>() instead of the MIN() macro.'
            '  [runtime/max_min_macros] [4]',
            'foo.h')

    def test_ctype_fucntion(self):
        self.assert_lint(
            'int i = isascii(8);',
            'Use equivelent function in <wtf/ASCIICType.h> instead of the '
            'isascii() function.  [runtime/ctype_function] [4]',
            'foo.cpp')

    def test_names(self):
        name_underscore_error_message = " is incorrectly named. Don't use underscores in your identifier names.  [readability/naming/underscores] [4]"
        name_tooshort_error_message = " is incorrectly named. Don't use the single letter 'l' as an identifier name.  [readability/naming] [4]"

        # Basic cases from WebKit style guide.
        self.assert_lint('struct Data;', '')
        self.assert_lint('size_t bufferSize;', '')
        self.assert_lint('class HTMLDocument;', '')
        self.assert_lint('String mimeType();', '')
        self.assert_lint('size_t buffer_size;',
                         'buffer_size' + name_underscore_error_message)
        self.assert_lint('short m_length;', '')
        self.assert_lint('short _length;',
                         '_length' + name_underscore_error_message)
        self.assert_lint('short length_;',
                         'length_' + name_underscore_error_message)
        self.assert_lint('unsigned _length;',
                         '_length' + name_underscore_error_message)
        self.assert_lint('unsigned long _length;',
                         '_length' + name_underscore_error_message)
        self.assert_lint('unsigned long long _length;',
                         '_length' + name_underscore_error_message)

        # Allow underscores in Objective C files.
        self.assert_lint('unsigned long long _length;',
                         '',
                         'foo.m')
        self.assert_lint('unsigned long long _length;',
                         '',
                         'foo.mm')
        self.assert_lint('#import "header_file.h"\n'
                         'unsigned long long _length;',
                         '',
                         'foo.h')
        self.assert_lint('unsigned long long _length;\n'
                         '@interface WebFullscreenWindow;',
                         '',
                         'foo.h')
        self.assert_lint('unsigned long long _length;\n'
                         '@implementation WebFullscreenWindow;',
                         '',
                         'foo.h')
        self.assert_lint('unsigned long long _length;\n'
                         '@class WebWindowFadeAnimation;',
                         '',
                         'foo.h')

        # Variable name 'l' is easy to confuse with '1'
        self.assert_lint('int l;', 'l' + name_tooshort_error_message)
        self.assert_lint('size_t l;', 'l' + name_tooshort_error_message)
        self.assert_lint('long long l;', 'l' + name_tooshort_error_message)

        # Pointers, references, functions, templates, and adjectives.
        self.assert_lint('char* under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('const int UNDER_SCORE;',
                         'UNDER_SCORE' + name_underscore_error_message)
        self.assert_lint('static inline const char const& const under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('WebCore::RenderObject* under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('int func_name();',
                         'func_name' + name_underscore_error_message)
        self.assert_lint('RefPtr<RenderObject*> under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('WTF::Vector<WTF::RefPtr<const RenderObject* const> > under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('int under_score[];',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('struct dirent* under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('long under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('long long under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('long double under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('long long int under_score;',
                         'under_score' + name_underscore_error_message)

        # Declarations in control statement.
        self.assert_lint('if (int under_score = 42) {',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('else if (int under_score = 42) {',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('for (int under_score = 42; cond; i++) {',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('while (foo & under_score = bar) {',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('for (foo * under_score = p; cond; i++) {',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('for (foo * under_score; cond; i++) {',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('while (foo & value_in_thirdparty_library) {', '')
        self.assert_lint('while (foo * value_in_thirdparty_library) {', '')
        self.assert_lint('if (mli && S_OK == mli->foo()) {', '')

        # More member variables and functions.
        self.assert_lint('int SomeClass::s_validName', '')
        self.assert_lint('int m_under_score;',
                         'm_under_score' + name_underscore_error_message)
        self.assert_lint('int SomeClass::s_under_score = 0;',
                         'SomeClass::s_under_score' + name_underscore_error_message)
        self.assert_lint('int SomeClass::under_score = 0;',
                         'SomeClass::under_score' + name_underscore_error_message)

        # Other statements.
        self.assert_lint('return INT_MAX;', '')
        self.assert_lint('return_t under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('goto under_score;',
                         'under_score' + name_underscore_error_message)
        self.assert_lint('delete static_cast<Foo*>(p);', '')

        # Multiple variables in one line.
        self.assert_lint('void myFunction(int variable1, int another_variable);',
                         'another_variable' + name_underscore_error_message)
        self.assert_lint('int variable1, another_variable;',
                         'another_variable' + name_underscore_error_message)
        self.assert_lint('int first_variable, secondVariable;',
                         'first_variable' + name_underscore_error_message)
        self.assert_lint('void my_function(int variable_1, int variable_2);',
                         ['my_function' + name_underscore_error_message,
                          'variable_1' + name_underscore_error_message,
                          'variable_2' + name_underscore_error_message])
        self.assert_lint('for (int variable_1, variable_2;;) {',
                         ['variable_1' + name_underscore_error_message,
                          'variable_2' + name_underscore_error_message])

        # There is an exception for op code functions but only in the JavaScriptCore directory.
        self.assert_lint('void this_op_code(int var1, int var2)', '', 'Source/JavaScriptCore/foo.cpp')
        self.assert_lint('void op_code(int var1, int var2)', '', 'Source/JavaScriptCore/foo.cpp')
        self.assert_lint('void this_op_code(int var1, int var2)', 'this_op_code' + name_underscore_error_message)

        # GObject requires certain magical names in class declarations.
        self.assert_lint('void webkit_dom_object_init();', '')
        self.assert_lint('void webkit_dom_object_class_init();', '')

        # There is an exception for GTK+ API.
        self.assert_lint('void webkit_web_view_load(int var1, int var2)', '', 'Source/Webkit/gtk/webkit/foo.cpp')
        self.assert_lint('void webkit_web_view_load(int var1, int var2)', '', 'Source/Webkit2/UIProcess/gtk/foo.cpp')

        # Test that this doesn't also apply to files not in a 'gtk' directory.
        self.assert_lint('void webkit_web_view_load(int var1, int var2)',
            'webkit_web_view_load is incorrectly named. Don\'t use underscores in your identifier names.'
            '  [readability/naming/underscores] [4]', 'Source/Webkit/webkit/foo.cpp')
        # Test that this doesn't also apply to names that don't start with 'webkit_'.
        self.assert_lint_one_of_many_errors_re('void otherkit_web_view_load(int var1, int var2)',
            'otherkit_web_view_load is incorrectly named. Don\'t use underscores in your identifier names.'
            '  [readability/naming/underscores] [4]', 'Source/Webkit/webkit/foo.cpp')

        # There is an exception for some unit tests that begin with "tst_".
        self.assert_lint('void tst_QWebFrame::arrayObjectEnumerable(int var1, int var2)', '')

        # The Qt API uses names that begin with "qt_" or "_q_".
        self.assert_lint('void QTFrame::qt_drt_is_awesome(int var1, int var2)', '')
        self.assert_lint('void QTFrame::_q_drt_is_awesome(int var1, int var2)', '')
        self.assert_lint('void qt_drt_is_awesome(int var1, int var2);', '')
        self.assert_lint('void _q_drt_is_awesome(int var1, int var2);', '')

        # Cairo forward-declarations should not be a failure.
        self.assert_lint('typedef struct _cairo cairo_t;', '')
        self.assert_lint('typedef struct _cairo_surface cairo_surface_t;', '')
        self.assert_lint('typedef struct _cairo_scaled_font cairo_scaled_font_t;', '')

        # EFL forward-declarations should not be a failure.
        self.assert_lint('typedef struct _Ecore_Evas Ecore_Evas;', '')
        self.assert_lint('typedef struct _Ecore_Pipe Ecore_Pipe;', '')
        self.assert_lint('typedef struct _Eina_Rectangle Eina_Rectangle;', '')
        self.assert_lint('typedef struct _Evas_Object Evas_Object;', '')
        self.assert_lint('typedef struct _Ewk_History_Item Ewk_History_Item;', '')

        # const_iterator is allowed as well.
        self.assert_lint('typedef VectorType::const_iterator const_iterator;', '')

        # vm_throw is allowed as well.
        self.assert_lint('int vm_throw;', '')

        # Attributes.
        self.assert_lint('int foo ALLOW_UNUSED;', '')
        self.assert_lint('int foo_error ALLOW_UNUSED;', 'foo_error' + name_underscore_error_message)
        self.assert_lint('ThreadFunctionInvocation* leakedInvocation ALLOW_UNUSED = invocation.leakPtr()', '')

        # Bitfields.
        self.assert_lint('unsigned _fillRule : 1;',
                         '_fillRule' + name_underscore_error_message)

        # new operators in initialization.
        self.assert_lint('OwnPtr<uint32_t> variable(new uint32_t);', '')
        self.assert_lint('OwnPtr<uint32_t> variable(new (expr) uint32_t);', '')
        self.assert_lint('OwnPtr<uint32_t> under_score(new uint32_t);',
                         'under_score' + name_underscore_error_message)

        # Conversion operator declaration.
        self.assert_lint('operator int64_t();', '')

    def test_parameter_names(self):
        # Leave meaningless variable names out of function declarations.
        meaningless_variable_name_error_message = 'The parameter name "%s" adds no information, so it should be removed.  [readability/parameter_name] [5]'

        parameter_error_rules = ('-',
                                 '+readability/parameter_name')
        # No variable name, so no error.
        self.assertEqual('',
                          self.perform_lint('void func(int);', 'test.cpp', parameter_error_rules))

        # Verify that copying the name of the set function causes the error (with some odd casing).
        self.assertEqual(meaningless_variable_name_error_message % 'itemCount',
                          self.perform_lint('void setItemCount(size_t itemCount);', 'test.cpp', parameter_error_rules))
        self.assertEqual(meaningless_variable_name_error_message % 'abcCount',
                          self.perform_lint('void setABCCount(size_t abcCount);', 'test.cpp', parameter_error_rules))

        # Verify that copying a type name will trigger the warning (even if the type is a template parameter).
        self.assertEqual(meaningless_variable_name_error_message % 'context',
                          self.perform_lint('void funct(PassRefPtr<ScriptExecutionContext> context);', 'test.cpp', parameter_error_rules))

        # Verify that acronyms as variable names trigger the error (for both set functions and type names).
        self.assertEqual(meaningless_variable_name_error_message % 'ec',
                          self.perform_lint('void setExceptionCode(int ec);', 'test.cpp', parameter_error_rules))
        self.assertEqual(meaningless_variable_name_error_message % 'ec',
                          self.perform_lint('void funct(ExceptionCode ec);', 'test.cpp', parameter_error_rules))

        # 'object' alone, appended, or as part of an acronym is meaningless.
        self.assertEqual(meaningless_variable_name_error_message % 'object',
                          self.perform_lint('void funct(RenderView object);', 'test.cpp', parameter_error_rules))
        self.assertEqual(meaningless_variable_name_error_message % 'viewObject',
                          self.perform_lint('void funct(RenderView viewObject);', 'test.cpp', parameter_error_rules))
        self.assertEqual(meaningless_variable_name_error_message % 'rvo',
                          self.perform_lint('void funct(RenderView rvo);', 'test.cpp', parameter_error_rules))

        # Check that r, g, b, and a are allowed.
        self.assertEqual('',
                          self.perform_lint('void setRGBAValues(int r, int g, int b, int a);', 'test.cpp', parameter_error_rules))

        # Verify that a simple substring match isn't done which would cause false positives.
        self.assertEqual('',
                          self.perform_lint('void setNateLateCount(size_t elate);', 'test.cpp', parameter_error_rules))
        self.assertEqual('',
                          self.perform_lint('void funct(NateLate elate);', 'test.cpp', parameter_error_rules))

        # Don't have generate warnings for functions (only declarations).
        self.assertEqual('',
                          self.perform_lint('void funct(PassRefPtr<ScriptExecutionContext> context)\n'
                                            '{\n'
                                            '}\n', 'test.cpp', parameter_error_rules))

    def test_comments(self):
        # A comment at the beginning of a line is ok.
        self.assert_lint('// comment', '')
        self.assert_lint('    // comment', '')

        self.assert_lint('}  // namespace WebCore',
                         'One space before end of line comments'
                         '  [whitespace/comments] [5]')

    def test_webkit_export_check(self):
        webkit_export_error_rules = ('-',
                                  '+readability/webkit_export')
        self.assertEqual('',
                          self.perform_lint('WEBKIT_EXPORT int foo();\n',
                                            'WebKit/chromium/public/test.h',
                                            webkit_export_error_rules))
        self.assertEqual('',
                          self.perform_lint('WEBKIT_EXPORT int foo();\n',
                                            'WebKit/chromium/tests/test.h',
                                            webkit_export_error_rules))
        self.assertEqual('WEBKIT_EXPORT should only be used in header files.  [readability/webkit_export] [5]',
                          self.perform_lint('WEBKIT_EXPORT int foo();\n',
                                            'WebKit/chromium/public/test.cpp',
                                            webkit_export_error_rules))
        self.assertEqual('WEBKIT_EXPORT should only appear in the chromium public (or tests) directory.  [readability/webkit_export] [5]',
                          self.perform_lint('WEBKIT_EXPORT int foo();\n',
                                            'WebKit/chromium/src/test.h',
                                            webkit_export_error_rules))
        self.assertEqual('WEBKIT_EXPORT should not be used on a function with a body.  [readability/webkit_export] [5]',
                          self.perform_lint('WEBKIT_EXPORT int foo() { }\n',
                                            'WebKit/chromium/public/test.h',
                                            webkit_export_error_rules))
        self.assertEqual('WEBKIT_EXPORT should not be used on a function with a body.  [readability/webkit_export] [5]',
                          self.perform_lint('WEBKIT_EXPORT inline int foo()\n'
                                            '{\n'
                                            '}\n',
                                            'WebKit/chromium/public/test.h',
                                            webkit_export_error_rules))
        self.assertEqual('WEBKIT_EXPORT should not be used with a pure virtual function.  [readability/webkit_export] [5]',
                          self.perform_lint('{}\n'
                                            'WEBKIT_EXPORT\n'
                                            'virtual\n'
                                            'int\n'
                                            'foo() = 0;\n',
                                            'WebKit/chromium/public/test.h',
                                            webkit_export_error_rules))
        self.assertEqual('',
                          self.perform_lint('{}\n'
                                            'WEBKIT_EXPORT\n'
                                            'virtual\n'
                                            'int\n'
                                            'foo() = 0;\n',
                                            'test.h',
                                            webkit_export_error_rules))

    def test_other(self):
        # FIXME: Implement this.
        pass


class CppCheckerTest(unittest.TestCase):

    """Tests CppChecker class."""

    def mock_handle_style_error(self):
        pass

    def _checker(self):
        return CppChecker("foo", "h", self.mock_handle_style_error, 3)

    def test_init(self):
        """Test __init__ constructor."""
        checker = self._checker()
        self.assertEqual(checker.file_extension, "h")
        self.assertEqual(checker.file_path, "foo")
        self.assertEqual(checker.handle_style_error, self.mock_handle_style_error)
        self.assertEqual(checker.min_confidence, 3)

    def test_eq(self):
        """Test __eq__ equality function."""
        checker1 = self._checker()
        checker2 = self._checker()

        # == calls __eq__.
        self.assertTrue(checker1 == checker2)

        def mock_handle_style_error2(self):
            pass

        # Verify that a difference in any argument cause equality to fail.
        checker = CppChecker("foo", "h", self.mock_handle_style_error, 3)
        self.assertFalse(checker == CppChecker("bar", "h", self.mock_handle_style_error, 3))
        self.assertFalse(checker == CppChecker("foo", "c", self.mock_handle_style_error, 3))
        self.assertFalse(checker == CppChecker("foo", "h", mock_handle_style_error2, 3))
        self.assertFalse(checker == CppChecker("foo", "h", self.mock_handle_style_error, 4))

    def test_ne(self):
        """Test __ne__ inequality function."""
        checker1 = self._checker()
        checker2 = self._checker()

        # != calls __ne__.
        # By default, __ne__ always returns true on different objects.
        # Thus, just check the distinguishing case to verify that the
        # code defines __ne__.
        self.assertFalse(checker1 != checker2)
